#!/bin/bash
# HRB; (hob4003@med.cornell.edu)
# Updated 2023-08-18

StudyFolder=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data # location of Subject folder
Subject=W235 # space delimited list of subject IDs (format like W001, W002, etc.)
Sessions=$(cat "$StudyFolder"/Sessions.txt)
TE=2.399 # Difference in echo times; in EVO study, UW TE = 2.399, NKI TE = 2.46 

# module load python-3.7.7-gcc-8.2.0-onbczx6
# module load fsl/6.0.4

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

# Move intermediate and raw FMs into new folder, "intermediate"
for s in $Sessions; do

    # create /intermediate subdir if it does not exist
    if [ ! -d "$FieldMapFolder"/intermediate/ ]; then
        mkdir "$FieldMapFolder"/intermediate/
    fi

    # check one more time that /intermediate subdir exists; break loop if it doesn't
    if [ ! -d "$FieldMapFolder"/intermediate/ ]; then
        echo -e "ERROR: Failed to create subdirectory.\nBreaking loop without moving files."
        break
    fi

    for f in "$FieldMapFolder"/; do # iterate through NIFTI files in FM dir

        FinalPhase="$FieldMapFolder"/FM_rads_S"$s"_R1.nii.gz # final phase image fn
        FinalMag="$FieldMapFolder"/FM_mag_S"$s"_R1.nii.gz # final magnitude image fn

        # if file is not one of the final output FMs, move it to /intermediate subdir
        if [[ "$f" != "$FinalPhase" ]] && [[ "$f" != "$FinalMag" ]]; then
            mv "$f" "$FieldMapFolder"/intermediate/
        fi

    done

done