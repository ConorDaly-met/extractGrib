#!/bin/bash

if [ $# -lt 1 -o "$1" == "-h" ]; then
cat << USAGE

Usage:	$0 [-g <N>] </path/to/grib.file> [</path/to/grib.file> [</path/to/grib.file>]]
	$0 -h

	Extracts shortName,typeOfLevel,stepType,level from GRIB for translation to gl namelist
	
	-g <N>  Use grib edition <N> 
		1:   Extract "indicatorOfParameter,indicatorOfTypeOfLevel,timeRangeIndicator,level"
		2:   Extract "shortName,typeOfLevel,stepType,level"

	-h	Show this help

USAGE
exit
fi

GRIBEDITION=2
if [ "$1" == "-g" ]; then
  GRIBEDITION=$2
  shift 2
fi


# Extracts shortName,typeOfLevel,stepType,level from GRIB and translates to gl namelist
while [ $# -gt 0 ]; do
	if [ -z "$INFILE" ]; then
	  INFILE="$1"
	else
	  INFILE="$INFILE $1"
	fi
	shift
done

echo "Scanning ${INFILE}"
if [ $GRIBEDITION -eq 1 ]; then
  grib_ls -s preferLocalConcepts=1 -p indicatorOfParameter,indicatorOfTypeOfLevel,timeRangeIndicator,level $INFILE \
	| sed	\
		-e "s@${INFILE}@#${INFILE}@" \
		-e 's/  */:/g' -e 's/:$//' \
		-e 's/:timeRangeIndicator/:tri/' \
		-e 's/:instant/:0/' -e 's/:accum/:4/' \
		-e 's/:max/:2/' -e 's/:min/:2/' \
		-e 's/:sfc/:heightAboveGround/' -e 's/:pl/:isobaricInhPa/' \
		-e 's/:103:/:heightAboveSea:/' -e 's/:ml/:hybrid/' \
		-e 's/\(.*messages\)/#\1/' -e 's/^$/#/' \
	| sort
else
  grib_ls -s preferLocalConcepts=1 -p shortName,typeOfLevel,stepType,level $INFILE \
	| sed	\
		-e "s@${INFILE}@#${INFILE}@" \
                -e 's/  */:/g' -e 's/:$//' \
		-e 's/:stepType/:tri/' \
		-e 's/:instant/:0/' -e 's/:accum/:4/' \
		-e 's/:max/:2/' -e 's/:min/:2/' \
		-e 's/\(.*messages\)/#\1/' -e 's/^$/#/' \
	| sort
fi
