#!/bin/bash

################################################################################
#
# Copyright© 2015 Advanced Micro Devices, Inc. All rights reserved.
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
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
################################################################################

#Script level variables
SDK_TEMP_DIR="/tmp/AMDAPPSDK-3.0"
LOG_FILE="$SDK_TEMP_DIR/UninstallLog_$(date +"%m-%d-%Y"T"%H-%M-%S").log"
#INSTALL_DIR="/opt"
USERMODE_INSTALL=1    #A value of 1 indicates that the script will uninstall 
            #AMD APP SDK for the currently logged in user only

#Function Name: log
#Comments     : The log function logs the messages in the specified log file
#               By default info is not logged in the console
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

#Function Name: getLoggedInUserDetails
#Comments     : Get's the current loged-in user details and prints on the console.
getLoggedInUserDetails()
{
    CURRENT_USER=$(whoami)
    log "Logged in user: $CURRENT_USER" "$LINENO" "console"
}

#Function Name: getInstallationDirectory
#Comments     : This function checks for the presence of ini file in /etc/AMD/ directory
#               for root users, otherwise checks for the presence of ini in $HOME/etc/AMD/directory
#               This ini file contains the INSTALL_DIR as a key-value pair.
#               Note: Most likely the environment variable AMDAPPSDKROOT will also point to the same directory,
#               however the environment variable is not the best way to locate the installation directory
getInstallationDirectory()
{
    INIFILE="$HOME/etc/AMD/APPSDK-3.0.ini"
    if [ $UID -eq "0" ]; then
        #Root user
        INIFILE="/etc/AMD/APPSDK-3.0.ini"
    fi
    #Check whether the INIFILE exists or not
    #If it exists, then grab the value of the key INSTALL_DIR in it.
    log "Locating $INIFILE" "$LINENO" "console"
    if [ -e "$INIFILE" ]; then
        INSTALL_DIR=$(grep -r INSTALL_DIR "$INIFILE" | awk -F'=' '{print $2}')
        log "Detected AMD APP SDK-3.0 installed in: $INSTALL_DIR" "$LINENO" "console"
    else
        log "Failed to locate the ini file: $INIFILE" "$LINENO"
    fi
}

#Function Name: unhandleCatalyst
#Comments     : This function checks for the catalyst files are present or not.
unhandleCatalyst()
{
    Retval=1
    if grep -q Ubuntu <<< $OS_DISTRO; then
        log "Found Ubuntu OS system" "$LINENO"
        #Now search whther catalyst is installed or not
        if  [ "$OS_ARCH" == "32" ]; then 
            if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then    
                #Found files
                log "32-bit AMD Catalyst OpenCL Runtime is available, hence do nothing in  $INSTALL_DIR." "$LINENO"
            else
                log "32-bit AMD Catalyst OpenCL Runtime is not available, the controller should not have come here, if this exists please report it to AMD support team. " "$LINENO"
            fi
        elif [ "$OS_ARCH" = "64" ]; then
            if [[ -e "/usr/lib32/libOpenCL.so" ]] || [[ -e "/usr/lib32/libOpenCL.so.1" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]] || [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/i386-linux-gnu/libOpenCL.so" ]] || [[ -e "/usr/lib/i386-linux-gnu/libOpenCL.so.1" ]]; then
                #Found files
                log "64-bit  and 32-bit AMD Catalyst OpenCL Runtime is available, hence do nothing in  $INSTALL_DIR" "$LINENO"
            else
                log "64-bit AMD Catalyst OpenCL Runtime is not available, the controller should not have come here, if this exists please report it to AMD support team. " "$LINENO"
            fi
        else
            log "FAILURE: Found an incompatible OS Architecture: $OS_ARCH. Please report the issue." "$LINENO" "console"
        fi
    else
        if [ "$OS_ARCH" == "32" ]; then 
            if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]]; then
                #Found files
                log "32-bit AMD Catalyst OpenCL Runtime is available, hence do nothing in  $INSTALL_DIR." "$LINENO"
            else
                log "32-bit AMD Catalyst OpenCL Runtime is not available, the controller should not have come here, if this exists please report it to AMD support team. " "$LINENO"
            fi
        elif [ "$OS_ARCH" == "64" ]; then 
            if [[ -e "/usr/lib/libOpenCL.so" ]] || [[ -e "/usr/lib/libOpenCL.so.1" ]] || [[ -e "/usr/lib64/libOpenCL.so" ]] || [[ -e "/usr/lib64/libOpenCL.so.1" ]]; then
                #Found files
                log "64-bit AMD Catalyst OpenCL Runtime is available, hence do nothing in  $INSTALL_DIR" "$LINENO"
            else
                log "64-bit AMD Catalyst OpenCL Runtime is not available, the controller should not have come here, if this exists please report it to AMD support team. " "$LINENO"
            fi
        else
            log "FAILURE: Found an incompatible OS Architecture: $OS_ARCH. Please report the issue." "$LINENO" "console"
        fi
    fi
    return $Retval
}

