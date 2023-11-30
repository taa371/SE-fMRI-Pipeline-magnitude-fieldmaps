#!/bin/bash
# Holland Brown
# Updated: 2023-11-30

# Note: need jq installed
# Note: can get slice timing by running rorden_get_slice_times.m

inputJson=/Volumes/LACIE-SHARE/EVO_MRI/organized/NKI/NKI_task_params.json
SubjectListTxt=/Volumes/LACIE-SHARE/EVO_MRI/organized/NKI/subjectlist.txt
SessionsTxt=/Volumes/LACIE-SHARE/EVO_MRI/organized/NKI/Sessions.txt
RunsTxt=/Volumes/LACIE-SHARE/EVO_MRI/organized/NKI/Runs.txt

for Subject in $(cat "$SubjectListTxt"); do

    for Session in $(cat "$SessionsTxt"); do

        UnprocFuncDir=/Volumes/LACIE-SHARE/EVO_MRI/organized/NKI/"$Subject"/func/unprocessed/task/floop/session_"$Session"/run_"$Run"
        origJson="$UnprocFuncDir"/"$Subject"_floop_S"$Session"_R1.json

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