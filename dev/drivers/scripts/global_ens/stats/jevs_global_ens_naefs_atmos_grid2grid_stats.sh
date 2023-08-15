#PBS -N jevs_global_ens_naefs_atmos_grid2grid_stats
#PBS -j oe
#PBS -S /bin/bash
#PBS -q dev
#PBS -A VERF-DEV
#PBS -l walltime=00:30:00
#PBS -l place=vscatter:exclhost,select=1:ncpus=4:mem=100GB
#PBS -l debug=true


export OMP_NUM_THREADS=1
# 2 processes (naefs/upper) + 1 (24h apcp)
#
set -x

export HOMEevs=/lfs/h2/emc/vpppg/noscrub/${USER}/EVS

source $HOMEevs/versions/run.ver

export NET=evs
export RUN=atmos
export STEP=stats
export COMPONENT=global_ens
export VERIF_CASE=grid2grid
export MODELNAME=naefs


module reset
module load prod_envir/${prod_envir_ver}

source $HOMEevs/modulefiles/$COMPONENT/${COMPONENT}_${STEP}.sh





export KEEPDATA=YES


export cyc=00
export COMIN=/lfs/h2/emc/vpppg/noscrub/${USER}/$NET/$evs_ver
export COMOUT=/lfs/h2/emc/vpppg/noscrub/${USER}/$NET/$evs_ver
export FIXevs=/lfs/h2/emc/vpppg/noscrub/emc.vpppg/verification/EVS_fix
export DATA=/lfs/h2/emc/stmp/${USER}/evs/tmpnwprd
export job=${PBS_JOBNAME:-jevs_${MODELNAME}_${VERIF_CASE}_${STEP}}
export jobid=$job.${PBS_JOBID:-$$}

export gefs_number=20

export maillist='geoffrey.manikin@noaa.gov,binbin.zhou@noaa.gov'

${HOMEevs}/jobs/global_ens/stats/JEVS_GLOBAL_ENS_STATS
