# SystemC CASLab-GPU Simulator User Guide 

## CASLab-GPU ISA is a lite version of the HSAIL (Heterogeneous System Architecture Intermediate Language) specification developed by the HSA foundation.

The CASLab GPU project involves:

1. A CASLab-GPU Sim, which is a configurable OpenCL HSAIL GPU simulator in SystemC supporting OpenCL and TensorFlow CNN APIs. 
2. The CASLab GPU OpenCL compiler, which is based on the LLVM framework. The compiler optimizes and translates OpenCL programs or Python TensorFlow CNN model to CASLab-GPU machine code.

The project is developed by the CASLab members, NCKU EE,  since 2013 with lots of dedicated efforts.

## Prerequistes
- Libraries (to be informed.)
- python version should more than 3.
- systemC version should be more than 2.3.0. (must be compile in C++ 11)
- gcc, g++ version should be more than 5.

## How to run
0-1.Requirements for CASLab-GPUSIM
```
    sudo apt-get install cmake libelf-dev zlib1g-dev libglu1-mesa-dev ocl-icd-opencl-dev
```
0-2.SystemC library (compile in C++ 11)
 ```
  tar xvf systemc-2.3.0.tgz
  cd systemc-2.3.0
  mkdir objdir
  cd objdir
  ../configure CXXFLAGS="-DSC_CPLUSPLUS=201103L" --prefix=${YOUR_SYSTEMC_PATH}
  make -j
  make install
  ```

1.Setup Paths.

```    
    1. [Use your systemc library]
       Change "SYSTEMC_DIR" in file "setup.sh" to your SystemC path.
       export SYSTEMC_DIR=YOUR_SYSTEMC_PATH

       or 
       Add "export SYSTEMC_HOME=YOUR_SYSTEMC_PATH" to environment rc file, 
       e.g. Bash : ~/.bash_aliases or Zsh ~/.zshrc

    2. [Use provided systemc library] 
       Use the default SYSTEMC_DIR which is set as $(pwd)/systemc
``` 
2.Open a terminal to setup libraries path.

```    
    source setup.sh
``` 
3.Use the terminal to simulate the GPU.
- If simulator would only be run once and not logging , do

```
    ./gpu
```

- Otherwise, Use script to start the simuatlor
   - It will display message and dump to `${TMP_DIR}/exec_history/` at the same  time,\
    and restart the simuation when last simulation end
```
    ./exec_loop.sh
```
4-1.Open another terminal to run the benchmarks  

```   
    source setup.sh
    cd cl_testbench/bfs
    make
    ./run_bfs

``` 

4-2.For AMD benchmarks, cmake first.

```   
    source setup.sh
    cd cl_testbench/BlackScholes
    cmake .
    make
    ./run_BLK
``` 

## Configuration

**Benchmarks**

The benchmarks source code is in `cl_testbench`.

You can change the size of benchmark to normal thread size.

2.1 Rodinia: please download the [Rodinia Benchmark](https://github.com/yuhc/gpu-rodinia/tree/master/opencl) and generate the size you want.

(bfs)
    
2.2 AMD: you can change the size in the .h , .hpp or .cpp file.

(BlackScholes, FloydWarshall)

2.3 NVIDIA: you can change the size in the .h , .hpp or .cpp file.

(oclVectorAdd)
