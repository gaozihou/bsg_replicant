# Copyright (c) 2021, University of Washington All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may
# be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This Makefile compiles, links, and executes examples Run `make help`
# to see the available targets for the selected platform.

################################################################################
# environment.mk verifies the build environment and sets the following
# makefile variables:
#
# LIBRAIRES_PATH: The path to the libraries directory
# HARDWARE_PATH: The path to the hardware directory
# EXAMPLES_PATH: The path to the examples directory
# BASEJUMP_STL_DIR: Path to a clone of BaseJump STL
# BSG_MANYCORE_DIR: Path to a clone of BSG Manycore
###############################################################################

REPLICANT_PATH:=$(shell git rev-parse --show-toplevel)

include $(REPLICANT_PATH)/environment.mk
include $(BSG_MACHINE_PATH)/Makefile.machine.include

# hammerblade helpers
hammerblade-helpers-dir = $(EXAMPLES_PATH)/cuda/dwarfs/imports/hammerblade-helpers
include $(hammerblade-helpers-dir)/libhammerblade-helpers-host.mk

# graph tools
graphtools-dir = $(EXAMPLES_PATH)/cuda/dwarfs/imports/graph-tools
include $(graphtools-dir)/libgraphtools.mk

# eigen
eigen-dir = $(EXAMPLES_PATH)/cuda/dwarfs/imports/eigen

include parameters.mk
include $(APPLICATION_PATH)/inputs.mk

vpath %.cpp $(APPLICATION_PATH)
vpath %.cpp $(APPLICATION_PATH)/src/device
vpath %.cpp $(APPLICATION_PATH)/src/host
vpath %.cpp $(APPLICATION_PATH)/src/common
vpath %.cpp $(EXAMPLES_PATH)/cuda/dwarfs/src
vpath %.c   $(APPLICATION_PATH)
vpath %.c   $(APPLICATION_PATH)/src/device
vpath %.c   $(APPLICATION_PATH)/src/host
vpath %.c   $(APPLICATION_PATH)/src/common
vpath %.c   $(EXAMPLES_PATH)/cuda/dwarfs/src

# TEST_NAME is the basename of the executable
TEST_NAME = main
# KERNEL_NAME is the name of the CUDA-Lite Kernel
KERNEL_NAME = kernel_spmm

###############################################################################
# Host code compilation flags and flow
###############################################################################
# TEST_SOURCES is a list of source files that need to be compiled
TEST_SOURCES  = spmm_main_abrev_multipod_model.cpp
TEST_SOURCES += Random.cpp

TEST_HEADERS =  $(shell find $(APPLICATION_PATH)/include/host/ -name *.h)
TEST_HEADERS += $(shell find $(APPLICATION_PATH)/include/host/ -name *.hpp)
TEST_HEADERS += $(shell find $(APPLICATION_PATH)/include/common/ -name *.h)
TEST_HEADERS += $(shell find $(APPLICATION_PATH)/include/common/ -name *.hpp)
TEST_HEADERS =  $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/host/ -name *.h)
TEST_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/host/ -name *.hpp)
TEST_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/common/ -name *.h)
TEST_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/common/ -name *.hpp)

DEFINES += -D_XOPEN_SOURCE=500 -D_BSD_SOURCE -D_DEFAULT_SOURCE
CDEFINES += 
CXXDEFINES += 

FLAGS     = -O3 -g -Wall -Wno-unused-function -Wno-unused-variable
FLAGS    += -I$(APPLICATION_PATH)/include/host
FLAGS    += -I$(APPLICATION_PATH)/include/common
FLAGS    += -I$(EXAMPLES_PATH)/cuda/dwarfs/include/host
FLAGS    += -I$(EXAMPLES_PATH)/cuda/dwarfs/include/common
CFLAGS   += -std=c99 $(FLAGS)
CXXFLAGS += -std=c++11 $(FLAGS)
CXXFLAGS += -I$(eigen-dir)
CXXFLAGS += $(libhammerblade-helpers-host-interface-cxxflags)
CXXFLAGS += $(libgraphtools-interface-cxxflags)

