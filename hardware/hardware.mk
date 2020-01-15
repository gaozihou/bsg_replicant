# Copyright (c) 2019, University of Washington All rights reserved.
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

# This makefile fragmeent adds to the list of hardware sources
# $(VSOURCES) and $(VHEADERS) that are necessary to use this project.

# Some $(VSOURCES) and $(VHEADERS) are generated by scripts. These
# files have rules that generate the outputs, so it is good practice
# to have rules depend on $(VSOURCES) and $(VHEADERS)

# This file REQUIRES several variables to be set. They are typically
# set by the Makefile that includes this makefile..
# 
# CL_DIR: The path to the root of the BSG F1 Repository
ifndef CL_DIR
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: CL_DIR is not defined$(NC)"))
endif

# HARDWARE_PATH: The path to the hardware folder in BSG F1
ifndef HARDWARE_PATH
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: HARDWARE_PATH is not defined$(NC)"))
endif

# BSG_MANYCORE_DIR: The path to the bsg_manycore repository
ifndef BSG_MANYCORE_DIR
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: BSG_MANYCORE_DIR is not defined$(NC)"))
endif

# BASEJUMP_STL_DIR: The path to the bsg_manycore repository
ifndef BASEJUMP_STL_DIR
$(error $(shell echo -e "$(RED)BSG MAKE ERROR: BASEJUMP_STL_DIR is not defined$(NC)"))
endif

# Makefile.machine.include defines the Manycore hardware
# configuration.
include $(CL_DIR)/Makefile.machine.include
CL_MANYCORE_MAX_EPA_WIDTH            := $(BSG_MACHINE_MAX_EPA_WIDTH)
CL_MANYCORE_DATA_WIDTH               := $(BSG_MACHINE_DATA_WIDTH)
CL_MANYCORE_VCACHE_WAYS              := $(BSG_MACHINE_VCACHE_WAY)
CL_MANYCORE_VCACHE_SETS              := $(BSG_MACHINE_VCACHE_SET)
CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS  := $(BSG_MACHINE_VCACHE_BLOCK_SIZE_WORDS)
CL_MANYCORE_VCACHE_MISS_FIFO_ELS     := $(BSG_MACHINE_VCACHE_MISS_FIFO_ELS)
CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS := $(BSG_MACHINE_VCACHE_STRIPE_SIZE_WORDS)
CL_MANYCORE_BRANCH_TRACE_EN          := $(BSG_MACHINE_BRANCH_TRACE_EN)
CL_MANYCORE_RELEASE_VERSION          ?= $(shell echo $(FPGA_IMAGE_VERSION) | sed 's/\([0-9]*\)\.\([0-9]*\).\([0-9]*\)/000\10\20\3/')
CL_MANYCORE_COMPILATION_DATE         ?= $(shell date +%m%d%Y)
CL_TOP_MODULE                        := cl_manycore

# The following variables are defined by environment.mk if this bsg_f1
# repository is a submodule of bsg_bladerunner. If they are not set,
# we use default values.
BASEJUMP_STL_COMMIT_ID ?= deadbeef
BSG_MANYCORE_COMMIT_ID ?= feedcafe
BSG_F1_COMMIT_ID       ?= 42c0ffee
FPGA_IMAGE_VERSION     ?= 0.0.0

# The manycore architecture sources are defined in arch_filelist.mk. The
# unsynthesizable simulation sources (for tracing, etc) are defined in
# sim_filelist.mk. Each file adds to VSOURCES and VINCLUDES and depends on
# BSG_MANYCORE_DIR
include $(BSG_MANYCORE_DIR)/machines/arch_filelist.mk

# So that we can limit tool-specific to a few specific spots we use VDEFINES,
# VINCLUDES, and VSOURCES to hold lists of macros, include directores, and
# verilog sources (respectively). These are used during simulation compilation,
# but transformed into a tool-specific syntax where necesssary.
VINCLUDES += $(HARDWARE_PATH)

VSOURCES += $(HARDWARE_PATH)/bsg_bladerunner_mem_cfg_pkg.v
VSOURCES += $(HARDWARE_PATH)/bsg_bladerunner_configuration.v
VSOURCES += $(HARDWARE_PATH)/cl_manycore_pkg.v
VSOURCES += $(HARDWARE_PATH)/$(CL_TOP_MODULE).sv
VSOURCES += $(HARDWARE_PATH)/bsg_manycore_wrapper.v
VSOURCES += $(HARDWARE_PATH)/bsg_print_stat_snoop.v

VSOURCES += $(CL_DIR)/hardware/bsg_bladerunner_rom.v
VSOURCES += $(CL_DIR)/hardware/axil_to_mcl.v
VSOURCES += $(CL_DIR)/hardware/s_axil_mcl_adapter.v
VSOURCES += $(CL_DIR)/hardware/axil_to_mem.sv

VHEADERS += $(HARDWARE_PATH)/f1_parameters.vh
VHEADERS += $(HARDWARE_PATH)/axil_to_mcl.vh
VHEADERS += $(HARDWARE_PATH)/bsg_axi_bus_pkg.vh
VHEADERS += $(HARDWARE_PATH)/bsg_bladerunner_rom_pkg.vh
VHEADERS += $(HARDWARE_PATH)/cl_manycore_defines.vh
VHEADERS += $(HARDWARE_PATH)/cl_id_defines.vh

