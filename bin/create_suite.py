import os, sys
#import time, datetime
from datetime import datetime, timedelta
import time
from time import gmtime as gmtime
from time import strftime as tstrftime
import getpass
import argparse

import ecflow as ec

# The name of this suite
SUITE_NAME = os.environ['SUITE_NAME']

# User/host variables
CLUSTER = os.environ['HOSTNAME']
USER = os.environ["USER"]

# Ecflow variables
ECF_HOST = os.environ["ECF_HOST"]
ECF_PORT = os.environ["ECF_PORT"]
ECF_HOME = os.environ["ECF_HOME"]

# Where this project is installed
EXTRGRIB = os.environ["EXTRGRIB"]

# Force replace suite
FORCE = os.environ["FORCE"]

# Recover the bash variable determining which models to process
MODEL_SUITES = os.environ["MODEL_SUITES"]
# Convert this variable to a python list
model_suites = MODEL_SUITES.split(" ")


defs = ec.Defs()
suite = defs.add_suite(SUITE_NAME)
suite.add_variable("USER",           USER)
suite.add_variable("SUITE_NAME",     SUITE_NAME)
suite.add_variable("ECF_HOME",       "%s"%ECF_HOME)
suite.add_variable("ECF_INCLUDE",    "%s/etc/ecf"%EXTRGRIB)
suite.add_variable("ECF_FILES",      "%s/etc/ecf"%EXTRGRIB)
suite.add_variable("TASK",           "")
suite.add_variable("YMD",            "")
suite.add_variable("HH",             "")
suite.add_variable("SUB_H",          "sub.h")

# If running at ECMWF, use the schedule script
if "ecgb" in CLUSTER:
    STHOST= 'sc1'
    SCHOST= 'cca'
    WSHOST= 'ecgb11'
    HOST= '%SCHOST%'
    ECF_JOB_CMD= 'export STHOST=%STHOST% ; /usr/local/apps/schedule/1.4/bin/schedule %USER% %HOST% %ECF_JOB% %ECF_JOBOUT%'
    ECF_KILL_CMD= 'export STHOST=%STHOST% ; /usr/local/apps/schedule/1.4/bin/schedule %USER% %HOST% %ECF_RID% %ECF_JOB% %ECF_JOBOUT% kill'
    ECF_STATUS_CMD= 'export STHOST=%STHOST% ; /usr/local/apps/schedule/1.4/bin/schedule %USER% %HOST% %ECF_RID% %ECF_JOB% %ECF_JOBOUT% status'
    suite.add_variable("STHOST",            STHOST)
    suite.add_variable("SCHOST",            SCHOST)
    suite.add_variable("WSHOST",            WSHOST)
    suite.add_variable("HOST",                HOST)
    suite.add_variable("ECF_JOB_CMD",       ECF_JOB_CMD)
    suite.add_variable("ECF_KILL_CMD",      ECF_KILL_CMD)
    suite.add_variable("ECF_STATUS_CMD",    ECF_STATUS_CMD)
    suite.add_variable("ECF_HOME",          "/hpc%s"%ECF_HOME)
    suite.add_variable("ECF_INCLUDE",       "/hpc%s/share/ecf"%EXTRGRIB)
    suite.add_variable("ECF_FILES",         "/hpc%s/share/ecf"%EXTRGRIB)
    suite.add_variable("SUB_H",             "qsub.h")


def ENSMSEL_to_list(ENSMSEL):
    if ENSMSEL == "":
        print("Deterministic forecast only")
        ensmbrs = [ 'det' ]
    else:
        # Convert this string into a list item containing all ensemble members
        ensmsel = sum(((list(range(*[int(b) + c
            for c, b in enumerate(a.split('-'))]))
            if '-' in a else [int(a)]) for a in ENSMSEL.split(',')), [])
        # Pad this list to 3 digits
        ensmbrs = [str(mbr).zfill(3) for mbr in ensmsel]
    return ensmbrs

