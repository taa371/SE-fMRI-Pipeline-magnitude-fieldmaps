#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# hob4003; (hob4003@med.cornell.edu)

MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"
SUBJECTS_DIR="$Subdir"/anat/T1w # note: this is used for "bbregister" calls;
NTHREADS=$4
StartSession=$5
module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load python-3.7.7-gcc-8.2.0-onbczx6
module load fsl/6.0.4
module load afni/afni
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a

# fresh workspace dir.
rm -rf "$Subdir"/workspace/ > /dev/null 2>&1 
mkdir "$Subdir"/workspace/ > /dev/null 2>&1 

# create a temp "find_fm_params.m"
cp -rf "$MEDIR"/res0urces/find_fm_params.m \
"$Subdir"/workspace/temp.m

# define some Matlab variables
echo "addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m > temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1  
echo Subdir=["'$Subdir'"] | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1
echo StartSession="$StartSession" | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1  		
cd "$Subdir"/workspace/ # run script via Matlab 
matlab -nodesktop -nosplash -r "temp; exit" > /dev/null 2>&1  

# delete some files;
rm "$Subdir"/workspace/temp.m
cd "$Subdir" 

# count the number of sessions
sessions=("$Subdir"/func/unprocessed/rest/session_*)
sessions=$(seq 1 1 "${#sessions[@]}")

