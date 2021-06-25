#!/bin/bash
module purge
module load gl cdo
export FIMEX=/home/cdaly/cdtemp/gridpp/bin/fimex
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/cdaly/cdtemp/gridpp/lib/:/home/cdaly/cdtemp/gridpp/lib64
NCDEFS=etc/AromeMetCoOpGribReaderConfig_Trg_tmp_pr_cl_th_IE.xml

bindir=$(dirname $0)
INCDIRBASE=${INCDIRBASE-${bindir}/../etc/namelist_inc}
if [ ! -z "${USERAREA}" ]; then
	INCDIR=$(echo ${USERAREA} | sed -e 's@/griblists/.*@/namelist_inc@')
fi
INCDIR=${INCDIR-etc/namelist_inc}
CENTRE=""
NAMDIR=etc

function usage() {
cat << USAGE

Usage:	$0 -m
	$0 [-M -f <outfile.name>] [-i <infile.name>] [-g <grib edition>] [-k <packing type>] [(-c <cutout>) | (-r <reproj>)] [-p <parameter.list>] -d <DTG> -s <step> [-e <ensemble_member>:<ensemble_count>[:<ensemble_type>]]
	$0 -h

	Writes out a namelist for use with gl.  Concatenate multiple outputs to a single list for better read efficiency using the '-m / -M' switches.

	-C	Set the 'centre' (currently: ${CENTRE})
	-m	Output the read into memory namelist.
	-M	Include a read from memory entry in the namelist. Requires a '-f' argument.
	-mx	Set 'maxfl=' in namelist
	-e	Ensemble member : count '10:15[:2]'
			Number of this member : number of ensemble members : type of ensemble forecast (optional, default 0)
	-f	Include an OUTFILE=<outfile.name> entry in the namelist
	-g	Include an OUTPUT_FORMAT='grib1|2' entry in the namelist
	-k	Include a  packingtype='grid_...' entry in the namelist
	-i	Include an  INFILE=<infile.name> entry in the namelist
	-c	Include a rectangular subdomain entry in the namelist
			Use '-c help' for help
	-r	Include a reprojected subdomain entry in the namelist (useful for thinning)
			Use '-r help' for help
	-p	Include a parameter list entry in the namelist
			Use '-p help' for help
	-x	Include a parameter exclusion list entry in the namelist
			Use '-x help' for help

	-d	Date Time Group 'yyyymmddhhmm'

	-s	Forecast Step 'hhh'

USAGE

}

MEM_IN=${INCDIRBASE}/00-tomemory.inc
MEMOUT=${INCDIRBASE}/00-frommemory.inc
HEADER=${INCDIRBASE}/00-header.inc
DTGNAME=${INCDIRBASE}/05-dtg.inc
FSTNAME=${INCDIRBASE}/05-fstart.inc
ENSEMBNAME=${INCDIRBASE}/07-ensemble.inc
FOOTER=${INCDIRBASE}/99-footer.inc

TOGRIBBASE=${INCDIRBASE}/01-grib
TOPACKBASE=${INCDIRBASE}/02-grid_
FSTART=-1
FSTARTINTERVAL=1
FREQ_RESET_TEMP=${FREQ_RESET_TEMP-3}
CUTOUTBASE=${INCDIR}/${CENTRE}/10-
REPROJBASE=${INCDIR}/${CENTRE}/20-
PARAMSBASE=${INCDIR}/${CENTRE}/30-
PARAMSEXCLBASE=${INCDIR}/${CENTRE}/40-

EXCLPATTERN='^#|^[[:space:]]$'

DTG=0
MAXFL=0
EZONE=0
INMEMORY=false
APPEND=false
OUTMEMORY=false
TOGRIBNAME="NULL"
TOPACKNAME="NULL"
CUTOUTNAME="NULL"
REPROJNAME="NULL"
PARAMSNAME="NULL"
PARAMSEXCLNAME="NULL"
OUTFILENAME="NULL"
INFILENAME="NULL"
INFILENAMEMEM="NULL"

