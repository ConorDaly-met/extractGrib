#!/bin/bash
#
# extrgrib_clean.sh
#
# Expects WORKPATH and DTG as environment vars.
# usage:
#	cleanDir /path/to/data "file_pattern"
#
#	Uses the find command to list and delete files 
#	Files are defined by "file_pattern" in the usual 'find' regex syntax
#
#
function cleanDir() {
  local DIR
  local NAME

  DIR=$1
  NAME=$2

  echo "find ${DIR} -name "${NAME}" -exec ls -l {} \;"
  find ${DIR} -name "${NAME}"  -exec ls -l      {} \;
  find ${DIR} -name "${NAME}"  -exec /bin/rm -f {} \;
}

if [ -z "${WORKPATH}" ]; then
    echo "Error: Need WORKPATH environment variable"
    exit 1
fi
if [ -z "${DTG}" ]; then
    echo "Error: Need DTG environment variable"
    exit 1
fi
echo "Running  $(basename $0) at :"$(date)
# delete old files [defined by DTG]
echo "Clean up files for DTG : "$DTG
# Forecast files
cleanDir ${WORKPATH}/         "fc${DTG}*"
# Log files
cleanDir ${WORKPATH}/log/     "extractGrib_*_${DTG}*.log"


