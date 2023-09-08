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
UnprocFuncDir=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1
origJson=Rest_S"$Session"_R1_E1.json
inputJson=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/UW_scan_params.json
finalJson=Rest_S"$Session"_R1_E1_final.json

# create json file for testing
# if ! [ -f "$UnprocFuncDir"/"$origJson" ]; then
#     testStr='{ "key1": "value1", "key2": "value2", "EstimatedEffectiveEchoSpacing": 0.000296815 }'
#     echo -e "$testStr" >> "$UnprocFuncDir"/"$origJson"
# fi

# create empty final json
# if ! [ -f "$UnprocFuncDir"/"$finalJson" ]; then
#     touch "$UnprocFuncDir"/"$finalJson"
# fi

# read json files into bash strings
# origStr=$(cat "$UnprocFuncDir"/"$origJson")
# echo -e "$origStr" # test

# estimEcho=$(jq -r '.[] | .[] | .EstimatedEffectiveEchoSpacing' "$finalJson")
estimEcho=$( jq -r '.EstimatedEffectiveEchoSpacing' "$UnprocFuncDir"/"$origJson" )
echo -e "$estimEcho" # test
# jq --argjson newval "$somevalue" '.array[] += { new_key: $newval }' <<<"$json"
jq '+= { "EffectiveEchoSpacing": [".EstimatedEffectiveEchoSpacing"] }' <<<"$UnprocFuncDir"/"$origJson"
# jq --arg EffectiveEchoSpacing "$estimEcho" '. += $ARGS.named' <<< "$UnprocFuncDir"/"$origJson"
# jq '[.[] | .["EstimatedEffectiveEchoSpacing"] = .["EffectiveEchoSpacing"]]' "$UnprocFuncDir"/"$origJson"

# combine 2 files into final json (this works, but contents of each file are in separate curly brackets in new file)
jq -s '.' "$inputJson" "$UnprocFuncDir"/"$origJson" > "$UnprocFuncDir"/"$finalJson"

# estimEcho=$(jq -r '.[] | .[] | .EstimatedEffectiveEchoSpacing' "$finalJson")
# jq '[.[] | .["EffectiveEchoSpacing"] = .["EstimatedEffectiveEchoSpacing"]]' "$UnprocFuncDir"/"$finalJson" # change estim echo space key name

# edit one element of the json file
# "$UnprocFuncDir"/"$finalJson" | jq .EffectiveEchoSpacing = "$UnprocFuncDir"/"$finalJson" | jq .EstimatedEffectiveEchoSpacing
# jq --argfile params "$UnprocFuncDir"/"$origJson" 'select(.EstimatedEffectiveEchoSpacing?)|{(.EstimatedEffectiveEchoSpacing):$params[.EstimatedEffectiveEchoSpacing]}' "$UnprocFuncDir"/"$finalJson" | jq .EffectiveEchoSpacing '[inputs] | add'

# if estimated effective echo spacing is not equal to effective echo spacing...
# estimEchoSpacing=$( "$UnprocFuncDir"/"$finalJson" | jq .EstimatedEffectiveEchoSpacing )
# echo -e "$estimEchoSpacing"
# "$UnprocFuncDir"/"$finalJson" | jq '.[] | select(.EffectiveEchoSpacing==.EstimatedEffectiveEchoSpacing)'
# "$UnprocFuncDir"/"$finalJson" | jq .EffectiveEchoSpacing = "'"$estimEchoSpacing"'"