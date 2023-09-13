#!/bin/bash
# ICA-AROMA Artifact Identification and Removal (part of the denoising pipeline)
# Hussain Bukhari, Holland Brown
# Updated 2023-09-13

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

echo -e $PATH

# count the number of sessions
sessions=("$Subdir"/func/unprocessed/rest/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions
for s in $sessions ; do
	# count number of runs for this session
	runs=("$Subdir"/func/unprocessed/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")
	for r in $runs ; do
		echo "session_$s/run_$r" >> "$Subdir"/AllScans.txt  
        echo 10 >> "$Subdir"/func/unprocessed/rest/session_"$s"/run_"$r"/rmVols.txt
	done
done

# define a list of directories
AllScans=$(cat "$Subdir"/AllScans.txt) # NOTE: this is used for parallel processing purposes
# rm "$Subdir"/AllScans.txt # remove intermediate file

# func --------------------
for s in $AllScans ; do

	echo -e "$s"

	python2.7 /athena/victorialab/scratch/hob4003/ME_Pipeline/ICA-AROMA-master/ICA_AROMA.py -in "$Subdir"/func/rest/"$s"/Rest_E1_acpc.nii.gz -out "$Subdir"/func/rest/"$s"/Rest_ICAAROMA.nii.gz -m "$Subdir"/func/xfms/rest/T1w_nonlin_brain_func_mask.nii.gz -mc "$Subdir"/func/rest/"$s"/MCF.par -dim 30 -den 'aggr'

# TEST
#python2.7 /athena/victorialab/scratch/hob4003/ME_Pipeline/ICA-AROMA-master/ICA_AROMA.py -in /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/rest/session_1/run_1/Rest_E1_acpc.nii.gz -out /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/rest/session_1/run_1/Rest_E1_AROMA.nii.gz -m /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/xfms/rest/T1w_nonlin_brain_func_mask.nii.gz -mc /athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/97043/func/rest/session_1/run_1/MCF.par -dim 30 -den 'aggr'

done 
# end function ------------

# TEST: see if I can get parallelize to work in my cluster env
# func () {
# 	echo -e "CHECK:\n\tSubdir=$2\n\tAtlasTemplate=$4\n\tAllScans=$6\n\tAromaPyDir=$7" # check vbls were properly handed off to new env

# 	python2.7 "$7"/ICA_AROMA.py -in "$2"/func/rest/"$6"/Rest_E1_acpc.nii.gz -out "$2"/func/rest/"$6"/Rest_E1_AROMA.nii.gz -m "$2"/func/xfms/rest/T1w_nonlin_brain_func_mask.nii.gz -mc "$2"/func/rest/"$6"/MCF.par -dim 30 -den 'aggr'  

# }
# export -f func
# parallel --jobs $NTHREADS func ::: $MEDIR ::: $Subdir ::: $Subject ::: $AtlasTemplate ::: $DOF ::: $AllScans ::: $AromaPyDir