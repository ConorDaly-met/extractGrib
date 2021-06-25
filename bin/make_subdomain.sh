#!/bin/bash

VERBOSE=0
bindir=$(dirname $0)
MYCOMMENT="#"
#echo $bindir
REL=$(echo $bindir | cut -c1)
if [ "$REL" != "/" ]; then
  bindir=$(pwd)/$bindir
fi
#echo $bindir
rulesdir=${bindir}/../etc/rules
NAMELISTSUBDOMAINBASE=${rulesdir}/rp_src.inc
NAMELISTPOINTSBASE=${rulesdir}/point_src.inc

function usage() {
cat << USAGE

Usage:	$0 [-c <comment>] [(-r <resolution> | -rt <latres> -rn <lonres>)]
		(-sw <LATSOUTH>,<LONWEST> | -np <NLAT>,<NLON> | -lc <CLAT>,<CLON> | -ne <LATNORTH>,<LATEAST>) 

      	$0 -l <LAT>,<LON> [-c <comment>]

	Creates a gl namelist for the extraction of subdomain or point data
	
	-c <comment>	Adds a comment to the output

	############ Point extraction #####################
	-l <LAT>,<LON>	Specifies the point to be extracted.
			Output will be a csv file.

	############ Subdomain extraction #####################
	-sw <LAT>,<LON>		Coordinates of SouthWest corner
	-np <NLAT>,<NLON>	Number of grid points 
	-lc <LAT>,<LON>		Coordinates of Centre point
	-ne <LAT>,<LON>		Coordinates of NorthEast corner

	-r  <resolution>		Size of grid box in metres.  (Currently: $LATRES x $LONRES)
	-rt <Latitude  resolution>	N-S length of gridbox in metres (Currently: $LATRES)
	-rn <Longitude resolution>	W-E length of gridbox in metres (Currently: $LONRES)

	The subdomain is specified by two of:
		The SouthWest corner,
		The number of grid points,
		The centre point,
		The NorthEast corner.
	
		The default gridbox size is $DEFLATRES x $DEFLONRES

		Output will be a grib subdomain
	
USAGE
}

function verbecho() {
	if [ $VERBOSE -gt 0 ]; then
		echo $@
	fi
}

function makeLatlonSet() {
	local myLAT=$1
	local myLON=$2
	NLON=$(($NLON + 1))
	if [ $NLON -eq 1 ]; then
		GPLATSET="gplat = "
		GPLONSET="gplon = "
	fi
	GPLATS=$GPLATS$myLAT,
	GPLONS=$GPLONS$myLON,
}

function makeParamSet() {
	verbecho "makeParamSet($1)"
	local myPARAM=$1
	if [ -z $PARAMLIST ]; then
		echo "Could not find PARAMLIST"
		return
	fi
	PARAMSET=$(grep $myPARAM $PARAMLIST)
	if [ $? -ne 0 ]; then
		echo "Could not find $PARAM in $PARAMLIST"
		return
	fi
	PARAMCOUNT=$(($PARAMCOUNT + 1))
	if [ $PARAMCOUNT -eq 1 ]; then
		SHORTNAMESET="readkey%shortname="
		LEVTYPESET="readkey%levtype="
		LEVELSET="readkey%level="
		TRISET="readkey%tri="
	fi
	SHORTNAME=$(echo $PARAMSET | cut -f2 -d,)
	SHORTNAMES=$SHORTNAMES\'$SHORTNAME\',
	LEVTYPE=$(echo $PARAMSET | cut -f3 -d,)
	LEVTYPES=$LEVTYPES\'$LEVTYPE\',
	LEVEL=$(echo $PARAMSET | cut -f4 -d,)
	LEVELS=$LEVELS$LEVEL,
	TRI=$(echo $PARAMSET | cut -f5 -d,)
	TRIS=$TRIS$TRI,
	if [ $TRI -eq 2 ]; then
	  VALUETYPE="Max/Min "
	elif [ $TRI -eq 4 ]; then
	  VALUETYPE="Accumulated "
	fi
	VALUES="$VALUES,$VALUETYPE$myPARAM"
}

function calcInt() {
	# Calculate the supplied and truncate to integer
	echo "$@" | bc -l | cut -f1 -d.
}

function calcIntRound() {
	# Calculate the supplied and round to integer
	echo "$@ + 0.5" | bc -l | cut -f1 -d.
}

function calcFloat() {
	# Calculate the supplied
	#echo "$@" | bc -l | sed -e 's/0*$//'
	echo "scale=3; $@" | bc -l
}

