#!/bin/bash

# # # # TEMPORARY  SCRIPT # # # # # # # # # # # # # 
# This script is used to set a few environment    #
# variables before calling create_suite.py        #
# It's functionality should be replaced entirely  #
# by the installation script (cmake)              #
# # # # # # # # # # # # # # # # # # # # # # # # # #

module purge
module load eccodes/gnu-4.8.5/2.18.0
module load ecflow/gnu-7.3.1/5.5.3

export EXP="makegrib"

export ECF_HOST="reaserve"
export ECF_PORT="5518"
export FORCE="True"

export EXTRGRIB="/data/rdarcy/uwcwtest_repos/extractgrib"
export ECF_HOME="/home/rdarcy/ecflow_suites"

python3 create_suite.py