# sweep the sessions;
for s in $sessions ; do

	# count number of runs for this session;
	runs=("$Subdir"/func/unprocessed/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")

	# sweep the runs;
	for r in $runs ; do

		# check to see if this file exists or not;
		if [ -f "$Subdir/func/unprocessed/field_maps/FM_real_S"$s"_R"$r".nii.gz" ]; then

			# the "AllFMs.txt" file contains 
			# dir. paths to every pair of field maps;
			echo S"$s"_R"$r" >> "$Subdir"/AllFMs.txt  

		fi

	done

done

# define a list of directories;
AllFMs=$(cat "$Subdir"/AllFMs.txt)
rm "$Subdir"/AllFMs.txt # remove intermediate file;

# create a white matter segmentation (.mgz --> .nii.gz);
mri_binarize --i "$Subdir"/anat/T1w/"$Subject"/mri/aparc+aseg.mgz --wm --o "$Subdir"/anat/T1w/"$Subject"/mri/white.mgz > /dev/null 2>&1  # 2023-07-24 WORKED!
mri_convert -i "$Subdir"/anat/T1w/"$Subject"/mri/white.mgz -o "$Subdir"/anat/T1w/"$Subject"/mri/white.nii.gz --like "$Subdir"/anat/T1w/T1w_acpc_dc_restore.nii.gz > /dev/null 2>&1   # create a white matter segmentation (.mgz --> .nii.gz); # 2023-07-24 WORKED!

# create clean tmp. copy of freesurfer folder;
rm -rf "$Subdir"/anat/T1w/freesurfer > /dev/null 2>&1 
cp -rf "$Subdir"/anat/T1w/"$Subject" "$Subdir"/anat/T1w/freesurfer > /dev/null 2>&1 # 2023-07-24 WORKED!

# create & define the FM "library";
rm -rf "$Subdir"/func/field_maps/AllFMs > /dev/null 2>&1
mkdir -p "$Subdir"/func/field_maps/AllFMs > /dev/null 2>&1 # 2023-07-24 WORKED!
WDIR="$Subdir"/func/field_maps/AllFMs

# ---------------------------------------------------------------------------------------
for ThisFM in $AllFMs
do

    echo $ThisFM

    # copy over field map pair to workspace 
    cp -r "$Subdir"/func/unprocessed/field_maps/FM_real_"$ThisFM".nii.gz "$WDIR"/FM_real_"$ThisFM".nii.gz
    cp -r "$Subdir"/func/unprocessed/field_maps/FM_imaginary_"$ThisFM".nii.gz "$WDIR"/FM_imaginary_"$ThisFM".nii.gz

    # count the number of volumes;
    RealnVols=`fslnvols "$4"/FM_real_"$5".nii.gz`
    ImgnrynVols=`fslnvols "$4"/FM_imaginary_"$5".nii.gz`

    # avg. the images, if needed
    if [[ $RealnVols > 1 ]] ; then 
    	mcflirt -in "$4"/AP_"$5".nii.gz -out "$4"/AP_"$5".nii.gz
    	fslmaths "$4"/AP_"$5".nii.gz -Tmean "$4"/AP_"$5".nii.gz
    	mcflirt -in "$4"/PA_"$5".nii.gz -out "$4"/PA_"$5".nii.gz
    	fslmaths "$4"/PA_"$5".nii.gz -Tmean "$4"/PA_"$5".nii.gz
    fi

    # merge the field maps into a single 4D image;
    # fslmerge -t "$4"/AP_PA_"$5".nii.gz "$4"/AP_"$5".nii.gz "$4"/PA_"$5".nii.gz > /dev/null 2>&1 

    # prepare field map files using TOPUP; 
    # topup --imain="$4"/AP_PA_"$5".nii.gz --datain="$2"/func/field_maps/acqparams.txt \ # DONE for NKI using fsl_prepare_fieldmap
    # --iout="$4"/FM_mag_"$5".nii.gz --fout="$4"/FM_rads_"$5".nii.gz --config=b02b0.cnf > /dev/null 2>&1  
    # fslmaths "$4"/FM_rads_"$5".nii.gz -mul 6.283 "$4"/FM_rads_"$5".nii.gz > /dev/null 2>&1 # convert to radians # DONE
    # fslmaths "$4"/FM_mag_"$5".nii.gz -Tmean "$4"/FM_mag_"$5".nii.gz > /dev/null 2>&1 # magnitude image # DONE
    # bet "$4"/FM_mag_"$5".nii.gz "$4"/FM_mag_brain_"$5".nii.gz -f 0.35 -R > /dev/null 2>&1 # temporary bet image # DONE

    # register reference volume to the T1-weighted anatomical image; use bbr cost function 
    "$MEDIR"/res0urces/epi_reg_dof --epi="$WDIR"/FM_mag_"$ThisFM".nii.gz --t1="$Subdir"/anat/T1w/T1w_acpc_dc_restore.nii.gz \
    --t1brain="$Subdir"/anat/T1w/T1w_acpc_dc_restore_brain.nii.gz --out="$WDIR"/fm2acpc_"$ThisFM" --wmseg="$Subdir"/anat/T1w/"$Subject"/mri/white.nii.gz --dof=6 > /dev/null 2>&1 

    # use BBRegister to fine-tune the existing co-registration; output FSL style transformation matrix; (not sure why --s isnt working, renaming dir. to "freesurfer" as an ugly workaround)
    bbregister --s freesurfer --mov "$WDIR"/fm2acpc_"$ThisFM".nii.gz --init-reg "$MEDIR"/res0urces/FSL/eye.dat --surf white.deformed --bold --reg "$WDIR"/fm2acpc_bbr_"$ThisFM".dat --6 --o "$WDIR"/fm2acpc_bbr_"$ThisFM".nii.gz > /dev/null 2>&1  
    tkregister2 --s freesurfer --noedit --reg "$WDIR"/fm2acpc_bbr_"$ThisFM".dat --mov "$WDIR"/fm2acpc_"$ThisFM".nii.gz --targ "$Subdir"/anat/T1w/T1w_acpc_dc_restore.nii.gz --fslregout "$WDIR"/fm2acpc_bbr_"$ThisFM".mat > /dev/null 2>&1  

    # combine the original and 
    # fine tuned affine matrix;
    convert_xfm -omat "$WDIR"/fm2acpc_"$ThisFM".mat \
    -concat "$WDIR"/fm2acpc_bbr_"$ThisFM".mat \
    "$WDIR"/fm2acpc_"$ThisFM".mat > /dev/null 2>&1

    # apply transformation to the relevant files;
    flirt -dof 6 -interp spline -in "$WDIR"/FM_mag_"$ThisFM".nii.gz -ref "$Subdir"/anat/T1w/T1w_acpc_dc_restore_brain.nii.gz -out "$WDIR"/FM_mag_acpc_"$ThisFM".nii.gz -applyxfm -init "$WDIR"/fm2acpc_"$ThisFM".mat > /dev/null 2>&1  
    fslmaths "$WDIR"/FM_mag_acpc_"$ThisFM".nii.gz -mas "$Subdir"/anat/T1w/T1w_acpc_dc_restore_brain.nii.gz "$WDIR"/FM_mag_acpc_brain_"$ThisFM".nii.gz  > /dev/null 2>&1  
    flirt -dof 6 -interp spline -in "$WDIR"/FM_rads_"$ThisFM".nii.gz -ref "$Subdir"/anat/T1w/T1w_acpc_dc_restore_brain.nii.gz -out "$WDIR"/FM_rads_acpc_"$ThisFM".nii.gz -applyxfm -init "$WDIR"/fm2acpc_"$ThisFM".mat > /dev/null 2>&1  
    wb_command -volume-smoothing "$WDIR"/FM_rads_acpc_"$ThisFM".nii.gz 2 "$WDIR"/FM_rads_acpc_"$ThisFM".nii.gz -fix-zeros > /dev/null 2>&1 

done


# This section is repeated in post_func_preproc_fm.sh (only run once)
# merge & average the co-registered field map images accross sessions;  
fslmerge -t "$Subdir"/func/field_maps/Avg_FM_rads_acpc.nii.gz "$WDIR"/FM_rads_acpc_S*.nii.gz > /dev/null 2>&1  
fslmaths "$Subdir"/func/field_maps/Avg_FM_rads_acpc.nii.gz -Tmean "$Subdir"/func/field_maps/Avg_FM_rads_acpc.nii.gz > /dev/null 2>&1  
fslmerge -t "$Subdir"/func/field_maps/Avg_FM_mag_acpc.nii.gz "$WDIR"/FM_mag_acpc_S*.nii.gz > /dev/null 2>&1  
fslmaths "$Subdir"/func/field_maps/Avg_FM_mag_acpc.nii.gz -Tmean "$Subdir"/func/field_maps/Avg_FM_mag_acpc.nii.gz > /dev/null 2>&1  

# perform a final brain extraction;
fslmaths "$Subdir"/func/field_maps/Avg_FM_mag_acpc.nii.gz -mas "$Subdir"/anat/T1w/T1w_acpc_dc_restore_brain.nii.gz \
"$Subdir"/func/field_maps/Avg_FM_mag_acpc_brain.nii.gz > /dev/null 2>&1  
rm -rf "$Subdir"/anat/T1w/freesurfer/ # remove softlink;
