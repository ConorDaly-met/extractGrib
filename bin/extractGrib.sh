#!/bin/bash
#
# Name:		extractGrib.sh
# Author:	Conor Daly <conor.daly@met.ie>
# Date:		17-jun-2021
#
# Purpose:	Run the extraction of forecast data from Harmonie NWP output
#
# Description:	Constructs dynamic namelists for gl for extraction of NWP 
#		from FA to GRIB.  Processes any griblist/<centre>/standing.list 
#		found in the user area.  Processes any griblist/<centre>/user.list
#		found in the user area if called with a 'user' switch.  Processes
#		griblist/<centre>/user.list if called with 'centre' switch.
#
[ -f header.sh ] && . header.sh

# Need to set ulimit unlimited
ulimit -s unlimited

# My bindir
mybindir=$(dirname $0)
extractor="${mybindir}/extract_FA"

# Binary
BINARY=$BINDIR/gl
# Debug level
PRINTLEV=0

# Input forecast
FCSTPATH=${FCSTPATH-.}
GETIOSERV=${GETIOSERV-no}
MBRPREFIX=${MBRPREFIX-}
MBRPATH=${MBRPATH-.}
EXPT=${EXPT-HARM}
DOMAIN=${DOMAIN-IRELAND25_090}
TYPLIST=${TYPLIST-"fp his"}
TYPCOUNT=0
EZONE=${EZONE-11}

# Forecast date/step/member etc
DTG=${DTG-2021061006}
STEP=${STEP-3}
ENSMBR=${ENSMBR--1}
ENSCTL=${ENSCTL--1}
ENSTYP=${ENSTYP-0}
NUMMBR=${NUMMBR-16}

# User area
USERAREA=${USERAREA-~/hm_home/extractGrib/share/griblists}

function usage() {
if [ "X$1" == "Xmanual" ]; then
	less ${mybindir}/../README.md
else
cat << USAGE

Usage:	$0 [-a <USERAREA>] [-f <FCST/PATH>] [-m] [-t <type> [-t <type>]] [-h] [-i] [-k] [-n]
	$0 -h [manual]

	Extracts requested dataset(s) from Harmonie FA outputs using user-supplied request lists.

	-a <USERAREA>       Sets the source area for user lists           (currently: ${USERAREA})
	-d <DTG>            Sets the DateTimeGroup for the forecast       (currently: ${DTG})
	-dm <DOMAIN>        Sets the Domain name for the forecast         (currently: ${DOMAIN})
	-em <ENSMBR>        Sets the Ensemble Member for the forecast     (currently: ${ENSMBR})
	-en <NUMMBR>        Sets the Number of forecasts in the ensemble  (currently: ${NUMMBR})
	-ex <EXPT>          Sets the Experiment name for the forecast     (currently: ${EXPT})
	-ez <EZONE>         Sets the boundary zone to remove from his/sfx (currently: ${EZONE})
	-f <FCST/PATH>      Sets the input path for the forecast          (currently: ${FCSTPATH})
	-m                  Sets a member path of the form mbrXXX to be appended to <FCST/PATH>
	-s <STEP>      		Sets the Step for the forecast                (currently: ${STEP})
	-t <type>           Sets the input file type(s) for the forecast      (currently: ${TYPLIST})
	                    Available types are    fp  - fullpos
                                               his - history
                                               sfx - SURFEX

	-i                  Fetch the forecast files directly from the I/O servers
	-k                  Do not delete the namelist
	-n                  Dry-run.  Does not execute the gl run, just makes and displays the namelist

	-h                  Show this help
	-h manual           Displays the README.md file

	Environment Variables:

	extractGrib expects the following environment variables to be set:
                It will accept them from the commandline also.

        Variable    Current Value   Comment
        --------    -------------   -------
        FCSTPATH    ${FCSTPATH}
                                    Path to the input forecast
        EXPT        ${EXPT}	
                                    The experiment name
        DOMAIN      ${DOMAIN}
                                    The forecast domain name
        EZONE       ${EZONE}
                                    The boundary zone to remove from his/sfx files

        DTG         ${DTG}	
                                    The date/time group for the forecast
        STEP        ${STEP}	
                                    The forecast step
        ENSMBR      ${ENSMBR}
                                    The ensemble member
        NUMMBR      ${NUMMBR}
                                    The number of forecasts in the ensemble

USAGE
fi
}