# compilation.mk defines rules for compilation of C/C++
include $(EXAMPLES_PATH)/compilation.mk

###############################################################################
# Host code link flags and flow
###############################################################################

LDFLAGS += $(libhammerblade-helpers-host-interface-ldflags)
LDFLAGS += $(libgraphtools-interface-ldflags)

# link.mk defines rules for linking of the final execution binary.
include $(EXAMPLES_PATH)/link.mk
$(TEST_OBJECTS): $(libhammerblade-helpers-host-interface-libraries)
$(TEST_OBJECTS): $(libhammerblade-helpers-host-interface-headers)
$(TEST_OBJECTS): $(libgraphtools-interface-libraries)
$(TEST_OBJECTS): $(libgraphtools-interface-headers)
$(TEST_OBJECTS): $(TEST_HEADERS)
$(TEST_OBJECTS): $($(INPUT))
###############################################################################
# Device code compilation flow
###############################################################################

# BSG_MANYCORE_KERNELS is a list of manycore executables that should
# be built before executing.
ifndef BSG_MANYCORE_KERNELS
$(error "BSG_MANYCORE_KERNELS not defined")
endif

#RISCV_TARGET_OBJECTS  = main.riscv.rvo
RISCV_HEADERS += $(shell find $(APPLICATION_PATH)/include/device/ -name *.h)
RISCV_HEADERS += $(shell find $(APPLICATION_PATH)/include/device/ -name *.hpp)
RISCV_HEADERS += $(shell find $(APPLICATION_PATH)/include/common/ -name *.h)
RISCV_HEADERS += $(shell find $(APPLICATION_PATH)/include/common/ -name *.hpp)
RISCV_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/device/ -name *.h)
RISCV_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/device/ -name *.hpp)
RISCV_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/common/ -name *.h)
RISCV_HEADERS += $(shell find $(EXAMPLES_PATH)/cuda/dwarfs/include/common/ -name *.hpp)
RISCV_HEADERS += $(EXAMPLES_PATH

ifeq ($(OPT),yes)
RISCV_TARGET_OBJECTS += spmm_dynamic.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_solve_row_hash_table.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_compute_offsets_sum_tree.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_copy_results.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_sort_row.riscv.rvo
RISCV_CCPPFLAGS += -DSPMM_SOLVE_ROW_LOCAL_DATA_WORDS=$(shell echo 128*6 | bc)
#RISCV_CCPPFLAGS += -DCOMPLEX_HASH
RISCV_CCPPFLAGS += -DALIGNED_TABLE
RISCV_CCPPFLAGS += -DSPMM_PREFETCH
else
RISCV_TARGET_OBJECTS += spmm.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_solve_row_hash_table.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_compute_offsets_sum_tree.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_copy_results.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_sort_row.riscv.rvo
RISCV_CCPPFLAGS += -DSPMM_SOLVE_ROW_LOCAL_DATA_WORDS=0
endif
RISCV_TARGET_OBJECTS += spmm_init.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_hash_table.riscv.rvo
RISCV_TARGET_OBJECTS += spmm_barrier.riscv.rvo
# use 1 thread or 128 threads
ifeq ($(PARALLEL),yes)
TX=$(BSG_MACHINE_GLOBAL_X)
TY=$(BSG_MACHINE_GLOBAL_Y)
else
TX=1
TY=1
endif

RISCV_INCLUDES  += -I$(APPLICATION_PATH)/include/device
RISCV_INCLUDES  += -I$(APPLICATION_PATH)/include/common
RISCV_INCLUDES  += -I$(EXAMPLES_PATH)/cuda/dwarfs/include/device
RISCV_INCLUDES  += -I$(EXAMPLES_PATH)/cuda/dwarfs/include/common
RISCV_CCPPFLAGS += -D__KERNEL__ -ffreestanding $(EXTRA_RISCV_CCPPFLAGS)
RISCV_CCPPFLAGS += -DLOG2_THREADS=$(shell echo 'l($(TX)*$(TY))/l(2)' | bc -l | xargs printf '%.f\n')
RISCV_CCPPFLAGS += -DNONZEROS_TABLE_SIZE=1024
RISCV_OPT_LEVEL  = -O3

TILE_GROUP_DIM_X=$(TX)
TILE_GROUP_DIM_Y=$(TY)
RISCV_DEFINES += -DTILE_GROUP_DIM_X=$(TILE_GROUP_DIM_X)
RISCV_DEFINES += -DTILE_GROUP_DIM_Y=$(TILE_GROUP_DIM_Y)
RISCV_DEFINES += -Dbsg_tiles_X=$(TILE_GROUP_DIM_X)
RISCV_DEFINES += -Dbsg_tiles_Y=$(TILE_GROUP_DIM_Y)
RISCV_DEFINES += -D__KERNEL__
RISCV_DEFINES += -DGROUPS=$(GROUPS)
RISCV_DEFINES += -DVCACHE_STRIPE_WORDS=$(BSG_MACHINE_VCACHE_STRIPE_WORDS)
RISCV_DEFINES += -DTAG_ROW_SOLVE=0x1
RISCV_DEFINES += -DTAG_OFFSET_COMPUTE=0x2
RISCV_DEFINES += -DTAG_RESULTS_COPY=0x3
RISCV_DEFINES += -D__KERNEL_SPMM__
RISCV_DEFINES += -D__PART__
include $(APPLICATION_PATH)/utils.mk
RISCV_DEFINES += -DLOG2_VCACHE_STRIPE_WORDS=$(call log2,$(BSG_MACHINE_VCACHE_STRIPE_WORDS))
RISCV_DEFINES += -DLOG2_GLOBAL_X=$(call log2,$(BSG_MACHINE_GLOBAL_X))
RISCV_DEFINES += -DLOG2_GLOBAL_Y=$(call log2,$(BSG_MACHINE_GLOBAL_Y))

include $(EXAMPLES_PATH)/cuda/riscv.mk

RISCV_CXX = $(RISCV_GXX)
RISCV_CC  = $(RISCV_GCC)

###############################################################################
# Execution flow
#
# C_ARGS: Use this to pass arguments that you want to appear in argv
#         For SPMD tests C arguments are: <Path to RISC-V Binary> <Test Name>
#
# SIM_ARGS: Use this to pass arguments to the simulator
###############################################################################
C_ARGS  = $(BSG_MANYCORE_KERNELS) $(KERNEL_NAME)
C_ARGS += $($(INPUT)) $($(INPUT)__directed) $($(INPUT)__weighted) $($(INPUT)__zero-indexed)
C_ARGS += $(TILE_GROUP_DIM_X) $(TILE_GROUP_DIM_Y)
C_ARGS += $(PARTFACTOR) $(PARTITION)

SIM_ARGS ?=

# Include platform-specific execution rules
include $(EXAMPLES_PATH)/execution.mk

###############################################################################
# Default rules, help, and clean
###############################################################################
.DEFAULT_GOAL := help
help:
	@echo "Usage:"
	@echo "make {clean | $(TEST_NAME).{profile,debug} | $(TEST_NAME).{profile,debug}.log}"
	@echo "      $(TEST_NAME).profile: Build executable with profilers enabled"
	@echo "      $(TEST_NAME).debug: Build waveform executable (if VCS)"
	@echo "      $(TEST_NAME).{profile,debug}.log: Run specific executable"
	@echo "      clean: Remove all subdirectory-specific outputs"


.PHONY: clean

stats:
	PYTHONPATH=$(BSG_MANYCORE_DIR)/software/py python3 -m vanilla_parser --only stats_parser --vcache-stats vcache_stats.csv