function tomemory() {
  if [ "$INMEMORY" == "true" ]; then
    #grep -v '^#' ${MEM_IN}
    egrep -v ${EXCLPATTERN} ${MEM_IN}
    if [ "X$APPEND" == "XNEW" ]; then
      echo " OUTPUT_TYPE = 'NEW',"
    fi
    if [ "X$APPEND" == "XAPPEND" ]; then
      echo " OUTPUT_TYPE = 'APPEND',"
    fi
    if [ ${MAXFL} -gt 0 ]; then
      echo " maxfl=${MAXFL},"
    fi
    if [ ${EZONE} -ne 0 ]; then
      echo " istop=-${EZONE},"
      echo " jstop=-${EZONE},"
    fi
  fi
}

function frommemory() {
  if [ "$OUTMEMORY" == "true" ]; then
    #grep -v '^#' ${MEMOUT}
    egrep -v ${EXCLPATTERN} ${MEMOUT}
  fi
}

function  infilemem() {
  if [ "$INFILENAMEMEM" != "NULL" ]; then
    tomemory
    if [ "X$APPEND" == "X-M" ]; then
      echo " OUTPUT_TYPE = 'APPEND',"
    fi
    echo " INPUT_FORMAT='FA',"
    echo -n " INFILE='"
    echo -n ${INFILENAMEMEM}
    echo "'"
    fstart
    echo "/"
  fi
}

function  infile() {
  if [ "$INFILENAME" != "NULL" ]; then
    echo -n "INFILE='"
    echo -n ${INFILENAME}
    echo "'"
  fi
}

function header() {
  #grep -v '^#' ${HEADER}
  egrep -v ${EXCLPATTERN} ${HEADER}
}

function dtgout() {
# Translate various date/time placeholders to real values
  if [ $DTG -gt 0 ]; then
    YMD=$(echo $DTG | cut -c1-8)
    HH=$(echo $DTG | cut -c9-10)
    HHMM="${HH}00"
    egrep -v ${EXCLPATTERN} ${DTGNAME} | sed -e "s/<CENTER>/${CENTER}/" -e "s/<PROCESS>/${PROCESS}/" -e "s/<YMD>/$YMD/" -e "s/<HHMM>/$HHMM/" -e "s/<HHH>/$HHH/"
  fi
}

function fstart() {
# Translate various fstart placeholders to real values
  if [ ! -z "${FSTARTXN}" ]; then
    egrep -v ${EXCLPATTERN} ${FSTNAME} | sed -e "s/<FSTARTXN>/$FSTARTXN/g" -e "s/<FSTARTG>/$FSTARTG/g"
  fi
}

function ensemble() {
  if [ "X$ENSEMBLE" != "X" ]; then
    MBR=$(echo $ENSEMBLE | cut -f1 -d:)
    MBRS=$(echo $ENSEMBLE | cut -f2 -d:)
    TMBR=$(echo $ENSEMBLE | cut -f3 -d:)
    if [ -z "$TMBR" ]; then
	TMBR=0
    fi
    egrep -v ${EXCLPATTERN} ${ENSEMBNAME} | sed -e "s/<MBR>/$MBR/" -e "s/<MBRS>/$MBRS/" -e "s/<TMBR>/$TMBR/"
  fi
}

function togrib() {
  if [ "$TOGRIBNAME" != "NULL" ]; then
    #grep -v '^#' ${TOGRIB}
    egrep -v ${EXCLPATTERN} ${TOGRIB}
  fi
}

function topack() {
  if [ "$TOPACKNAME" != "NULL" ]; then
    #grep -v '^#' ${TOPACK}
    egrep -v ${EXCLPATTERN} ${TOPACK}
  fi
}

function footer() {
  #grep -v '^#' ${FOOTER}
  egrep -v ${EXCLPATTERN} ${FOOTER}
}

function cutout() {
  if [ "$CUTOUTNAME" != "NULL" ]; then
    #grep -v '^#' ${CUTOUT}
    egrep -v ${EXCLPATTERN} ${CUTOUT}
  fi
}

