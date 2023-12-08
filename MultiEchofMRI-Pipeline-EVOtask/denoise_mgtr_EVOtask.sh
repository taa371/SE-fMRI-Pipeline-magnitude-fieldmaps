#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# HB; (syb4001@med.cornell.edu)
# HRB; (hob4003@med.cornell.edu)
# Grayordinate smoothing and denoising
# Updated 2023-08-18

Subject=$1
StudyFolder=$2
Subdir="$StudyFolder"/"$Subject"
MEDIR=$3
CiftiList=$(cat $4)
TaskName=$5


module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load fsl/6.0.4
module load afni/afni
module load python-3.7.7-gcc-8.2.0-onbczx6
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a



# fresh workspace dir.
rm -rf "$Subdir"/workspace/ > /dev/null 2>&1 
mkdir "$Subdir"/workspace/ > /dev/null 2>&1 
		cd "$Subdir"/workspace/ # perform mgtr using Matlab

# count the number of sessions
sessions=("$Subdir"/func/task/"$TaskName"/session_*)
sessions=$(seq 1 1 "${#sessions[@]}")

# sweep the sessions
for s in $sessions ; do

	# count number of runs for this session
	runs=("$Subdir"/func/task/"$TaskName"/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}" )

	# sweep the runs
	for r in $runs ; do
        for c in $CiftiList ; do
        echo -e " this is sub $1 session $s run $r cifti $c"
		# create temporary mgtr_volume.m 
		cp -rf "$MEDIR"/res0urces/mgtr_volume.m \
		"$Subdir"/workspace/temp.m

		# define some Matlab variables
		echo Input=["'$Subdir/func/task/"$TaskName"/session_$s/run_$r/"$c".nii.gz'"] | cat - "$Subdir"/workspace/temp.m > temp && mv temp "$Subdir"/workspace/temp.m
		echo Subdir=["'$Subdir'"]  | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m
		echo Output_MGTR=["'$Subdir/func/task/"$TaskName"/session_$s/run_$r/"$c"+MGTR'"] | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m
		echo Output_Betas=["'$Subdir/func/task/"$TaskName"/session_$s/run_$r/"$c"+MGTR_Betas'"] | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m
		echo "addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m

		matlab -nodesktop -nosplash -r "temp; exit" #> /dev/null 2>&1	 
		#rm "$Subdir"/workspace/temp.m
        done
	done
	
done

# delete workspace dir.
#rm -rf "$Subdir"/workspace/ > /dev/null 2>&1 