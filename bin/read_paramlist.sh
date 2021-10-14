#!/bin/bash
#
# Name:		read_paramlist.sh
# Author:	Conor Daly <conor.daly@met.ie>
# Date:		30-Nov-2020
#
# Purpose:	Read a parameter list and construct a 'gl' namelist 'readkey%...' stanza
#
# History:
#
#	07-Dec-2020
#	Conor Daly
#	Version 2
#	Read param_source.cfg to identify source file and method
#
#	30-Nov-2020
#	Conor Daly
#	Version 1
#	Initial Version

#DEBUG=debug
bindir=$(dirname $0)
PARAMSOURCE=${bindir}/../share/paramlists/param_source.cfg

function usage() {
cat << USAGE

Usage:	$0 (-d|p|b) (-I|P|B) <path/to/param.list>
	$0 -h

	Read param.list and write out a gl namelist stanza for the contained parameters.
	If param.list contains the header: indicatorOfParameter the gl namelist stanza will use readkey%pid
                                           Otherwise the gl namelist stanza will use readkey%shortname

	-d	Diagnostic    params (readkey%...)
	-p	Postprocessed params (pppkey%...)
	-b	Diag + Post_p params (pppkey%...)

	-I	ICMSHHARM... is the source FA file
	-P	PFHARM... is the source FA file
	-B	Both ICMSHHARM... and PFHARM... are the source FA files

	-h	Show this help

USAGE
}

function getShortName() {
  shortName=$(echo $LINE | cut -f1 -d:)
}

function getLevType() {
  levType=$(echo $LINE | cut -f2 -d:)
}

function getTri() {
  tri=$(echo $LINE | cut -f3 -d:)
}

function getLevels() {
  Levels=$(echo $LINE | cut -f4 -d: | tr ',' ' ')
}

if [ $# -lt 3 ]; then
  echo
  usage
  exit 2
fi

function setKey() {
  # set KEY to pppkey if necessary
  echo $PARAMSET | grep $1 > /dev/null
  STK=$?
  if [ $STK -eq 0 ]; then
    echo $PARAMSETDD | grep $1 > /dev/null
    STK=$?
    if [ $STK -ne 0 ]; then
      KEY=pppkey
    fi
  fi
}

function isParam() {
  snn=$(echo ${shortName} | tr -d [0-9])
  if [ "$snn" == "${shortName}" ]; then
    # Characters
    PT="${shortName}[0-9-]*:${levType}:${tri}"
    PTL="${shortName}[0-9-]*:${levType}:${tri},${l}"
  else
    # Digits
    PT="[a-z-]*${shortName}:${levType}:${tri}"
    PTL="[a-z-]*${shortName}:${levType}:${tri},${l}"
  fi
if [ "X$DEBUG" == "Xdebug" ]; then
  echo $DD
  echo -n "seeking $PTL -"
fi
  P="@$PTL"
  #if [ "$DD" == "both" ]; then
  #  setKey $PT
  #fi
# the direct - 'dd' parameterset contains some specific levels
# that we must exclude from a 'pp' set
  if [ "$DD" == "pp" ]; then
    PSET=$PARAMSETDD
  else
    PSET=$PARAMSET
  fi

  echo $PSET | grep $P > /dev/null
  ST=$?
#  echo $ST
  if [ $ST -eq 0 ]; then
    if [ "$DD" == "pp" ]; then
      return 1
    fi
  elif [ $ST -ne 0 ]; then
if [ "X$DEBUG" == "Xdebug" ]; then
  echo
  echo -n "seeking $PT -"
fi
    P="@$PT[^,]"
    echo $PARAMSET | grep $P > /dev/null
    ST=$?
  fi
  # If we are writing readkey%pid, we don't need a match
  # unless we are writing pppkey%pid
  if [ "${SNNAME}" == "indicatorOfParameter" ]; then
    if [ $ST -ne 0 -a "$DD" != "pp" ]; then
      ST=0
    fi
  fi
  return $ST
}

MODE=$(echo $1 | cut -c2)
while [ $# -gt 1 ]; do
case "$1" in
	"-d")
		KEY=readkey
		DD=dd
		shift
	;;
	"-p")
		KEY=pppkey
		DD=pp
		PPONLY="lwrite_pponly = .TRUE., cape_version=1,"
		PPONLY="cape_version=1,"
		shift
	;;
	"-b")
		KEY=readkey
		DD=both
		PPONLY="cape_version=1,"
		shift
	;;
	"-B")
		FA=BB
		shift
	;;
	"-I")
		FA=IC
		shift
	;;
	"-P")
		FA=PF
		shift
	;;
	*)
		echo
		echo "Unrecognised arg: -$MODE"
		echo
		usage
		exit
	;;
