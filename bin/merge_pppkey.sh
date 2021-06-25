#!/bin/bash

if [ "$1" == "-mx" ]; then
  maxfl="maxfl=$2,"
  shift; shift
fi

NAML=$1
NAMOUTL=${NAML}_$$

PPPST=false

declare -a PPPKEY=()
declare -a PPPLINE=()
declare -a Keys=()
declare -a Keysout=()
KEYSCOUNT=0
SNCOUNT=0
LTCOUNT=0
TRCOUNT=0
LVCOUNT=0
PDCOUNT=0
PPPKEY[0]="&naminterp"
PPPKEY[1]="INPUT_FORMAT='MEMORY'"
PPPKEY[2]="OUTPUT_FORMAT='MEMORY'"
PPPKEY[3]="OUTPUT_TYPE = 'APPEND'"
PPPKEY[4]="cape_version=1"
PPPKEY[5]="pppkey"
PPPKEY[10]="lignore_duplicates=.TRUE."
PPPKEY[11]="lwrite_pponly=.TRUE."
PPPKEY[12]="/"
PPPKEYFOUND=false

SNKey="pppkey%shortname"
LTKey="pppkey%levtype"
TRKey="pppkey%tri"
LVKey="pppkey%level"
PDKey="pppkey%pdtn"

SNKeylist=""
LTKeylist=""
TRKeylist=""
LVKeylist=""
PDKeylist=""

function find_pppkey() {
	PPPPOS=$(grep -n '<PPPSTANZA>' $NAMOUTL | cut -f1 -d:)
	echo $PPPPOS
}

function write_pppkey() {
	for n in $(seq 0 4); do
		echo "${PPPKEY[$n]}"
	done
	if [ ! -z ${maxfl} ]; then
		echo ${maxfl}
	fi
	[ ${SNCOUNT} -gt 0 ] && echo "${SNKeylist}"
	[ ${LTCOUNT} -gt 0 ] && echo "${LTKeylist}"
	[ ${TRCOUNT} -gt 0 ] && echo "${TRKeylist}"
	[ ${LVCOUNT} -gt 0 ] && echo "${LVKeylist}"
	[ ${PDCOUNT} -gt 0 ] && echo "${PDKeylist}"

	#echo "${PPPKEY[10]}"
	echo "${PPPKEY[11]}"
	echo "${PPPKEY[12]}"
}

function write_removedups() {
cat << RMDUPS
&naminterp
INPUT_FORMAT='MEMORY'
OUTPUT_FORMAT='MEMORY'
OUTPUT_TYPE = 'NEW'
lignore_duplicates=.TRUE.
/
RMDUPS
}

