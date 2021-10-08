#!/bin/bash

# History
#
# 23-Nov-2020
# Conor Daly
# Version 02
# Added multiple file support.
# Added ensemble support.
#
# 13-Nov-2020
# Conor Daly
# Version 01
# Initial version
#
BINDIR=$(dirname $0)
OUTPATH=.
NAMELIST=extract_FA_$$.nam
KEEPNAM=false
DRYRUN=false
TOMEMORY=false
FROMMEMORY=false
USEINFILE=false
ENSEMBLE=""
EZONE=${EZONE-11}
GRIBLIST=griblist
INFILE=()
NUMFILES=0
echo "GL: $GL"
GL=${GL-$(which gl)}
echo "BN: $BINARY"
BINARY=${BINARY-${GL}}
echo "BN: $BINARY"
GL=${BINARY-${GL}}


echo "Command received:"
echo $(basename $0) $*
echo
echo "GL: $GL"
#echo "BN: $BINARY"


function usage() {
cat << USAGE

Usage:	$0 [-k] [-n] -d <DTG> -s <step> [-C <centre>] [-e <ensemble_member>:<ensemble_count>] [-g <griblist> [-g <griblist>]] [-t <type>] -f <infile> [-f <infile2 [-f <infile3>...]] [-o <path/to/output/>]

	Constructs a gl namelist and applies it to <infile> leaving output in <path/to/output/>

	-C <CENTRE>	Set the centre

	-d <DTG>	Standard DateTimeGroup

	-e	Ensemble member : count '10:15'
			Number of this member : number of ensemble members

	-f <infile>	The input FA file(s).  Multiple files will be loaded into memory before the writeout.

	-g <griblist>	The list of grib files to be produced along with their configurations
				Default: $GRIBLIST

	-k		Do not delete the namelist.  

	-n		Dry run.  Generate the namelist only.  (implies -k)

	-o <path/to/output/>	Output files will be placed here.  Directory will be made if necessary.

	-s <step>	What forecast step

	-t <type>	What type of input file (NWP, SFX,...)
				
USAGE
}

if [ $# -lt 1 ]; then
  usage
  exit
fi

while [ $# -gt 0 ]; do
	case "$1" in
		-h)
			usage
			exit
		;;
		-C)
			CENTRE=$2
			shift;shift
		;;
		-d)
			DTG=$2
			shift;shift
		;;
		-e)
			ENSEMBLE="$1 $2"
			shift;shift
		;;
		-f)
if [ $NUMFILES -gt 0 ]; then
  INFILE+=" "
fi
			INFILE+=$2
			NUMFILES=$(($NUMFILES + 1))
			shift;shift
echo "Got file: $INFILE"
		;;
		-g)
			if [ -z "$GRIBLISTLIST" ]; then
				GRIBLISTLIST="$2"
			else
				GRIBLISTLIST+=" $2"
			fi
			shift;shift
		;;
		-i)
			USEINFILE=true
			shift
		;;
		-k)
			KEEPNAM=true
			shift
		;;
		-m)
			FROMMEMORY=true
			shift
		;;
		-n)
			DRYRUN=true
			shift
		;;
		-o)
			OUTPATH=$2
			NAMELIST=${OUTPATH}/${NAMELIST}
			shift;shift
		;;
		-s)
			STEP=$2
			shift;shift
		;;
		-t)
			INTYPE=$2
			shift;shift
		;;
		-T)
			  TOMEMORY=true
			shift
		;;
		*)
			echo 
			echo "Error, unknown arg: $1"
			usage
			exit
		;;
	esac
done

function fileroot() {
	FILEROOT="fc${DTG}"
}

function makeHHH() {
    STEP=$(echo $STEP | sed -e 's/^0*\([0-9]\)/\1/')
	if [ $STEP -lt 10 ]; then
		HHH="00$(($STEP))"
	elif [ $STEP -lt 100 ]; then
		HHH="0$(($STEP))"
	else
		HHH=$(($STEP))
	fi
}

function makefilename() {
	UUU=$(basename $GRIBLIST | cut -f1 -d.)
	if [ "$UUU" == "standing" ]; then
		UUU=""
	else
		#UUU=${UUU^^}_
		UUU=$(echo ${UUU}_ | tr [:lower:] [:upper:])
	fi
	FILENAME="${FILEROOT}+${HHH}${UUU}${GRB}"
}

function merge_pppkey() {
	if [ $NUMFILES -gt 1 ]; then
		NF="-mx $NUMFILES"
	fi
	${BINDIR}/merge_pppkey.sh $NF $NAMELIST > ${NAMELIST}.tmp
	mv ${NAMELIST}.tmp ${NAMELIST}
}

