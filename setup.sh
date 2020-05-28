#!/bin/bash

if [ "${BASH_SOURCE[0]}" = "" ]; then
	ScriptFullPath=${(%):-%x}
else                                                                                                                                                                                     
	ScriptFullPath=${BASH_SOURCE[0]}
fi
ProjectBase="$( cd "$( dirname "${ScriptFullPath}" )" >/dev/null && pwd )"
unset ScriptFullPath

if [ -z ${SYSTEMC_HOME} ]; then
	# You should add the systemC directory path here.
	export SYSTEMC_DIR=$(pwd)/systemc
else
	# Or use system environment
	export SYSTEMC_DIR=${SYSTEMC_HOME}
fi


export CASLAB_PROJ=${ProjectBase}

export SYSTEMC_LIB=${SYSTEMC_DIR}/lib-linux64
export CASGPU_DEVLIB="opencl.casgpu.bc;ocml.casgpu.bc;ockl.casgpu.bc"
export LLVM_DIR=${ProjectBase}/CASLab-Compiler/bin
export DEVLIB_DIR=${ProjectBase}/CASLab-Compiler/share/device-lib
export LD_LIBRARY_PATH=${SYSTEMC_LIB}:${ProjectBase}/runtime_lib
export LIBRARY_PATH=${ProjectBase}/runtime_lib
export C_INCLUDE_PATH=${ProjectBase}
export CPLUS_INCLUDE_PATH=${ProjectBase}
export TMP_DIR=/run/user/$(id -u)/gpu_tmp