# The run family should contain the operational functionality of the suite
# If a task in run aborts, operators will be instructed to intervene
def create_family_run():
    #### These variables should be sourced from HARMONIE expirement directory ###
    # Source HM_LIB/ecf/config_mbr${ENSMBR}.h 
    start_ymd = "20211001" # From progress.log
    #############################################################################


    run = ec.Family("run")
    run.add_limit("par", 6)
    run.add_repeat(ec.RepeatDate("YMD",int(start_ymd), 20990101, 1))
    run.add_trigger("/" + model_suite + "/Date:YMD >= :YMD")
    # For this experiment, recover the list of cycles HH_LIST
    HH_LIST = os.environ["HH_LIST"]
    # Split this (e.g. 00-18:6) into the range (e.g. 00-18) and the steps (e.g. 6)
    HH_LIST_range, HH_LIST_steps = HH_LIST.split(':')
    # Construct a list object consisting of each valid cycle
    hh_list = sum(((list(range(*[int(b) + c
        for c, b in enumerate(a.split('-'))], int(HH_LIST_steps)))
        if '-' in a else [int(a)]) for a in HH_LIST_range.split(',')), [])
    # Pad this list to have leading zeroes, i.e. 0 -> 00 etc
    cycle_list = [str(cycle).zfill(2) for cycle in hh_list]

    cycle_i = 0
    for cycle in cycle_list:
        fc = run.add_family(cycle).add_inlimit("par")
        fc.add_variable("HH", cycle)
        fc.add_trigger("/" + model_suite + "/Date/Hour:HH >=" + cycle)
        null="null"
        # For this experiment, recover the list of ensemble members ENSMSEL
        ensmbrs = ENSMSEL_to_list(ENSMSEL)

        # Iterate over each ensemble member
        for mbr in ensmbrs:
            # Retrieve the LL_LIST for this member
            LL_LIST = os.environ[model_suite + "_mbr" + mbr + "_LL_LIST"]
            LL_LIST = LL_LIST.split(",")

            # LL_LIST determines the LL for this particular member and cycle
            # Expand the LL_LIST to the length of cycle_list
            q, r = divmod(len(cycle_list), len(LL_LIST))
            ll_list = q * LL_LIST + LL_LIST[:r]
            # Get the ll for this member/cycle using the cycle_i iterator
            max_ll = ll_list[cycle_i]
    
            archive_root = os.environ[model_suite + "_mbr" + mbr + "_ARCHIVE_ROOT"]

            fm = fc.add_family("mbr"+mbr)
            # Update variables required for extractGrib
            fm.add_variable("FCSTPATH",     archive_root) # This is $ARCHIVE
            fm.add_variable("EXP",          model_suite)
            fm.add_variable("DOMAIN",       DOMAIN)
            fm.add_variable("EZONE",        null)
            fm.add_variable("DTG",          null)
            fm.add_variable("STEP",         null)
            fm.add_variable("ENSMBR",       mbr)
            fm.add_variable("MAX_LL",       max_ll)
            fm.add_variable("EXTRGRIB_LISTENERS",       EXTRGRIB_LISTENERS)
            fm.add_variable("ARCHIVE_ROOT", archive_root)

            for lstnr in range(0, int(EXTRGRIB_LISTENERS)):
                if (int(lstnr) <= int(max_ll)):
                    fl = fm.add_family('listen' + str(lstnr))
                    fl.add_variable("listener",    lstnr)
                    if ensmbr == "det":
                        trigger_mbr = ""
                    else:
                        trigger_mbr = "Mbr" + mbr + "/"
                    te = fl.add_task("extract_grib")
                    # Trigger when model forecast YMD > extractGrib YMD
                    te.add_trigger("/" + model_suite + "/Date:YMD > ../../../../run:YMD")
                    # Trigger when model forecast YMD = extractGrib YMD, but model forecast HH > extractGrib HH
                    te.add_part_trigger("( /" + model_suite + "/Date:YMD == ../../../../run:YMD and /" + model_suite + "/Date/Hour:HH > " + cycle + " )", False)
                    # Trigger when model forecast DTG = extractGrib DTG, and model forecast is complete
                    te.add_part_trigger("( /" + model_suite + "/Date:YMD == ../../../../run:YMD and /" + model_suite + "/Date/Hour:HH == " + cycle + " and ( /" + model_suite + "/Date/Hour/Cycle/" + trigger_mbr + "Forecasting/Forecast == complete or ( /" + model_suite + "/Date/Hour/Cycle/" + trigger_mbr + "Forecasting/Forecast == active and /" + model_suite + "/Date/Hour/Cycle/" + trigger_mbr + "Forecasting/Forecast:hh >= " + str(lstnr) + " ) ) )", False)
