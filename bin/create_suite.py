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

# The config setting
EXTRGRIB_CONFIG = os.environ["EXTRGRIB_CONFIG"]

# How long to wait before cleaning
KEEP_DAYS = os.environ["KEEP_DAYS"]

# Force replace suite
FORCE = os.environ["FORCE"]

START_DTG = os.environ["START_DTG"]
start_ymd = START_DTG[0:8]
start_hh = START_DTG[8:10]

# Recover the bash variable determining which models to process
MODEL_SUITES = os.environ["MODEL_SUITES"]
# Convert this variable to a python list
model_suites = MODEL_SUITES.split(" ")


defs = ec.Defs()
suite = defs.add_suite(SUITE_NAME)
suite.add_variable("USER",           USER)
suite.add_variable("SUITE_NAME",     SUITE_NAME)
suite.add_variable("EXTRGRIB",       EXTRGRIB)
suite.add_variable("EXTRGRIB_CONFIG", EXTRGRIB_CONFIG)
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
    suite.add_variable("SUBCLEAN_H",        "qsub_clean.h")


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

# Generate a list of cycles
def make_cycle_list():
    HH_LIST = os.environ["HH_LIST"]
    # Split this (e.g. 00-18:6) into the range (e.g. 00-18) and the steps (e.g. 6)
    HH_LIST_range, HH_LIST_steps = HH_LIST.split(':')
    # Construct a list object consisting of each valid cycle
    hh_list = sum(((list(range(*[int(b) + c
        for c, b in enumerate(a.split('-'))], int(HH_LIST_steps)))
        if '-' in a else [int(a)]) for a in HH_LIST_range.split(',')), [])
    # Pad this list to have leading zeroes, i.e. 0 -> 00 etc
    cycle_list = [str(cycle).zfill(2) for cycle in hh_list]

    return cycle_list

# create family cycles
def create_family_cycles(node, model_suite, node_type, deltadays):
    cycle_list = make_cycle_list()

    cycle_i = 0
    for cycle in cycle_list:
        fc = create_family_cycle(node, cycle)
        create_family_members(fc, model_suite, node_type, cycle, cycle_i, deltadays)
        # Iterate cycle_i so we know which ll to pick from ll_list
        cycle_i = cycle_i + 1

# create individual cycles
def create_family_cycle(node, cycle):
    fc = node.add_family(cycle).add_inlimit("par")
    fc.add_variable("HH", cycle)
    return fc

# create individual members
def create_family_member(node, mbr, model_suite, node_type):
    null="null"
    archive_root = os.environ[model_suite + "_mbr" + mbr + "_ARCHIVE_ROOT"]
    fm = node.add_family("mbr"+mbr)
    # Update variables required for extractGrib
    DOMAIN = os.environ[model_suite + '_DOMAIN']
    EXTRGRIB_WORKERS = os.environ["EXTRGRIB_WORKERS"]
    fm.add_variable("FCSTPATH",     archive_root) # This is $ARCHIVE
    fm.add_variable("EXP",          model_suite)
    fm.add_variable("DOMAIN",       DOMAIN)
    fm.add_variable("EZONE",        null)
    fm.add_variable("DTG",          null)
    fm.add_variable("STEP",         null)
    fm.add_variable("ENSMBR",       mbr)
    fm.add_variable("EXTRGRIB_WORKERS",       EXTRGRIB_WORKERS)
    fm.add_variable("ARCHIVE_ROOT", archive_root)

    return fm

# Create family members
def create_family_members(node, model_suite, node_type, cycle, cycle_i, deltadays):
    ENSMSEL = os.environ[model_suite + '_ENSMSEL']
    ensmbrs = ENSMSEL_to_list(ENSMSEL)
    for mbr in ensmbrs:
        fm = create_family_member(node, mbr, model_suite, node_type)
        create_family_workers(fm, mbr, model_suite, node_type, cycle, cycle_i, deltadays)
    
