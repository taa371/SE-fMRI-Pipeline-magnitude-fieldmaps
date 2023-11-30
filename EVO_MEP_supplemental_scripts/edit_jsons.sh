#!/bin/bash
# Holland Brown
# Updated: 2023-11-30

# Fix parameter names in UW JSONs to match what ME Pipeline expects

# Note: need jq installed
# Note: can get slice timing by running rorden_get_slice_times.m

inputJson=/media/holland/EVO_Estia/EVO_MRI/organized/UW_task_params.json
SubjectListTxt=/media/holland/EVO_Estia/EVO_MRI/organized/subjectlist.txt
SessionsTxt=/media/holland/EVO_Estia/EVO_MRI/organized/Sessions.txt
RunsTxt=/media/holland/EVO_Estia/EVO_MRI/organized/Runs.txt

for Subject in $(cat "$SubjectListTxt"); do

    for Session in $(cat "$SessionsTxt"); do

        for Run in $(cat "$RunsTxt"); do

            UnprocFuncDir=/media/holland/EVO_Estia/EVO_MRI/organized/UW/"$Subject"/func/unprocessed/task/adjective/session_"$Session"/run_"$Run"
            origJson="$UnprocFuncDir"/"$Subject"_S"$Session"_R"$Run"_adjective.json

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