# The following functions convert a decimal string to a binary string,
# and a hexadecimal string (WITHOUT the preceeding 0x) into binary
# strings of 32-characters in length
define dec2bin
	`perl -e 'printf "%032b\n",'$(1)`
endef

define hex2bin
	`perl -e 'printf "%032b\n",'0x$(1)`
endef

# Each manycore design contains a Read-Only Memory (ROM) that
# describes its configuration. This ROM is generated by BaseJump using
# bsg_ascii_to_rom, which parses an ASCII file that encodes binary
# data. Each rom entry is a 32-character string with 1/0 values. Each
# line is a separate entry. This target generates the verilog for the rom.
$(HARDWARE_PATH)/%.v: $(HARDWARE_PATH)/%.rom
	python $(BASEJUMP_STL_DIR)/bsg_mem/bsg_ascii_to_rom.py $< \
               bsg_bladerunner_configuration > $@

# This target generates the ASCII file for the ROM. To add entries to
# the ROM, add more commands below.
$(HARDWARE_PATH)/bsg_bladerunner_configuration.rom: $(CL_DIR)/Makefile.machine.include
	@echo $(call hex2bin,$(CL_MANYCORE_RELEASE_VERSION))   > $@.temp
	@echo $(call hex2bin,$(CL_MANYCORE_COMPILATION_DATE))  >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_MAX_EPA_WIDTH))     >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DATA_WIDTH))        >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DIM_X))             >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_DIM_Y))             >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_HOST_COORD_X))      >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_HOST_COORD_Y))      >> $@.temp
	@echo $(call dec2bin,0)                                >> $@.temp
	@echo $(call hex2bin,$(BASEJUMP_STL_COMMIT_ID))        >> $@.temp
	@echo $(call hex2bin,$(BSG_MANYCORE_COMMIT_ID))        >> $@.temp
	@echo $(call hex2bin,$(BSG_F1_COMMIT_ID))              >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_WAYS))       >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_SETS))       >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS))  >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS)) >> $@.temp
	@echo $(call dec2bin,$(CL_MANYCORE_VCACHE_MISS_FIFO_ELS)) >> $@.temp
	mv $@.temp $@

# Each manycore design on has a set of parameters that define
# it. Instead of passing these parameters as command-line defines
# (which is tool-specific) we generate a header file.
$(HARDWARE_PATH)/f1_parameters.vh: $(CL_DIR)/Makefile.machine.include
	@echo "\`ifndef F1_DEFINES" > $@
	@echo "\`define F1_DEFINES" >> $@
	@echo "\`define CL_MANYCORE_MAX_EPA_WIDTH $(CL_MANYCORE_MAX_EPA_WIDTH)" >> $@
	@echo "\`define CL_MANYCORE_DATA_WIDTH $(CL_MANYCORE_DATA_WIDTH)" >> $@
	@echo "\`define CL_MANYCORE_DIM_X $(CL_MANYCORE_DIM_X)" >> $@
	@echo "\`define CL_MANYCORE_DIM_Y $(CL_MANYCORE_DIM_Y)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_SETS $(CL_MANYCORE_VCACHE_SETS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_WAYS $(CL_MANYCORE_VCACHE_WAYS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS $(CL_MANYCORE_VCACHE_BLOCK_SIZE_WORDS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS $(CL_MANYCORE_VCACHE_STRIPE_SIZE_WORDS)" >> $@
	@echo "\`define CL_MANYCORE_VCACHE_MISS_FIFO_ELS $(CL_MANYCORE_VCACHE_MISS_FIFO_ELS)" >> $@
	@echo "\`define CL_MANYCORE_MEM_CFG $(CL_MANYCORE_MEM_CFG)" >> $@
	@echo "\`define CL_MANYCORE_BRANCH_TRACE_EN $(CL_MANYCORE_BRANCH_TRACE_EN)" >> $@
	@echo "\`endif" >> $@

# This package defines the number of lines in the ROM
$(HARDWARE_PATH)/bsg_bladerunner_rom_pkg.vh: $(HARDWARE_PATH)/bsg_bladerunner_configuration.rom
	@echo "\`ifndef BSG_BLADERUNNER_ROM_PKG" > $@
	@echo "\`define BSG_BLADERUNNER_ROM_PKG" >> $@
	@echo >> $@
	@echo "package bsg_bladerunner_rom_pkg;" >> $@
	@echo >> $@
	@echo "parameter rom_width_p = 32;" >> $@
	@echo "parameter rom_els_p = `wc -l < $<`;" >> $@
	@echo >> $@
	@echo "endpackage" >> $@
	@echo >> $@
	@echo "\`endif" >> $@


.PHONY: hardware.clean

hardware.clean:
	rm -f $(HARDWARE_PATH)/bsg_bladerunner_configuration.{rom,v}
	rm -f $(HARDWARE_PATH)/f1_parameters.vh
	rm -f $(HARDWARE_PATH)/bsg_bladerunner_rom_pkg.vh
