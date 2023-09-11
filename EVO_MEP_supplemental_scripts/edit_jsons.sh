#!/bin/bash
# Holland Brown
# Updated: 2023-09-08
# NOTE: need jq installed
# NOTE: can get slice timing by running rorden_get_slice_times.m
# Sources:
    # https://stackoverflow.com/questions/24942875/change-json-file-by-bash-script
    # https://jqlang.github.io/jq/manual/
    # https://notearena.com/lesson/combining-multiple-json-files-using-jq-in-shell-scripting/

Subject="W004" # subject ID
Session="2" # session number
#UnprocFuncDir=/athena/victorialab/scratch/hob4003/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1 # destination for new JSON files
#jsonFn=Rest_S"$Session"_R1_E1.json
UnprocFuncDir=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/"$Subject"_test/func/unprocessed/rest/session_"$Session"/run_1
origJson=Rest_S"$Session"_R1_E1.json
inputJson=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/UW_scan_params.json
finalJson=Rest_S"$Session"_R1_E1_final.json


# estimEcho=$(jq -r '.[] | .[] | .EstimatedEffectiveEchoSpacing' "$finalJson")

# save params from existing files in bash variables
estimEcho=$( jq -r '.EstimatedEffectiveEchoSpacing' "$UnprocFuncDir"/"$origJson" )
echo -e "$estimEcho" # test


# add new params to subject's resting-state json
EstimatedEffectiveEchoSpacing=$(jq -r --arg EffectiveEchoSpacing "$estimEcho" '
    .resource[]
    | select(.username=="$estimEcho") 
    | .id' "$finalJson")

# jq --argjson newval "$somevalue" '.array[] += { new_key: $newval }' <<<"$json"
jq '+= { "EffectiveEchoSpacing": [".EstimatedEffectiveEchoSpacing"] }' <<<"$UnprocFuncDir"/"$origJson" # this approach works, but still in separate curly brackets
# jq --arg EffectiveEchoSpacing "$estimEcho" '. += $ARGS.named' <<< "$UnprocFuncDir"/"$origJson"
# jq '[.[] | .["EstimatedEffectiveEchoSpacing"] = .["EffectiveEchoSpacing"]]' "$UnprocFuncDir"/"$origJson"

# combine 2 files into final json (this works, but contents of each file are in separate curly brackets in new file -> causes indexing problems)
# jq -s '.' "$inputJson" "$UnprocFuncDir"/"$origJson" > "$UnprocFuncDir"/"$finalJson"