esac
done

PARAMLIST=$1

if [ ! -f $PARAMLIST ]; then 
  echo "$PARAMLIST not found"
  exit
fi

if [ "$DD" == "both" ]; then
  if [ "$FA" == "BB" ]; then
    PATTERN="PF:dd|PF:pp|IC:dd|IC:pp"
  else
    PATTERN="$FA:dd|$FA:pp"
  fi
else
  if [ "$FA" == "BB" ]; then
    PATTERN="PF:$DD|IC:$DD"
    PATTERND="PF:dd|IC:dd"
  else
    PATTERN="$FA:$DD"
    PATTERND="$FA:dd"
  fi
fi
# Read the relevant parameter set.
# We replace newlines with comma and add a leading comma.
# This facilitates the grep in the  isParam() function
PARAMSETDD=$(egrep "$PATTERND" $PARAMSOURCE | grep -v '#' | cut -f1-3 -d: | tr '\n' '@' | sed -e 's/^/@/')
PARAMSET=$(egrep "$PATTERN" $PARAMSOURCE | grep -v '#' | cut -f1-3 -d: | tr '\n' '@' | sed -e 's/^/@/')
if [ "X$DEBUG" == "Xdebug" ]; then
  echo "Paramset: $PARAMSET"
fi

# See are we dealing with GRIB1 "indicatorOfParameter" or GRIB2 "shortName"
SNNAME=$(grep ":tri:level" ${PARAMLIST} | cut -f1 -d:)

if [ "${SNNAME}" == "shortName" ]; then
  SNKey="%shortname="
elif [ "${SNNAME}" == "indicatorOfParameter" ]; then
  SNKey="%pid="
elif [ -z "${SNNAME}" ]; then
  echo "Error, failed to find column header"
  exit 1
fi
LTKey="%levtype="
TRKey="%tri="
LVKey="%level="

COUNT=0
while read -r LINEIN
do
  LINE=$(echo $LINEIN | cut -f1 -d#)
  if [ ! -z $LINE ]; then
    #echo $LINE
    getShortName
    # Do not write out the header.
    if [ "$shortName" == "shortName" ]; then
      continue
    elif [ "$shortName" == "indicatorOfParameter" ]; then
      continue
    fi
    getLevType
    getTri
    getLevels
    #echo $Levels
    for ls in $(echo $Levels)
    do
      ll=$(echo $ls | sed -e 's/\([0-9][0-9]*\)-/\1 /')
      if [ "$ls" == "$ll" ]; then
	ll="$ls $ls"
      fi
      for l in $(seq -w $ll)
      do

#seq -w $(echo $l | tr - ' ')
      isParam
      ST=$?
      if [ $ST -eq 0 ]; then
if [ "X$DEBUG" == "Xdebug" ]; then
	echo " yes"
      fi
        if [ "${SNNAME}" == "shortName" ]; then
          SNKey+="'${shortName}',"
        elif [ "$SNNAME" == "indicatorOfParameter" ]; then
	  # $shortName contains pid
          SNKey+="${shortName},"
        fi
        LTKey+="'${levType}',"
        TRKey+="${tri},"
        LVKey+="${l},"
	COUNT=$(($COUNT + 1))
      else if [ "X$DEBUG" == "Xdebug" ]; then
	echo " no"
      fi
      fi
    done
    done
  fi
  
done < $PARAMLIST

if [ $COUNT -gt 0 ]; then
  if [ "$KEY" == "pppkey" ]; then
    echo "$PPONLY"
  fi
  echo "${KEY}$SNKey"
  echo "${KEY}$LTKey"
  echo "${KEY}$LVKey"
  echo "${KEY}$TRKey"
  exit 0
fi
exit 1
