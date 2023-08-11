#!/bin/bash
# syb4001
# hob4003

StudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage);

# Load modules 
# define the 
# starting point 
if [ -z "$4" ]
	then
	    StartSession=1
	else
	    StartSession=$4
fi

module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load fsl/6.0.4
module load afni/afni
module load python-3.7.7-gcc-8.2.0-onbczx6
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a

# reformat subject folder path;
if [ "${StudyFolder: -1}" = "/" ]; then
	StudyFolder=${StudyFolder%?};
fi

# define subject directory;
Subdir="$StudyFolder"/"$Subject"

# define some directories containing 
# custom matlab scripts and various atlas files;
MEDIR="/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline"
CiftiList1="$MEDIR"/config/EVO_CiftiList_MGTR.txt # .txt file containing list of files on which to perform MGTR before ICA-AROMA (use if you intend to skip ICA-AROMA entirely)
CiftiList2="$MEDIR"/config/EVO_CiftiList_ICAAROMA.txt # .txt file containing list of files on which to perform MGTR after ICA-AROMA
CiftiList3="$MEDIR"/config/EVO_CiftiList_ICAAROMA+MGTR.txt # .txt file containing list of files to be mapped to surface. user can specify OCME, OCME+MEICA, OCME+MEICA+MGTR, and/or OCME+MEICA+MGTR_Betas

# these variables should not be changed unless you have a very good reason
DOF=6 # this is the degrees of freedom (DOF) used for SBref --> T1w and EPI --> SBref coregistrations;
AtlasTemplate="$MEDIR/res0urces/FSL/MNI152_T1_2mm_brain.nii.gz" # define a lowres MNI template; 
AtlasSpace="T1w" # define either native space ("T1w") or MNI space ("MNINonlinear")

EnvironmentScript="/athena/victorialab/scratch/hob4003/ME_Pipeline/Hb_HCP_master/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script
source ${EnvironmentScript}	# Set up pipeline environment variables and software
PATH=$PATH:/usr/lib/python2.7/site-packages # added this to find python 2.7 packages

# Testing ------------------------------------------------------------------------------

echo -e "Denoising Pipeline: AROMA + MGTR + smooth + vol2surf"

# OPTION 1: perform signal-decay denoising on pre-ICAAROMA files (do this to skip AROMA altogether)
# echo -e "MGTR without ICA-AROMA for subject {$2}..."
#"$MEDIR"/func_denoise_mgtr_SE.sh "$Subject" "$StudyFolder" \
#"$MEDIR" "$CiftiList1" # pre-AROMA Ciftilist

# OPTION 2, step 1: ICA AROMA signal denoising for Single-Echo data
# echo -e "ICA-AROMA for subject {$2}..."
#"$MEDIR"/ICAAROMA_SE_denoise_DE_FMs.sh "$MEDIR" "$Subject" "$StudyFolder" \
#"$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

# OPTION 2, step 2: perform signal-decay denoising on post-ICAAROMA files
echo -e "Post-AROMA MGTR for subject {$2}..."
"$MEDIR"/func_denoise_mgtr_SE.sh "$Subject" "$StudyFolder" \
"$MEDIR" "$CiftiList2" # post-AROMA CiftiList

# project AROMA output volumes onto a surface
#echo -e "Project volumes to surface for subject {$2}..."
#"$MEDIR"/func_vol2surf.sh "$Subject" "$StudyFolder" \
#"$MEDIR" "$CiftiList3" "1"

# 1.75 mm smoothing before projecting onto a surface
#echo -e "Smooth and project to surface for subject {$2}..."
#"$MEDIR"/func_smooth.sh "$Subject" "$StudyFolder" "1.75" "$CiftiList3"