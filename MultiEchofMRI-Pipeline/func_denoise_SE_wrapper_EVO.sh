#!/bin/bash
# Denoise Functional Data (3rd of 3 wrappers in the ME pipeline); Single-Echo Version
# Hussain Bukhari, Holland Brown
# Updated 2023-09-13

StudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage)
StartSession=$4

RunMGTR=false # NOTE: PIs decided not to run MGTR script for EVO study (see Chuck's papers on gray-ordinates for more info)
RunICAAroma=true # Motion correction and artifact identification (run this for EVO participants)
Vol2FirstSurf=true # project denoised volumes onto a surface
SmoothVol2SecondSurf=false # additional 1.75 mm smoothing before projecting onto a second surface

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

# ---------------------- Begin Denoising Pipeline ----------------------

echo -e "Denoising Pipeline: AROMA + MGTR + smooth + vol2surf"

# Run ICA-AROMA for motion correction and artifact identification
if [ $RunICAAroma == true ]; then
	echo -e "Running ICA-AROMA for Subject {$2}..."
	"$MEDIR"/ICAAROMA_SE_denoise_DE_FMs.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"
fi

# Run MGTR for further smoothing using gray-ordinates (do not run for EVO)
if [ $RunMGTR == true ]; then
	echo -e "Running MGTR for Subject {$2}..."
	"$MEDIR"/func_denoise_mgtr_SE_EVO.sh "$Subject" "$StudyFolder" "$MEDIR" "$CiftiList2"
fi

# Project ICA-AROMA output volumes onto a surface
if [ $Vol2FirstSurf == true ]; then
	echo -e "Projecting ICAAROMA-corrected volumes onto surface for Subject {$2}..."
	"$MEDIR"/func_vol2surf.sh "$Subject" "$StudyFolder" "$MEDIR" "$CiftiList3" $StartSession
fi

# 1.75 mm smoothing before projecting onto another surface (haven't decided whether to run for EVO yet)
if [ $SmoothVol2SecondSurf == true ]; then
	echo -e "Smoothing and projecting onto surface for subject {$2}..."
	"$MEDIR"/func_smooth.sh "$Subject" "$StudyFolder" "1.75" "$CiftiList3"
fi

