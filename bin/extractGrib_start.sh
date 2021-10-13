#!/bin/bash

# This script will create the ecFlow suite definition and load it into the
# ecfFlow server. It can take a 'host' argument for a specific environment


bold=$(tput bold)
normal=$(tput sgr0)
unline=$(tput smul)

# Define a usage function
usage() {

PROGNAME=`basename $0`

cat << USAGE

${bold}NAME${normal}
        ${PROGNAME} - Start a new HARMONIE EXTRGRIB processing suite

${bold}USAGE${normal}
        ${PROGNAME} -e <harmlbc-name> -c <configuration> -l <install location> -s DTG [ -h ]

${bold}DESCRIPTION${normal}
        Script to start new EXTRGRIB processing suite

${bold}OPTIONS${normal}
        -r ${unline}harmlbc-name${normal}
           Name for your Harmonie EXTRGRIB processing suite

        -c ${unline}system-configuration${normal}
           System confgiuration file. config-sh/config.<system-configuration> file must exist.
        
        -l ${unline}install-location${normal}
           Might replace this with CMake
        
        -s ${unline}start DTG${normal}
           Define DTG to start processing
        
        -h Help! Print usage information.

USAGE
}

# Default host is reaserve
default_config="METIE.LinuxRH7gnu"

# Default experiment name is process_lbcs
# This can be changed with the -e flag to set up a parallel experiment in the
# same ecFlow server
default_exp="process_lbcs"

START_DTG=$(date +%Y%m%d%H)

# The location of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
repo_dir=$(dirname ${script_dir})

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -c|--config|--configuration)
      shift
      if test $# -gt 0; then
        export config=$1
      else
        echo "$0: No configuration specified '-c'"
        echo "Try '$0 -h' for more information"
        exit 1
      fi
      shift
      ;;
    -e|--exp|--experiment) # Name of this experiment
      shift
      if test $# -gt 0; then
        export EXP=$1
      fi
      shift
      ;;
    -l|--location) # Where to install this suite
      shift
      if test $# -gt 0; then
        export install_location=$1
      fi
      shift
      ;;
    -s|--start) # DTG to start. By defualt, it follows the operational schedule
      shift
      if test $# -gt 0; then
        export START_DTG=$1
      fi
      shift
      ;;
    *)
      break
      ;;
  esac
done

# Set the config/EXP
export EXTRGRIB_CONFIG=${config:-$default_config}
export EXP=${EXP:-$default_exp}

# The default install_location
default_install_location="$HOME/ecflow_suites"

# Set the install location
export install_location=${install_location:-$default_install_location}

# START_DTG must be 10 characters long and must only be integers
if [[ ${#START_DTG} -ne 10 ]] || ! [[ $START_DTG =~ ^[0-9]+$ ]]
then
    echo "ERROR: START_DTG must be in YYYYMMDDHH format"
    exit 1
fi
export START_DTG

# The install location must exist and be writable
if ! [ -w $install_location ]
then
    echo "ERROR: The install location does not exist or you do not have write permission"
    echo "  ${install_location} does not exist/not writable by user ${USER}"
    exit 1
fi

# Make sure such a config exists
if ! [ -s ${repo_dir}/share/config/config.${EXTRGRIB_CONFIG} ] 
then
    echo "ERROR: No configuration file could be found for ${EXTRGRIB_CONFIG}"
    echo "  ${repo_dir}/share/config/config.${EXTRGRIB_CONFIG} does not exist"
    exit 1
fi

export EXTRGRIB_DATA=${install_location}/${EXP}
# Make the exp directory
[ -d ${EXTRGRIB_DATA} ] || mkdir ${EXTRGRIB_DATA}

# Sync from the repo to the install location on all hosts
rsync --exclude='.git' -aP ${repo_dir}/ ${EXTRGRIB_DATA}/

# If at ECMWF, also sync to cca
if [ ${EXTRGRIB_CONFIG} == "ecgb-cca" ]
then
    rsync -aP --exclude='.git' -aP ${repo_dir}/ cca:${EXTRGRIB_DATA}/
fi

cd ${EXTRGRIB_DATA}



# # # # TEMPORARY  SCRIPT # # # # # # # # # # # # # 
# This script is used to set a few environment    #
# variables before calling create_suite.py        #
# It's functionality should be replaced entirely  #
# by the installation script (cmake)              #
# # # # # # # # # # # # # # # # # # # # # # # # # #

#module purge
#module load eccodes/gnu-4.8.5/2.18.0
#module load ecflow/gnu-7.3.1/5.5.3
#source ../share/config/config.ecgb-cca
#set -x
export SUITE_NAME="extractGrib"

#export ECF_HOST="reaserve"
#export ECF_PORT="5518"
export FORCE="True"

export EXTRGRIB=${EXTRGRIB-"$HOME/metapp/extractGrib"}
export ECF_HOME="$HOME/ecflow_suites"

source $EXTRGRIB/share/config/config.${EXTRGRIB_CONFIG}
# Source config_exp
for model_suite in $MODEL_SUITES
do
    # Source the Env_system file to determine HM_LIB
    export EXP=$model_suite
    source $HOME/hm_home/${model_suite}/Env_system
    echo "HM_LIB=$HM_LIB"
    #HM_LIB="/data/rdarcy/uwcwtest_repos/extractgrib/etc/config"
    source ${HM_LIB}/ecf/config_exp.h || exit 1
    # Get member information
    if [ -z $ENSMSEL ]
    then
        export "${model_suite}_mbrdet_ENSMSEL="$ENSMSEL""
        export "${model_suite}_mbrdet_LL_LIST="$LL_LIST""
        export "${model_suite}_mbrdet_ARCHIVE_ROOT="$ARCHIVE_ROOT""
    else
        # Get the list of ensemble members
        module unload python
        module load python3/3.8.8-01

        ENSMBRS=$(python3 ${EXTRGRIB}/bin/ensmsel_to_list.py $ENSMSEL)
        ENSMBRS=$(echo $ENSMBRS | sed -E "s/\[|\]|'|,//g")
        for ENSMBR in $ENSMBRS
        do
            source ${HM_LIB}/ecf/config_mbr${ENSMBR}.h || exit 1
            export "${model_suite}_mbr${ENSMBR}_LL_LIST="$LL_LIST""
            export "${model_suite}_mbr${ENSMBR}_ARCHIVE_ROOT="$ARCHIVE_ROOT""
        done

    fi
    export "${model_suite}_ENSMSEL="$ENSMSEL""
    export "${model_suite}_DOMAIN="$DOMAIN""
    source $EXTRGRIB/share/config/config.ecgb-cca
done
cd $EXTRGRIB/bin
python3 create_suite.py
