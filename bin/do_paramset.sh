#!/bin/bash

bindir=$(dirname $0)

function usage() {
cat << USAGE

Usage:	$0 [-b] -o <path/to/namelists/> [-n <namelist_name>] <path/to/parameter.list> 
	$0 -h

	Reads <path/to/parameter.list> and outputs appropriate namelist entries for
		each of 'direct' and 'postprocessed' data from ICMSHHARM and PFHARM forecast files.

	-b Write both Diagnostic and Postprocessed params to a single namelist

	-o Output path.
		Files will be written of the form '30-parameter_P-d.inc' where 'parameter' is the
		name of the <parameter.list> with the '.list' extension removed.

	-n Namelist name.
		This will replace the 'parameter' element of the output filename.

	-h Show this help

USAGE
}

if [ $# -lt 3 ]; then
  usage
  exit
fi

DDSET='-d -p'
DDSET='-p'
FASET='P I'
FASET='B'
while [ $# -gt 1 ]; do
	case "$1" in
		-h)
			usage
			exit
		;;
		-b)
			NAMEBOTH=true
			DDSET+=' -b'
			shift
		;;
		-o)
			NAMELISTPATH=$2
			shift;shift
		;;
		-n)
			NAMELIST=$2
			shift;shift
		;;
		*)
			echo
			echo "Error, unrecognised arg: $1"
			usage
			exit
		;;
	esac
done

PARAMLIST=$1
if [ ! -f ${PARAMLIST} ]; then
	echo
	echo "Error, $PARAMLIST not found"
	echo
	exit
fi

if [ "X${NAMELIST}" == "X" ]; then
	NAMELIST=$(basename $PARAMLIST .list)
fi
OPREFIX=${NAMELISTPATH}/30-${NAMELIST}

for DD in $DDSET; do
	for FA in $FASET; do
			O=${OPREFIX}_${FA}${DD}.inc
			${bindir}/read_paramlist ${DD} -${FA} ${PARAMLIST} > $O
			if [ $? -ne 0 ]; then
				rm $O
			fi
	done
done