function isOdd() {
	# returns 1 if odd, 0 otherwise
    local TESTVAL=$(echo $1 | sed -e 's/^0*\([1-9]\)/\1/')
	TMP=$((${TESTVAL} / 2))
	TMP2=$(($TMP * 2))
	REM=$((${TESTVAL} - $TMP2))
	return $REM
}

function makeTEF() {
	# Returns 0 for input <= 0, 2 for even, 3 for odd
	if [ $1 -le 0 ]; then
		return $1
	else
		isOdd $1
		TEF=$(($? + 2))
		return $TEF
	fi
}

function getIOFILES() {
	# Get a list of files from the I/O nodes
	local TYP=$1
	IOPATH="${FCSTPATH}/${MBRPATH}/forecast"
	case "$TYP" in
		fp)
			FPATTERN="PF${EXPT}${DOMAIN}+0${STEP}*"
			EPATTERN=""
		;;
		his)
			FPATTERN="ICMSH${EXPT}+0${STEP}*"
			EPATTERN="ICMSH${EXPT}+0${STEP}*.sfx*"
		;;
		sfx)
			FPATTERN="ICMSH${EXPT}+0${STEP}*.sfx*"
			EPATTERN=""
		;;
	esac
#set -x
	if [ -z ${EPATTERN} ]; then
		FNAMELIST=$(find ${IOPATH} -name ${FPATTERN} | grep io_serv | sort)
	else
		FNAMELIST=$(find ${IOPATH} -name ${FPATTERN} -not -name ${EPATTERN} | grep io_serv | sort)
	fi
#set +x
	echo "find ${IOPATH} -name ${FPATTERN}"
	echo "Fnamelist: $FNAMELIST"
}

function getINFILE() {
	# Get a list of complete FA files
	local TYP=$1
	case "$TYP" in
		fp)
			FNAME="${FCSTPATH}/${MBRPATH}/PF${EXPT}${DOMAIN}+0${STEP}"
		;;
		his)
			FNAME="${FCSTPATH}/${MBRPATH}/ICMSH${EXPT}+0${STEP}"
		;;
		sfx)
			FNAME="${FCSTPATH}/${MBRPATH}/ICMSH${EXPT}+0${STEP}.sfx"
		;;
	esac
	echo "Fname: $FNAME"
}

function waitFor() {
	# Wait for a file to appear and to stop changing size
	# Wait for up to WTIMEOUT sec for the file to appear
	# Check size change every 3 sec up to remaining WTIMEOUT x 3
	# until file stops changing.
	local WTIMEOUT=180
	local WFILE=$1
	local WCOUNT=0
	local WSIZE=1
	local LSIZE=0

	echo -n "Awaiting mbr-$ENSMBR $WFILE "
	while [ ! -f $WFILE ]; do
		sleep 1
		echo -n "."
		WCOUNT=$(($WCOUNT + 1))
		if [ $WCOUNT -gt $WTIMEOUT ]; then
			echo " TIMEOUT for ${WFILE}"
			return 1
		fi
	done
	echo
	echo -n "Checking mbr-$ENSMBR file size"
	while [ $LSIZE -ne $WSIZE ]; do
		LSIZE=$WSIZE
		WSIZE=$(stat -t $WFILE | cut -f2 -d' ')
		if [ $LSIZE -eq $WSIZE ]; then
			echo
			echo "$WSIZE"
			return 0
		fi
		sleep 3
		echo -n "."
		WCOUNT=$(($WCOUNT + 1))
		if [ $WCOUNT -gt $WTIMEOUT ]; then
			echo " TIMEOUT for ${WFILE}"
			return 1
		fi
	done
	echo
}

function outDir() {
	# Create a per-Centre specific output directory
	grep -v '#' $1 | grep -- '-C ' | sed -e 's@.*-C \([a-z][a-z][a-z][a-z]\) [^/]*@\1@' | uniq
}

#echo "Binary: $BINARY"

# define basic extract command
myextractcmd="${extractor}"

