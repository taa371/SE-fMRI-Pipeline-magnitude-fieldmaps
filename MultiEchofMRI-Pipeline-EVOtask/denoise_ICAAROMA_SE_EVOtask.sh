#!/bin/bash
# Identification & removal of artifacts via ICA-AROMA (part of the SE denoising pipeline)
# Charles Lynch, Hussain Bukhari, Holland Brown
# Updated 2024-05-24

# assign initial variables 
MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"
AtlasTemplate=$4
DOF=$5
NTHREADS=$6
StartSession=$7
AromaPyDir=$8
TaskName=$9

# load modules 
rm "$Subdir"/AllScans.txt # remove intermediate file
#module load python-3.7.7-gcc-8.2.0-onbczx6

module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load fsl/6.0.4
module load afni/afni
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a
module unload python

# count the number of sessions
sessions=("$Subdir"/func/unprocessed/task/"$TaskName"/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions
for s in $sessions ; do
	# count number of runs for this session
	runs=("$Subdir"/func/unprocessed/task/"$TaskName"/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")
	for r in $runs ; do
		echo "session_$s/run_$r" >> "$Subdir"/AllScans.txt  
        echo 4 >> "$Subdir"/func/unprocessed/task/"$TaskName"/session_"$s"/run_"$r"/rmVols.txt
	done
done

# define a list of directories
AllScans=$(cat "$Subdir"/AllScans.txt) # NOTE: this is used for parallel processing purposes
# rm "$Subdir"/AllScans.txt # remove intermediate file

# func --------------------
for s in $AllScans ; do

	echo -e "$s"

	python2.7 /athena/victorialab/scratch/hob4003/ME_Pipeline/ICA-AROMA-master/ICA_AROMA.py -in "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E1_acpc.nii.gz -out "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_ICAAROMA.nii.gz -m "$Subdir"/func/xfms/"$TaskName"/T1w_nonlin_brain_func_mask.nii.gz -mc "$Subdir"/func/"$TaskName"/"$s"/MCF.par -dim 30 -den 'aggr'

done 
# end function ------------

# TEST: run on 1 subject, 1 session
#python2.7 /athena/victorialab/scratch/hob4003/ME_Pipeline/ICA-AROMA-master/ICA_AROMA.py -in /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/task/"$TaskName"/session_1/run_1/"$TaskName"_E1_acpc.nii.gz -out /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/task/"$TaskName"/session_1/run_1/"$TaskName"_E1_AROMA.nii.gz -m /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/xfms/"$TaskName"T1w_nonlin_brain_func_mask.nii.gz -mc /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/task/"$TaskName"/session_1/run_1/MCF.par -dim 30 -den 'aggr'
