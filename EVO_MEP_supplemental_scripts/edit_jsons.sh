#!/bin/bash
# Holland Brown
# Updated: 2023-12-04

#                    >>>>    Edit parameter names in UW JSONs to match what ME Pipeline expects    <<<<

#                                               >>>>    Description    <<<<

    # For EVO study, UW scans were collected on a Philips scanner and have different parameter names in their JSON files than JSONs from Siemens scans.
    # The Liston/Power labs' Multi-Echo fMRI Preprocessing Pipeline depends on values extracted from JSONs in the Siemens format.
    # This script takes parameter values that already exist in Philips JSONs (except slice times and phase encoding direction) and pastes them into the Philips JSONs under Siemens parameter names.
    # It means those parameters will be listed twice in the JSONs, but the ME Pipeline will only read the parameters with Siemens labels.

#                                               >>>>    Ingredients    <<<<

    # (1) Need jq installed in bash environment (package for editing JSON files)

    # (2) Reference JSON file with parameters and format you want -> 'inputJson'
        # Copy and paste parameters you need from the Philips JSONs into 'inputJson'; change parameter names to match Siemens
        # Siemens names of parameters MEP needs: EchoTime, RepetitionTime, PhaseEncodingDirection, EffectiveEchoSpacing, SliceTiming

    # (3) SliceTiming (usually not in Philips JSONs already) -> you could exclude this and MEP will skip slice-time correction, but that's not ideal
        # Can calculate slice timing by running rorden_get_slice_times.m; then copy and paste into 'inputJson'

    # (4) PhaseEncodingDirection (usually not in Philips JSONs already) -> this parameter is very important; excluding it will break MEP
        # NOTE: Philips JSONs have a parameter called "PhaseEncodingAxis"; this is not the same as PhaseEncodingDirection!
        # Figure out PhaseEncodingDirection from +/- signs of x,y,z axes in header info of a Philips func image (use command 'fslhd'; must have fsl installed)
        # Having an incorrect value here can be catastrophic, so make sure you have the correct PhaseEncodingDirection (it's 'j-' for EVO task and rest fMRI)



inputJson=/Volumes/EVO_Estia/EVO_MRI/organized/UW_task_params.json
SubjectListTxt=/Volumes/EVO_Estia/EVO_MRI/organized/subjectlist_tmp.txt
SessionsTxt=/Volumes/EVO_Estia/EVO_MRI/organized/Sessions.txt
RunsTxt=/Volumes/EVO_Estia/EVO_MRI/organized/Runs.txt

for Subject in $(cat "$SubjectListTxt"); do

    for Session in $(cat "$SessionsTxt"); do

        for Run in $(cat "$RunsTxt"); do

            UnprocFuncDir=/Volumes/EVO_Estia/EVO_MRI/organized/UW/"$Subject"/func/unprocessed/task/adjective/session_"$Session"/run_"$Run"
            origJson="$UnprocFuncDir"/adjective_S"$Session"_R"$Run"_E1.json

            # save params from existing files in bash variables
            echoTime=$( jq -r '.EchoTime' "$inputJson" )
            repTime=$( jq -r '.RepetitionTime' "$inputJson" )
            phEncodeDir=$( jq -r '.PhaseEncodingDirection' "$inputJson" )
            sliceTime=$( jq -r '.SliceTiming' "$inputJson" )
            estimEcho=$( jq -r '.EstimatedEffectiveEchoSpacing' "$origJson" )

            # add new params to subject's resting-state json
            cp "$origJson" "$UnprocFuncDir"/temp.json
            jq --argjson jq_var $echoTime '. += {"EchoTime": $jq_var}' "$UnprocFuncDir"/temp.json >"$origJson"
            rm "$UnprocFuncDir"/temp.json

            cp "$origJson" "$UnprocFuncDir"/temp.json
            jq --argjson jq_var $repTime '. += {"RepetitionTime": $jq_var}' "$UnprocFuncDir"/temp.json >"$origJson"
            rm "$UnprocFuncDir"/temp.json

            cp "$origJson" "$UnprocFuncDir"/temp.json
            jq --arg jq_var "$phEncodeDir" '. += { "PhaseEncodingDirection": $jq_var }' "$UnprocFuncDir"/temp.json >"$origJson"
            rm "$UnprocFuncDir"/temp.json

            cp "$origJson" "$UnprocFuncDir"/temp.json
            jq --argjson jq_var "$estimEcho" '. += { "EffectiveEchoSpacing": $jq_var }' "$UnprocFuncDir"/temp.json >"$origJson"
            rm "$UnprocFuncDir"/temp.json

            cp "$origJson" "$UnprocFuncDir"/temp.json
            jq --argjson jq_var "$sliceTime" '. += { "SliceTiming": $jq_var }' "$UnprocFuncDir"/temp.json >"$origJson"
            rm "$UnprocFuncDir"/temp.json
    
        done

    done

done