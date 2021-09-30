set -e # stop the shell on first error
#set -u # fail when using an undefined variable
#set -x # echo script lines as they are executed


# Defines the variables that are needed for any communication with ECF

ECF_PORT=%ECF_PORT%  export ECF_PORT  # The server port number
ECF_HOST=${ECF_HOST-"%ECF_HOST%"}  export ECF_HOST  # The name of ecf host that issued this task
ECF_NAME=%ECF_NAME%  export ECF_NAME  # The name of this current task
ECF_PASS=%ECF_PASS%  export ECF_PASS  # A unique password
ECF_RID=$$ export ECF_RID

is_ecflow_alive() {

 PING_COUNT=1
 while true
 do
    # Ping the server. If it responds, break the loop.
    ecflow_client --host=$ECF_HOST --port=$ECF_PORT --ping && break

    # Try to ping the server 5 timesthen give up.
    echo "The ecflow server did not respond to the ping request on attempt ${PING_COUNT}."
    PING_COUNT=$((PING_COUNT+1))
    if [ ${PING_COUNT} -gt 5 ]
    then
        echo "Ran out of patience while pinging ecflow server!"
        # <<<Send a mail here to inform of the failure>>>
        # Break the while loop (don't keep the script active indefinitely)
        break
    fi

    # Sleep for 2 minutes
    echo "Try pinging again in 2 minutes..."
    sleep 120
 done

}


# Define the path where to find ecflow_client
# make sure client and server use the *same* version.
# Important when there are multiple versions of ecFlow

PATH=/usr/local/apps/ecflow/%ECF_VERSION%/bin:$PATH export PATH

killcmd="echo not working"
# Tell ecFlow we have started
is_ecflow_alive
ecflow_client --init=$$
ecflow_client --alter add variable ECF_KILL_CMD "$killcmd" %ECF_NAME%


# Define a error handler
ERROR() {
   set +e                      # Clear -e flag, so we don't fail
                               # Syncing logs between cca/ccb  and ecgb
      cat << \EndOnERR
ERROR:ECF_ABORT_HM
</PRE>
<PRE>
EndOnERR

   ecflow_client --abort=trap  # Notify ecFlow that something went wrong, using 'trap' as the reason
   trap 0                      # Remove the trap
   exit 1                      # End the script with exit code 1
}


# Trap any calls to exit and errors caught by the -e flag
trap ERROR 0


# Trap any signal that may cause the script to fail
trap '{ echo "Killed by a signal"; ERROR ; }' 1 2 3 4 5 6 7 8 10 12 13 15

#####################


TASK=%TASK%             export TASK
ECF_TRYNO=%ECF_TRYNO%   export ECF_TRYNO
HH=%HH%                 export HH
YMD=%YMD%               export YMD
HARMLBCS=%HARMLBCS%     export HARMLBCS
EXP=%EXP%               export EXP
# HH needs two characters. From that, define DTG etc
HH=`echo %HH% | awk '{printf "%%2.2d",$1}'`
DTG=%YMD%$HH                    export DTG

YY=`echo %YMD% | awk '{print substr($1,1,4)}'`
MM=`echo %YMD% | awk '{print substr($1,5,2)}'`
DD=`echo %YMD% | awk '{print substr($1,7,2)}'`
export YY MM DD

export ECF_PARENT ECF_GRANDPARENT
ECF_PARENT=$( perl -e "@_=split('/','$ECF_NAME');"'print $_[$#_-1]' )
ECF_GRANDPARENT=$( perl -e "@_=split('/','$ECF_NAME');"'print $_[$#_-2]' )

# Source config
. %HARMLBCS%/share/config/config.%LBC_CONFIG%
