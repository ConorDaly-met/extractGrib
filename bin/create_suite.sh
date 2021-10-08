#!/bin/bash

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
export SUITE_NAME="makegrib"

#export ECF_HOST="reaserve"
#export ECF_PORT="5518"
export FORCE="True"

export EXTRGRIB="$PERM/uwcwtest_repos/extractGrib"
export ECF_HOME="$HOME/ecflow_suites"

source $EXTRGRIB/share/config/config.ecgb-cca
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
    else
        # Get the list of ensemble members
        module unload python
        module load python3/3.8.8-01

        ENSMBRS=$(python3 ensmsel_to_list.py $ENSMSEL)
        ENSMBRS=$(echo $ENSMBRS | sed -E "s/\[|\]|'|,//g")
        for ENSMBR in $ENSMBRS
        do
            source ${HM_LIB}/ecf/config_mbr${ENSMBR}.h || exit 1
            export "${model_suite}_mbr${ENSMBR}_LL_LIST="$LL_LIST""
        done

    fi
    export "${model_suite}_ENSMSEL="$ENSMSEL""
    export "${model_suite}_DOMAIN="$DOMAIN""
    source $EXTRGRIB/share/config/config.ecgb-cca
done

python3 create_suite.py
