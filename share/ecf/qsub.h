#PBS -q nf
#PBS -l EC_total_tasks=1
#PBS -l EC_tasks_per_node=1
#PBS -l EC_memory_per_task=30000MB 
#PBS -A uwcwecds
#PBS -v OMP_NUM_THREADS=12
#PBS -l EC_threads_per_task=12
#PBS -j oe
#PBS -N %TASK%
#PBS -m n
#PBS -o /dev/null

JOBOUT=`echo "%ECF_JOBOUT%" | sed -e "s/^\/hpc//"`

exec 1>$JOBOUT 2>&1
