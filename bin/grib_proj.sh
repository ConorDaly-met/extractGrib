#!/bin/bash

if [ $# -lt 1 -o "$1" == "-h" ]; then
cat << USAGE

Usage:	$0 </path/to/grib.file>
	$0 -h

	Extracts projection information from GRIB and translates to gl namelist
	
	-h	Show this help

USAGE
exit
fi


# Extracts projection information from GRIB and translates to gl namelist

INFILE=$1

#grib_dump $INFILE \
#	| egrep "D?InMetres|Nx|Ny|FirstGrid|Latin.InDegrees|LoVInDegrees|gridType" \
#	| grep -v '#' | sort | uniq
#
echo "# $INFILE"

grib_dump $INFILE | head -n 180 \
	| egrep "D?InMetres|N[ijxy]|FirstGrid|Latin.InDegrees|LoVInDegrees|gridType|OfSouthernPoleInDegrees|DirectionIncrementInDegrees" \
	| grep -v '#' | sort | uniq \
	| sed \
	      -e 's/N[ix]/outgeo%nlon/'                                  -e 's/N[jy]/outgeo%nlat/' \
              -e "s/gridType = /outgeo%gridtype = '/"                    -e "s/gridtype = '\(.*\)$/gridtype = '\1'/" \
	      -e 's/DxInMetres = \([0-9]*\)/outgeo%dlon = \1./'          -e 's/DyInMetres = \([0-9]*\)/outgeo%dlat = \1./' \
	      -e 's/iDirectionIncrementInDegrees = \([0-9]*\)/outgeo%dlon = \1./'          -e 's/jDirectionIncrementInDegrees = \([0-9]*\)/outgeo%dlat = \1./' \
	      -e 's/Latin1InDegrees = \([0-9.]*\)/outgeo%projlat = \1./' -e 's/Latin2InDegrees = \([0-9.]*\)/outgeo%projlat2 = \1./' \
	      -e 's/latitudeOfSouthernPoleInDegrees = \([-0-9.]*\)/outgeo%polat = \1./' \
	      -e 's/longitudeOfSouthernPoleInDegrees = \([-0-9.]*\)/outgeo%polon = \1./' \
	      -e 's/latitudeOfFirstGridPointInDegrees = \([-0-9.]*\)/outgeo%south = \1./' \
	      -e 's/longitudeOfFirstGridPointInDegrees = \([-0-9.]*\)/outgeo%west = \1./' \
	      -e 's/LoVInDegrees = \([-0-9.]*\)/outgeo%projlon = \1./' \
	      -e 's/;//' -e 's/\(\.[0-9]*\)\./\1/' > grib_proj$$

wlon=$(grep 'outgeo%west' grib_proj$$ | cut -f2 -d=)
wloni=$(echo $wlon | cut -f1 -d.)
if [ $wloni -lt 180 ]; then
  cat grib_proj$$
else
  wlonnew=$(echo "-360.0 + $wlon" | bc -l)
  sed -e "s/\(outgeo.west.*\)${wlon}/\1 ${wlonnew}/" grib_proj$$
fi
rm grib_proj$$
