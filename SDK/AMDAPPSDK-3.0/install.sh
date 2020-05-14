#!/bin/bash

#################################################################################
#
# Copyright (c) 2015 Advanced Micro Devices, Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, 
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, 
#   this list of conditions and the following disclaimer in the documentation 
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
# WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
# SUCH DAMAGE.
# 
#################################################################################

# source shflags
. ./shflags

#Define flags --silent or -s
#Define flags --acceptEULA or -a. This is applicable only for silent install.
DEFINE_boolean 'silent' false 'Install AMD APP SDK v3.0 silently with default options' 's'
DEFINE_string 'acceptEULA' '' 'Accept the AMD APP SDK EULA' 'a'

#Script level variables
EULA_FILE=`pwd`/APPSDK-EULA-linux.txt
INSTALL_ARCH="x64"
SDK_TEMP_DIR="${HOME}/AMDAPPSDK-3.0"
LOG_FILE="$SDK_TEMP_DIR/InstallLog_$(date +"%m-%d-%Y"T"%H-%M-%S").log"
INSTALL_DIR="/opt"
USERMODE_INSTALL=1    #A value of 1 indicates that the script will install 
                    #AMD APP SDK for the currently logged in user only

#Function Name    : log
#Comments    :#The log function logs the messages in the specified log file
             #By default info is not logged in the console
log()
{
    Message="[$(date +"%m-%d-%Y"T"%T")][$2]$1"
    if [ -e "$LOG_FILE" ]; then
        #First log statement to the file
        echo "$Message" >> "$LOG_FILE"
    else
        touch "$LOG_FILE"
        chmod 666 "$LOG_FILE"
        echo "$Message" >> "$LOG_FILE"
    fi

    if [ -n "$3" -a "$3" == "console" ]; then
        #dump the message to the console as well
        echo "$1"
    fi
}

#Function Name: getOSDetails
#Comments     : Get's the complete details of OS and prints it on the console.
getOSDetails()
{
    OS_ARCH=$(getconf LONG_BIT)
    if [ $? -ne 0 ]; then
        log "getconf LONG_BIT failed. Trying alternate method using uname to get the OS type." "$LINENO" "console"
        #alternate method of finding out the OS type
        OS_ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
    fi
    
    log "Detected OS Architecture: $OS_ARCH" "$LINENO" "console"
    
    OS_DISTRO=$(lsb_release -si)
    if [ $? -ne 0 ]; then
        log "FAILURE: Could not detect the OS distribution. Please check for the presence of /etc/lsb_release." "$LINENO" "console"
    fi
    
    log "Detected OS Distribution: $OS_DISTRO" "$LINENO" "console"
    
    OS_VERSION=$(lsb_release -sr)
    if [ $? -ne 0 ]; then
        log "FAILURE: Could not detect the OS distribution. Please check for the presence of /etc/lsb_release." "$LINENO" "console"
    fi
    
    log "Detected OS Version: $OS_VERSION" "$LINENO" "console"
}

#Function Name: checkPrerequisites
#Comments     : gets the architecture details of the current installer which is been installed.
checkPrerequisites()
{
    if [ "$OS_ARCH" = "32" -a "$INSTALL_ARCH" = "amd64" ]; then
        log "The 64-bit AMD APP SDK v3.0 cannot be installed on a 32-bit Operating System. Please use the 32-bit AMD APP SDK v3.0. The installer will now exit." "$LINENO" 
        return 1
    else
        return 0
    fi
}

#Function Name: getLoggedInUserDetails
#Comments     : gets the current logged-in user details and prints on the console.
getLoggedInUserDetails()
{
    CURRENT_USER=$(whoami)
    log "Logged in user: $CURRENT_USER" "$LINENO" "console"
}

askYN()
{
    while true;
    do
        read -p "$1 " yn
        case ${yn:-$2} in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer Yes(Y) or No(N).";;
        esac
    done
}

#Function Name: showEULAAndWait
#Comments     : Shows the EULA on the console and waits for the user 
#               to provide the input. If the user enter 'Y' the 
#               installation continues and if the user enters 'N' 
#               then installer exists installation.
showEULAAndWait()
{
    log "---------------------------------------------------------------------------------" "$LINENO" "console"
    cat "$EULA_FILE" | more
    log "---------------------------------------------------------------------------------" "$LINENO" "console"
    
    while true;
    do
        read -p "Do you accept the licence (y/n)? " yn
        case ${yn} in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer Yes(Y) or No(N).";;
        esac
    done
}

#Function Name: diskSpaceAvailable
#Comments     : This function checks space available for installing the APPSDK installer.
diskSpaceAvailable()
{
    #Get the size of the payload
    PayloadSize=$(du -shb)
    log "Payload size: $PayloadSize" "$LINENO" 
    log "Removing the . character" "$LINENO" 
    PayloadSize=${PayloadSize%?}
    log "Size after removing the . character: $PayloadSize" "$LINENO" 
    PayloadSize="${PayloadSize%%*( )}"
    log "Size after Trimming the . character: $PayloadSize" "$LINENO" 
}

