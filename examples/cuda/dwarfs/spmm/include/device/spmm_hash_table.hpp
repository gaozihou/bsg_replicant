#pragma once
#include "spmm_solve_row.hpp"
#include "util.h"

namespace hash_table {
/* hash table entry */
    typedef struct spmm_elt {
        spmm_partial_t part; //!< partial
        spmm_elt    *bkt_next; //!< next in bucket
        spmm_elt    *tbl_next; //!< next in table
    } spmm_elt_t;

#ifndef SPMM_SOLVE_ROW_LOCAL_DATA_WORDS
#error "define SPMM_SOLVE_ROW_LOCAL_DATA_WORDS"
#endif

#define SPMM_ELT_LOCAL_POOL_SIZE                                        \
    (SPMM_SOLVE_ROW_LOCAL_DATA_WORDS*sizeof(int)/sizeof(spmm_elt_t))
/**
 * Pool of entries allocated in DMEM.
 */
    extern thread spmm_elt_t local_elt_pool[SPMM_ELT_LOCAL_POOL_SIZE];

/**
 * List of all entries in the table.
 */
    extern thread spmm_elt_t *tbl_head;
    extern thread int tbl_num_entries;

/**
 * List of available free frames in local memory
 */
    extern thread spmm_elt_t *free_local_head;

/**
 * List of available free frames in off-chip memory
 */
    extern thread spmm_elt_t *free_global_head;

/**
 * Total non-zeros table
 */
#ifndef NONZEROS_TABLE_SIZE
#error "define NONZEROS_TABLE_SIZE"
#endif
    extern spmm_elt_t *nonzeros_table [bsg_global_X * bsg_global_Y * NONZEROS_TABLE_SIZE];

    /* type of for hash index */
    typedef unsigned hidx_t;

#if defined(ALIGNED_TABLE)
    extern thread hidx_t block_select;
#endif

#ifndef LOG2_VCACHE_STRIPE_WORDS
#error "Define LOG2_VCACHE_STRIPE_WORDS"
#endif

#ifndef LOG2_GLOBAL_X
#error "Define LOG2_GLOBAL_X"
#endif

#ifndef LOG2_GLOBAL_Y
#error "Define LOG2_GLOBAL_Y"
#endif

#if defined(ALIGNED_TABLE)
/**
 * x cord shift
 */
#define X_SHIFT                                 \
    (LOG2_VCACHE_STRIPE_WORDS)
/**
 * south-not-north bit shift
 */
#define SOUTH_NOT_NORTH_SHIFT                   \
    ((X_SHIFT)+(LOG2_GLOBAL_X))
/**
 * y cord shift (selects set in vcache)
 */
#define Y_SHIFT                                 \
    ((SOUTH_NOT_NORTH_SHIFT)+1)
/**
 * high bits shift
 */
#define HI_SHIFT                                \
    ((Y_SHIFT)+(LOG2_GLOBAL_Y-1))
#endif

    /**
     * Do some initialization for the hash function.
     */
    static void hash_init()
    {
#if defined(ALIGNED_TABLE)
        hidx_t tbl_x, tbl_y, south_not_north;
        tbl_x = __bsg_x;
        south_not_north = __bsg_y / (bsg_global_Y/2);
        tbl_y = __bsg_y % (bsg_global_Y/2);
        pr_dbg("init: bsg_global_X = %3u, bsg_global_Y = %3u\n"
               , bsg_global_X
               , bsg_global_Y);
        pr_dbg("init: (x=%3d,y=%3d): tbl_y = %3u, tbl_x = %3u, south_not_north = %3u\n"
               , __bsg_x
               , __bsg_y
               , tbl_y
               , tbl_x
               , south_not_north);
        block_select
            = (tbl_y << Y_SHIFT)
            | (south_not_north << SOUTH_NOT_NORTH_SHIFT)
            | (tbl_x << X_SHIFT);
#endif
    }

    /**
     * Hash function
     */
    static int hash(int sx)
    {
        hidx_t x = static_cast<hidx_t>(sx);
#if defined(COMPLEX_HASH)
        // maybe do an xor shift
        // maybe just the low bits
        x = ((x >> 16) ^ x) * 0x45d9f3bU;
        x = ((x >> 16) ^ x) * 0x45d9f3bU;
        x = ((x >> 16) ^ x);
#endif
        x = x % NONZEROS_TABLE_SIZE;
#if !defined(ALIGNED_TABLE)
        return x;
#else
        hidx_t hi = x / VCACHE_STRIPE_WORDS;
        hidx_t lo = x % VCACHE_STRIPE_WORDS;
        return (hi << HI_SHIFT) | block_select | lo;
#endif
    }