# Create family workers
def create_family_workers(node, mbr, model_suite, node_type, cycle, cycle_i, deltadays):
    NUM_WORKERS = 1
    max_ll = 0
    if(node_type == "run"):
        # Retrieve the LL_LIST for this member
        LL_LIST = os.environ[model_suite + "_mbr" + mbr + "_LL_LIST"]
        LL_LIST = LL_LIST.split(",")
        # LL_LIST determines the LL for this particular member and cycle
        # Expand the LL_LIST to the length of cycle_list
        q, r = divmod(len(make_cycle_list()), len(LL_LIST))
        ll_list = q * LL_LIST + LL_LIST[:r]
        # Get the ll for this member/cycle using the cycle_i iterator
        max_ll = ll_list[cycle_i]
        NUM_WORKERS = os.environ["EXTRGRIB_WORKERS"]
        node.add_variable("MAX_LL",       max_ll)

    for wrkr in range(0, int(NUM_WORKERS)):
        if (int(wrkr) <= int(max_ll)):
            fw = create_family_worker(node, wrkr, model_suite, node_type)
            te = create_task(fw, node_type, max_ll, wrkr, NUM_WORKERS, model_suite, cycle, mbr, deltadays)
    
# Create the individual workers
def create_family_worker(node, wrkr, model_suite, node_type):
    fw = node.add_family('worker' + str(wrkr))
    fw.add_variable("worker",    wrkr)

    return fw

# Create the task
def create_task(node, node_type, max_ll, wrkr, numwrkr, model_suite, cycle, mbr, deltadays):
    if(node_type == "run"):
        task = "extract_grib"
    if(node_type == "clean"):
        task = "extrgrib_clean"
    if(node_type == "archive"):
        task = "extrgrib_archive"

    te = node.add_task(task)

    # Add a meter to 'run' node
    if(node_type == "run"):
        mdx = (int(max_ll) - int(wrkr)) % int(numwrkr)
        mx = int(max_ll) - mdx
        meter = ec.Meter("STEP",-1,mx,mx)
        te.add_meter(meter)

    create_trigger(te, node_type, model_suite, cycle, mbr, wrkr, deltadays)


    return te

# Create the triggers
def create_trigger(node, node_type, model_suite, cycle, mbr, wrkr, deltadays):
    if mbr == "det":
        trigger_mbr = ""
        defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast")
        defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Forecasting/Forecast:hh")
    else:
        trigger_mbr = "Mbr" + mbr + "/"
        defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Mbr" + str(mbr) + "/Forecasting/Forecast")
        defs.add_extern("/" + model_suite + "/Date/Hour/Cycle/Mbr" + str(mbr) + "/Forecasting/Forecast:hh")
    # Trigger when model forecast YMD > extractGrib YMD
    trigger_source = "/" + model_suite + "/Date"
    trigger_compare="../../../../../../run/%s/Date" %(model_suite)
    trigger_delta = " + %s" %(deltadays)
    if(node_type == "run"):
        trigger_compare=""
    if(node_type == "clean"):
        trigger_source=""
    if(node_type == "run"):
        # Trigger when model forecast YMD > extractGrib YMD
        node.add_trigger(trigger_source + ":YMD" + trigger_delta + " > " + trigger_compare + ":YMD")
        # Trigger when model forecast YMD = extractGrib YMD, but model forecast HH > extractGrib HH
        node.add_part_trigger("( " + trigger_source + ":YMD" + trigger_delta + " == " + trigger_compare + ":YMD and " + trigger_source + "/Hour:HH > " + cycle + " )", False)
        # Trigger when model forecast DTG = extractGrib DTG, and model forecast is complete
        node.add_part_trigger("( " + trigger_source + ":YMD" + trigger_delta + " == " + trigger_compare + ":YMD and " + trigger_source + "/Hour:HH == " + cycle + " and ( " + trigger_source + "/Hour/Cycle/" + trigger_mbr + "Forecasting/Forecast == complete or ( " + trigger_source + "/Hour/Cycle/" + trigger_mbr + "Forecasting/Forecast == active and " + trigger_source + "/Hour/Cycle/" + trigger_mbr + "Forecasting/Forecast:hh >= " + str(wrkr) + " ) ) )", False)
    if(node_type == "clean"):
        # Trigger when clean YMD+7 < extractGrib YMD
        node.add_trigger(trigger_source + ":YMD" + trigger_delta + " < " + trigger_compare + ":YMD")
        # Trigger when clean YMD+7 == extractGrib YMD, and extractGrib HH is complete
        node.add_part_trigger("( " + trigger_source + ":YMD" + trigger_delta + " == " + trigger_compare + ":YMD and " + trigger_compare + "/" + cycle + " == complete )", False)


    
