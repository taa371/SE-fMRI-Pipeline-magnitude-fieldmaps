#!/bin/bash
# Denoise Functional Data (3rd of 3 wrappers in the ME pipeline); Multi-Echo Version
# Chuck Lynch, Hussain Bukhari
# Updated 2023-05-04 

StudyFolder=$1 # location of Subject folder
Subject=$2 #  subject / folder name;
NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage);
StartSession=$4

# Load modules
module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load fsl/6.0.4
module load afni/afni
module load python/3.9.0
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a



# ME-ICA options;
MEPCA=kundu # set the pca decomposition method (see "tedana -h" for more information)
MaxIterations=500 
MaxRestarts=10

# reformat subject folder path  
if [ "${StudyFolder: -1}" = "/" ]; then
	StudyFolder=${StudyFolder%?};
fi

# define subject directory;
Subdir="$StudyFolder"/"$Subject"

# define some directories containing 
# custom matlab scripts and various atlas files;
MEDIR="REPME/MEF-P-HB/MultiEchofMRI-Pipeline"
DOF=6 # this is the degrees of freedom (DOF) used for SBref --> T1w and EPI --> SBref coregistrations;
CiftiList="$MEDIR"/config/CiftiList.txt # .txt file containing list of files to be mapped to surface. user can specify OCME, OCME+MEICA, OCME+MEICA+MGTR, and/or OCME+MEICA+MGTR_Betas
KernelList="$MEDIR"/config/KernelSize.txt # 
AtlasTemplate="$MEDIR/res0urces/FSL/MNI152_T1_2mm.nii.gz" # define a lowres MNI template
AtlasSpace="T1w" # define either native space ("T1w") or MNI space ("MNINonlinear")

# set variable value that sets up environment
EnvironmentScript="REPME/Hb_HCP_master/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script
source ${EnvironmentScript}	# Set up pipeline environment variables and software

echo -e "\nMulti-Echo Preprocessing & Denoising Pipeline" 

echo -e "Performing Signal-Decay Based Denoising"

# perform signal-decay denoising; 
"$MEDIR"/func_denoise_meica.sh "$Subject" "$StudyFolder" "$NTHREADS" \
"$MEPCA" "$MaxIterations" "$MaxRestarts" "$StartSession"

echo -e "Removing Spatially Diffuse Noise via MGTR"

# remove spatially diffuse noise; 
"$MEDIR"/func_denoise_mgtr.sh "$Subject" \
"$StudyFolder" "$MEDIR" "$StartSession"

echo -e "Mapping Denoised Functional Data to Surface"

# perform signal-decay denoising; 
"$MEDIR"/func_vol2surf.sh "$Subject" "$StudyFolder" \
"$MEDIR" "$CiftiList" "$StartSession"