#Function Name: dumpPayload
#Comments     : This function dumps/copies all the files and folders to $INSTALL_DIR. 
dumpPayload()
{
    #$1 contains the directory where the payload has to be moved.
    log "Installing to $INSTALL_DIR." "$LINENO" "console"
    
    mkdir -pv --mode 755 "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
    Retval=$?
    if [ $Retval -ne 0 ]; then
        log "Failed to create the $INSTALL_DIR. The installation cannot continue." "$LINENO" "console"
    else
        #Install Directory created successfully, now copy over the contents to the directory
        cp -rvu ./* "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -ne 0 ]; then
            log "Failed to install files in the $INSTALL_DIR directory." "$LINENO" "console"
        else
            log "Payload copied to $INSTALL_DIR" "$LINENO" 
            #Change the permission of clinfo
            if [ "$OS_ARCH" == "32" ]; then
                chmod -v 755 "$INSTALL_DIR/bin/x86/clinfo" >> "$LOG_FILE" 2>&1
            else
                #Changing mode for both 32-bit and 64-bit clinfo.
                chmod -v 755 "$INSTALL_DIR/bin/x86/clinfo" >> "$LOG_FILE" 2>&1
                chmod -v 755 "$INSTALL_DIR/bin/x86_64/clinfo" >> "$LOG_FILE" 2>&1
            fi
            
            #In case of root, give execute permissions to all users for samples
            if [ "$USERMODE_INSTALL" == "0" ]; then
                #Change the permission of the directory
                #If the logged in user is root, then give others and groups rw permissions
                chmod -Rv 755 "$INSTALL_DIR/bin" >> "$LOG_FILE" 2>&1
                chmod -Rv 755 "$INSTALL_DIR/lib" >> "$LOG_FILE" 2>&1
                chmod -Rv 755 "$INSTALL_DIR/include" >> "$LOG_FILE" 2>&1
                chmod -Rv 755 "$INSTALL_DIR/samples" >> "$LOG_FILE" 2>&1
                chmod -v 755 "$INSTALL_DIR/docs" >> "$LOG_FILE" 2>&1
                pushd "$INSTALL_DIR/docs" >> "$LOG_FILE" 2>&1
                    chmod -v 644 * >> "$LOG_FILE" 2>&1
                popd >> "$LOG_FILE" 2>&1
            fi
        fi
    fi
    
    return $Retval
}

askDirectory()
{
    while true;
    do
        Directory="$2"
        read -e -p "$1: [$2]" Directory
        if [ -z "$Directory" ]; then
            Directory="$2"
        fi

        #remove trailing directory separator if present
        Directory="${Directory%/}"
        Directory="${Directory}/AMDAPPSDK-3.0"
        log "You have chosen to install AMD APP SDK v3.0 in directory: $Directory" "$LINENO", "console"
        break;
    done
}

#Function Name: createVendorsDirectory
#Comments     : creates the vendors directory under appropriate directory depending on the user.
createVendorsDirectory()
{
    Retval=0
    VENDORS_DIR="$1"
    
    if [ ! -d "$VENDORS_DIR" ]; then
        #VENDORS_DIR does not exist, so create it.
        log "[INFO]Executing mkdir -pv --mode 755 $VENDORS_DIR" $LINENO
        mkdir -pv --mode 755 "$VENDORS_DIR" >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -ne 0 ]; then
            log "Failed to create the ICD registrations directory: $VENDORS_DIR" "$LINENO" 
            return $Retval
        else
            log "Successfully created the ICD registrations directory: $VENDORS_DIR" "$LINENO"
        fi
    else
        log "$VENDORS_DIR for $USER already exists." "$LINENO"
    fi
        
    return $Retval
}

#Function Name: registerOpenCLICD
#Comments     : this function checks for $VENDORS_DIR, if exists just logs, 
#               else creates the $VENDORS_DIR. After creation of $VENDORS_DIR,
#               it checks for the vendors directory, and registers the ICD's.
registerOpenCLICD()
{
    Retval=0
    VENDORS_DIR="/etc/OpenCL"
    
    if [ "${USERMODE_INSTALL}" -ne 0 ]; then
        #User mode installation
        VENDORS_DIR="${INSTALL_DIR}${VENDORS_DIR}/vendors"
    else
        VENDORS_DIR="${VENDORS_DIR}/vendors"
    fi
    
    AMDOCL32="$VENDORS_DIR/amdocl32.icd"
    
    createVendorsDirectory "$VENDORS_DIR"
    Retval=$?
    if [ $Retval -ne 0 ]; then
        log "Failed to create the ICD registrations directory: $VENDORS_DIR" "$LINENO" 
        return $Retval
    fi

    #Checking, if Catalyst is present or not.
    #If Catalyst is present, we are assuming that $AMDOCL might have been installed by catalyst, hence skipping the registration of $AMDOCL.
    #If Catalyst is not present then we are going ahead and creating the $VENDORS_DIR and registering $AMDOCL.
    if  [ "$OS_ARCH" == "32" ]; then
        if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then
            log "Catalyst is present, hence skipping the registration of $AMDOCL" "$LINENO"
        else
            log "echo libamdocl32.so > \"\$AMDOCL32\"" "$LINENO"            
            echo libamdocl32.so > "$AMDOCL32"
            Retval=$?
            if [ $Retval -ne 0 ]; then
                log "FAILURE: Could not register : $AMDOCL32 file. Could not register AMD as a 32-bit OpenCL vendor." "$LINENO" 
            else
                chmod 666 "$AMDOCL32" >> "$LOG_FILE" 2>&1
            fi
        fi
    elif [ "$OS_ARCH" == "64" ]; then
        AMDOCL64="$VENDORS_DIR/amdocl64.icd"
        if [ -e "/usr/lib/libOpenCL.so" -o -e "/usr/lib/libOpenCL.so.1" ]; then
            log "Catalyst is present,hence skipping the registration $AMDOCL64 files" "$LINENO"
        else
            log "echo libamdocl64.so > \"\$AMDOCL64\"" "$LINENO"
            echo libamdocl64.so > "$AMDOCL64"
            Retval=$?
            if [ $Retval -ne 0 ]; then
                log "FAILURE: Could not register : $AMDOCL64 file. Could not register AMD as a 64-bit OpenCL vendor." "$LINENO" 
            else
                chmod 666 "$AMDOCL64" >> "$LOG_FILE" 2>&1
            fi
        fi
    else
        log "FAILURE: Found an incompatible OS Architecture: $OS_ARCH. Please report the issue." "$LINENO" "console"
        Retval=1
    fi
    
    return $Retval
}

#Function Name: addEnvironmentVariable
#Comments     : This function first checks whether the Environment variable is 
#               present or not. If present it deletes the environment variable
#               and then add back the variable with the new value. if not found
#               it just add the variable.
addEnvironmentVariable()
{
    FILE="$1"
    ENVIRONMENT_VARIABLE_NAME="$2"
    ENVIRONMENT_VARIABLE_VALUE="$3"
    
    #First check whether the entry already exists, if it does then delete and recreate
    log "Checking for the presence of $ENVIRONMENT_VARIABLE_NAME in the file: $FILE using grep" "$LINENO"

    grep "$ENVIRONMENT_VARIABLE_NAME" "$FILE" >> "$LOG_FILE" 2>&1
    Retval=$?
    if [ $Retval -eq 0 ]; then
        #found an existing entry, which needs to be deleted
        log "Found an entry for $ENVIRONMENT_VARIABLE_NAME in file: $FILE. Deleted it." "$LINENO" 
        sed -i.bak "/$ENVIRONMENT_VARIABLE_NAME/d" "$FILE" >> "$LOG_FILE" 2>&1
        
        #Confirm whether the command did its job in removing the file.
        grep "$ENVIRONMENT_VARIABLE_NAME" "$FILE" >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -ne 0 ]; then
            log "Entry for $ENVIRONMENT_VARIABLE_NAME removed." "$LINENO"
            Retval=0
            #Add the entry back
            log "echo export \"$ENVIRONMENT_VARIABLE_NAME=\"$ENVIRONMENT_VARIABLE_VALUE\"\" >> \"$FILE\"" "$LINENO" 
            echo "export $ENVIRONMENT_VARIABLE_NAME=\"$ENVIRONMENT_VARIABLE_VALUE\"" >> "$FILE"
        else
            log "FAILURE: Could not delete entry for $ENVIRONMENT_VARIABLE_NAME removed." "$LINENO"
            log "[WARN]: Could not update $FILE with the latest value for the environment variable: $ENVIRONMENT_VARIABLE_NAME=$ENVIRONMENT_VARIABLE_VALUE. You will need to update the file with the correct value." "$LINENO" "console"
            return 1
        fi
    else
        log "No Entry for $ENVIRONMENT_VARIABLE_NAME in file: $FILE. Adding it."
        #Add the entry back
        log "echo export \"$ENVIRONMENT_VARIABLE_NAME=\"$ENVIRONMENT_VARIABLE_VALUE\"\" >> \"$FILE\"" "$LINENO" 
        echo "export $ENVIRONMENT_VARIABLE_NAME=\"$ENVIRONMENT_VARIABLE_VALUE\"" >> "$FILE"
    fi
    
    #If the control comes here this means that the variable was added back
    #Now check.
    grep "$ENVIRONMENT_VARIABLE_NAME" "$FILE" >> "$LOG_FILE" 2>&1
    Retval=$?
    if [ $Retval -eq 1 ]; then
        #echo ENVIRONMENT_VARIABLE_NAME not found. i.e., the command failed to add the environment variable in the file
        log "[WARN]: Could not add the entry $ENVIRONMENT_VARIABLE_NAME=$ENVIRONMENT_VARIABLE_VALUE in the file: $FILE. You will need to update the file manually." "$LINENO" "console"
    else
        log "Exported $ENVIRONMENT_VARIABLE_NAME=$ENVIRONMENT_VARIABLE_VALUE via $FILE." "$LINENO" "console"
    fi
    
    return $Retval
}

#Function Name: updateEnvironmentVariables
#Comments     : This function updates the environment variables, depending upon the user logged-in.
#               if it's a non-root user, this function updates the variables in $HOME/.bashrc file.
#               if it's a root user, this function updates the values in /etc/profile.d/AMDAPPSDK.sh.
updateEnvironmentVariables()
{
    #This also needs to be set as an environment variable 
    AMDAPPSDKROOT="$INSTALL_DIR"
    if [ "$USERMODE_INSTALL" == "0" ]; then
        #Installing as root user
        AMDAPPSDK_PROFILE="/etc/profile.d/AMDAPPSDK.sh"
    else
        #non root user
        AMDAPPSDK_PROFILE="$HOME/.bashrc"
    fi
    #Create the values of the AMDAPPSDKROOT
    if [ "$USERMODE_INSTALL" == "0" ]; then
        #Installing as root user
        #Update the AMDAPPSDKROOT environment variable in /etc/profile.d directory as root user
        log "Exporting AMDAPPSDKROOT=$AMDAPPSDKROOT to $AMDAPPSDK_PROFILE", "$LINENO"
        addEnvironmentVariable "$AMDAPPSDK_PROFILE" "AMDAPPSDKROOT" "$AMDAPPSDKROOT"
        
        log "Exporting AMDAPPSDKROOT=$AMDAPPSDKROOT to $AMDAPPSDK_PROFILE", "$LINENO"
        addEnvironmentVariable "$AMDAPPSDK_PROFILE" "AMDAPPSDKROOT" "$AMDAPPSDKROOT"
        chmod -v 644 "$AMDAPPSDK_PROFILE" >> "$LOG_FILE" 2>&1
                        
        log "Rebuilding linker cache..." "$LINENO" "console"
        ldconfig -v >> "$LOG_FILE" 2>&1
    else
        #non root user
        #Add the AMDAPPSDKROOT environment variable
        addEnvironmentVariable "$AMDAPPSDK_PROFILE" "AMDAPPSDKROOT" "$AMDAPPSDKROOT"
        addEnvironmentVariable "$AMDAPPSDK_PROFILE" "AMDAPPSDKROOT" "$AMDAPPSDKROOT"
    fi
        
    #Create the values of the LD_LIBRARY_PATH and .conf files
    #Create the values .conf file
    AMDAPP_CONF_32="/etc/ld.so.conf.d/amdAPP_x86.conf"

    if [ "$OS_ARCH" == "64" ]; then
        AMDAPP_CONF_64="/etc/ld.so.conf.d/amdAPP_x86_64.conf"
    fi

    #Create the values of the LD_LIBRARY_PATH
    if [ -n "$LD_LIBRARY_PATH" ]; then
        #LD_LIBRARY_PATH exists
        log "LD_LIBRARY_PATH exists. Existing Value: $LD_LIBRARY_PATH" "$LINENO" 

        #Check if it is terminated with a : character
        LD_LIBRARY_PATH="${LD_LIBRARY_PATH%:}"
        LD_LIBRARY_PATH32="${LD_LIBRARY_PATH}:${INSTALL_DIR}/lib/x86/"
        log "LD_LIBRARY_PATH32 updated." "$LINENO"
        if [ "$OS_ARCH" == "64" ]; then
            LD_LIBRARY_PATH64="${LD_LIBRARY_PATH}:${INSTALL_DIR}/lib/x86_64/:${INSTALL_DIR}/lib/x86/"
            log "LD_LIBRARY_PATH64 updated." "$LINENO"            
        fi
    else
        log "LD_LIBRARY_PATH does not exists." "$LINENO" 
        LD_LIBRARY_PATH32="${INSTALL_DIR}/lib/x86/"
        if [ "$OS_ARCH" == "64" ]; then
            LD_LIBRARY_PATH64="${INSTALL_DIR}/lib/x86_64/"
        fi
    fi

    log "LD_LIBRARY_PATH32: $LD_LIBRARY_PATH32" "$LINENO"
    log "LD_LIBRARY_PATH64: $LD_LIBRARY_PATH64" "$LINENO"
   
    # Disable adding LD_LIBRARY_PATH on an install. LD_LIBRARY_PATH should never be
    # modified by an installation script. 
    #if [ "$OS_ARCH" == "32" ]; then
    #    addEnvironmentVariable "$AMDAPPSDK_PROFILE" "LD_LIBRARY_PATH" "$LD_LIBRARY_PATH32"
    #else 
    #    addEnvironmentVariable "$AMDAPPSDK_PROFILE" "LD_LIBRARY_PATH" "$LD_LIBRARY_PATH64"
    #fi
    
    if [ "$USERMODE_INSTALL" == "0" ]; then
        log "Root mode, no need to create the OPENCL_VENDOR_PATH environment variable, skipping it." $LINENO
    else
        #Adding OPENCL_VENDOR_PATH, only if Catalyst is not present.
        if grep -q Ubuntu <<< $OS_DISTRO; then
            log "Found Ubuntu OS system" "$LINENO"
            #Now search whther catalyst is installed or not
            if [ "$OS_ARCH" == "32" ]; then
                if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then    
                    #Found files
                    log "32-bit AMD Catalyst OpenCL Runtime is available hence skipping the LD_LIBRARY_PATH  and OPENCL_VENDOR_PATH updates." "$LINENO"
                else
                    addEnvironmentVariable "$AMDAPPSDK_PROFILE" "OPENCL_VENDOR_PATH" "$INSTALL_DIR/etc/OpenCL/vendors/"
                fi
            else
                if [[ -e "/usr/lib32/libOpenCL.so" ]] || [[ -e "/usr/lib32/libOpenCL.so.1" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]] || [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/i386-linux-gnu/libOpenCL.so" ]] || [[ -e "/usr/lib/i386-linux-gnu/libOpenCL.so.1" ]]; then
                    #Found files
                    log "64-bit AMD Catalyst OpenCL Runtime is available hence skipping the LD_LIBRARY_PATH  and OPENCL_VENDOR_PATH updates." "$LINENO"
                else
                    addEnvironmentVariable "$AMDAPPSDK_PROFILE" "OPENCL_VENDOR_PATH" "$INSTALL_DIR/etc/OpenCL/vendors/"
                fi
            fi
        else
            if [ "$OS_ARCH" == "32" ]; then 
                if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then
                    #Found files
                    log "32-bit AMD Catalyst OpenCL Runtime is available hence skipping the LD_LIBRARY_PATH and OPENCL_VENDOR_PATH update." "$LINENO"
                else
                    addEnvironmentVariable "$AMDAPPSDK_PROFILE" "OPENCL_VENDOR_PATH" "$INSTALL_DIR/etc/OpenCL/vendors/"
                fi
            else
                if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]] || [[ -e "/usr/lib64/libOpenCL.so" ]] || [[ -e "/usr/lib64/libOpenCL.so.1" ]]; then
                    #Found files
                    log "64-bit AMD Catalyst OpenCL Runtime is available hence skipping the LD_LIBRARY_PATH and OPENCL_VENDOR_PATH update." "$LINENO"
                else
                    addEnvironmentVariable "$AMDAPPSDK_PROFILE" "OPENCL_VENDOR_PATH" "$INSTALL_DIR/etc/OpenCL/vendors/"
                fi
            fi
        fi
    fi
    
    log "Done updating Environment variables for $USER" "$LINENO" "console"
}

#Function Name: recreateSoftLink
#Comments     : Check whether /usr/bin/clinfo is a soft-link or a actual file. If it is an actual file, then we don't touch it.
#               Recreates the soft-link if already a soft-link exists and it is created by AMDAPPSDK only.
#               Else if it is a soft link created by any other sources we are doing nothing.
recreateSoftLink()
{
    #check whether $Filename it is a soft-link
    #we check whether it is a soft-link or a actual file. If it is an actual file, then we don't touch it.
    CLINFOLinkName="$1/clinfo"
    Filename="/usr/bin/clinfo"

    if [ -h "$Filename" ]; then
        #file is a soft-link so read the link
        LinkTarget=$(readlink $Filename)
        log "$Filename is a soft-link to $LinkTarget" "$LINENO"
        #checking whether the link is been created by APPSDK or by any other.
        if [[ "$LinkTarget" == *AMDAPPSDK* ]]; then
            #Assuming that the soft link is been created by APPSDK
            #so we are recreating the soft-link to the latest/appropriate file
            log "Re-creating soft-link to the appropriate $INSTALL_DIR/bin/*/clinfo in $1" "$LINENO" 
            
            #Create the $1 directory: Only if it is user-mode.
            if [ "$USERMODE_INSTALL" == "1" ]; then        
                if [ ! -d "$HOME/bin" ] ; then
                    #bin directory does not exist, so create it
                    log "$HOME/bin directory does not exist, so creating it." "$LINENO" 
                    mkdir -v "$HOME/bin"  >> "$LOG_FILE" 2>&1
                else
                    log "$HOME/bin directory already exists, so skipping the creation of directory." "$LINENO"
                fi
            else
                log "Installation is done in root mode and /bin folder already exists in /usr/bin , so skipping the creation of directory." "$LINENO"
            fi
            if [ "$OS_ARCH" = "32" ]; then
                ln -svf "$INSTALL_DIR/bin/x86/clinfo" "$CLINFOLinkName" >> "$LOG_FILE" 2>&1
            else
                ln -svf "$INSTALL_DIR/bin/x86_64/clinfo" "$CLINFOLinkName" >> "$LOG_FILE" 2>&1
            fi
        else
            log "[WARN]$Filename is a soft-link, but not created by AMDAPPSDK. Hence,skipping creation of soft-link." "$LINENO"
        fi
    else 
        #File is not a soft-link. #check it is a a regular file
        if [ -f $Filename ]; then
            #it is a regular file, most likely created by the catalyst installer, so skipping creating soft-links to clinfo.
            log "$Filename is a regular file, most likely created by the catalyst installer, so skipping creating soft-links to clinfo." "$LINENO"
            Retval=0
        else
            #Some other kind of file, should not be the case, log it and move ahead
            log "[WARN]$Filename is not a regular file. Skipping creation of soft-link." "$LINENO"
            Retval=0
        fi
    fi
}
    
