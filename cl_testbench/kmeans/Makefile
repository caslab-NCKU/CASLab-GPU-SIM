
# C compiler
CC = g++
CC_FLAGS = -g -O2 

kmeans: cluster.o getopt.o read_input.o kmeans_clustering.o rmse.o
	$(CC) $(CC_FLAGS) -DRD_WG_SIZE_0=256 -DRD_WG_SIZE_1=256 kmeans.cpp cluster.o getopt.o read_input.o kmeans_clustering.o rmse.o -o kmeans -I$(HSAGPU_INC) -I$(HSAGPU_INC)/include -L$(HSAGPU_LIB) -lhsagpu -I$(HSA_INC) -L$(HSA_LIB) -lhsa-runtime64 -I$(HSAKMT_INC) -L$(HSAKMT_LIB) -lhsakmt -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -latomic

%.o: %.[ch]
	$(CC) $(CC_FLAGS) $< -c

cluster.o: cluster.c 
	$(CC) $(CC_FLAGS) cluster.c -c -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL

getopt.o: getopt.c 
	$(CC) $(CC_FLAGS) getopt.c -c -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL

kmeans.o: kmeans.c 
	$(CC) $(CC_FLAGS) read_input.c -c -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL

rmse.o: rmse.c
	$(CC) $(CC_FLAGS) rmse.c -c -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL

clean:
	rm -f *.o *~ kmeans *.linkinfo


