#SBATCH  --qos=normal
#SBATCH  --get-user-env
#SBATCH  --export=NONE
#SBATCH  --error=/dev/null
#SBATCH  --output=/dev/null
#SBATCH  --job-name=%TASK%
#SBATCH  --workdir=%ECF_HOME%

JOBOUT=%ECF_JOBOUT%
exec 1>$JOBOUT 2>&1