#Function Name: installCLINFO
#Comments     : This function creates the soft-link to appropriate 
#               $INSTALL_DIR/bin/*/clinfo, depending on the user
installCLINFO()
{
    Filename="/usr/bin/clinfo"
    
    if [ "$USERMODE_INSTALL" == "0" ]; then
        #root user
        #Check whether the /usr/bin/clinfo is already existing. If it is then it could be there because
        #of Catalyst installing it or a user creating it manually or on existing version of
        #APP SDK Creating it. If it is created by APPSDK we are recreating the soft-link with the latest, else we will install the CLINFO, 
        
        if [ -e "$Filename" ]; then
            log "$Filename already exists." "$LINENO"
            recreateSoftLink "/usr/bin"
        else
            log "$Filename does not exist." "$LINENO"
            log "Creating soft-link to the appropriate $INSTALL_DIR/bin/*/clinfo in /usr/bin" "$LINENO" 
            if [ "$OS_ARCH" = "32" ]; then
                ln -svf "$INSTALL_DIR/bin/x86/clinfo" "$Filename" >> "$LOG_FILE" 2>&1
            else
                ln -svf "$INSTALL_DIR/bin/x86_64/clinfo" "$Filename" >> "$LOG_FILE" 2>&1
            fi
        fi
    else
        #non-root user
        if [ -e "$Filename" ]; then
            log "$Filename already exists." "$LINENO"
            recreateSoftLink "$HOME/bin"
        else
            HomeCLINFO="$HOME/bin/clinfo"
            log "Non root user, /usr/bin/clino does not exist, so creating soft link $HOME/bin/clinfo." "$LINENO" 
            #check whether the bin exists or not
            if [ ! -d "$HOME/bin" ] ; then
                #bin directory does not exist, so create it
                log "$HOME/bin directory does not exist, so creating it." "$LINENO" 
                mkdir -v "$HOME/bin"  >> "$LOG_FILE" 2>&1
            fi
            #Now the directory exist so create a soft-link
            log "Creating soft-link to the appropriate $INSTALL_DIR/bin/*/clinfo in $HOME/bin" "$LINENO" 
            if [ "$OS_ARCH" = "32" ]; then
                ln -svf "$INSTALL_DIR/bin/x86/clinfo" "$HomeCLINFO" >> "$LOG_FILE" 2>&1
            else
                ln -svf "$INSTALL_DIR/bin/x86_64/clinfo" "$HomeCLINFO" >> "$LOG_FILE" 2>&1
            fi
        fi
    fi
}