# The run family should contain the operational functionality of the suite
# If a task in run aborts, operators will be instructed to intervene
def create_family_run():
    #### These variables should be sourced from HARMONIE expirement directory ###
    # Source HM_LIB/ecf/config_mbr${ENSMBR}.h 
    #start_ymd = "20211013" # From progress.log
    #############################################################################


    #print("START_YMD =", start_ymd)
    run = ec.Family("run")
    deltadays = 0
    # Create the families in the suite
    for model_suite in model_suites:
        fm = create_family_model(run, model_suite)
        fy = create_family_ymd(fm, 'Date', deltadays)
        create_family_cycles(fy, model_suite, "run", deltadays)

    return run

def create_family_ymd(node, fname, deltadays):
    fm = node.add_family(fname)
    fm.add_limit("par", 6)
    if(deltadays == 0):
        fm.add_repeat(ec.RepeatDate("YMD",int(start_ymd), 20990101, 1))
    else:
        # Figure out what date to start the cycle
        start_ymd_object = datetime.strptime(str(start_ymd), "%Y%m%d")
        fname_start_ymd_object = start_ymd_object - timedelta(days = int(deltadays))
        fname_start_ymd = fname_start_ymd_object.strftime("%Y%m%d")
        # Add a repeat over YMD
        fm.add_repeat(ec.RepeatDate("YMD",int(fname_start_ymd), 20990101, 1))

    return fm

def create_family_model(node, model_suite):
    fm = node.add_family(model_suite)
    #fm.add_limit("par", 6)
    #fm.add_repeat(ec.RepeatDate("YMD",int(start_ymd), 20990101, 1))
    # Recover ensemble list ENSMSEL
    HH_LIST = os.environ[model_suite + '_HH_LIST']
    #ENSMSEL = os.environ[model_suite + '_ENSMSEL']
    START_DTG = os.environ[model_suite + '_START_DTG']
    # Add externs
    #ensmbrs = ENSMSEL_to_list(ENSMSEL)
    defs.add_extern("/" + model_suite + "/Date:YMD")
    defs.add_extern("/" + model_suite + "/Date/Hour:HH")
    fm.add_variable("EXP",     model_suite)

    return fm

# The maintenance family should contain housekeeping tasks such as deleting
# old files, cleaning working directories, archiving etc.
# If a task in maint aborts, operators will issue a next working day request
def create_family_maint():
    maint= ec.Family("maint")
    # Create the families in the suite
    for model_suite in model_suites:
        fm = create_family_model(maint, model_suite)
        fy = create_family_ymd(fm, 'clean', KEEP_DAYS)
        create_family_cycles(fy, model_suite, "clean", KEEP_DAYS)
    return maint

suite.add_family(create_family_run())
suite.add_family(create_family_maint())
#create_family_maint()

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
#exit(0)
# Mark all HH before start_hh complete
for model_suite in model_suites:
    START_DTG = os.environ[model_suite + '_START_DTG']
    start_hh = START_DTG[8:10]
    # For this experiment, recover the list of cycles HH_LIST
    HH_LIST = os.environ[model_suite + '_HH_LIST']
    # Split this (e.g. 00-18:6) into the range (e.g. 00-18) and the steps (e.g. 6)
    HH_LIST_range, HH_LIST_steps = HH_LIST.split(':')
    # Construct a list object consisting of each valid cycle
    hh_list = sum(((list(range(*[int(b) + c
        for c, b in enumerate(a.split('-'))], int(HH_LIST_steps)))
        if '-' in a else [int(a)]) for a in HH_LIST_range.split(',')), [])
    # Pad this list to have leading zeroes, i.e. 0 -> 00 etc
    cycle_list = [str(cycle).zfill(2) for cycle in hh_list]
    if int(start_hh) > 0:
        for cycle in cycle_list:
            if int(cycle) < int(start_hh):
                print("mark complete:", cycle)
                client.force_state_recursive("/%s/run/%s/Date/%s" %(suite.name(), model_suite, cycle), ec.State.complete)
            #client.force_state_recursive("/%s/%s/maint/clean/%s" %(suite.name(), model_suite, cycle), ec.State.complete)
            #if os.environ["ARCHIVE"] == "yes":
            #    client.force_state_recursive("/%s/%s/maint/archive/%s" %(suite.name(), lbc_stream, cycle), ec.State.complete)
exit(0)
# Resume the suite
client.resume("/%s" %suite.name())


exit(0)

