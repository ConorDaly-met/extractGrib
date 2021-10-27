# Specific HPC commands go here
# This header is for low-resource cleaning tasks
# use qsub.h for resource-intensive extraction tasks
#PBS -q ns
#PBS -l EC_total_tasks=1
#PBS -l EC_tasks_per_node=1
#PBS -A uwcwecds
#PBS -v OMP_NUM_THREADS=1
#PBS -l EC_threads_per_task=1
#PBS -j oe
#PBS -N %TASK%
#PBS -m n
#PBS -o /dev/null

JOBOUT=`echo "%ECF_JOBOUT%" | sed -e "s/^\/hpc//"`

exec 1>$JOBOUT 2>&1
