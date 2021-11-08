# use dynamic work scheduling
SPMM_RV				= spmm_dynamic.riscv.rvo
# use hash table to solve row
SPMM_SOLVE_ROW_RV		= spmm_solve_row_hash_table.riscv.rvo
# use sum tree to compute offsets
SPMM_COMPUTE_OFFSETS_RV		= spmm_compute_offsets_sum_tree.riscv.rvo
# use copy results
SPMM_COPY_RESULTS_RV		= spmm_copy_results.riscv.rvo
# use sort
SPMM_SORT_ROW_RV		= spmm_sort_row.riscv.rvo
# use local memory
SPMM_SOLVE_ROW_LOCAL_DATA_WORDS	= $(shell echo 256*2|bc)
# use prefetch
SPMM_PREFETCH                   = yes
# prefetch factor of 4
SPMM_PREFETCH_N			= 4
# use an aligned hash table
SPMM_ALIGNED_TABLE		= yes
# do sort results
SPMM_SKIP_SORTING		= no
# tiles grab four work items at once
SPMM_WORK_GRANULARITY		= 1