#C compiler
CC = g++

SRC = oclVectorAdd.cpp

CC_FLAGS = -g -O3

EXE = oclVectorAdd

release:$(SRC)
	echo $(OPENCL_LIB)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(CASLAB_PROJ)/SDK/NVIDIA-SDK/shared/inc -I$(CASLAB_PROJ)/SDK/NVIDIA-SDK/OpenCL/common/inc -L$(CASLAB_PROJ)/SDK/NVIDIA-SDK/OpenCL/common/lib -loclUtil_x86_64 -L$(CASLAB_PROJ)/SDK/NVIDIA-SDK/OpenCL/common/lib -lshrUtil_x86_64 -I$(HSAGPU_INC) -I$(HSAGPU_INC)/include -L$(HSAGPU_LIB) -lhsagpu -I$(HSA_INC) -L$(HSA_LIB) -lhsa-runtime64 -I$(HSAKMT_INC) -L$(HSAKMT_LIB) -lhsakmt -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -latomic

run:
	./$(EXE)

clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo result*
	rm -f input.txt
	rm -f kernel_info.txt
	rm -f _temp.cl
	rm -f output.hbin