function cutouthelp() {
  echo
  if [ "$CUTOUTNAME" == "help" ]; then
    echo "Available cutouts"
    echo
    ls ${CUTOUTBASE}* | cut -f2- -d- | sed -e 's/.inc//'
    echo
    echo "use '-c cutoutname help' for details..."
  else
    echo "Help on $CUTOUT"
    echo
    cat $CUTOUT
  fi
  echo
}

function reproj() {
  if [ "$REPROJNAME" != "NULL" ]; then
    #grep -v '^#' ${REPROJ}
    egrep -v ${EXCLPATTERN} ${REPROJ}
  fi
}

function reprojhelp() {
  echo
  if [ "$REPROJNAME" == "help" ]; then
    echo "Available reprojections"
    echo
    ls ${REPROJBASE}* | cut -f2- -d- | sed -e 's/.inc//'
    echo
    echo "use '-r reprojname help' for details..."
  else
    echo "Help on $REPROJ"
    echo
    cat $REPROJ
  fi
  echo
}

function params() {
  if [ "$PARAMSNAME" != "NULL" ]; then
    if [ "X$APPEND" == "XNEW" ]; then
      egrep -v ${EXCLPATTERN} ${PARAMS} | grep -v lwrite_pponly
    else
      #grep -v '^#' ${PARAMS}
      egrep -v ${EXCLPATTERN} ${PARAMS}
    fi
  fi
}

function paramshelp() {
  echo
    if [ "$PARAMSNAME" == "help" ]; then
    echo "Available parameter sets"
    echo
    echo
    echo "use '-p paramsname help' for details..."
  ls ${PARAMSBASE}* | cut -f2- -d- | sed -e 's/.inc//'
  else
    echo "Help on $PARAMS"
    echo
    cat $PARAMS
  fi
  echo
}

function paramsexcl() {
  if [ "$PARAMSEXCLNAME" != "NULL" ]; then
    #grep -v '^#' ${PARAMSEXCL}
    egrep -v ${EXCLPATTERN} ${PARAMSEXCL}
  fi
}

function paramsexclhelp() {
  echo
    if [ "$PARAMSEXCLNAME" == "help" ]; then
    echo "Available parameter sets"
    echo
    echo
    echo "use '-p paramsname help' for details..."
  ls ${PARAMSEXCLBASE}* | cut -f2- -d- | sed -e 's/.inc//'
  else
    echo "Help on $PARAMSEXCL"
    echo
    cat $PARAMSEXCL
  fi
  echo
}

function outfile() {
  if [ "$OUTFILENAME" != "NULL" ]; then
    echo -n "OUTFILE='"
    echo -n ${OUTFILENAME}
    echo "'"
  fi
}

function setCenter() {
	case "$CENTRE" in
		eidb)
			CENTER=233
			PROCESS=43
		;;
		knmi)
			CENTER=99
			PROCESS=43
		;;
		dmi)
			CENTER=9999
			PROCESS=43
		;;
		imo)
			CENTER=999
			PROCESS=43
		;;
		*)
			CENTER=233
		;;
	esac
}

