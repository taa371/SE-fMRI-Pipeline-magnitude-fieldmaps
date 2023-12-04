#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# HRB; (hob4003@med.cornell.edu)

MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"
AtlasTemplate=$4
DOF=$5
NTHREADS=$6
StartSession=$7

# count the number of sessions
sessions=("$Subdir"/func/rest/session_*)
sessions=$(seq $StartSession 1 "${#sessions[@]}")

# sweep the sessions
for s in $sessions ; do

	# count number of runs for this session
	runs=("$Subdir"/func/rest/session_"$s"/run_*)
	runs=$(seq 1 1 "${#runs[@]}")

	# sweep the runs;
	for r in $runs ; do

		# "AllScans.txt" contains dir. paths to every scan
		echo /session_"$s"/run_"$r" >> "$Subdir"/AllScans.txt  

	done

done

# define a list of directories;
AllScans=$(cat "$Subdir"/AllScans.txt) # note: this is used for parallel processing purposes.
rm "$Subdir"/AllScans.txt # remove intermediate file;

# This section was commented out in the GitHub distro... why? Should I run this?
# --------------------------------------------------------------------------------------------------

# finally, calculate frame-wise displacement and generate stop-motion movies summarizing motion and respiration parameters and show minimally preprocessed images

# fresh workspace dir.
rm -rf "$Subdir"/workspace/ > /dev/null 2>&1 
mkdir "$Subdir"/workspace/ > /dev/null 2>&1 

# create & define the "MotionQA" folder;
rm -rf "$Subdir"/func/qa/MotionQA > /dev/null 2>&1
mkdir -p "$Subdir"/func/qa/MotionQA > /dev/null 2>&1

# create a temp. "motion_qa.m"
cp -rf "$MEDIR"/res0urces/motion_qa.m \
"$Subdir"/workspace/temp.m

# define some Matlab variables
echo "addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m > temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1  
echo Subdir=["'$Subdir'"] | cat - "$Subdir"/workspace/temp.m >> temp && mv temp "$Subdir"/workspace/temp.m > /dev/null 2>&1  		
cd "$Subdir"/workspace/ # run script via Matlab 
matlab -nodesktop -nosplash -r "temp; exit" #> /dev/null 2>&1  

# delete temp. workspace;
rm -rf "$Subdir"/workspace