deleteClinfoSoftlink()
{
    Filename="$1"    
    #check whether it is a soft-link
    if [ -h "$Filename" ]; then
        #file is a soft-link so read the link
        LinkTarget=$(readlink $Filename)
        log "$Filename is a soft-link to $LinkTarget" "$LINENO"
        if [[ "$LinkTarget" == *AMDAPPSDK* ]]; then
            #Assuming that the soft link is been created by APPSDK
            #so we are deleting the soft-link
            log "Deleting the soft-link from the appropriate $INSTALL_DIR/bin/*/clinfo in /usr/bin" "$LINENO" 
            rm -rvf "$Filename" >> "$LOG_FILE" 2>&1
        else
            log "The Soft-link present is not created by AMDAPPSDK, so skipping deletion of soft-links to clinfo" "$LINENO"
        fi
    else 
        #File is not a soft-link. #check it is a a regular file
        if [ -f "$Filename" ]; then
            #it is a regular file, most likely created by the catalyst installer, so skipping deletion of soft-links to clinfo.
            log "$Filename is a regular file, most likely created by the catalyst installer, so skipping deletion of soft-links to clinfo." "$LINENO"
            Retval=0
        else
            #Some other kind of file, should not be the case, log it and move ahead
            log "[WARN]$Filename is not a regular file. Skipping deletion of soft-link." "$LINENO"
            Retval=0
        fi
    fi
}

#Function Name: uninstallCLINFO
#Returns      : returns zero if clinfo file has been deleted, if not returns non-zero value.
#Comments     : Depending upon the user logged-in, deletes the CLINFO file from $INSTALL_DIR
uninstallCLINFO()
{
    Filename=/usr/bin/clinfo
    if [ "$USERMODE_INSTALL" == "0" ]; then
        #root user
        #Check whether the /usr/bin/clinfo is already existing. If it is then it could be there because
        #of Catalyst installing it or a user creating it manually or on existing version of
        #APP SDK Creating it. Whatever be the case, if it is, then we just check
        #whether it is a soft-link or a actual file. If it is an actual file, then we don't touch it.
        if [ -e "$Filename" ]; then
            log "$Filename exists, so deleting the soft links." "$LINENO"
            deleteClinfoSoftlink "$Filename"
        else
            log "$Filename does not exist, so skipping deletion of soft-links." "$LINENO"
        fi
    else
        #non-root user
        Filename=$HOME/bin/clinfo
        if [ -e "$Filename" ]; then
            log "$HomeCLINFO exists, so deleting the soft links." "$LINENO"
            #check whether it is a soft-link
            rm -rvf "$Filename" >> "$LOG_FILE" 2>&1
        else
            #clinfo file does not exist,so soft link does not exists
            log "clinfo file does not exist in $HOME/bin directory." "$LINENO"
        fi                
    fi
    return $Retval
}