function latToNlat() {
	verbecho "latToNlat $1 $2"
	local LAT1=$1
	local LAT2=$2
	DIFFLAT=$(calcFloat "$LAT2 - $LAT1")
	verbecho "DiffLat: $DIFFLAT"
	DIFFLINT=$(echo $DIFFLAT | cut -c1)
	verbecho "DiffLint: $DIFFLINT"
	if [ $DIFFLINT == '-' ]; then
		echo
		echo "Error, latitudes out of order: $1 $2" >&2 
		exit 1
	fi
	
	LATN=$(calcIntRound "$LATNUM * $DIFFLAT / 10")
	verbecho "latn:   $LATN"
}

function lonToNlon() {
	verbecho "lonToNlon($1 $2 $3)"
	local LON1=$1
	local LON2=$2
	local LAT1=$3
	ILAT1=$(echo $LAT1 | cut -f1 -d.)
	if [ $ILAT1 -eq 50 ]; then
		LONNUM=$LONNUM50
	elif [ $ILAT1 -eq 51 ]; then
		LONNUM=$LONNUM51
	elif [ $ILAT1 -eq 52 ]; then
		LONNUM=$LONNUM52
	elif [ $ILAT1 -eq 53 ]; then
		LONNUM=$LONNUM53
	elif [ $ILAT1 -eq 54 ]; then
		LONNUM=$LONNUM54
	elif [ $ILAT1 -eq 55 ]; then
		LONNUM=$LONNUM55
	else
		LONNUM=$LONNUM52
	fi
	if [ "$LONFACTOR" != "-1" ]; then
		verbecho "lonfactor $LONFACTOR"
		LONNUM=$(factorNum $LONNUM $LONFACTOR)
		verbecho "lonnum $LONNUM"
	fi
	DIFFLON=$(calcFloat "$LON2 - $LON1")
	verbecho "DiffLon: $DIFFLON"
	DIFFLINT=$(echo $DIFFLON | cut -c1)
	if [ $DIFFLINT == '-' ]; then
		echo
		echo "Error, longitudes out of order: $1 $2" >&2 
		exit 1
	fi
	
	LONN=$(calcIntRound "$LONNUM * $DIFFLON / 10")
	verbecho "lonn:   $LONN"
}

function nlatToSW() {
	verbecho "nlatToSW($1 $2)"
	local LATN=$1
	local LAT2=$2
	DIFFLAT=$(calcFloat "$LATN / $LATNUM * 10")
	verbecho "difflat: $DIFFLAT"
	LATSOUTH=$(calcFloat "$LAT2 - $DIFFLAT")
	verbecho "latSouth: $LATSOUTH"
}

function nlonToSW() {
	verbecho "nlonToSW($1 $2 $3)"
	local LONN=$1
	local LON2=$2
	local LAT2=$3
	ILAT2=$(echo $LAT2 | cut -f1 -d.)
	if [ $ILAT2 -eq 50 ]; then
		LONNUM=$LONNUM50
	elif [ $ILAT2 -eq 51 ]; then
		LONNUM=$LONNUM51
	elif [ $ILAT2 -eq 52 ]; then
		LONNUM=$LONNUM52
	elif [ $ILAT2 -eq 53 ]; then
		LONNUM=$LONNUM53
	elif [ $ILAT2 -eq 54 ]; then
		LONNUM=$LONNUM54
	elif [ $ILAT2 -eq 55 ]; then
		LONNUM=$LONNUM55
	else
		LONNUM=$LONNUM52
	fi
	if [ "$LONFACTOR" != "-1" ]; then
		verbecho "lonfactor $LONFACTOR"
		LONNUM=$(factorNum $LONNUM $LONFACTOR)
	fi
	verbecho "lonnum $LONNUM"
	DIFFLON=$(calcFloat "$LONN / $LONNUM * 10")
	verbecho "difflon: $DIFFLON"
	LONWEST=$(calcFloat "$LON2 - $DIFFLON")
	verbecho "lonWest: $LONWEST"
}

