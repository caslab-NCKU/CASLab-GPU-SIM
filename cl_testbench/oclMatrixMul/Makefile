#C compiler
CC = g++

SRC = oclMatrixMul.cpp matrixMul_gold.cpp

CC_FLAGS = -g -O3

EXE = oclMatrixMul

release:$(SRC)
	echo $(OPENCL_LIB)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(CASLAB_PROJ)/SDK/NVIDIA-SDK/shared/inc -I$(CASLAB_PROJ)/SDK/NVIDIA-SDK/OpenCL/common/inc -L$(CASLAB_PROJ)/SDK/NVIDIA-SDK/OpenCL/common/lib -loclUtil_x86_64 -L$(CASLAB_PROJ)/SDK/NVIDIA-SDK/OpenCL/common/lib -lshrUtil_x86_64 -I$(HSAGPU_INC) -I$(HSAGPU_INC)/include -L$(HSAGPU_LIB) -lhsagpu -I$(HSA_INC) -L$(HSA_LIB) -lhsa-runtime64 -I$(HSAKMT_INC) -L$(HSAKMT_LIB) -lhsakmt -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -latomic

run:
	./$(EXE)

clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo result*