function namelist() {
	${BINDIR}/FA_namelist.sh $@
}

function outDir() {
	# Create a per-Centre specific output directory
	echo $@ | sed -e 's@.*-C \([a-z]*\) [^/]*@\1@'
}


if [ ! -d $OUTPATH ]; then
  mkdir -p $OUTPATH
fi

#if [ ! -f ${INFILE} ]; then
#  echo
#  echo "Error, $INFILE does not exist"
#  echo
#  exit
#fi


fileroot
echo "Received step: $STEP"
makeHHH
echo "Working with $FILEROOT - $HHH"

#if [ $USEINFILE == true ]; then
#  INCFILE="-i $INFILE"
#fi

if [ -f $NAMELIST ]; then
  rm $NAMELIST
fi

echo "$NUMFILES received:"
if [ $NUMFILES -gt 1 -o "$FROMMEMORY" == "true" ]; then
    MEMORY=-M
    NUMFILES=$(($NUMFILES + 1))
fi

if [ $FROMMEMORY == true ]; then
  for N in ${INFILE[@]}; do
    MYEZONE="-E ${EZONE}"
    echo "file: $N"
    echo $N | grep PF >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      MYEZONE=""
    fi
    if [ -f $N ]; then
      echo namelist -s $HHH -mx $NUMFILES ${MYEZONE} -m $N $MEMORY
      namelist -s $HHH -mx $NUMFILES ${MYEZONE} -m $N $MEMORY >> ${NAMELIST}
    fi
  done
fi

for GRIBLIST in $GRIBLISTLIST; do
if [ ! -f $GRIBLIST ]; then
  echo "No griblist found"
else
  echo "Processing griblist: ${GRIBLIST}"
  # Sort griblist to place 'MEMORY' entries first
  TMPGRIBLIST=$(basename $GRIBLIST)$$
  egrep -i  '^memory[[:space:]]'       ${GRIBLIST} | sed -e 's/#.*//' >  ${TMPGRIBLIST}
  egrep -iv '^memory[[:space:]]|^#|^$' ${GRIBLIST} | sed -e 's/#.*//' >> ${TMPGRIBLIST}
  exec < $TMPGRIBLIST

  read GBLIST
  while [ "X$GBLIST" != "X" ]; do
    COMMENT=$(echo $GBLIST | cut -c1)
    if [ "$COMMENT" != '#' ]; then
      GRB=$(echo $GBLIST | cut -f1 -d' ')
      ARGS=$(echo $GBLIST | cut -f2- -d' ')
      makefilename
      if [ "$GRB" == "memory" -o "$GRB" == "MEMORY" ]; then
        echo namelist $ARGS $MEMORY
        namelist $ARGS $MEMORY >> ${NAMELIST}
      else
        outDir ${ARGS}
        OUTDIR=$(outDir ${ARGS})
	if [ ! -d $OUTPATH/${OUTDIR} ]; then
	  mkdir -p $OUTPATH/${OUTDIR}
	fi
        echo namelist -d $DTG -s $HHH $ENSEMBLE $ARGS $INCFILE $MEMORY -f ${OUTPATH}/${OUTDIR}/$FILENAME
        namelist -d $DTG -s $HHH $ENSEMBLE $ARGS $INCFILE $MEMORY -f ${OUTPATH}/${OUTDIR}/$FILENAME >> ${NAMELIST}
      fi
    fi
  
  read GBLIST
  done
  rm $TMPGRIBLIST
fi
done

merge_pppkey ${NAMELIST}

#CMD="$GL -p -n ${NAMELIST} $INFILE"
CMD="$GL -timing -igd -p -n ${NAMELIST}"
if [ $DRYRUN != true ]; then
  echo
  echo "Namelist used: $NAMELIST"
  echo "############ START of NAMELIST ####################"
  cat $NAMELIST
  echo "############ END   of NAMELIST ####################"
  echo
  time $MPPGL $CMD
  STATUS=$?
  echo "ran: $MPPGL $CMD"
  echo "Status: $STATUS"
  if [ $STATUS -ne 0 ]; then
    KEEPNAM=true
  fi
else
  echo
  echo "Dry run, displaying namelist ${NAMELIST}"
#  echo "To do the extract, run: "
#  echo
#  echo "	$CMD"
#  KEEPNAM=true
  echo
  echo "############ START of NAMELIST ####################"
  cat $NAMELIST
  echo "############ END   of NAMELIST ####################"
fi
echo
if [ $KEEPNAM == true ]; then
  echo "Namelist used: $NAMELIST"
else
  rm ${NAMELIST}
fi
