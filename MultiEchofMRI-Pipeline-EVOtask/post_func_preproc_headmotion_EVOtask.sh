#!/bin/bash
# Chuck Lynch, Hussain Bukhari, Holland Brown
# Updated 2023-12-05

# Calculate frame-wise displacement and generate stop-motion movies summarizing motion and respiration parameters and show minimally preprocessed images

MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"
AtlasTemplate=$4
DOF=$5
NTHREADS=$6
StartSession=$7

module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load python-3.7.7-gcc-8.2.0-onbczx6
module load fsl/6.0.4
module load afni/afni
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a


# fresh workspace dir.
 rm -rf "$Subdir"/workspace/  
 mkdir "$Subdir"/workspace/  

# create & define the "MotionQA" folder;
 rm -rf "$Subdir"/func/floop/qa/MotionQA 
 mkdir -p "$Subdir"/func/floop/qa/MotionQA 

# create a temp. "motion_qa.m"
 cp -rf "$MEDIR"/res0urces/motion_qa_EVOfloop.m "$Subdir"/workspace/temp.m

# define some Matlab variables
echo "addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m >> "$Subdir"/workspace/tmp.m && mv "$Subdir"/workspace/tmp.m "$Subdir"/workspace/temp.m   
echo Subdir=["'$Subdir'"] | cat - "$Subdir"/workspace/temp.m >> "$Subdir"/workspace/tmp1.m && mv "$Subdir"/workspace/tmp1.m "$Subdir"/workspace/temp.m 
echo StartSession="$StartSession" | cat - "$Subdir"/workspace/temp.m >> "$Subdir"/workspace/tmp2.m && mv "$Subdir"/workspace/tmp2.m "$Subdir"/workspace/temp.m   		
cd "$Subdir"/workspace/ # run script via Matlab 
matlab -nodesktop -nosplash -r "temp; exit" 

# delete temp. workspace
rm -rf "$Subdir"/workspace