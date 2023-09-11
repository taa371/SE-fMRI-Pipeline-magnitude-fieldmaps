#!/bin/bash
# Holland Brown
# Updated 2023-09-11
# Check for necessary JSON files in /func/unprocessed/rest dirs; copy files from main data dir

# Note: if needed, should be run before func_preproc_coreg.sh in functional pipeline; however, likely not needed now that I wrote edit_jsons.sh

if [ ! -d  "$Subdir"/func/rest/session_1 ]; then
	cp -r "$Subdir"/func/unprocessed/rest/session_1 "$Subdir"/func/rest/
	echo -e "Copying unprocessed S1 resting-state files to "$Subdir"/func/rest/ ..."
fi
if [ ! -d  "$Subdir"/func/rest/session_2 ] && [ -d "$Subdir"/func/unprocessed/rest/session_2 ]; then
	cp -r "$Subdir"/func/unprocessed/rest/session_2 "$Subdir"/func/rest/
	echo -e "Copying unprocessed S2 resting-state files to "$Subdir"/func/rest/ ..."
fi
if [ ! -d "$Subdir"/func/xfms ]; then
	mkdir "$Subdir"/func/xfms
	mkdir "$Subdir"/func/xfms/rest
	echo -e "Creating "$Subdir"/func/xfms directory..."
fi
if [ ! -f "$Subdir"/func/rest/session_1/run_1/SliceTiming.txt ]; then
	cp $StudyFolder/SliceTiming.txt "$Subdir"/func/rest/session_1/run_1
	echo -e "Copying SliceTiming.txt from study dir to /rest/session_1/..."
fi
if [ ! -f "$Subdir"/func/rest/session_1/run_1/EffectiveEchoSpacing.txt ]; then
	cp $StudyFolder/EffectiveEchoSpacing.txt "$Subdir"/func/rest/session_1/run_1
	echo -e "Copying EffectiveEchoSpacing.txt from study dir to /rest/session_1/..."
fi
if [ ! -f "$Subdir"/func/rest/session_1/run_1/TE.txt ]; then
	cp $StudyFolder/TE.txt "$Subdir"/func/rest/session_1/run_1
	echo -e "Copying TE.txt from study dir to /rest/session_1/..."
fi
if [ ! -f "$Subdir"/func/rest/session_1/run_1/TR.txt ]; then
	cp $StudyFolder/TR.txt "$Subdir"/func/rest/session_1/run_1
	echo -e "Copying TR.txt from study dir to /rest/session_1/..."
fi

if [ ! -f "$Subdir"/func/rest/session_2/run_1/SliceTiming.txt ]; then
	cp $StudyFolder/SliceTiming.txt "$Subdir"/func/rest/session_2/run_1
	echo -e "Copying SliceTiming.txt from study dir to /rest/session_2/..."
fi
if [ ! -f "$Subdir"/func/rest/session_2/run_1/EffectiveEchoSpacing.txt ]; then
	cp $StudyFolder/EffectiveEchoSpacing.txt "$Subdir"/func/rest/session_2/run_1
	echo -e "Copying EffectiveEchoSpacing.txt from study dir to /rest/session_2/..."
fi
if [ ! -f "$Subdir"/func/rest/session_2/run_1/TE.txt ]; then
	cp $StudyFolder/TE.txt "$Subdir"/func/rest/session_2/run_1
	echo -e "Copying TE.txt from study dir to /rest/session_2/..."
fi
if [ ! -f "$Subdir"/func/rest/session_2/run_1/TR.txt ]; then
	cp $StudyFolder/TR.txt "$Subdir"/func/rest/session_2/run_1
	echo -e "Copying TR.txt from study dir to /rest/session_2/..."
fi
if [ ! -f "$Subdir"/func/xfms/rest/EffectiveEchoSpacing.txt ]; then
	cp "$Subdir"/func/rest/session_1/run_1/EffectiveEchoSpacing.txt "$Subdir"/func/xfms/rest
	echo -e "Copying EffectiveEchoSpacing.txt to /xfms/ from "$Subdir"/func/rest/ ..."
fi