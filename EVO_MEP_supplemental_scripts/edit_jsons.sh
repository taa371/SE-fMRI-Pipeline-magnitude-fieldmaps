#!/bin/bash
# Holland Brown
# Updated: 2023-09-11

# Note: need jq installed
# Note: can get slice timing by running rorden_get_slice_times.m

inputJson=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/UW_scan_params.json
SubjectListTxt=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/subjectlist.txt
SessionsTxt=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/Sessions.txt

for Subject in $(cat "$SubjectListTxt"); do

    for Session in $(cat "$SessionsTxt"); do

        UnprocFuncDir=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1
        origJson="$UnprocFuncDir"/Rest_S"$Session"_R1_E1.json

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