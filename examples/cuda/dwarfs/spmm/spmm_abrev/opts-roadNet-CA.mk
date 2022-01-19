# use dynamic work scheduling
SPMM_RV				= spmm_dynamic.riscv.rvo
# use hash table to solve row
SPMM_SOLVE_ROW_RV		= spmm_solve_row_insertion_sort
SPMM_HASH_TABLE			= no
# use sum tree to compute offsets
SPMM_COMPUTE_OFFSETS_RV		= spmm_compute_offsets_sum_tree
# use copy results
SPMM_COPY_RESULTS_RV		= spmm_copy_results
# don't use sort
SPMM_SORT_ROW_RV		= 
# use local memory
SPMM_SOLVE_ROW_LOCAL_DATA_WORDS	= 256
# use prefetch
SPMM_PREFETCH                   = yes
# prefetch factor of 4
SPMM_PREFETCH_N			= 4
# use an aligned hash table
SPMM_ALIGNED_TABLE		= yes
# do sort results
SPMM_SKIP_SORTING		= yes
# tiles grab four work items at once
SPMM_WORK_GRANULARITY		= 128
