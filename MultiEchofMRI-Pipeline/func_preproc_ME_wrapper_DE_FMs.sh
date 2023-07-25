#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)

StudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage);

# Load modules define the starting point 
StartSession=$4

module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load python-3.7.7-gcc-8.2.0-onbczx6
module load fsl/6.0.4
module load afni/afni
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

# these variables should not be changed unless you have a very good reason
DOF=6 # this is the degrees of freedom (DOF) used for SBref --> T1w and EPI --> SBref coregistrations;
AtlasTemplate="$MEDIR/res0urces/FSL/MNI152_T1_2mm.nii.gz" # define a lowres MNI template; 
AtlasSpace="T1w" # define either native space ("T1w") or MNI space ("MNINonlinear")

# set variable value that sets up environment
EnvironmentScript="/athena/victorialab/scratch/hob4003/ME_Pipeline/Hb_HCP_master/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script
source ${EnvironmentScript}	# Set up pipeline environment variables and software

echo -e "\nMulti-Echo Preprocessing & Denoising Pipeline"

# ---------------------------------------------------------------------------------------
echo -e "\nProcessing the Field Maps"

# process all field maps & create an average image 
# for cases where scan-specific maps are unavailable;
"$MEDIR"/func_preproc_fm_DE_FMs.sh "$MEDIR" "$Subject" \
"$StudyFolder" "$NTHREADS"

#echo -e "\n Post Processing the Field Maps"
# leave commented out - this is redundant with last code block in func_preproc_fm.sh
# "$MEDIR"/post_func_preproc_fm.sh "$MEDIR" "$Subject" \
# "$StudyFolder" "$NTHREADS"

echo -e "Coregistering SBrefs to the Anatomical Image"

# create an avg. sbref image and co-register that 
image & all individual SBrefs to the T1w image;
"$MEDIR"/func_preproc_coreg_DE_FMs.sh "$MEDIR" "$Subject" "$StudyFolder" \
"$AtlasTemplate" "$DOF" "$NTHREADS"

echo -e "\nDone.\n"

# ---------------------------------------------------------------------------------------
#echo -e "Correcting for Slice Time Differences, Head Motion, & Spatial Distortion"

# correct func images for slice time differences and head motion;
#"$MEDIR"/func_preproc_headmotion.sh "$MEDIR" "$Subject" "$StudyFolder" \
#"$AtlasTemplate" "$DOF" "$NTHREADS" 
#echo -e " Unobjective for Slice Time Differences, Head Motion, & Spatial Distortion"


# correct func images for slice time differences and head motion;
#"$MEDIR"/unobjective.sh "$MEDIR" "$Subject" "$StudyFolder" \
#"$AtlasTemplate" "$DOF" "$NTHREADS" 