#Function Name: removeEnvironmentVariable
#Returns      : returns zero if the EnvironmentVariablehas been deleted, if not returns non-zero value.
#Comments     : This function checks whether the EnvironmentVariable is present or not,through Grep command.
#               If present, it deletes the EnvironmentVariable, if not present-it skips the deletion.
removeEnvironmentVariable()
{
    FILE="$1"
    ENVIRONMENT_VARIABLE_NAME="$2"
    #First check whether the entry exists, if it does then delete, else skip the deletion.
    log "Checking for the presence of $ENVIRONMENT_VARIABLE_NAME in the file: $FILE using grep" "$LINENO"
    grep "$ENVIRONMENT_VARIABLE_NAME" "$FILE" >> "$LOG_FILE" 2>&1
    Retval=$?
    if [ $Retval -eq 0 ]; then
        #found an entry, which needs to be deleted
        log "Found an entry for $ENVIRONMENT_VARIABLE_NAME in file: $FILE. Deleted it." "$LINENO" 
        sed -i.bak "/$ENVIRONMENT_VARIABLE_NAME/d" "$FILE" >> "$LOG_FILE" 2>&1    
        #Confirm whether the command did its job in removing the file.
        grep "$ENVIRONMENT_VARIABLE_NAME" "$FILE" >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -ne 0 ]; then
            log "Entry for $ENVIRONMENT_VARIABLE_NAME removed." "$LINENO"
            Retval=0
        else
            log "FAILURE: Could not delete entry for $ENVIRONMENT_VARIABLE_NAME removed." "$LINENO"
            Retval=$?
        fi
    else
        log "No Entry for $ENVIRONMENT_VARIABLE_NAME in file: $FILE. hence skipping the deletion." "$LINENO"
    fi
    return $Retval
}

#Function Name: addEnvironmentVariable
#Comments     : This function adds back the environment variables, after updating the environment variables.
addEnvironmentVariable()
{
    FILE="$1"
    ENVIRONMENT_VARIABLE_NAME="$2"
    ENVIRONMENT_VARIABLE_VALUE="$3"
    #Adding the environment variable back
    log "echo export \"$ENVIRONMENT_VARIABLE_NAME=\"$ENVIRONMENT_VARIABLE_VALUE\"\" >> \"$FILE\"" "$LINENO" 
    echo "export $ENVIRONMENT_VARIABLE_NAME=\"$ENVIRONMENT_VARIABLE_VALUE\"" >> "$FILE"    
}

