include ./make.config

#C compiler
CC = g++

SRC = bfs.cpp timer.cc

CC_FLAGS = -g -O3

EXE = bfs

release:$(SRC)
	echo $(OPENCL_LIB)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(HSAGPU_INC) -I$(HSAGPU_INC)/include -L$(HSAGPU_LIB) -lhsagpu -I$(HSA_INC) -L$(HSA_LIB) -lhsa-runtime64 -I$(HSAKMT_INC) -L$(HSAKMT_LIB) -lhsakmt -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -latomic

errmsg:$(SRC)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -D ERRMSG PTX_MSG

ptx:$(SRC)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -D PTX_MSG

profile:$(SRC)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -D PROFILING

res:$(SRC)
	$(CC) $(CC_FLAGS) -fopenmp $(SRC) -o $(EXE) -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL -D RES_MSG

debug: $(SRC)
	$(CC) $(CC_FLAGS) $(SRC) -o $(EXE) -I$(OPENCL_INC) -L$(OPENCL_LIB) -lOpenCL 

run:
	./$(EXE)

clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo result*
	rm -f input.txt
	rm -f kernel_info.txt
	rm -f _temp.cl
	rm -f output.hbin
