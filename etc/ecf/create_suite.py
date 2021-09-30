import os, sys
#import time, datetime
from datetime import datetime, timedelta
import time
from time import gmtime as gmtime
from time import strftime as tstrftime
import getpass
import argparse

import ecflow as ec

EXP = os.environ['EXP']
MAX_LL = os.environ['MAX_LL']

MULTITASK = os.environ["MULTITASK"]

CLUSTER = os.environ['HOSTNAME']
USER = os.environ["USER"]

ECF_HOST = os.environ["ECF_HOST"]
ECF_PORT = os.environ["ECF_PORT"]

# How long to wait before cleaning
KEEP_DAYS = os.environ["KEEP_DAYS"]

# Force replace suite
FORCE = os.environ["FORCE"]

START_DTG = os.environ["START_DTG"]
start_ymd = START_DTG[0:8]
start_hh = START_DTG[8:10]


defs = ec.Defs()
suite = defs.add_suite(EXP)
suite.add_variable("USER",           USER)
suite.add_variable("EXP",            EXP)
suite.add_variable("ECF_HOME",       "%s"%LBC_WORK)
suite.add_variable("ECF_INCLUDE",    "%s/share/ecf"%HARMLBCS)
suite.add_variable("ECF_FILES",      "%s/share/ecf"%HARMLBCS)
suite.add_variable("TASK",           "")
suite.add_variable("YMD",            "")
suite.add_variable("HH",             "")
suite.add_variable("MAX_LL",         MAX_LL)
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
    suite.add_variable("ECF_HOME",          "/hpc%s"%LBC_WORK)
    suite.add_variable("ECF_INCLUDE",       "/hpc%s/share/ecf"%HARMLBCS)
    suite.add_variable("ECF_FILES",         "/hpc%s/share/ecf"%HARMLBCS)
    suite.add_variable("SUB_H",             "qsub.h")

def create_family_run():
    run = ec.Family("run")
    run.add_limit("par", 6)
    return run

def create_family_maint():
    maint= ec.Family("maint")
    maint.add_limit("par", 6)
    return maint

# Create the families in the suite
suite.add_family(create_family_run())
suite.add_family(create_family_maint())

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
print("Saving definition to file '%s.def'"%EXP)
defs.save_as_defs("%s.def"%EXP)

print("loading on %s@%s" %(ECF_HOST,ECF_PORT))

# Suspend the suite to allow cycles to be forced complete
client.suspend("/%s" %suite.name())
# Begin the suite
client.begin_suite("/%s" % suite.name(), True)

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
