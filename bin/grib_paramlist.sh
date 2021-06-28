#!/bin/bash

if [ $# -lt 1 -o "$1" == "-h" ]; then
cat << USAGE

Usage:	$0 </path/to/grib.file>
	$0 -h

	Extracts shortName,typeOfLevel,stepType,level from GRIB and translates to gl namelist
	
	-h	Show this help

USAGE
exit
fi


# Extracts shortName,typeOfLevel,stepType,level from GRIB and translates to gl namelist
INFILE=$1

grib_ls -s preferLocalConcepts=1 -p shortName,typeOfLevel,stepType,level $INFILE \
	| sed	-e 's/  */:/g' -e 's/:$//' \
		-e 's/:stepType/:tri/' \
		-e 's/:instant/:0/' -e 's/:accum/:4/' \
		-e 's/:max/:2/' -e 's/:min/:2/' \
		-e 's/\(.*messages\)/#\1/' -e 's/^$/#/' \
		-e "s@^$INFILE@#$INFILE@" \
	| sort