#Function Name: updateEnvironmentVariables
#Returns      : returns zero if the EnvironmentVariablehas been updated, if not returns non-zero value.
#Comments     : this function updates and also unset the EnvironmentVariables which have been updated during installation.
updateEnvironmentVariables()
{
    #This function updates and also unset an environment variable 
    AMDAPPSDKROOT="$INSTALL_DIR"
    Retval=1
    if [ $UID -eq "0" ]; then
        #Installed as root user
        AMDAPPSDK_PROFILE="/etc/profile.d/AMDAPPSDK.sh"
    else
        if [ -e "$HOME/.bashrc" ]; then
            AMDAPPSDK_PROFILE="$HOME/.bashrc"
        else
            log "Could not locate $HOME/.bashrc. Unable to remove environment variables" "$LINENO" 
        fi
    fi
    #Update the AMDAPPSDKROOT environment variable in /etc/profile.d directory as root user
    removeEnvironmentVariable "$AMDAPPSDK_PROFILE" "AMDAPPSDKROOT"
    Retval=$?
    if [ $Retval -eq 1 ]; then
            #Environment variables files are not deleted, you may have to delete it manually.
            log "[WARN]: Could not delete the Environment variables from the $AMDAPPSDK_PROFILE file , You will need to delete them manually." "$LINENO" "console"
    else
            log "The Environment variables for AMDAPPSDK has been deleted the $AMDAPPSDK_PROFILE file." "$LINENO" "console"
    fi
    if [ -e "/usr/lib/libOpenCL.so" -o -e "/usr/lib/libOpenCL.so.1" ]; then
        log "AMD Catalyst OpenCL Runtime is available, hence OPENCL_VENDOR_PATH might not have been updated/created by installer, so skipping the updation." "$LINENO"
    else
        #Delete the OPENCL_VENDOR_PATH environment variable            
        removeEnvironmentVariable "$AMDAPPSDK_PROFILE" "OPENCL_VENDOR_PATH" 
        Retval=$?
        if [ $Retval -eq 1 ]; then
                #Environment variables are not deleted, you may have to delete it manually.
                log "[WARN]: Could not delete the Environment variables from the $AMDAPPSDK_PROFILE file , You will need to delete them manually." "$LINENO" "console"
        else
                log "The Environment variables for AMDAPPSDK has been deleted the $AMDAPPSDK_PROFILE file." "$LINENO" "console"
        fi
    fi
        
    AMDAPP_CONF_32="/etc/ld.so.conf.d/amdAPP_x86.conf"
    if [ "$OS_ARCH" == "64" ]; then
        AMDAPP_CONF_64="/etc/ld.so.conf.d/amdAPP_x86_64.conf"
    fi
    if [ "$OS_ARCH" == "32" ]; then
        #deleting AMDAPPSDK_conf file 
        rm -vf $AMDAPP_CONF_32 >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -eq 1 ]; then
            #The configuration files are not deleted, you may have to delete it manually.
            log "[WARN]: Could not delete the configuration file, You will need to delete the file manually." "$LINENO" "console"
        else
            log "The configuration file for AMDAPPSDK has been deleted." "$LINENO" "console"
        fi
    else
        #deleting AMDAPPSDK_conf files 
        rm -vf $AMDAPP_CONF_32 >> "$LOG_FILE" 2>&1
        rm -vf $AMDAPP_CONF_64 >> "$LOG_FILE" 2>&1
        Retval=$?
        if [ $Retval -eq 1 ]; then
            #the config files are not deleted, you may have to delete it manually.
            log "[WARN]: Could not delete the configuration files, You will need to delete them manually." "$LINENO" "console"
        else
            log "The configuration files for AMDAPPSDK has been deleted." "$LINENO" "console"
        fi
    fi
    #special updation of $LD_LIBRARY_PATH.
    #first checks whether the $LD_LIBRARY_PATH exists or not.
    #if exists, again it checks whether it is terminated with semicolon or not.
    #in-turn it checks whether LD_LIBRARY_PATH contains the updated path, if found it will delete only the value which has         
    #been updated during installation.
    #if its not found it just logs the case and skips deletion of $LD_LIBRARY_PATH.
    #after updation of LD_LIBRARY_PATH, it writes back the updated value to the system
    #Deleting the values of the LD_LIBRARY_PATH
    if [ -n "$LD_LIBRARY_PATH" ]; then
        #LD_LIBRARY_PATH exists
        log "LD_LIBRARY_PATH exists. Existing Value: $LD_LIBRARY_PATH" "$LINENO" 
    
        #Check for the updated LD_LIBRARY_PATH while installing.    
        #Remove the trailing : character, if any. The below bash shell code will do that.
        LD_LIBRARY_PATH="${LD_LIBRARY_PATH%:}"    #System's LD_LIBRARY_PATH
    
        #Create the Path that the installer would have added for APP SDK
        LD_LIBRARY_PATH32="${INSTALL_DIR}/lib/x86/"
        if [ "$OS_ARCH" == "64" ]; then
            LD_LIBRARY_PATH64="${INSTALL_DIR}/lib/x86_64/"
        fi

        #checking whether $LD_LIBRARY_PATH contains $LD_LIBRARY_PATH32, if found we need to delete only the value which is appended during installing.
        # if not found just logs the case and skips deletion.
        if [[ $LD_LIBRARY_PATH =~ "$LD_LIBRARY_PATH32" ]] ; then
                #$LD_LIBRARY_PATH32 path is found in LD_LIBRARY_PATH, hence deleting the trailing part of it.
                log "$LD_LIBRARY_PATH32 path is found in LD_LIBRARY_PATH, hence deleting the $LD_LIBRARY_PATH32 part from $LD_LIBRARY_PATH " "$LINENO"
                #Deleting duplicate values if any exists, without sorting the order of values.                
                export LD_LIBRARY_PATH="`echo "$LD_LIBRARY_PATH" |awk 'BEGIN{RS=":";}{sub(sprintf("%c$",10),"");if(A[$0]){}else{A[$0]=1;printf(((NR==1)?"":":")$0)}}'`";                                
                #Deleting $LD_LIBRARY_PATH64 part from $LD_LIBRARY_PATH
                LD_LIBRARY_PATH=$( echo $LD_LIBRARY_PATH | sed -e 's!'$LD_LIBRARY_PATH32'!!' -e 's/::/' )
                log "The new LD_LIBRARY_PATH value is: $LD_LIBRARY_PATH" "$LINENO"
                addEnvironmentVariable "$AMDAPPSDK_PROFILE" "LD_LIBRARY_PATH" "$LD_LIBRARY_PATH"
        else
            log "$LD_LIBRARY_PATH32 does not exists." "$LINENO" 
        fi
        #checking whether $LD_LIBRARY_PATH contains $LD_LIBRARY_PATH64, if found we need to delete only the value which is appended during installing.
        # if not found just log the case and skip deletion.
        if [[ $LD_LIBRARY_PATH =~ "$LD_LIBRARY_PATH64" ]] ; then
                #$LD_LIBRARY_PATH64 path is found in LD_LIBRARY_PATH, hence deleting the trailing part of it.
                log "$LD_LIBRARY_PATH64 path is found in LD_LIBRARY_PATH, hence deleting the $LD_LIBRARY_PATH64 part from $LD_LIBRARY_PATH " "$LINENO"
                #Deleting duplicate values if any exists, without sorting the order of values.                
                export LD_LIBRARY_PATH="`echo "$LD_LIBRARY_PATH" |awk 'BEGIN{RS=":";}{sub(sprintf("%c$",10),"");if(A[$0]){}else{A[$0]=1;printf(((NR==1)?"":":")$0)}}'`";                                    
                #Deleting $LD_LIBRARY_PATH64 part from $LD_LIBRARY_PATH
                LD_LIBRARY_PATH=$( echo $LD_LIBRARY_PATH | sed -e 's!'$LD_LIBRARY_PATH64'!!' -e 's/::/' )
                log "The new LD_LIBRARY_PATH value is $LD_LIBRARY_PATH" "$LINENO"
                addEnvironmentVariable "$AMDAPPSDK_PROFILE" "LD_LIBRARY_PATH" "$LD_LIBRARY_PATH"        
        else
            log "$LD_LIBRARY_PATH64 does not exists." "$LINENO" 
        fi
        if [ -z "$LD_LIBRARY_PATH" ]; then
            if [ $UID -ne "0" ]; then
                #Non-Root user                
                removeEnvironmentVariable "$AMDAPPSDK_PROFILE" "LD_LIBRARY_PATH"
                Retval=$?
                if [ $Retval -eq 1 ]; then
                    #The LD_LIBRARY_PATH is not deleted. No need to warn the user.
                    #log "[WARN]: The LD_LIBRARY_PATH is not deleted, You may need to delete the variable manually." "$LINENO"
                    log "There were no LD_LIBRARY_PATH entries" "$LINENO"
                else
                    log "The LD_LIBRARY_PATH is deleted" "$LINENO"
                fi                
            fi            
        fi
    else
        # LD_LIBRARY_PATH does not exists, hence skipping the deletion.
        log "LD_LIBRARY_PATH does not exists." "$LINENO" 
    fi
    
    #Remove the Profile file i.e., /etc/profile.d/AMDAPPSDK.sh only if root mode installation was done.
    #Since for user mode the profile file is $HOME/.bashrc, which we do not want to delete
    if [ $UID -eq "0" ]; then
        if [ -e "$AMDAPPSDK_PROFILE" ]; then
            rm -vf "$AMDAPPSDK_PROFILE" >> "$LOG_FILE" 2>&1
        fi
        
        if [ -e "$AMDAPPSDK_PROFILE.bak" ]; then
            rm -vf "$AMDAPPSDK_PROFILE.bak" >> "$LOG_FILE" 2>&1
        fi
    fi
    
    log "Done updating Environment variables for $USER" "$LINENO" "console"
}