while [ $# -gt 0 ]; do
case "$1" in
	-C)
		CENTRE=$2
		setCenter
		CUTOUTBASE=${INCDIR}/${CENTRE}/10-
		REPROJBASE=${INCDIR}/${CENTRE}/20-
		PARAMSBASE=${INCDIR}/${CENTRE}/30-
		PARAMSEXCLBASE=${INCDIR}/${CENTRE}/40-
		shift; shift
	;;
	-E)
		EZONE=$2
		shift; shift
	;;
	-h)
		usage
		exit
	;;
	-m)
		header
		INMEMORY=true
		if [ $# -gt 1 ]; then
			INFILENAMEMEM=$2
			if [ $# -gt 2 ]; then
				APPEND=$3
			fi
			infilemem
		else
			tomemory
			footer
		fi
		shift
		exit
	;;
	-mx)
		MAXFL=$2
		shift; shift
	;;
	-d)
		DTG=$2
		shift; shift
	;;
	-e)
		ENSEMBLE=$2
		shift; shift
	;;
	-s)
		HHH=$(echo $2 | sed -e 's/^0*//')
		FSTARTXN=$(( ( ($HHH - $FSTARTINTERVAL) / $FREQ_RESET_TEMP ) * $FREQ_RESET_TEMP))
		FSTARTG=$(($HHH - $FSTARTINTERVAL))
		if [ $FSTARTXN -lt 0 ]; then
			FSTARTXN=0
		fi
		if [ $FSTARTG -lt 0 ]; then
			FSTARTG=0
		fi
		HHH=$(printf "%03d" $HHH)
		shift; shift
	;;
	-f)
		OUTFILENAME=$2
		shift; shift
	;;
	-g)
		TOGRIBNAME=$2
		TOGRIB=${TOGRIBBASE}${TOGRIBNAME}.inc
		shift; shift
	;;
	-i)
		INFILENAME=$2
		shift; shift
	;;
	-M)
		OUTMEMORY=true
		shift
	;;
	-T)
		 INMEMORY=true
		 APPEND=APPEND
		shift
	;;
	-k)
		TOPACKNAME=$2
		TOPACK=${TOPACKBASE}${TOPACKNAME}.inc
		shift; shift
	;;
	-c)
		CUTOUTNAME=$2
		CUTOUT=${CUTOUTBASE}${CUTOUTNAME}.inc
		shift; shift
		# Help on cutout/reproj/param
		if [ "$CUTOUTNAME" == "help" ]; then
			cutouthelp >&2
			exit
		elif [ $# -gt 0 -a "$1" == "help" ]; then
			cutouthelp >&2
			exit
		fi
	;;
	-r)
		REPROJNAME=$2
		REPROJ=${REPROJBASE}${REPROJNAME}.inc
		shift; shift
		# Help on cutout/reproj/param
		if [ "$REPROJNAME" == "help" ]; then
			reprojhelp >&2
			exit
		elif [ $# -gt 0 -a "$1" == "help" ]; then
			reprojhelp >&2
			exit
		fi
	;;
	-p)
		PARAMSNAME=$2
		PARAMS=${PARAMSBASE}${PARAMSNAME}.inc
		shift; shift
		# Help on cutout/reproj/param
		if [ "$PARAMSNAME" == "help" ]; then
			paramshelp >&2
			exit
		elif [ $# -gt 0 -a "$1" == "help" ]; then
			paramshelp >&2
			exit
			exit
		fi
	;;
	-x)
		PARAMSEXCLNAME=$2
		PARAMSEXCL=${PARAMSEXCLBASE}${PARAMSEXCLNAME}.inc
		shift; shift
		# Help on cutout/reproj/param
		if [ "$PARAMSEXCLNAME" == "help" ]; then
			paramsexclhelp >&2
			exit
		elif [ $# -gt 0 -a "$1" == "help" ]; then
			paramsexclhelp >&2
			exit
			exit
		fi
	;;
	-d)
		DEBUG=true
		shift
	;;
	*)
		echo "Unknown arg: $1" >&2
		usage >&2
		exit
	;;
esac
done

if [ "X$DEBUG" == "Xtrue" ]; then
  echo "Args:" >&2
  echo "-C $CENTRE" >&2
  echo "-M $OUTMEMORY" >&2
  echo "-f $OUTFILENAME" >&2
  echo "-c $CUTOUTNAME" >&2
  echo "-r $REPROJNAME" >&2
  echo "-p $PARAMSNAME" >&2
fi

# Test for expected switches
# Must have outfile name if '-M' from memory switch
if [ $INMEMORY == false -a $OUTMEMORY == true -a "$OUTFILENAME" == "NULL" ]; then
  echo >&2 
  echo "Error, outputfilename must be supplied to read from memory" >&2
  usage >&2
  exit
fi
# Can only have cutout (-c) or reproj (-r), not both
if [ "$CUTOUTNAME" != "NULL" -a "$REPROJNAME" != "NULL" ]; then
  echo >&2 
  echo "Error, you may only use a cutout (-c) or reproj (-r), not both." >&2
  usage >&2
  exit
fi


#set -x
header
frommemory
tomemory
infile
togrib
dtgout
fstart
ensemble
topack
cutout
reproj
params
paramsexcl
outfile
footer