#Function Name: reportMetrics
#Comments     : This function reports to metrics.amd.com
reportMetrics()
{
    WGET=$(which wget)
    Retval=$?
    if [ $Retval -eq 0 ]; then
        log "Reporting to metrics.amd.com" "$LINENO"
        if [ "$OS_ARCH" == "32" ]; then
            $WGET --tries=2 -O "$SDK_TEMP_DIR/Linux_fullInstall_$USER.gif" -U "DEV/SDK Mozilla (X11; Linux x86; rv:25.0) Gecko/20100101 Firefox/25.0" "http://metrics.amd.com/b/ss/amdvdev/1/H.23.3/s84357590374752?AQB=1&ndh=1&t=23%2F7%2F2013%2012%3A00%3A01%203%20240&ce=UTF-8&ns=amd&pageName=%2Fdeveloper.amd.com%2Fsdk&g=http%3A%2F%2Fdeveloper.amd.com%2Fsdk%3Faction%3Dinstalled%26file%3DFull_L3.0-GA-L&cc=USD&ch=%2Fdeveloper.amd.com%2Fsdk%2F&server=developer.amd.com&events=event8%2Cevent62&c1=developer.amd.com&c2=developer.amd.com%2Fsdk&c3=developer.amd.com%2Fsdk&c4=developer.amd.com%2Fsdk&v8=http%3A%2F%2Fdeveloper.amd.com%2Fsdk%3Faction%3Dinstalled%26file%3DFull_L3.0-GA-L&c13=SDK%7Cinstalled%7CFull_L3.0-GA-L&c15=SDK%20Downloader&c17=index.aspx%3Faction%3Dinstalled%26file%3DFull_L3.0-GA-L&c25=amdvdev&c51=SDK%7Cinstalled%7CFull_L3.0-GA-L&s=1280x1024&c=32&j=1.5&v=Y&k=Y&bw=1280&bh=1024&ct=lan&hp=N&AQE=1" >> "$LOG_FILE" 2>&1
        else
            $WGET --tries=2 -O "$SDK_TEMP_DIR/Linux_fullInstall_$USER.gif" -U "DEV/SDK Mozilla (X11; Linux x86_64; rv:25.0) Gecko/20100101 Firefox/25.0" "http://metrics.amd.com/b/ss/amdvdev/1/H.23.3/s84357590374752?AQB=1&ndh=1&t=23%2F7%2F2013%2012%3A00%3A01%203%20240&ce=UTF-8&ns=amd&pageName=%2Fdeveloper.amd.com%2Fsdk&g=http%3A%2F%2Fdeveloper.amd.com%2Fsdk%3Faction%3Dinstalled%26file%3DFull_L3.0-GA-L&cc=USD&ch=%2Fdeveloper.amd.com%2Fsdk%2F&server=developer.amd.com&events=event8%2Cevent62&c1=developer.amd.com&c2=developer.amd.com%2Fsdk&c3=developer.amd.com%2Fsdk&c4=developer.amd.com%2Fsdk&v8=http%3A%2F%2Fdeveloper.amd.com%2Fsdk%3Faction%3Dinstalled%26file%3DFull_L3.0-GA-L&c13=SDK%7Cinstalled%7CFull_L3.0-GA-L&c15=SDK%20Downloader&c17=index.aspx%3Faction%3Dinstalled%26file%3DFull_L3.0-GA-L&c25=amdvdev&c51=SDK%7Cinstalled%7CFull_L3.0-GA-L&s=1280x1024&c=32&j=1.5&v=Y&k=Y&bw=1280&bh=1024&ct=lan&hp=N&AQE=1" >> "$LOG_FILE" 2>&1
        fi
    else
        log "Failed to locate wget command. Skipping metrics reporting." "$LINENO"
    fi
    
    return $?
}

