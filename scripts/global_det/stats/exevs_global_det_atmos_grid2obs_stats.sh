#!/bin/sh
###############################################################################
# Name of Script: exevs_global_det_atmos_grid2obs_stats.sh 
# Purpose of Script: This script generates grid-to-observations
#                    verification statistics using METplus for the
#                    atmospheric component of global deterministic models
# Log history:
###############################################################################

set -x

export VERIF_CASE_STEP_abbrev="g2os"

# Set run mode
if [ $RUN_ENVIR = nco ]; then
    export evs_run_mode="production"
    source $config
else
    export evs_run_mode=$evs_run_mode
fi
echo "RUN MODE:$evs_run_mode"

# Make directory
mkdir -p ${VERIF_CASE}_${STEP}

# Check user's config settings
python $USHevs/global_det/global_det_atmos_check_settings.py
status=$?
[[ $status -ne 0 ]] && exit $status
[[ $status -eq 0 ]] && echo "Succesfully ran global_det_atmos_check_settings.py"
echo

# Create output directories
python $USHevs/global_det/global_det_atmos_create_output_dirs.py
status=$?
[[ $status -ne 0 ]] && exit $status
[[ $status -eq 0 ]] && echo "Succesfully ran global_det_atmos_create_output_dirs.py"
echo

# Link needed data files and set up model information
python $USHevs/global_det/global_det_atmos_get_data_files.py
status=$?
[[ $status -ne 0 ]] && exit $status
[[ $status -eq 0 ]] && echo "Succesfully ran global_det_atmos_get_data_files.py"
echo

# Create job scripts data
python $USHevs/global_det/global_det_atmos_stats_grid2obs_create_job_scripts.py
status=$?
[[ $status -ne 0 ]] && exit $status
[[ $status -eq 0 ]] && echo "Succesfully ran global_det_atmos_stats_grid2obs_create_job_scripts.py"

# Run job scripts for reformat, generate, and gather
for group in reformat generate gather; do
    chmod u+x ${VERIF_CASE}_${STEP}/METplus_job_scripts/$group/*
    group_ncount_job=$(ls -l  ${VERIF_CASE}_${STEP}/METplus_job_scripts/$group/job* |wc -l)
    nc=1
    if [ $USE_CFP = YES ]; then
        group_ncount_poe=$(ls -l  ${VERIF_CASE}_${STEP}/METplus_job_scripts/$group/poe* |wc -l)
        while [ $nc -le $group_ncount_poe ]; do
            poe_script=$DATA/${VERIF_CASE}_${STEP}/METplus_job_scripts/$group/poe_jobs${nc}
            chmod 775 $poe_script
            export MP_PGMMODEL=mpmd
            export MP_CMDFILE=${poe_script}
            if [ $machine = WCOSS2 ]; then
                export LD_LIBRARY_PATH=/apps/dev/pmi-fix:$LD_LIBRARY_PATH
                launcher="mpiexec -np ${nproc} -ppn ${nproc} --cpu-bind verbose,depth cfp"
            elif [ $machine = HERA -o $machine = ORION -o $machine = S4 -o $machine = JET ]; then
                export SLURM_KILL_BAD_EXIT=0
                launcher="srun --export=ALL --multi-prog"
            fi
            $launcher $MP_CMDFILE
            nc=$((nc+1))
        done
    else
        while [ $nc -le $group_ncount_job ]; do
            sh +x $DATA/${VERIF_CASE}_${STEP}/METplus_job_scripts/$group/job${nc}
            nc=$((nc+1))
        done
    fi
done

# Copy files to desired location
if [ $SENDCOM = YES ]; then
    # Copy atmos
    for RUN_DATE_PATH in $DATA/${VERIF_CASE}_${STEP}/METplus_output/$RUN.*; do
        RUN_DATE_DIR=$(echo ${RUN_DATE_PATH##*/})
        for RUN_DATE_SUBDIR_PATH in $DATA/${VERIF_CASE}_${STEP}/METplus_output/$RUN_DATE_DIR/*; do
            RUN_DATE_SUBDIR=$(echo ${RUN_DATE_SUBDIR_PATH##*/})
            for FILE in $RUN_DATE_SUBDIR_PATH/$VERIF_CASE/*; do
                cp -v $FILE $COMOUT/$RUN_DATE_DIR/$RUN_DATE_SUBDIR/$VERIF_CASE/.
            done
        done
    done
    # Copy model files
    for MODEL in $model_list; do
        for MODEL_DATE_PATH in $DATA/${VERIF_CASE}_${STEP}/METplus_output/$MODEL.*; do
            MODEL_DATE_SUBDIR=$(echo ${MODEL_DATE_PATH##*/})
            for FILE in $DATA/${VERIF_CASE}_${STEP}/METplus_output/$MODEL_DATE_SUBDIR/*; do
                cp -v $FILE $COMOUT/$MODEL_DATE_SUBDIR/.
            done
        done
    done
fi

# Non-production jobs
if [ $evs_run_mode != "production" ]; then
    # Send data to archive
    if [ $SENDARCH = YES ]; then
        python $USHevs/global_det/global_det_atmos_copy_to_archive.py
        status=$?
        [[ $status -ne 0 ]] && exit $status
        [[ $status -eq 0 ]] && echo "Succesfully ran global_det_atmos_copy_to_archive.py"
        echo
    fi
    # Send data to METviewer AWS server
    if [ $SENDMETVIEWER = YES ]; then
        python $USHevs/global_det/global_det_atmos_load_to_METviewer_AWS.py
        status=$?
        [[ $status -ne 0 ]] && exit $status
        [[ $status -eq 0 ]] && echo "Succesfully ran global_det_atmos_load_to_METviewer_AWS.py"
        echo
    else
        # Clean up
        if [ $KEEPDATA != "YES" ] ; then
            cd $DATAROOT
            rm -rf $DATA
        fi
    fi
fi
