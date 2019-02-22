#define _BSD_SOURCE
#define _XOPEN_SOURCE 500

#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

#include "deploy.h"
#include "../device.h"
#include "fifo.h"
#include "loader/spmd_loader.h"


int main () {
	
	printf("Running the Manycore-Cache-Loopback test on a 4x4.\n\n");

	/* Setup host */
	struct Host *host = (struct Host *) malloc(sizeof(struct Host));	 
	deploy_init_host(host, 0, 0); // DMA arguments unused	

	/* mmap the OCL BAR */
	char *ocl_base = deploy_mmap_ocl();
	if (ocl_base == 0) {
		printf("Error when mmap'ing OCL Bar.\n");
		return 0;
	}

	// check the manycore dimension
	if (!deploy_check_dim()) {
		printf("Manycore dimensions in FPGA are not as expected.\n");
		return 0;
	}

	parse_elf(getenv("MAIN_LOOPBACK"), 0, 0, true);
	load_icache();
	load_dram();
	load_dmem();
	unfreeze(0, 0);
  	/*---------------------------------------------------------------------------*/
	// check receive packet 
	/*---------------------------------------------------------------------------*/
	printf("Checking receive packet...\n");
	usleep(100); /* 100 us */	
	uint32_t *receive_packet = deploy_read_fifo(1, NULL);
	printf("Receive packet: ");
	print_hex((uint8_t *) receive_packet);

	return 0;

	//if (!all_req_complete())
	//	printf("binary test: warning - there are outstanding host requests.\n");
}