#Function Name: reportStats
#Comments     : Check whether internet connection is available.
#               Ping metrics.amd.com first, if successfull go ahead and report metrics.
#               If ping fails (port blocked or genuine failure) try downloading
#               verison.txt from developer.amd.com (try this only once).
#               If the download succeeds then report metrics, otherwise skip reporting metrics.
reportStats()
{
    log "Checking Internet connectivity. Please wait..." "$LINENO" "console"
    
    # We first check whether internet connection is available.
    # Ping metrics.amd.com first, if successfull go ahead and report metrics
    # If ping fails (port blocked or genuine failure) try downloading verison.txt from developer.amd.com (try this only once)
    # If the download succeeds then report metrics, otherwise skip reporting metrics.
    
    PING=$(which ping)
    Retval=$?
    if [ $Retval -ne 0 ]; then
        log "Failed to locate ping command" "$LINENO"
        return $Retval
    fi
    
    log "PING Command: ${PING}" "$LINENO"
    $PING -c 4 metrics.amd.com >> "$LOG_FILE" 2>&1
    Retval=$?
    if [ $Retval -eq 0 ]; then
        # Has internet access
        reportMetrics
        return $?
    fi
    
    #Ping failed, ping may be blocked or some other reason
    #Try downloading the default from metrics.amd.com
    WGET=$(which wget)
    Retval=$?
    if [ $Retval -ne 0 ]; then
        log "Failed to locate wget command. Skipping metrics reporting." "$LINENO"
        return $Retval
    fi
    
    #If the code has come here this means that ping has failed
    #So we try downloading from metrics.amd.com
    $WGET -v --tries=1 -O "$SDK_TEMP_DIR/metrics-amd-com.html" -U "DEV/SDK Mozilla (X11; Linux x86; rv:25.0) Gecko/20100101 Firefox/25.0" "http://metrics.amd.com"  >> "$LOG_FILE" 2>&1
    Retval=$?
    if [ $Retval -eq 0 ]; then
        #Looks like metrics.amd.com is accessible, ping might have been blocked.
        reportMetrics
        Retval=$?
    fi
    
    return $Retval
}

#Function Name: createAPPSDKIni
#Comments     : This function creates the INI file in the appropriate folder,
#               for root user it creates in /etc/AMD folder, for non-root 
#               it creates the file in $HOME/etc/AMD The Ini file consists the
#               value of $INSTALL_DIR, which can be used to check whether 
#               APP SDK is already installed for the logged in user.
#               The $INSTALL_DIR value can be used while repairing the 
#               APP SDK or even while uninstalling the APP SDK.
createAPPSDKIni()
{
    AMDAPPSDK_DIR=/etc/AMD
    if [ "$UID" -ne 0 ]; then
        #Non-root
        AMDAPPSDK_DIR=${HOME}${AMDAPPSDK_DIR}
    fi
    
    AMDAPPSDK_INIFILE="${AMDAPPSDK_DIR}/APPSDK-3.0.ini"
    Retval=1

    #AS of now if the file exists, we log it and then re-create the file.
    if [ -e "$AMDAPPSDK_INIFILE" ]; then
        #log that the INI file pre-exists and the file is been re-created with the new value.
        log "The $AMDAPPSDK_INIFILE pre-exists" "$LINENO."
    fi
    
    #create the ini file with the INSTALL_DIR value.
    mkdir -pv "$AMDAPPSDK_DIR" --mode 755 "$INSTALL_DIR" >> "$LOG_FILE" 2>&1        
    Retval=$?
    if [ $Retval -eq 0 ] ; then
        echo [GENERAL] > "$AMDAPPSDK_INIFILE"
        echo INSTALL_DIR=$INSTALL_DIR >> "$AMDAPPSDK_INIFILE"
    else
        log "Failed to create the directory for $AMDAPPSDK_INIFILE." "$LINENO"
    fi
    
    return $Retval
}

