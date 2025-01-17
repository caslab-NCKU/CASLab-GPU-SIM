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
#include "SDKFile.hpp"

#if defined(_WIN32) || defined(__CYGWIN__)
#include <direct.h>
#define GETCWD _getcwd
#else // !_WIN32
#include <cstring>
#include <cstdlib>
#include <unistd.h>
#define GETCWD ::getcwd
#endif // !_WIN32

namespace streamsdk
{

std::string
getCurrentDir()
{
    const   size_t  pathSize = 4096;
    char    currentDir[pathSize];

    // Check if we received the path
    if (GETCWD(currentDir, pathSize) != NULL) {
        return std::string(currentDir);
    }

    return  std::string("");
}

int
SDKFile::writeBinaryToFile(const char* fileName, const char* birary, size_t numBytes)
{
    FILE *output = NULL;
    output = fopen(fileName, "wb");
    if(output == NULL)
        return SDK_FAILURE;

    fwrite(birary, sizeof(char), numBytes, output);
    fclose(output);

    return SDK_SUCCESS;
}


int
SDKFile::readBinaryFromFile(const char* fileName)
{
    FILE * input = NULL;
    size_t size = 0;
    char* binary = NULL;

    input = fopen(fileName, "rb");
    if(input == NULL)
    {
        return SDK_FAILURE;
    }

    fseek(input, 0L, SEEK_END); 
    size = ftell(input);
    rewind(input);
    binary = (char*)malloc(size);
    if(binary == NULL)
    {
        return SDK_FAILURE;
    }
    fread(binary, sizeof(char), size, input);
    fclose(input);
    source_.assign(binary, size);
    free(binary);

    return SDK_SUCCESS;
}




bool
SDKFile::open(
    const char* fileName)   //!< file name
{
    size_t      size;
    char*       str;

    // Open file stream
    std::fstream f(fileName, (std::fstream::in | std::fstream::binary));

    // Check if we have opened file stream
    if (f.is_open()) {
        size_t  sizeFile;
        // Find the stream size
        f.seekg(0, std::fstream::end);
        size = sizeFile = (size_t)f.tellg();
        f.seekg(0, std::fstream::beg);

        str = new char[size + 1];
        if (!str) {
            f.close();
            return  false;
        }

        // Read file
        f.read(str, sizeFile);
        f.close();
        str[size] = '\0';

        source_  = str;

        delete[] str;

        return true;
    }

    return false;
}

} // namespace streamsdk
