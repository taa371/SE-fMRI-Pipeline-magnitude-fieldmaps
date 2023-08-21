#!/bin/bash
# Hussain Bukhari
# Holland Brown
# This script submits parallel anatomical slurm jobs for all subjects in subjectlist.txt
# Minimum inputs needed after /path/to/wrapper: (1) /path/to/data/folder; (2) subject ID; (3) TE, i.e. dwell time; (4) magnitude field map; (5) phase field map; (6) number of threads

TE="4.901" # NOTE: For EVO study, UW TE is 4.901 ms, NKI TE is 2.46 ms
MagnitudeInputName="NONE" # The MagnitudeInputName variable should be set to a 4D magnitude volume with two 3D timepoints or "NONE" if not used
PhaseInputName="NONE"
#MagnitudeInputName="FM_mag_S1_R1.nii.gz" # The MagnitudeInputName variable should be set to a 4D magnitude volume with two 3D timepoints or "NONE" if not used
#PhaseInputName="FM_rads_S1_R1.nii.gz" # The PhaseInputName variable should be set to a 3D phase difference volume or "NONE" if not used

for i in $(cat subjectlist.txt); do 

  TMP=$(echo $i)

  sbatch --mem=64G --partition=scu-cpu --wrap="/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline/anat_highres_HCP_wrapper_par_EVO.sh /athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data ${TMP} $TE $MagnitudeInputName $PhaseInputName 30"

done