moveLibrary()
{
    Retval=0
    
    if [ -e "$LIBRARY_DIRECTORY/libOpenCL.so.1" -o -e "$LIBRARY_DIRECTORY/libOpenCL.so" ]; then
        #Found files to be moved.
        log "Moving the files libOpenCL.so* for backup under: $SDKDirectory/sdk " "$LINENO"
        #Moving the files for backup.
        mv -fv "$LIBRARY_DIRECTORY/libOpenCL.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1
        mv -fv "$LIBRARY_DIRECTORY/libOpenCL.so.1" "$SDKDirectory" >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -eq 0 ]; then
            log "Successfully moved libOpenCL.so* files files to $SDKDirectory for backup. " "$LINENO" 
        else
            log "Failed to move libOpenCL.so* files to $SDKDirectory for backup. " "$LINENO"
            return $Retval
        fi
        
        if [ "$OS_ARCH" == "32" ]; then
         
          log "Moving the files libamd* for backup under: $SDKDirectory/sdk " "$LINENO" 
          #Moving the files for backup.
          mv -fv "$LIBRARY_DIRECTORY/libamdhsasc32.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1
          mv -fv "$LIBRARY_DIRECTORY/libamdocl32.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1
          mv -fv "$LIBRARY_DIRECTORY/libamdoclcl32.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1    
          Retval=$?
          if [ $Retval -eq 0 ]; then
              log "Successfully moved libamd* files to $SDKDirectory for backup. " "$LINENO" 
          else
              log "Failed to move libamd* files files to $SDKDirectory for backup. " "$LINENO"
              return $Retval
          fi
         else
          mv -fv "$LIBRARY_DIRECTORY/libamdhsasc64.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1
          mv -fv "$LIBRARY_DIRECTORY/libamdocl64.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1
          mv -fv "$LIBRARY_DIRECTORY/libamdoclcl64.so" "$SDKDirectory" >> "$LOG_FILE" 2>&1    
          Retval=$?
          if [ $Retval -eq 0 ]; then
              log "Successfully moved libamd* files to $SDKDirectory for backup. " "$LINENO" 
          else
              log "Failed to move libamd* files files to $SDKDirectory for backup. " "$LINENO"
              return $Retval
          fi
         fi
         
    else
        log "The $LIBRARY_DIRECTORY does not contain libOpenCL.so* files to be moved, to $SDKDirectory for backup. " "$LINENO"
    fi
    return $Retval
}

#Function Name: moveLibraries
#Comments     : This function handles moving of the libamd* and libOpenCL.so*
#               files from $INSTALL_DIR/lib/$OS_ARCH to $INSTALL_DIR/lib/$OS_ARCH/sdk
#               depending on the $OS_ARCH. 
#               Also creates a soft link to usr/lib/libOpenCL.so file
#               We are moving the file as backup.
#               If catalyst is un-installed after installing AMDAPPSDK, 
#               then in-order to use AMDAPPSDK OpenCL runtime, 
#               the user can copy our libraries back manually and use them.

moveLibraries()
{
    LIBRARY_DIRECTORY="$1"
    SDKDirectory="$LIBRARY_DIRECTORY/sdk"
    Retval=0
    if [ -d "$SDKDirectory" ]; then
        log "The $SDKDirectory folder already exists. " "$LINENO"
    else
        #create the sdk directories under $INSTALL_DIR/lib/x86 or $INSTALL_DIR/lib/x86_64 depending on $OS_ARCH
        mkdir -v --mode 755 "$SDKDirectory" >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -eq 0 ]; then
            log "The sdk folder has been successfully created under: $SDKDirectory " "$LINENO" 
        else
            log "Failed to create the sdk folder under: $LIBRARY_NAME, Please create the "sdk" folder under $LIBRARY_NAME directory and move all libamd* and libOpenCL.so* manually in-order to use catalyst OpenCL run-times. " "$LINENO"
            return $Retval
        fi
    fi
        
    #Now the $SDKDirectory, has been created or already exists.
    #Now check whether $LIBRARY_DIRECTORY directory contains libamd* and libOpenCL.so* files to be moved.
    #If files are present then only move them to $SDKDirectory directory.
    #else just log it.
    if [ -e "$LIBRARY_DIRECTORY/libOpenCL.so.1" -o -e "$LIBRARY_DIRECTORY/libOpenCL.so" ]; then
        #$LIBRARY_DIRECTORY directory contains libamd* and libOpenCL.so* files.
        if [ `ls -A "$SDKDirectory" | wc -l` -eq 0 ]; then 
            #Move libamd* and libOpenCL.so* files to $SDKDirectory
            log "Moving the files libamd* and libOpenCL.so* for backup under: $SDKDirectory/sdk " "$LINENO"
            moveLibrary
            Retval=$?
            if [ $Retval -eq 0 ]; then
                log "The libamd* and libOpenCL.so* files has been successfully moved to: $SDKDirectory " "$LINENO" 
            else
                log "Failed to move libamd* and libOpenCL.so* files to: $SDKDirectory. " "$LINENO"
                return $Retval
            fi
        else
            #The folder is not empty.
            #Now check whether the $SDKDirectory contains libamd* and libOpenCL.so* files or not.
            #If files are present delete the old files and then move the new files.
            #Else just move the files.
            if [ -e "$SDKDirectory/libamd*" ]; then -o 
                #$SDKDirectory already contains libamd* and libOpenCL.so* files
                #Remove the old libamd* files.
                log "Deleting old libamd* from: $SDKDirectory " "$LINENO"
                rm -rvf "$SDKDirectory/libamd*" >> "$LOG_FILE" 2>&1
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "The libamd* files has been successfully deleted from : $SDKDirectory " "$LINENO" 
                else
                    log "Failed to delete libamd* files from: $SDKDirectory. " "$LINENO"
                    return $Retval
                fi
            else
                log "The $SDKDirectory directory does not contain libOpenCL.so* files, so skipping the deletion of files from : $SDKDirectory " "$LINENO"
            fi
            if [ -e "$SDKDirectory/libOpenCL.so*" ]; then
                #$SDKDirectory already contains libamd* and libOpenCL.so* files
                #Remove the old libOpenCL.so* files from $SDKDirectory.
                log "Deleting old libOpenCL.so* from: $SDKDirectory " "$LINENO"
                rm -rvf "$SDKDirectory/libOpenCL.so*" >> "$LOG_FILE" 2>&1
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "The libOpenCL.so* files has been successfully deleted from : $SDKDirectory " "$LINENO" 
                else
                    log "Failed to delete libOpenCL.so* files from: $SDKDirectory. " "$LINENO"
                    return $Retval
                fi
            else
                log "The $SDKDirectory directory does not contain libOpenCL.so* files, so skipping the deletion of files from : $SDKDirectory " "$LINENO"
            fi
            #Now the $SDKDirectory directory does not contain libamd* and libOpenCL.so* files, so move them.
            log "Moving the files libamd* and libOpenCL.so* for backup under: $SDKDirectory/sdk " "$LINENO"
            moveLibrary
            Retval=$?
            if [ $Retval -eq 0 ]; then
                log "The libamd* and libOpenCL.so* files has been successfully moved to: $SDKDirectory " "$LINENO" 
            else
                log "Failed to move libamd* and libOpenCL.so* files to: $SDKDirectory. " "$LINENO"
                return $Retval
            fi
        fi    
    else
        log "The $LIBRARY_DIRECTORY directory does not contain libamd* and libOpenCL.so* files, so skipping the moving of files. " "$LINENO"
    fi
    
    return $Retval
}    