#                    if ensmbr == "det":
#                        te.add_trigger("/" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast == complete or ( /" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast == active and /" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast:hh >=" + str(lstnr) + ")")
#                    else:
#                        te.add_trigger("/" + model_suite + "/Date/Hour/Cycle/Mbr" + ensmbr + "/Forecasting/Forecast == complete or ( /" + model_suite + "/Date/Hour/Cycle/Mbr" + ensmbr + "/Forecasting/Forecast == active and /" + model_suite + "/Date/Hour/Cycle/Mbr" + ensmbr + "/Forecasting/Forecast:hh >=" + str(lstnr) + ")")


        # Iterate cycle_i so we know which ll to pick from ll_list
        cycle_i = cycle_i + 1
    return run

# The maintenance family should contain housekeeping tasks such as deleting
# old files, cleaning working directories, archiving etc.
# If a task in maint aborts, operators will issue a next working day request
def create_family_maint():
    maint= ec.Family("maint")
    maint.add_limit("par", 6)
    return maint

# Create the families in the suite
for model_suite in model_suites:
    fm = suite.add_family(model_suite)
    # Recover ensemble list ENSMSEL
    ENSMSEL = os.environ[model_suite + '_ENSMSEL']
    DOMAIN = os.environ[model_suite + '_DOMAIN']
    EXTRGRIB_LISTENERS = os.environ["EXTRGRIB_LISTENERS"]
    # Add externs
    ensmbrs = ENSMSEL_to_list(ENSMSEL)
    defs.add_extern("/" + model_suite + "/Date:YMD")
    defs.add_extern("/" + model_suite + "/Date/Hour:HH")
    for ensmbr in ensmbrs:
        if ensmbr == 'det':
            defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast")
            defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast:hh")
        else:
            defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Mbr" + str(ensmbr) + "/Forecasting/Forecast")
            defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Mbr" + str(ensmbr) + "/Forecasting/Forecast:hh")

    fm.add_variable("EXP",     model_suite)
    fm.add_family(create_family_run())
    fm.add_family(create_family_maint())

# Define a client object with the target ecFlow server
client = ec.Client(ECF_HOST, ECF_PORT)

# If the force flag is set, load the suite regardless of whether an
# experiment of the same name exists in the ecFlow server
if FORCE == "True":
    client.load(defs, force=True)
else:
    try:
        client.load(defs, force=False)
    except:
        print("ERROR: Could not load %s on %s@%s" %(suite.name(), ECF_HOST, ECF_PORT))
        print("Use the force option to replace an existing suite:")
        print("    harmlbcs_start.sh -f")
        exit(1)

# Save the definition to a .def file
print("Saving definition to file '%s.def'"%SUITE_NAME)
defs.save_as_defs("%s.def"%SUITE_NAME)
#exit(0)
print("loading on %s@%s" %(ECF_HOST,ECF_PORT))

# Suspend the suite to allow cycles to be forced complete
client.suspend("/%s" %suite.name())
# Begin the suite
client.begin_suite("/%s" % suite.name(), True)
exit(0)
# Mark all HH before start_hh complete
if int(start_hh) > 0:
    for h in range (0,int(start_hh),6):
        hh = str(h).zfill(2)
        print("mark complete:", hh)
        for lbc_stream in lbc_streams:
            client.force_state_recursive("/%s/%s/run/%s" %(suite.name(), lbc_stream, hh), ec.State.complete)
            client.force_state_recursive("/%s/%s/maint/clean/%s" %(suite.name(), lbc_stream, hh), ec.State.complete)
            if os.environ["ARCHIVE"] == "yes":
                client.force_state_recursive("/%s/%s/maint/archive/%s" %(suite.name(), lbc_stream, hh), ec.State.complete)

# Resume the suite
client.resume("/%s" %suite.name())


exit(0)

