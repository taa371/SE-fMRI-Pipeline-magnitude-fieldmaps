#!/bin/bash
# Additional smoothing before projecting onto another surface (part of the SE denoising pipeline)
# Charles Lynch, Hussain Bukhari, Holland Brown
# Updated 2023-09-15

Subject=$1
StudyFolder=$2
Subdir="$StudyFolder"/"$Subject"
KernelSize=$(cat $3)
CiftiList=$(cat $4)

# count the number of sessions
sessions=("$Subdir"/func/rest/session_*)
sessions=$(seq 1 1 "${#sessions[@]}")

# sweep the sessions
for s in $sessions; do

	# count number of runs for this session
	runs=("$Subdir"/func/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}" )

	# sweep the runs;
	for r in $runs; do

		# sweep the cifti(s);			
		for c in $CiftiList; do

			# sweep the kernel(s);
			for k in $KernelSize; do

				# smooth with geodesic (for surface data) and Euclidean (for volumetric data) Gaussian kernels
				wb_command -cifti-smoothing "$Subdir"/func/rest/session_"$s"/run_"$r"/"$c".dtseries.nii "$k" "$k" COLUMN "$Subdir"/func/rest/session_"$s"/run_"$r"/"$c"_s"$k".dtseries.nii \
				-left-surface "$Subdir"/anat/T1w/fsaverage_LR32k/"$Subject".L.midthickness.32k_fs_LR.surf.gii -right-surface "$Subdir"/anat/T1w/fsaverage_LR32k/"$Subject".R.midthickness.32k_fs_LR.surf.gii -merged-volume

			done

		done

	done
	
done

# delete workspace dir
rm -rf "$Subdir"/workspace/

# calculate temporal mean and standard deviation; demean and normalize dense time-series 
wb_command -cifti-reduce "$Subdir"/func/rest/session_"$s"/run_"$r"/"$c".dtseries.nii MEAN "$Subdir"/func/rest/session_"$s"/run_"$r"/MEAN.dscalar.nii
wb_command -cifti-reduce "$Subdir"/func/rest/session_"$s"/run_"$r"/"$c".dtseries.nii STDEV "$Subdir"/func/rest/session_"$s"/run_"$r"/STDEV.dscalar.nii
wb_command -cifti-math '((x-mean)/stdev)' "$Subdir"/func/rest/session_"$s"/run_"$r"/"$c".dtseries.nii -fixnan 0 -var x "$Subdir"/func/rest/session_"$s"/run_"$r"/"$c".dtseries.nii \
-var mean "$Subdir"/func/rest/session_"$s"/run_"$r"/MEAN.dscalar.nii -select 1 1 -repeat -var stdev "$Subdir"/func/rest/session_"$s"/run_"$r"/STDEV.dscalar.nii -select 1 1 -repeat

# remove some intermediate files
rm "$Subdir"/func/rest/session_"$s"/run_"$r"/MEAN.dscalar.nii 
rm "$Subdir"/func/rest/session_"$s"/run_"$r"/STDEV.dscalar.nii