#Function Name: createOpenCLSoftLink
#Comments     : creates the soft-link libOpenCL.so to libOpenCL.so.1
#               This is done depending upon the libOpenCL.so file.
#               If libOpenCL.so exist we are doing nothing.
#               If only libOpenCL.so.1 is present in /usr/lib, then we are creating the soft-link libOpenCL.so to libOpenCL.so.1
#               The libOpenCL.so* file are created depending upon the catalyst installation, so to handle this we are creating soft-link
#               And libOpenCL.so is required by cmake files to pick the catalyst runtimes.
#               If libOpenCL.so file is not found in /usr/lib, then cmake picks up the AMDAPPSDK runtimes.
createOpenCLSoftLink()
{
    Retval=0
    if grep -q Ubuntu <<< $OS_DISTRO; then
        if [ -e "/usr/lib/libOpenCL.so" ]; then
            log "The /usr/lib/libOpenCL.so file exists, hence doing nothing" "$LINENO"
        else
            if [ -e "/usr/lib/libOpenCL.so.1" ]; then
                log "Creating soft-link libOpenCL.so to libOpenCL.so.1 in usr/lib" "$LINENO"
                if [ "$OS_ARCH" == "32" ]; then
                    ln -sv "/usr/lib/libOpenCL.so.1" "$INSTALL_DIR/lib/x86/libOpenCL.so" >> "$LOG_FILE" 2>&1
                    Retval=$?
                    if [ $Retval -eq 0 ]; then
                        log "Successfully created a soft-link " "$LINENO" 
                    else
                        log "Failed to create a soft-link. " "$LINENO"
                    fi
                else
                    ln -sv "/usr/lib/libOpenCL.so.1" "$INSTALL_DIR/lib/x86_64/libOpenCL.so" >> "$LOG_FILE" 2>&1
                    Retval=$?
                    if [ $Retval -eq 0 ]; then
                        log "Successfully created a soft-link " "$LINENO" 
                    else
                        log "Failed to create a soft-link. " "$LINENO"
                    fi
                fi
            else
                log "Catalyst is not present, so the controller should not have come here, Please report the same to AMD support team at http://devgurus.amd.com/community/opencl" "$LINENO"
            fi
        fi
    else
        #Non Ubuntu machines
        if [ "$OS_ARCH" == "32" ]; then
            if [ -e "/usr/lib/libOpenCL.so" ]; then
                log "The /usr/lib/libOpenCL.so file exists, hence doing nothing" "$LINENO"
            else
                if [ -e "/usr/lib/libOpenCL.so.1" ]; then
                    log "Creating soft-link libOpenCL.so to libOpenCL.so.1 in $INSTALL_DIR/lib/x86. " "$LINENO"
                    ln -sv  "/usr/lib/libOpenCL.so.1" "$INSTALL_DIR/lib/x86/libOpenCL.so" >> "$LOG_FILE" 2>&1
                    Retval=$?
                    if [ $Retval -eq 0 ]; then
                        log "Successfully created a soft-link " "$LINENO" 
                    else
                        log "Failed to create a soft-link. " "$LINENO"
                    fi
                else
                    log "Catalyst is not present, so the controller should not have come here, Please report the same to AMD support team at http://devgurus.amd.com/community/opencl" "$LINENO"
                fi
            fi

        elif [ "$OS_ARCH" = "64" ]; then
            if [ -e "/usr/lib64/libOpenCL.so" ]; then
                log "The /usr/lib64/libOpenCL.so file exists, hence doing nothing" "$LINENO"
            else
                if [ -e "/usr/lib64/libOpenCL.so.1" ]; then
                    log "Creating soft-link libOpenCL.so. to libOpenCL.so.1 in $INSTALL_DIR/lib/x86_64" "$LINENO"
                    ln -sv "/usr/lib64/libOpenCL.so.1" "$INSTALL_DIR/lib/x86_64/libOpenCL.so" >> "$LOG_FILE" 2>&1
                    Retval=$?
                    if [ $Retval -eq 0 ]; then
                        log "Successfully created a soft-link " "$LINENO" 
                    else
                        log "Failed to create a soft-link. " "$LINENO"
                    fi
                else
                    log "Catalyst is not present, so the controller should not have come here, Please report the same to AMD support team at http://devgurus.amd.com/community/opencl" "$LINENO"
                fi
            fi
        else
            log "FAILURE: Found an incompatible OS Architecture: $OS_ARCH. Please report the issue." "$LINENO" "console"
        fi
    fi
    
    return $Retval
}

#Function Name: handleCatalyst
#Comments     :This function removes the libOpenCL.so and the libamdocl32/64.so if catalyst is installed.
#              It also creates the libOpenCL.so soft-link to the appropriate libOpenCL.so.1
handleCatalyst()
{
    LIB32="$INSTALL_DIR/lib/x86"
    if [ "$OS_ARCH" = "64" ]; then
        LIB64="$INSTALL_DIR/lib/x86_64"
    fi
    if grep -q Ubuntu <<< $OS_DISTRO; then
        log "Found Ubuntu OS system" "$LINENO"
        #Now search whther catalyst is installed or not
        if [ "$OS_ARCH" == "32" ] ; then
            if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then    
                #Found files
                log "32-bit AMD Catalyst OpenCL Runtime is available, hence moving the files to  $INSTALL_DIR." "$LINENO"
                #Move files and create soft link        
                moveLibraries "$LIB32"
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully moved libamd* and libOpenCL.so* files for backup under: $SDKDirectory/sdk " "$LINENO" 
                else
                    log "Failed to move libamd* and libOpenCL.so* files, Please create the sdk folder under $SDKDirectory directory and move all libamd* and libOpenCL.so* manually. " "$LINENO"
                fi
                
                createOpenCLSoftLink
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully created a soft-link " "$LINENO" 
                else
                    log "Failed to create a soft-link. " "$LINENO"
                fi
            else
                log "Catalyst is not present, so doing nothing" "$LINENO"
            fi
        else
            if [[ -e "/usr/lib32/libOpenCL.so" ]] || [[ -e "/usr/lib32/libOpenCL.so.1" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]] || [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/i386-linux-gnu/libOpenCL.so" ]] || [[ -e "/usr/lib/i386-linux-gnu/libOpenCL.so.1" ]]; then
                #Found files
                log "64-bit AMD Catalyst OpenCL Runtime is available, hence moving the files in  $INSTALL_DIR" "$LINENO"
                #Move files and create soft link        
                moveLibraries "$LIB64"
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully moved libamd* and libOpenCL.so* files for backup under: $SDKDirectory/sdk " "$LINENO" 
                    #Now the files has been successfully moved to $SDKDirectory/sdk, so now we are creating the soft-link in /usr/bin
                else
                    log "Failed to move libamd* and libOpenCL.so* files, Please create the sdk folder under $SDKDirectory directory and move all libamd* and libOpenCL.so* manually. " "$LINENO"
                fi
                
                createOpenCLSoftLink
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully created a soft-link " "$LINENO" 
                else
                    log "Failed to create a soft-link. " "$LINENO"
                fi
            else
                log "Catalyst is not present, so doing nothing" "$LINENO"
            fi
        fi
        
        
    else
        if [ "$OS_ARCH" == "32" ]; then 
            if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then
                #Found files
                log "32-bit AMD Catalyst OpenCL Runtime is available, hence moving the files in  $INSTALL_DIR." "$LINENO"
                #Move files and create soft link        
                moveLibraries "$LIB32"
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully moved libamd* and libOpenCL.so* files for backup under: $SDKDirectory/sdk " "$LINENO" 
                    #Now the files has been successfully moved to $SDKDirectory/sdk, so now we are creating the soft-link in /usr/bin
                else
                    log "Failed to move libamd* and libOpenCL.so* files, Please create the sdk folder under $SDKDirectory directory and move all libamd* and libOpenCL.so* manually. " "$LINENO"
                fi
                
                createOpenCLSoftLink
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully created a soft-link " "$LINENO" 
                else
                    log "Failed to create a soft-link. " "$LINENO"
                fi
            else
                log "Catalyst is not present, so doing nothing" "$LINENO"
            fi
        else
            if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]] || [[ -e "/usr/lib64/libOpenCL.so" ]] || [[ -e "/usr/lib64/libOpenCL.so.1" ]]; then
                #Found files
                log "64-bit AMD Catalyst OpenCL Runtime is available, hence moving the files in  $INSTALL_DIR" "$LINENO"
                #Move files and create soft link
                moveLibraries "$LIB64"
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully moved libamd* and libOpenCL.so* files for backup under: $SDKDirectory/sdk " "$LINENO" 
                    #Now the files has been successfully moved to $SDKDirectory/sdk, so now we are creating the soft-link in /usr/bin
                else
                    log "Failed to move libamd* and libOpenCL.so* files, Please create the sdk folder under $SDKDirectory directory and move all libamd* and libOpenCL.so* manually. " "$LINENO"
                fi
                
                createOpenCLSoftLink
                Retval=$?
                if [ $Retval -eq 0 ]; then
                    log "Successfully created a soft-link " "$LINENO" 
                else
                    log "Failed to create a soft-link. " "$LINENO"
                fi
            else
                log "Catalyst is not present, so doing nothing" "$LINENO"
            fi
        fi
    fi
}

