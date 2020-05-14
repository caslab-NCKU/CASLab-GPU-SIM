#C compiler
CC = g++

SRC = nearestNeighbor.cpp clutils.cpp utils.cpp

CC_FLAGS = -g -O3

EXE = nn

release:
	$(CC) $(CC_FLAGS) -lOpenCL  -fopenmp $(SRC) -o $(EXE) -I$(HSAGPU_INC) -L$(HSAGPU_LIB) -I$(HSA_INC) -L$(HSA_LIB) -lhsa-runtime64 -I$(HSAKMT_INC) -L$(HSAKMT_LIB) -lhsakmt -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL 

	
clean: 
	rm -f $(EXE) 
