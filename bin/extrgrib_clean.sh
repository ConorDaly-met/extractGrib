#!/bin/bash
#
# extrgrib_clean.sh
#
# Expects WORKPATH and DTG as environment vars.
# Optionally expects KEEP_DAYS as environment var.
# usage:
#	cleanDir /path/to/data "file_pattern"
#
#	Uses the find command to list and delete files 
#	Files are defined by "file_pattern" in the usual 'find' regex syntax
#   If KEEP_DAYS is set, "-mtime $KEEP_DAYS" is also used
#
#
function cleanDir() {
  local DIR
  local NAME

  DIR=$1
  NAME=$2

  MTIME=""
  # If KEEP_DAYS is supplied, use that also
  # This will find files for a single day
  if [ $# -eq 3 ]; then
      MTIME="-mtime $3"
  fi

  echo "find ${DIR} -name "${NAME}" ${MTIME} -exec ls -l {} \;"
  find ${DIR} -name "${NAME}" ${MTIME} -exec ls -l      {} \;
  find ${DIR} -name "${NAME}" ${MTIME} -exec /bin/rm -f {} \;
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

# Left over gl namelists (only from a failed run)
if [ ! -z "${KEEP_DAYS}" ]; then
    cleanDir ${WORKPATH}/     "extract_FA*.nam" ${KEEP_DAYS}
fi


