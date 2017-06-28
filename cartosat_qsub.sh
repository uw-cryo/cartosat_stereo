#! /bin/bash

jobscript=$SRCDIR/pbs_scripts/singlepair.pbs

dirlist=$(ls -d 17*)
for i in $dirlist
do
    qsub -N $i -v pair=$i -q normal -lselect=1:ncpus=20:model=ivy,walltime=2:00:00 $jobscript
done