#Function Name: unregisterOpenCLICD
#Returns      : returns zero if the $VENDOR_DIR is deleted,
#               if not returns non-zero value.
#Comments     : Depending upon the user and catalyst driver installed,
#               this function deletes the $VENDOR_DIR.
unregisterOpenCLICD()
{
    Retval=1
    
    VENDORS_DIR="/etc/OpenCL/vendors"
    DeleteFolder=0
            
    if [ $UID -eq "0" ]; then
        #root user
        #If catalyst is present, then the VENDORS_DIR would have been created by the catalyst,
        #In such a scenario the SDK Un-Installer should not do anything.
        #else DeleteFolder=1
        if [ "$OS_ARCH" = "32" ]; then
            if [ -e "/usr/lib/libOpenCL.so" -o -e "/usr/lib/libOpenCL.so.1" ]; then
                #Found files
                log "32-bit AMD Catalyst OpenCL Runtime is available hence skipping deletion of vendors directory." "$LINENO"
            else
                DeleteFolder=1        
            fi
        elif [ "$OS_ARCH" = "64" ]; then
            if [ -e /usr/lib/libOpenCL.so -o -e /usr/lib/libOpenCL.so.1 -o -e /usr/lib64/libOpenCL.so -o -e /usr/lib64/libOpenCL.so.1 -o -e /usr/lib/i386-linux-gnu/libOpenCL.so -o -e /usr/lib/i386-linux-gnu/libOpenCL.so ]; then
                #Found files
                log "64-bit AMD Catalyst OpenCL Runtime is available hence skipping deletion of vendors directory." "$LINENO"
            else
                DeleteFolder=1
            fi
        else
            log "Found an incompatible OS Architecture: "$OS_ARCH". Please report the issue" "$LINENO"
        fi
    else
        #non root user
        log "Pre-pending the directory: $INSTALL_DIR" "$LINENO"
        VENDORS_DIR="${INSTALL_DIR}${VENDORS_DIR}"
        DeleteFolder=1
    fi
    if [ "$DeleteFolder" == "1" ]; then
        log "deleting Vendors directory containing ICD registration files: $VENDORS_DIR" "$LINENO" 
        if [ ! -d "$VENDORS_DIR" ]; then
            log "Unable to locate/find the vendor directory: $VENDORS_DIR" "$LINENO"
            Retval=0
        else
            rm -rvf "$VENDORS_DIR" >> "$LOG_FILE" 2>&1
            Retval=$?
        fi
    else
        Retval=0
    fi
    return $Retval
}