   /**
    * Next reallocation size, initialize one cache line.
    */
    extern int elts_realloc_size;

    /**
     * Allocate a hash element.
     */
    static spmm_elt_t* alloc_elt()
    {
        spmm_elt_t *elt;
        // try to allocate from local memory
        if (free_local_head != nullptr) {
            elt = free_local_head;
            free_local_head = elt->tbl_next;
            elt->tbl_next = nullptr;
            return elt;
        // try to allocate from global memory
        } else if (free_global_head != nullptr) {
            elt = free_global_head;
            free_global_head = elt->tbl_next;
            elt->tbl_next = nullptr;
            return elt;
        // allocate more frames from global memory
        } else {
            spmm_elt_t *newelts = (spmm_elt_t*)spmm_malloc(elts_realloc_size*sizeof(spmm_elt_t));
            int i;
            for (i = 0; i < elts_realloc_size-1; i++) {
                newelts[i].tbl_next = &newelts[i+1];
            }
            newelts[elts_realloc_size-1].tbl_next = nullptr;
            free_global_head = &newelts[0];
            pr_dbg("  %s: free_global_head = 0x%08x\n"
                          , __func__
                          , free_global_head);
            elts_realloc_size <<= 1;
            return alloc_elt();
        }
    }

    /**
     * Return a hash element to the free pool
     */
    static void free_elt(spmm_elt_t *elt)
    {
        intptr_t eltaddr = reinterpret_cast<intptr_t>(elt);
        elt->bkt_next = nullptr;
        // belongs in local memory?
        if (!(eltaddr & 0x80000000)) {
            elt->tbl_next = free_local_head;
            free_local_head = elt;
        // belongs in global
        } else {
            elt->tbl_next = free_global_head;
            free_global_head = elt;
        }
    }

    /**
     * Update with v, idx, and the compute hash index hidx
     */
    static void update(float v, int idx, int hidx)
    {
            spmm_elt_t **u = &nonzeros_table[hidx];
            spmm_elt_t  *p = nonzeros_table[hidx];
            pr_dbg("  &table[%3d] = 0x%08x\n"
                          , idx
                          , u);
            pr_dbg("  table[%3d] = 0x%08x\n"
                          , idx
                          , p);
            while (p != nullptr) {
                // match?
                if (p->part.idx == idx) {
                    pr_dbg("  %3d found at 0x%08x\n"
                                  , idx
                                  , p);
#define      SPMM_NO_FLOPS
#if !defined(SPMM_NO_FLOPS)
                    p->part.val += v; // flw; fadd; fsw
#else
                    p->part.val  = v; // fsw
#endif
                    return;
                }
                u = &p->bkt_next;
                p = p->bkt_next;
            }
            // allocate a hash item
            p = alloc_elt();
            pr_dbg("  %3d not found, inserting at 0x%08x\n"
                          , idx
                          , p);
            // set item parameters
            p->part.idx = idx;
            p->part.val = v;
            p->bkt_next = nullptr;
            p->tbl_next = tbl_head;
            tbl_head = p;
            // update last
            *u = p;
            tbl_num_entries++;
            return;
    }

    /**
     * Hash table init
     */
    static void init()
    {
        pr_dbg("init: calling from " __FILE__ "\n");
        // initialize nonzeros table in dram
        pr_dbg("init: nonzeros_table[start] = 0x%08x\n"
                      , &nonzeros_table[0]);
        pr_dbg("init: nonzeros_table[end]   = 0x%08x\n"
                      , &nonzeros_table[ARRAY_SIZE(nonzeros_table)-1]);
        hash_init();
        // initialize list of local nodes
        int i;
        if (ARRAY_SIZE(local_elt_pool) > 0) {
            free_local_head = &local_elt_pool[0];
            for (i = 0; i < ARRAY_SIZE(local_elt_pool)-1; i++) {
                local_elt_pool[i].tbl_next = &local_elt_pool[i+1];
            }
            local_elt_pool[ARRAY_SIZE(local_elt_pool)-1].tbl_next = nullptr;
            pr_dbg("init: local_elt_pool[N-1]=0x%08x\n"
                          , &local_elt_pool[ARRAY_SIZE(local_elt_pool)-1]);
        }
        pr_dbg("init: free_local_head  = 0x%08x\n", free_local_head);
        pr_dbg("init: free_global_head = 0x%08x\n", free_global_head);
    }
}
