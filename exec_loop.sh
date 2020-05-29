#!/bin/sh -e

if ! [ -n ${TMP_DIR} ]; then
  echo "Setup enviroment first."
  exit 1
fi

EXE=./CASLab-GPU
LOG_DIR=${TMP_DIR}/exec_history

EnableLog=1
EnableLoop=1

if [ ${#} -gt 0 ]; then # Not looping if there's any arg
  EnableLoop=0
fi

if ! [ -x ${EXE} ]; then
  echo "Cannot find program \"${EXE}\""
  exit 1
fi
if ! [ -e ${LOG_DIR} ]; then
  mkdir -p ${LOG_DIR}
fi
if ! [ -d ${LOG_DIR} ]; then
  echo ${LOG_DIR} exist but not a directory
  exit 1
fi

while [ 1 = 1 ]; do
  DateTime=$(date '+%Y-%m-%d_%H-%M-%S')
  LogFileName=${LOG_DIR}/${DateTime}.log
  TimeLogName=${LOG_DIR}/${DateTime}.ExecTime.log

  if [ $EnableLog -eq 1 ]; then # Enable Log
    StartTime=$(date +%s)
    echo "Start Time:\t${StartTime}" > ${TimeLogName}
    stdbuf -o 0 ${EXE} | tee ${LOG_DIR}/${DateTime}.log
    EndTime=$(date +%s)
	TimeDiff=$((${EndTime} - ${StartTime}))
    echo "End Time:\t${EndTime}" >> ${TimeLogName}
	echo "Exec Time:\t$((${TimeDiff} / 3600)):$(( (${TimeDiff} / 60) % 60 )):$((${TimeDiff} % 60))" >> ${TimeLogName}
  else # Disable Log
    StartTime=$(date +%s)
    echo "Start Time:\t${StartTime}"
    ${EXE}
    EndTime=$(date +%s)
	TimeDiff=$((${EndTime} - ${StartTime}))
    echo "End Time:\t${EndTime}"
	echo "Exec Time:\t$((${TimeDiff} / 3600)):$(( (${TimeDiff} / 60) % 60 )):$((${TimeDiff} % 60))"
  fi
  [ ${EnableLoop} -ne 1 ] && break
  echo "\n-------------------------Reset Simualtor-------------------------\n"
done