# Commandline args handling
while [ $# -gt 0 ]; do
	case "$1" in
		-h)
			if [ $# -gt 1 -a "X$2" == "Xmanual" ]; then
				usage manual
			else
				usage
			fi
			exit
		;;
#		-h)
#			myextractcmd+=" $1"
#			shift
#		;;
		-a)
			USERAREA=$2
			shift;shift
		;;
		-d)
			DTG=$2
			shift;shift
		;;
		-dm)
			DOMAIN=$2
			shift;shift
		;;
		-em)
			ENSMBR=$2
			shift;shift
		;;
		-en)
			NUMMBR=$2
			shift;shift
		;;
		-ex)
			EXPT=$2
			shift;shift
		;;
		-ez)
			export EZONE=$2
			shift;shift
		;;
		-f)
			FCSTPATH=$2
			shift;shift
		;;
		-i)
			GETIOSERV="yes"
			shift
		;;
		-k)
			myextractcmd+=" $1"
			shift
		;;
		-m)
			MBRPREFIX="mbr"
			shift
		;;
		-n)
			myextractcmd+=" $1"
			shift
		;;
		-s)
			STEP=$2
			shift;shift
		;;
		-t)
			if [ $TYPCOUNT -eq 0 ]; then
				TYPLIST="$2"
			else
				TYPLIST+=" $2"
			fi
			TYPCOUNT=$(($TYPCOUNT + 1))
			shift;shift
		;;
		*)
			echo "unrecognised arg: $1"
			shift
			exit
		;;
	esac
done

# User area
export USERAREA

# Date time step handling
YMD=$(echo $DTG | cut -c1-8)
HH=$(echo $DTG | cut -c9-10)
if [ "$GETIOSERV" == "yes" ]; then
	FCSTPATH+="/${YMD}_${HH}"
fi
STEP=$(printf "%03d" $(echo $STEP | sed -e 's/^00*//'))

# Ensemble member handling
makeTEF $ENSMBR
ENSTYP=$?
echo "MBR: $MBRPREFIX $MBRPATH"
if [ ! -z "${MBRPREFIX}" -a "${MBRPATH}" == "." ]; then
	# Pad ENSMBR with leading zeros to 3 digits
	MBRPATH="${MBRPREFIX}$(echo 00${ENSMBR} | sed -e 's/.*\([0-9][0-9][0-9]\)$/\1/')"
fi

myextractcmd+=" -m"
myextractcmd+=" -d ${DTG}"
myextractcmd+=" -s ${STEP}"
myextractcmd+=" -e ${ENSMBR}:${NUMMBR}:${ENSTYP}"


# List of input files
FILECOUNT=0
echo $TYPLIST
TYPLIST=$(echo $TYPLIST | tr , ' ')
echo $TYPLIST
for TYP in ${TYPLIST} ; do
	if [ "$GETIOSERV" == "yes" ]; then
		echo getIOFILES $TYP
		getIOFILES $TYP
	else
		echo getINFILE $TYP
		getINFILE $TYP
		FNAMELIST=${FNAME}
	fi
	echo $FNAMELIST
	for FNAME in $FNAMELIST; do
		waitFor $FNAME
		if [ $? -eq 0 -a -f $FNAME ]; then
			myextractcmd+=" -f ${FNAME}"
			FILECOUNT=$(($FILECOUNT + 1))
		else
			echo "No file found: ${FNAME}"
		fi
	done
done
if [ $FILECOUNT -eq 0 ]; then
	echo
	echo "Error, no input file(s) found"
	echo
	exit 1
fi

extractcmd="${myextractcmd}"
for SLIST in $(find ${USERAREA} -name standing.list -o -name user.list); do
  #SLIST=${UD}/standing.list
  if [ -f ${SLIST} ]; then
    listtype=$(basename ${SLIST} .list)
    extractcmd+=" -g ${SLIST}"
    outDir ${SLIST}
    OUTDIR=$(outDir ${SLIST})
  fi
done
if [ ${ENSMBR} == "000" ]; then
  for SLIST in $(find ${USERAREA} -name control.list); do
    if [ -f ${SLIST} ]; then
      listtype=$(basename ${SLIST} .list)
      extractcmd+=" -g ${SLIST}"
      outDir ${SLIST}
      OUTDIR=$(outDir ${SLIST})
    fi
  done
fi
    extractcmd+=" -o ${MBRPATH}"
  
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "$(date) : Starting ${extractcmd}"
    if [ ! -d ${MBRPATH}/${OUTDIR} ]; then
	    mkdir -p ${MBRPATH}/${OUTDIR}
    fi
    echo "Log: ${MBRPATH}/${OUTDIR}/extractGrib_${listtype}_${STEP}.log" 
    echo
    #${extractcmd} 2>&1 | tee ${MBRPATH}/${OUTDIR}/extractGrib_${listtype}_${STEP}.log 
    #echo "${extractcmd} > ${MBRPATH}/${OUTDIR}/extractGrib_${listtype}_${STEP}.log"
    ${extractcmd} > ${MBRPATH}/${OUTDIR}/extractGrib_${listtype}_${STEP}.log 2>&1
    echo
    echo "$(date) : Finished ${extractcmd}"
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++"