#Function Name: main
#Comments     : this function executes all the functions called in it 
#               and creates the log files for all the functions irrespective of the results.
main()
{
    Retval=1
    if [ ! -d "$SDK_TEMP_DIR" ]; then
        #create the tmp directory for storing logs with 777 permissions.
        #this directory hierarchy will be owned by the logged in user.
        mkdir --parents --mode 777 "$SDK_TEMP_DIR"
    fi
    
    log "Starting installation of AMD APP SDK v3.0" "$LINENO" "console"
    log "Retrieving Operating System details..." "$LINENO" "console"
    
    getOSDetails
    getLoggedInUserDetails
    checkPrerequisites
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "The 64-bit AMD APP SDK v3.0 cannot be installed on a 32-bit Operating System. Please use the 32-bit AMD APP SDK v3.0." "$LINENO" "console"
        exit $Retval
    fi
    #Show the EULA and ask for continuation
    if [ ${FLAGS_silent} -eq ${FLAGS_TRUE} ]; then
        ACCEPTEULA=`echo ${FLAGS_acceptEULA} | tr '[:upper:]' '[:lower:]'`
        
        echo ACCEPTEULA: $ACCEPTEULA, FLAGS: $FLAGS_acceptEULA
        #If silent mode, then check whether the --acceptEULA flag is specified with the value=y or yes or true, or TRUE or 1.
        if [ "${ACCEPTEULA}" == "1" -o "${ACCEPTEULA}" == "y" -o "${ACCEPTEULA}" == "yes" ]; then
            log "EULA accepted, proceeding with silent installation", "$LINENO"
        else
            log "You will need to read and accept the EULA to install AMD APP SDK." "$LINENO" "console"
            exit 1
        fi
    else
        #not silent mode, show the EULA and wait for acceptance
        if showEULAAndWait; then
            log "EULA accepted, proceeding with console mode installation" "$LINENO"
        else
            log "You will need to read and accept the EULA to install AMD APP SDK." "$LINENO" "console"
            exit 1
        fi
    fi
    
    #If the user is a non-root user, ask whether the software needs to be installed for all users (root) or only
    #for the logged in user?
    
    #If only for logged in user, then the software will be installed in the home directory,
    #otherwise in the /opt/AMDAPPSDK/3.0 directory.
    if [ "$UID" -eq 0 ]; then
        log "AMD APP SDK v3.0 will be installed for all users." "$LINENO" "console"
        USERMODE_INSTALL=0
    else
        if [ ${FLAGS_silent} -eq ${FLAGS_TRUE} ]; then
            #silent mode, dump the message and proceed with installation
            log "Proceeding with non root silent mode installation." "$LINENO" "console"
            USERMODE_INSTALL=1
            INSTALL_DIR="$HOME"
        else
            log "Non root user, asking the user for continuation of installation." "$LINENO" "console"
            if askYN "AMD APP SDK v3.0 will be installed for $USER only if you choose to continue. If you want to install for all users, then you need to restart the installer with root credentials. Do you wish to continue [Y/N]?"; then
                #user wants to get ahead with a non-root installation
                USERMODE_INSTALL=1
                INSTALL_DIR="$HOME"
            else
                log "Please restart the installer with root credentials to install for all users. The installer will now quit." "$LINENO" "console"
                exit 0
            fi
        fi
    fi
    
    log "USERMODE_INSTALL: $USERMODE_INSTALL. (0: root user; 1: non-root user " "$LINENO" 
    
    #Now we know whether to perform a user-mode or a root-mode installation
    #Now ask for the install directory, default will be $INSTALL_DIR
    if [ ${FLAGS_silent} -ne ${FLAGS_TRUE} ]; then
        log "Prompting user for selecting the Installation Directory. Default is $INSTALL_DIR" "$LINENO"
        askDirectory "Enter the Installation directory. Press ENTER for choosing the default directory" "$INSTALL_DIR"
        INSTALL_DIR="$Directory"
    else
        INSTALL_DIR="${INSTALL_DIR}/AMDAPPSDK-3.0"
    fi
    
    #Now we need to copy the payload to the $INSTALL_DIR
    #The various use cases are:
    #    1. Fresh install
    #    2. The directory exists
    #    3. If it is a root mode install, then other users need to have rwx permissions
    #    4. If non-root mode install, then other users should not have any permissions.

    dumpPayload
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "Failed to install AMD APP SDK v3.0 to $INSTALL_DIR. The installation cannot continue." "$LINENO" "console"
        exit $Retval
    fi
    
    registerOpenCLICD
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "Failed to install AMD APP SDK v3.0 to $INSTALL_DIR. The installation cannot continue." "$LINENO" "console"
        exit $Retval
    fi
    
    updateEnvironmentVariables
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "Failed to update environment variables AMDAPPSDKROOT and/or LD_LIBRARY_PATH. The installation might still work, however you will need to create/update these environment variables manually. Consult the documentation for the same." "$LINENO" "console" 
    fi
    
    installCLINFO
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "[WARN]Failed to install clinfo." "$LINENO" "console"
    fi

    handleCatalyst
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "[WARN]Failed to update files to use existing catalyst drivers." "$LINENO" "console"
    fi
    
    reportStats
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "Failed to report statistics to metrics.amd.com." "$LINENO"
    fi
    
    createAPPSDKIni
    Retval=$?
    if [ $Retval -ne 0 ] ; then
        log "Failed to create the INI file for AMD APP SDK-3.0." "$LINENO"
        return $Retval
    fi
    
    log "Installation Log file: $LOG_FILE" "$LINENO" "console"
    log "You will need to log back in/open another terminal for the environment variable updates to take effect." "$LINENO" "console"
    
    return $Retval
}

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"

main "$@"
exit $?

