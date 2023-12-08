#!/bin/bash
# Charles Lynch, Holland Brown
# Remove signal bias, slice-time correction
# Updated 2023-12-08

MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"
AtlasTemplate=$4
DOF=$5
NTHREADS=$6
StartSession=$7
TaskName=$8


# count the number of sessions
sessions=("$Subdir"/func/"$TaskName"/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions
for s in $sessions ; do

	# count number of runs for this session
	runs=("$Subdir"/func/"$TaskName"/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")

	# sweep the runs;
	for r in $runs ; do

		# "AllScans.txt" contains dir. paths to every scan
		echo session_"$s"/run_"$r" >> "$Subdir"/AllScans.txt  

	done

done

# define a list of directories;
AllScans=$(cat "$Subdir"/AllScans.txt) # note: this is used for parallel processing purposes
rm "$Subdir"/AllScans.txt # remove intermediate file

# func -----------------------------------------------------------------------------------------------------
# clean up some folders;
for s in $AllScans ; do

	rm -rf "$Subdir"/func/"$TaskName"/"$s"/MCF > /dev/null 2>&1 # in case there is a previous folder left over
	mkdir "$Subdir"/func/"$TaskName"/"$s"/vols

	# define some acquisition parameters;
	te=$(cat "$Subdir"/func/"$TaskName"/"$s"/TE.txt)
	tr=$(cat "$Subdir"/func/"$TaskName"/"$s"/TR.txt)
	n_te=0 # set to zero;

	# define some files needed for optimal co-registration & cross-scan allignment
	IntermediateCoregTarget=$(cat "$Subdir"/func/"$TaskName"/"$s"/IntermediateCoregTarget.txt)
	Intermediate2ACPCWarp=$(cat "$Subdir"/func/"$TaskName"/"$s"/Intermediate2ACPCWarp.txt)

	# sweep the te;
	for i in $te ; do

		# track which te we are on
		n_te=`expr $n_te + 1` # tick

		# skip the longer te
		if [[ $i < 60 ]] ; then 

			# split original 4D task fMRI file into single 3D vols
			fslsplit "$Subdir"/func/unprocessed/task/"$TaskName"/"$s"/"$TaskName"*_E"$n_te".nii.gz "$Subdir"/func/"$TaskName"/"$s"/vols/E"$n_te"_

		fi

	done

	# sweep through all of the individual volumes;
	for i in $(seq -f "%04g" 0 $((`fslnvols "$Subdir"/func/unprocessed/task/"$TaskName"/"$s"/"$TaskName"*_E1.nii.gz` - 1))) ; do

		# combine te;
		fslmerge -t "$Subdir"/func/"$TaskName"/"$s"/vols/AVG_"$i".nii.gz "$Subdir"/func/"$TaskName"/"$s"/vols/E*_"$i".nii.gz   	
		fslmaths "$Subdir"/func/"$TaskName"/"$s"/vols/AVG_"$i".nii.gz -Tmean "$Subdir"/func/"$TaskName"/"$s"/vols/AVG_"$i".nii.gz

	done

	# merge the images;
	fslmerge -t "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz "$Subdir"/func/"$TaskName"/"$s"/vols/AVG_*.nii.gz # note: used for estimating head motion;
	fslmerge -t "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E1.nii.gz "$Subdir"/func/"$TaskName"/"$s"/vols/E1_*.nii.gz # note: used for estimating (very rough) bias field;
	rm -rf "$Subdir"/func/"$TaskName"/"$s"/vols/ # remove temporary dir.

	# use the first echo (w/ least amount of signal dropout) to estimate bias field;
	echo -e "\n\t$Subject, $s: Estimating bias field using first echo...\n\t\t"$TaskName"_E1.nii.gz -> Mean.nii.gz\n"
	fslmaths "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E1.nii.gz -Tmean "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz
	N4BiasFieldCorrection -d 3 -i "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz -o ["$Subdir"/func/"$TaskName"/"$s"/Mean_restored.nii.gz,"$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz] # estimate field inhomog.; 
	rm "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E1.nii.gz # remove intermediate file;

	# resample bias field image (ANTs --> FSL orientation);
	echo -e "\n\t$Subject, $s: Resampling ANTs bias field to FSL space...\n\t\tReference img, Mean.nii.gz -> Bias_field.nii.gz\n"
	flirt -in "$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz -ref "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz -applyxfm -init "$MEDIR"/res0urces/ident.mat -out "$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz -interp spline

	# remove signal bias;
	echo -e "\n\t$Subject: Correct for signal inhomegeneity for echo-averaged image...\n\t\tDivide "$TaskName"_AVG.nii.gz by Bias_field.nii.gz\n"
	fslmaths "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz -div "$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz

	# remove some intermediate files;
	rm "$Subdir"/func/"$TaskName"/"$s"/Mean*.nii.gz
	rm "$Subdir"/func/"$TaskName"/"$s"/Bias*.nii.gz

	# remove the first few volumes if needed;
	if [[ -f "$Subdir"/func/"$TaskName"/"$s"/rmVols.txt ]]; then
		echo -e "\n\t$Subject, $s: Removing first 10 volumes...\n\t\tOutput: "$TaskName"_AVG.nii.gz\n"
		nVols=`fslnvols "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz`
		rmVols=$(cat "$Subdir"/func/"$TaskName"/"$s"/rmVols.txt)
		fslroi "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz "$rmVols" `expr $nVols - $rmVols`
	fi

	# run an initial MCFLIRT to get rp. estimates prior to any slice time correction;
	echo -e "\n\t$Subject, $s: Initial MCFLIRT to estimate realignment params before slice-time correction...\n"
	mcflirt -dof "$DOF" -stages 3 -plots -in "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz -r "$Subdir"/func/"$TaskName"/"$s"/SBref.nii.gz -out "$Subdir"/func/"$TaskName"/"$s"/MCF
	rm "$Subdir"/func/"$TaskName"/"$s"/MCF.nii.gz # remove .nii output; not used moving forward 

	# perform slice time correction using custom timing file;
	if [[ -f "$Subdir"/func/"$TaskName"/"$s"/SliceTiming.txt ]]; then
		echo -e "\n\t$Subject: Slice-timing correction...\n\t\tOutput: "$TaskName"_AVG.nii.gz\n"
		slicetimer -i "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz -o "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz -r $tr --tcustom="$Subdir"/func/"$TaskName"/"$s"/SliceTiming.txt
	else
		echo -e "ERROR: $Subdir/func/"$TaskName"/$s/SliceTiming.txt does not exist. Skipping slice-timing correction."
	fi

	# now run another MCFLIRT; specify average sbref as ref. vol & output transformation matrices;
	echo -e "\n\t$Subject, $s: Second MCFLIRT for motion correction using average SBref as reference volume...\n"
	mcflirt -dof "$DOF" -mats -stages 4 -in "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG.nii.gz -r "$IntermediateCoregTarget" -out "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_mcf 
	rm "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_*.nii.gz > /dev/null 2>&1 # delete intermediate images; not needed moving forward;

	# sweep all of the echoes; 
	for e in $(seq 1 1 "$n_te") ; do

		# copy over echo "e"; 
		cp "$Subdir"/func/unprocessed/task/"$TaskName"/"$s"/"$TaskName"*_E"$e".nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz

		# remove the first few volumes if needed;
		if [[ -f "$Subdir"/func/"$TaskName"/"$s"/rmVols.txt ]]; then
			echo -e "\n\t$Subject, $s: Removing first 10 volumes...\n\t\tOutput: "$TaskName"_E"$e".nii.gz\n"
			fslroi "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz "$rmVols" `expr $nVols - $rmVols`
		fi

		# perform slice time correction using custom timing file;
		if [[ -f "$Subdir"/func/"$TaskName"/"$s"/SliceTiming.txt ]]; then
			echo -e "\n\t$Subject: Slice-timing correction...\n\t\tOutput: "$TaskName"_E"$e".nii.gz\n"
			slicetimer -i "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz --tcustom="$Subdir"/func/"$TaskName"/"$s"/SliceTiming.txt -r $tr -o "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz
		else
			echo -e "ERROR: $Subdir/func/"$TaskName"/$s/SliceTiming.txt does not exist. Skipping slice-timing correction."
		fi
		
		# split original data into individual volumes;
		fslsplit "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_mcf.mat/vol_ -t 

		# define affine transformation matrices and associated target images; 
		mats=("$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_mcf.mat/MAT_*)
		images=("$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_mcf.mat/vol_*.nii.gz)

		# sweep through the split images;
		for (( i=0; i<${#images[@]}; i++ )); do

			# warp image into 2mm MNI atlas space using a single spline transformation; 
			applywarp --interp=spline --in="${images["$i"]}" --premat="${mats["$i"]}" --warp="$Intermediate2ACPCWarp" --out="${images["$i"]}" --ref="$AtlasTemplate"

		done

		# merge corrected images into a single file & perform a brain extraction
		fslmerge -t "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e"_acpc.nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_mcf.mat/*.nii.gz
		fslmaths "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e"_acpc.nii.gz -mas "$Subdir"/func/xfms/"$TaskName"/T1w_acpc_brain_func_mask.nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e"_acpc.nii.gz # note: this step reduces file size, which is generally desirable but not absolutely needed.

		# remove some intermediate files;
		rm "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_AVG_mcf.mat/*.nii.gz # split volumes
		rm "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e".nii.gz # raw data 

	done

	# rename mcflirt transform dir.;
	rm -rf "$Subdir"/func/"$TaskName"/"$s"/MCF > /dev/null 2>&1
	mv "$Subdir"/func/"$TaskName"/"$s"/*_mcf*.mat "$Subdir"/func/"$TaskName"/"$s"/MCF

	# use the first echo (w/ least amount of signal dropout) to estimate bias field;
	echo -e "\n\t$Subject, $s: Estimating bias field using first echo...\n\t\t"$TaskName"_E1_acpc.nii.gz -> Mean.nii.gz\n"
	fslmaths "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E1_acpc.nii.gz -Tmean "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz
	fslmaths "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz -thr 0 "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz # remove any negative values introduced by spline interpolation;
	N4BiasFieldCorrection -d 3 -i "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz -o ["$Subdir"/func/"$TaskName"/"$s"/Mean_restored.nii.gz,"$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz] # estimate field inhomog.;

	# resample bias field image (ANTs --> FSL orientation);
	echo -e "\n\t$Subject, $s: Resampling ANTs bias field to FSL space...\n\t\tNew reference img, acpc-aligned Mean.nii.gz -> Bias_field.nii.gz\n"
	flirt -in "$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz -ref "$Subdir"/func/"$TaskName"/"$s"/Mean.nii.gz -applyxfm -init "$MEDIR"/res0urces/ident.mat -out "$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz -interp spline

	# sweep all of the echoes;
	echo -e "\n\t$Subject: Correct for signal inhomegeneity for all echoes...\n\t\tDivide "$TaskName"_E"$e"_acpc.nii.gz by Bias_field.nii.gz\n"
	for e in $(seq 1 1 "$n_te") ; do

		# correct for signal inhomog.;
		fslmaths "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e"_acpc.nii.gz -div "$Subdir"/func/"$TaskName"/"$s"/Bias_field.nii.gz "$Subdir"/func/"$TaskName"/"$s"/"$TaskName"_E"$e"_acpc.nii.gz

	done

	# remove some intermediate files;
	rm "$Subdir"/func/"$TaskName"/"$s"/Mean*.nii.gz

done

# END OF FUNCTION ------------------------------------------------------------------------------------------

# FUNCTION PARALLELIZATION DOESN'T WORK - so I put the contents of the function in the main body and search-and-replaced the vbls...
# export -f func # correct for head motion and warp to atlas space in single spline warp
# parallel --jobs $NTHREADS func ::: $MEDIR ::: $AtlasTemplate ::: $Subdir ::: $DOF ::: $AllScans > /dev/null 2>&1  

# ----------------------------------------------------------------------------------------------------------------------------------
# This is redundant with post_func_preproc_headmotion_EVOtask.sh; if running here, don't run post_func_preproc_headmotion_EVOtask.sh
# ----------------------------------------------------------------------------------------------------------------------------------

# finally, calculate frame-wise displacement and generate stop-motion movies 
# summarizing motion and respiration parameters and show minimally preprocessed images

# 2023-12-08: Commented out motion_qa Matlab script call to figure out next week (error in rp_filt, line 167)

# # fresh workspace dir.
# rm -rf "$Subdir"/workspace/
# mkdir "$Subdir"/workspace/

# # create & define the "MotionQA" folder;
# rm -rf "$Subdir"/func/"$TaskName"/qa/MotionQA > /dev/null 2>&1
# mkdir -p "$Subdir"/func/"$TaskName"/qa/MotionQA > /dev/null 2>&1

# # create a temp. "motion_qa.m"
# cp -rf "$MEDIR"/res0urces/motion_qa_EVO"$TaskName".m "$Subdir"/workspace/temp.m
# echo -e "\n\t------------------------------------------------------------------------"
# echo -e "\t$Subject Func Head Motion Matlab script (1 of 1): motion_qa_EVO$TaskName"
# echo -e "\t------------------------------------------------------------------------\n"

# # define some Matlab variables
# echo "addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m >> "$Subdir"/workspace/tmp.m && mv "$Subdir"/workspace/tmp.m "$Subdir"/workspace/temp.m   
# echo Subdir=["'$Subdir'"] | cat - "$Subdir"/workspace/temp.m >> "$Subdir"/workspace/tmp1.m && mv "$Subdir"/workspace/tmp1.m "$Subdir"/workspace/temp.m
# echo StartSession="$StartSession" | cat - "$Subdir"/workspace/temp.m >> "$Subdir"/workspace/tmp2.m && mv "$Subdir"/workspace/tmp2.m "$Subdir"/workspace/temp.m   		
# cd "$Subdir"/workspace/ # run script via Matlab 
# matlab -nodesktop -nosplash -r "temp; exit" 

# echo -e "\n\t----------------------------------------"
# echo -e "\t$Subject motion_qa_EVO$TaskName Complete"
# echo -e "\t----------------------------------------\n"

# # delete temp. workspace
# rm -rf "$Subdir"/workspace
# cd "$Subdir"