function write_keylists() {
	for k in ${Keysout[@]}; do
		kk=($(echo $k | tr , ' '))
		kl=${#kk[@]}
		# Build the pppkey%shortname
		if [ -z $SNKeylist ]; then
			SNKeylist+="$SNKey="
		fi
		SNKeylist+="${kk[0]},"
		if [ $kl -ge 1 ]; then
			SNCOUNT=$(($SNCOUNT + 1))
		fi
		# Build the pppkey%levtype
		if [ -z $LTKeylist ]; then
			LTKeylist+="$LTKey="
		fi
		LTKeylist+="${kk[1]},"
		if [ $kl -ge 2 ]; then
			LTCOUNT=$(($LTCOUNT + 1))
		fi
		# Build the pppkey%tri
		if [ -z $TRKeylist ]; then
			TRKeylist+="$TRKey="
		fi
		TRKeylist+="${kk[2]},"
		if [ $kl -ge 3 ]; then
			TRCOUNT=$(($TRCOUNT + 1))
		fi
		# Build the pppkey%level
		if [ -z $LVKeylist ]; then
			LVKeylist+="$LVKey="
		fi
		LVKeylist+="${kk[3]},"
		if [ $kl -ge 4 ]; then
			LVCOUNT=$(($LVCOUNT + 1))
		fi
		# Build the pppkey%pdtn
		if [ -z $PDKeylist ]; then
			PDKeylist+="$PDKey="
		fi
		if [ $kl -ge 5 ]; then
			PDKeylist+="${kk[4]},"
			PDCOUNT=$(($PDCOUNT + 1))
		else
			PDKeylist+="-1,"
		fi
	done
}

function sort_keys() {
	k=0
	for i in ${!Keys[@]}; do
		#echo "Checking ${Keys[$i]}"
		if [ $i -gt 0 ]; then
			skey=true
			ii=$(($i - 1))
			for j in $(seq 0 $ii) ; do
				#echo "         ${Keys[$j]}"
				if [ ${Keys[$i]} == ${Keys[$j]} ]; then
					#echo "duplicate found"
					#skey=false
					break
				fi
			done
			if [ "$skey" == "true" ]; then
				#echo "Storing"
				Keysout[$k]=${Keys[$i]}
				k=$(($k + 1))
			fi
		else
			#echo "Storing"
			Keysout[$k]=${Keys[$i]}
			k=$(($k + 1))
		fi
	done
	#echo ${Keysout[@]}
	#echo "${#Keys[@]} keys found"
	#echo "${#Keysout[@]} unique keys found"
	write_keylists
}

function compare_key() {

	SNKeys=($(echo $SNK | tr ',' ' '))
	LTKeys=($(echo $LTK | tr ',' ' '))
	TRKeys=($(echo $TRK | tr ',' ' '))
	LVKeys=($(echo $LVK | tr ',' ' '))
	PDKeys=($(echo $PDK | tr ',' ' '))
	for n in ${!SNKeys[@]}; do
		if [ ! -z ${SNKeys[$n]} ]; then
			Keys[$KEYSCOUNT]="${SNKeys[$n]},${LTKeys[$n]},${TRKeys[$n]},${LVKeys[$n]},${PDKeys[$n]}"
			KEYSCOUNT=$(($KEYSCOUNT + 1))
		else
			continue
		fi
	done
	#echo "$KEYSCOUNT keys found"
}

function store_pppkey() {
	local num=$1
	st=5
	SNK=""
	LTK=""
	TRK=""
	LVK=""
	PDK=""

	for n in $(seq $st $num); do
		KEY=$(echo ${PPPLINE[$n]} | cut -f1 -d'=')
		KEYV=$(echo ${PPPLINE[$n]} | cut -f2 -d'=')
		case $KEY in
			$SNKey)
				SNK="$KEYV"
			;;
			$LTKey)
				LTK="$KEYV"
			;;
			$TRKey)
				TRK="$KEYV"
			;;
			$LVKey)
				LVK="$KEYV"
			;;
			$PDKey)
				PDK="$KEYV"
			;;
		esac
	done
		
	compare_key
	
	if [ $PPPKEYFOUND != true ]; then
		echo "<PPPSTANZA>" >> $NAMOUTL
		PPPKEYFOUND=true
	fi
}

function test_nline() {
	NLN=$(echo $NLINE | sed -e 's/^ *//' -e 's/,$//')
	if [ "$NLN" == "${PPPKEY[0]}" ]; then
		PPPST=true
		PPPLINE[0]=$NLINE
		for n in $(seq 1 4) ; do
			read NLINE
			NLN=$(echo $NLINE | sed -e 's/^ *//' -e 's/,$//')
			PPPLINE[$n]=$NLINE
			if [ "$NLN" != "${PPPKEY[$n]}" ]; then
				PPPST=false
			fi
		done
		if [ $PPPST == false ]; then
			for n in $(seq 0 4); do
				echo ${PPPLINE[$n]} >> $NAMOUTL
			done
		else
			for n in $(seq 5 13); do
				read NLINE
				NLN=$(echo $NLINE | sed -e 's/^ *//' -e 's/,$//' | cut -f1 -d '%')
				PPPLINE[$n]=$NLINE
				#echo -n "N: $NLN"
				if [ "$NLN" != "pppkey" -a  "$NLN" != "/" -a "$NLN" != "${PPPKEY[10]}" -a "$NLN" != "${PPPKEY[11]}" ]; then
					PPPST=false
					#echo
					store_pppkey $n
					test_nline
					#echo $NLINE >> $NAMOUTL
					return
				fi
				#echo " P: $PPPST"
			done
		fi
	else
		echo $NLINE >> $NAMOUTL
	fi
}

function walk_naml() {
  local NAMLI=$1
  exec < $NAMLI
  read NLINE
  while [ "X$NLINE" != "X" ]; do
	test_nline
	read NLINE
  done
	
}

function merge_pppkey() {
  local NAML=$1
  walk_naml $NAML

}

#echo "Merging $NAML"
merge_pppkey $NAML

sort_keys
PPPPOS=$( find_pppkey)
HPOS=$(($PPPPOS -1))
TPOS=$(($PPPPOS +1))
head -n $HPOS $NAMOUTL
#write_removedups
write_pppkey
#write_removedups
tail -n +$TPOS $NAMOUTL
rm $NAMOUTL
#echo "Found pppkey stanza at $PPPPOS"
