#!/bin/bash
# HRB; (hob4003@med.cornell.edu)

StudyFolder=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data # location of Subject folder
Subject=W235 # space delimited list of subject IDs (format like W001, W002, etc.)
# NTHREADS=$3 # set number of threads
Sessions=$(cat "$StudyFolder"/Sessions.txt)
TE=2.46
# ClusterDir=

# module load python-3.7.7-gcc-8.2.0-onbczx6
# module load fsl/6.0.4

# Fresh destination dir
# for s in $Sessions; do
#     cp "$StudyFolder"/"$Subject"/func/unprocessed/field_maps/S"$s"_AxialField_Mapping_e1_imaginary.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed
#     cp "$StudyFolder"/"$Subject"/func/unprocessed/field_maps/S"$s"_AxialField_Mapping_e2_imaginary.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed
#     cp "$StudyFolder"/"$Subject"/func/unprocessed/field_maps/S"$s"_AxialField_Mapping_e1_real.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed
#     cp "$StudyFolder"/"$Subject"/func/unprocessed/field_maps/S"$s"_AxialField_Mapping_e2_real.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed
#     cp "$StudyFolder"/"$Subject"/func/unprocessed/field_maps/S"$s"_AxialField_Mapping_imaginary_real.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed
# done

# rm -r "$StudyFolder"/"$Subject"/func/unprocessed/field_maps
# mkdir "$StudyFolder"/"$Subject"/func/unprocessed/field_maps

# for s in $Sessions; do
#     mv "$StudyFolder"/"$Subject"/func/unprocessed/S"$s"_AxialField_Mapping_e1_imaginary.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed/field_maps
#     mv "$StudyFolder"/"$Subject"/func/unprocessed/S"$s"_AxialField_Mapping_e2_imaginary.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed/field_maps
#     mv "$StudyFolder"/"$Subject"/func/unprocessed/S"$s"_AxialField_Mapping_e1_real.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed/field_maps
#     mv "$StudyFolder"/"$Subject"/func/unprocessed/S"$s"_AxialField_Mapping_e2_real.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed/field_maps
#     mv "$StudyFolder"/"$Subject"/func/unprocessed/S"$s"_AxialField_Mapping_imaginary_real.nii.gz "$StudyFolder"/"$Subject"/func/unprocessed/field_maps
# done

FieldMapFolder="$StudyFolder"/"$Subject"/func/unprocessed/field_maps

for s in $Sessions; do

    # Step 1: merge the real field maps from the different echoes
    fslmerge -t "$FieldMapFolder"/S"$s"_real_merge "$FieldMapFolder"/S"$s"_AxialField_Mapping_e1_real.nii.gz "$FieldMapFolder"/S"$s"_AxialField_Mapping_e2_real.nii.gz

    # Step 2: merge the imaginary field maps from the different echoes
    fslmerge -t "$FieldMapFolder"/S"$s"_imag_merge "$FieldMapFolder"/S"$s"_AxialField_Mapping_e1_imaginary.nii.gz "$FieldMapFolder"/S"$s"_AxialField_Mapping_e2_imaginary.nii.gz

    # Step 3: Combine real and imaginary merged images into a complex image
    fslcomplex -complex "$FieldMapFolder"/S"$s"_real_merge "$FieldMapFolder"/S"$s"_imag_merge "$FieldMapFolder"/S"$s"_complex

    # Step 4: Extract magnitude image from the complex image
    fslcomplex -realabs "$FieldMapFolder"/S"$s"_complex "$FieldMapFolder"/FM_mag_S"$s"_R1.nii.gz 0 1 # final output magnitude image

    # Step 5: Extract two phase images from the complex image
    fslcomplex -realphase "$FieldMapFolder"/S"$s"_complex "$FieldMapFolder"/S"$s"_phase0_rad 0 1
    fslcomplex -realphase "$FieldMapFolder"/S"$s"_complex "$FieldMapFolder"/S"$s"_phase1_rad 1 1

    # Step 6: Unwrap the phase images
    prelude -a "$FieldMapFolder"/FM_mag_S"$s"_R1.nii.gz -p "$FieldMapFolder"/S"$s"_phase0_rad -o "$FieldMapFolder"/S"$s"_phase0_unwrapped_rad
    prelude -a "$FieldMapFolder"/FM_mag_S"$s"_R1.nii.gz -p "$FieldMapFolder"/S"$s"_phase1_rad -o "$FieldMapFolder"/S"$s"_phase1_unwrapped_rad

    # Step 7: Subtract phase images, multiply by 1000 and divide by the TE to get a combined phase image
    fslmaths "$FieldMapFolder"/S"$s"_phase0_unwrapped_rad -sub "$FieldMapFolder"/S"$s"_phase1_unwrapped_rad -mul 1000 -div $TE "$FieldMapFolder"/S"$s"_fieldmap_rad -odt float

    # Step 8: Use FSL Fugue to smooth the phase images
    fugue --loadfmap="$FieldMapFolder"/S"$s"_fieldmap_rad -s 1 --savefmap="$FieldMapFolder"/S"$s"_fieldmap_rad
    fugue --loadfmap="$FieldMapFolder"/S"$s"_fieldmap_rad --despike --savefmap="$FieldMapFolder"/S"$s"_fieldmap_rad
    fugue --loadfmap="$FieldMapFolder"/S"$s"_fieldmap_rad -m --savefmap="$FieldMapFolder"/FM_rads_S"$s"_R1.nii.gz # final output phase image

done