function calcNlatlon() {
	verbecho "calcNlatlon($1)"
	local MODE=$1
	verbecho "Mode: $MODE"
	if [ "$MODE" == "centre" ]; then
		LAT2=$LATCENTRE
		LON2=$LONCENTRE
	elif [ "$MODE" == "corner" ]; then
		LAT2=$LATNORTH
		LON2=$LONEAST
	fi
	if [ $SW -eq 1 ]; then
		LAT1=$LATSOUTH
		LON1=$LONWEST
	elif [ $LC -eq 1 ]; then
		LAT1=$LATCENTRE
		LON1=$LONCENTRE
		MODE=centre
	fi
	verbecho "Mode: $MODE"

	# Calculate NLAT
	latToNlat $LAT1 $LAT2
	NLAT=$LATN
	if [ "$MODE" == "centre" ]; then
		NLAT=$(($LATN * 2))
	fi
	NLAT=$(($NLAT + 1))

	# Calculate NLON
	if [ $LC -eq 1 ]; then
		LAT1=$LATCENTRE
	else
		LAT1=$(calcInt "$LATSOUTH + ($LATNORTH - $LATSOUTH)/2")
	fi
	lonToNlon $LON1 $LON2 $LAT1
	NLON=$LONN
	if [ "$MODE" == "centre" ]; then
		NLON=$(($LONN * 2))
	fi
	NLON=$(($NLON + 1))
}

function calcSW() {
	verbecho "calcSW($1)"
	local MODE=$1
	LATN=$NLAT
	LONN=$NLON
	LATN=$(($NLAT - 1))
	LONN=$(($NLON - 1))
	if [ "$MODE" == "centre" ]; then
		LAT2=$LATCENTRE
		LON2=$LONCENTRE
		LATN=$(($LATN / 2))
		LONN=$(($LONN / 2))
	elif [ "$MODE" == "corner" ]; then
		LAT2=$LATNORTH
		LON2=$LONEAST
	fi
	nlatToSW $LATN $LAT2
#set -x
	if [ "$MODE" == "corner" ]; then
		LAT2=$(calcInt "$LATSOUTH + ($LATNORTH - $LATSOUTH)/2")
	fi
	nlonToSW $LONN $LON2 $LAT2
#set +x
}

function calcCoords() {
#
#	1 means a coord needs to be calculated
#	2 means necessary coords exist
#
#	+-------+-------+-------+-------+-------+
#	|	|  SW	|  NP	|  LC	|  NE	|
#	+-------+-------+-------+-------+-------+
#	|  SW	|  	|   2	|   1	|   1	|
#	+-------+-------+-------+-------+-------+
#	|  NP	| 	|  	|   1	|   1	|
#	+-------+-------+-------+-------+-------+
#	|  LC	|  	|  	|  	|   1	|
#	+-------+-------+-------+-------+-------+
#	|  NE	|  	|  	|  	|  	|
#	+-------+-------+-------+-------+-------+

	if [ $SW -eq 1 ]; then
		if [ $NP -eq 1 ]; then
			verbecho "Got what we need"
			return
		elif [ $LC -eq 1 ]; then
			verbecho "Need nlat from centre"
			calcNlatlon centre
			return
		elif [ $NE -eq 1 ]; then
			verbecho "Need nlat from corner"
			calcNlatlon corner
			return
		fi
	elif [ $NP -eq 1 ]; then
		if [ $LC -eq 1 ]; then
			verbecho "Need SW from centre"
			calcSW centre
			return
		elif [ $NE -eq 1 ]; then
			verbecho "Need SW from corner"
			calcSW corner
			return
		fi
	elif [ $LC -eq 1 ]; then
		if [ $NE -eq 1 ]; then
			verbecho "Need nlat from corner"
			calcNlatlon corner
			verbecho "Need SW from corner"
			calcSW centre
			return
		fi
	fi
}

function getFactor() {
# produce a factor to 1 decimal place
	local NUM=$1
	local DIVISOR=$2
	FACTOR=-1
	if [ $NUM -ne $DIVISOR ]; then
		FACTOR=$(calcFloat "$NUM / $DIVISOR")
	fi
	echo $FACTOR
}

function factorNum() {
#set -x
	local NUM=$1
	local FACTOR=$2
	NUM=$(calcInt "$NUM / $FACTOR ")
	echo $NUM
#set +x
}

function calcLatLonNums() {
	LATFACTOR=$(getFactor ${LATRES} ${DEFLATRES})
	if [ "$LATFACTOR" != "-1" ]; then
		verbecho "latfactor $LATFACTOR"
		LATNUM=$(factorNum $LATNUM $LATFACTOR)
	fi
	verbecho "latnum $LATNUM"
	LONFACTOR=$(getFactor ${LONRES} ${DEFLONRES})
}

verbecho "args: $@"