#Function Name: removePayload
#Returns      : returns zero if $INSTALL_DIR is deleted, else returns non-zero.
#Comments     : This function deletes the installation directory: $INSTALL_DIR
removePayload()
{
    Retval=1
    if [ -d "$INSTALL_DIR" ]; then
        rm -rvf "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
        Retval=$?
    else
        log "$INSTALL_DIR not found!!" "$LINENO" "console"
    fi
    return $Retval
}

#Function Name: removeAPPSDKIni
#Returns      : returns zero if the $AMDAPPSDK_DIR is deleted,else returns non-zero.
#Comments     : Deleting the $AMDAPPSDK_DIR, which is been created while installing.
removeAPPSDKIni()
{
    Retval=1
    #Deleting the $AMDAPPSDK_DIR, which is been created while installing.
    AMDAPPSDK_DIR=/etc/AMD
    if [ "$UID" -ne 0 ]; then
        #Non-root
        AMDAPPSDK_DIR=${HOME}${AMDAPPSDK_DIR}
    fi
    if [ -d "$AMDAPPSDK_DIR" ]; then
        INIFILE="${AMDAPPSDK_DIR}/APPSDK-3.0.ini"

        log "$AMDAPPSDK_DIR found. Looking for file: ${INIFILE}" "$LINENO"

        if [ -e "${INIFILE}" ]; then
            #Found file delete it.
            rm -vf "${INIFILE}" >> "$LOG_FILE" 2>&1
        else
            #File not found, log it.
            log "${INIFILE} not found!!" "$LINENO" "console"
        fi

        ##Check if the /etc directory is empty, if yes, then delete the AMD directory under the /etc
        if [ "$(ls -A  $AMDAPPSDK_DIR)" ]; then
            log "$AMDAPPSDK_DIR is not empty, hence skipping the deletion of $AMDAPPSDK_DIR" "$LINENO" "console"
        else    
            rm -rvf "$AMDAPPSDK_DIR" >> "$LOG_FILE" 2>&1
            Retval=$?
        fi
    else
        log "$AMDAPPSDK_DIR not found!!" "$LINENO" "console"
    fi
    return $Retval
}

#Function Name: main
#Returns      : returns zero if all the functions gets executed else if
#               any function gets failed it will return non-zero.
#Comments     : this function executes all the functions called in it and
#               creates the log files for all the functions irrespective
#               of the results.
main()
{
    Retval=1
    if [ ! -d "$SDK_TEMP_DIR" ]; then
        #create the tmp directory for storing logs with 777 permissions.
        #this directory hierarchy will be owned by the logged in user.
        mkdir --parents --mode 777 "$SDK_TEMP_DIR"
    fi
    log "Starting un-installation of AMD APP SDK-3.0" "$LINENO" "console"
    log "Retrieving Operating System details..." "$LINENO" "console"

    getOSDetails
    getLoggedInUserDetails
    getInstallationDirectory
    unhandleCatalyst
    uninstallCLINFO
    updateEnvironmentVariables    
    unregisterOpenCLICD
    removePayload
    removeAPPSDKIni
    Retval=$?
    log "Un-installation of AMD APP SDK-3.0 completed." "$LINENO" "console"
    log "You may need to re-login to your console for updates to environment variable to take affect." "$LINENO" "console"

    return $Retval
}

main
exit $?
