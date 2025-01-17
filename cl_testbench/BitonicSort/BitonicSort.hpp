/**********************************************************************
Copyright �2012 Advanced Micro Devices, Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

�	Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
�	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
********************************************************************/


#ifndef BITONICSORT_H_
#define BITONICSORT_H_

#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <SDKCommon.hpp>
#include <SDKApplication.hpp>
#include <SDKCommandArgs.hpp>
#include <SDKFile.hpp>

/**
 * BitonicSort 
 * Class implements OpenCL  Bitonic Sort sample
 * Derived from SDKSample base class
 */

#define GROUP_SIZE 256

class BitonicSort : public SDKSample
{
    cl_uint                  seed;    /**< Seed value for random number generation */
    cl_double           setupTime;    /**< Time for setting up OpenCL */
    cl_double     totalKernelTime;    /**< Time for kernel execution */
    cl_double    totalProgramTime;    /**< Time for program execution */
    cl_double referenceKernelTime;    /**< Time for reference implementation */
    cl_uint             sortOrder;    /**< Flag to indicate sorting order */
    std::string    sortDescending;    /**< Argument to indicate sorting order */
	cl_uint                *input;    /**< Input array */
    cl_int                 length;    /**< length of the array */
    cl_uint    *verificationInput;    /**< Input array for reference implementation */
    cl_context            context;    /**< CL context */
    cl_device_id         *devices;    /**< CL device list */
    cl_mem            inputBuffer;    /**< CL memory buffer */
    cl_command_queue commandQueue;    /**< CL command queue */
    cl_program            program;    /**< CL program  */
    cl_kernel              kernel;    /**< CL kernel */
    int                iterations;    /**< Number of iterations to execute kernel */
    streamsdk::KernelWorkGroupInfo kernelInfo;/**< Structure to store kernel related info */

public:
    /** 
     * Constructor 
     * Initialize member variables
     * @param name name of sample (string)
     */
    BitonicSort(std::string name)
        : SDKSample(name)    {
            seed = 123;
            sortOrder = 0;
			sortDescending="desc";
            input = NULL;
            verificationInput = NULL;
            length = 1024;
            setupTime = 0;
            totalKernelTime = 0;
            iterations = 1;
        }

    /** 
     * Constructor 
     * Initialize member variables
     * @param name name of sample (const char*)
     */
    BitonicSort(const char* name)
        : SDKSample(name)    {
            seed = 123;
            sortOrder = 0;
			sortDescending="desc";
            input = NULL;
            verificationInput = NULL;
            length = 1024;
            setupTime = 0;
            totalKernelTime = 0;
            iterations = 1;
        }

    /**
     * Allocate and initialize host memory array with random values
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int setupBitonicSort();

    /**
     * Override from SDKSample, Generate binary image of given kernel 
     * and exit application
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int genBinaryImage();

    /**
     * OpenCL related initialisations. 
     * Set up Context, Device list, Command Queue, Memory buffers
     * Build CL kernel program executable
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int setupCL();

    /**
     * Set values for kernels' arguments, enqueue calls to the kernels
     * on to the command queue, wait till end of kernel execution.
     * Get kernel start and end time if timing is enabled
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int runCLKernels();

    /**
     * Helper to swap two values if first one is greater
     * @param a an unsigned int value
     * @param b an unsigned int value
     */
    void swapIfFirstIsGreater(cl_uint *a, cl_uint *b);

    /**
     * Reference CPU implementation of Bitonic Sort
     * for performance comparison
     * @param input the input array
     * @param length length of the array
     * @param sortIncreasing flag to indicate sorting order
     */
    void bitonicSortCPUReference(
        cl_uint * input, 
        const cl_uint length, 
        const cl_bool sortIncreasing);

    /**
     * Override from SDKSample. Print sample stats.
     */
    void printStats();

    /**
     * Override from SDKSample. Initialize 
     * command line parser, add custom options
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int initialize();

    /**
     * Override from SDKSample, adjust width and height 
     * of execution domain, perform all sample setup
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int setup();

    /**
     * Override from SDKSample
     * Run OpenCL Bitonic Sort
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int run();

    /**
     * Override from SDKSample
     * Cleanup memory allocations
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int cleanup();

    /**
     * Override from SDKSample
     * Verify against reference implementation
     * @return SDK_SUCCESS on success and nonzero on failure
     */
    int verifyResults();
};

#endif
