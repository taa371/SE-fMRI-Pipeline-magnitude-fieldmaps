#!/bin/bash
# syb4001 

# assign initial variables 
MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"
AtlasTemplate=$4
DOF=$5
NTHREADS=$6
StartSession=1

# load modules 
rm "$Subdir"/AllScans.txt # remove intermediate file;

module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load fsl/6.0.4
module load afni/afni
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a
module unload python
# count the number of sessions
sessions=("$Subdir"/func/unprocessed/rest/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions;
for s in $sessions ; do
	# count number of runs for this session;
	runs=("$Subdir"/func/unprocessed/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")
	for r in $runs ; do
		echo /session_"$s"/run_"$r" >> "$Subdir"/AllScans.txt  
        echo 10 >> "$Subdir"/func/unprocessed/rest/session_"$s"/run_"$r"/rmVols.txt
	done
done

# define a list of directories;
AllScans=$(cat "$Subdir"/AllScans.txt) # note: this is used for parallel processing purposes.

rm "$Subdir"/AllScans.txt # remove intermediate file;



func () {

python2.7 /home/syb4001/Desktop/syb4001/skewscles/ICA-AROMA-master/ICA_AROMA.py -in "$2"/func/rest"$6"/Rest_E1_acpc.nii.gz -out "$2"/func/rest"$6"/Rest_E1_AROMA.nii.gz -m "$2"/func/xfms/rest/T1w_nonlin_brain_func_mask.nii.gz -mc "$2"/func/rest"$6"/MCF.par -dim 30 -den 'aggr'  


}
export -f func # 
parallel --jobs $NTHREADS func ::: $MEDIR ::: $Subdir ::: $Subject ::: $AtlasTemplate ::: $DOF ::: $AllScans 