if [ $# -lt 2 ]; then
  usage
  exit
fi

########################################
# RES in metres
DEFLONRES=2500;DEFLATRES=2500
LONRES=2500;LATRES=2500
# NUM in gridpoints per 10 degree
# Latitude spacing is constant
LATNUM=444
# Longitude spacing depends on Latitude
LONNUM50=288; LONNUM51=282; LONNUM52=275
LONNUM53=269; LONNUM54=262; LONNUM55=256
########################################

##########################
# Have we got coordinates?
PT=0;NLON=0;NLAT=1
LC=0
NP=0;SW=0;NE=0
##############

##########################
# Set up parameter entries
PARAMCOUNT=0
SHORTNAMESET=""
LEVTYPESET=""
LEVELSET=""
TRISET=""
#########

verbecho "args: $@"
while [ $# -gt 0 ]; do
	case "$1" in
		-c)
			MYCOMMENT+=" $2"
			shift;shift
		;;
		-v)
			VERBOSE=1
			shift
		;;
		-d)
			YYYYMM=$2
			YYYY=$(echo $YYYYMM | cut -c1-4)
			MM=$(echo $YYYYMM | cut -c5-6)
			shift;shift
		;;
		-l)
#set -x
			LATLON=$2
			LAT=$(echo $LATLON | cut -f1 -d,)
			LON=$(echo $LATLON | cut -f2 -d,)
			makeLatlonSet $LAT $LON
#set +x
			PT=1
			shift;shift
		;;
		-np)
			NLATNLON=$2
			NLAT=$(echo $NLATNLON | cut -f1 -d,)
			NLON=$(echo $NLATNLON | cut -f2 -d,)
			NP=1
			shift;shift
		;;
		-lc)
			CLATCLON=$2
			LATCENTRE=$(echo $CLATCLON | cut -f1 -d,)
			LONCENTRE=$(echo $CLATCLON | cut -f2 -d,)
			LC=1
			shift;shift
		;;
		-sw)
			SLATWLON=$2
			LATSOUTH=$(echo $SLATWLON | cut -f1 -d,)
			LONWEST=$(echo $SLATWLON | cut -f2 -d,)
			SW=1
			shift;shift
		;;
		-ne)
			NLATELON=$2
			LATNORTH=$(echo $NLATELON | cut -f1 -d,)
			LONEAST=$(echo $NLATELON | cut -f2 -d,)
			NE=1
			shift;shift
		;;
		-p)
			PARAM=$2
			if [ "$PARAM" == "help" ]; then
				cat $PARAMTEXT
				exit
			fi
			makeParamSet $PARAM
			shift;shift
		;;
		-r)
			LATRES=$2
			LONRES=$2
			shift;shift
		;;
		-rn)
			LONRES=$2
			shift;shift
		;;
		-rt)
			LATRES=$2
			shift;shift
		;;
		-h)
			usage
			exit
		;;
		*)
			echo
			echo "Error, unrecognised arg: $1"
			usage
			exit
		;;
	esac
done

SD=$(($LC + $NP + $SW + $NE))

calcLatLonNums

if [ $PT -eq 1 ]; then
	if [ $SD -ne 0 ]; then
		echo
		echo "Error, conflicting coordinate set supplied"
		echo "Please supply either a point (-l) or a pair of domain coordinates"
		usage
		exit
	fi
	NAMELISTBASE=$NAMELISTPOINTSBASE
elif [ $SD -ne 2 ]; then
	echo
	echo "Error, not enough domain info supplied"
	usage
	exit
else
	NAMELISTBASE=$NAMELISTSUBDOMAINBASE
	calcCoords
fi

if [ $PARAMCOUNT -gt 0 ]; then
	export VALUES
fi
if [ $SD -eq 2 ]; then
	export NLAT
	export NLON
fi

sed -e "s/# <COMMENT>/$MYCOMMENT/" \
    -e "s/<NLON>/$NLON/" -e "s/<NLAT>/$NLAT/" \
    -e "s/<LONWEST>/$LONWEST/" -e "s/<LATSOUTH>/$LATSOUTH/" \
    -e "s/<LONRES>/$LONRES/" -e "s/<LATRES>/$LATRES/" \
    -e "s/<SHORTNAMESET>/$SHORTNAMESET/" -e "s/<SHORTNAME>/$SHORTNAMES/" \
    -e "s/<LEVTYPESET>/$LEVTYPESET/" -e "s/<LEVTYPE>/$LEVTYPES/" \
    -e "s/<LEVELSET>/$LEVELSET/" -e "s/<LEVEL>/$LEVELS/" \
    -e "s/<TRISET>/$TRISET/" -e "s/<TRI>/$TRIS/" \
    -e "s/<GPLATSET>/$GPLATSET/" -e "s/<GPLAT>/$GPLATS/" \
    -e "s/<GPLONSET>/$GPLONSET/" -e "s/<GPLON>/$GPLONS/" \
    $NAMELISTBASE 
