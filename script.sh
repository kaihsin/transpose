#!/bin/bash

#SBATCH --gres=gpu:1
#SBATCH --partition=gtest
#SBATCH --account=ACD109079
#SBATCH --error=slurm-%j.err
#SBATCH --output=slurm-%j.out

starttime=`date +%s.%N`

p=2
for i in `seq 3 4`; do
  b=$((1<<$i))

  ./cutt --datname=cutt-tebd-psi.dat   --bond=$b --size=$p,$b,$p,$b --perm=1,0,2,3
  ./cutensor --datname=cutensor-tebd-theta.dat --bond=$b --size=$p,$p,$b,$b --perm=2,0,1,3

done


endtime=`date +%s.%N`
runtime=`echo $endtime - $starttime | bc -l`
echo took $runtime seconds

