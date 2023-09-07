#!/bin/bash
# Holland Brown
# Updated: 2023-09-07
# NOTE: need jq installed (not installed on cluster)
# NOTE: can get slice timing by running rorden_get_slice_times.m
# Sources:
    # https://stackoverflow.com/questions/24942875/change-json-file-by-bash-script
    # https://jqlang.github.io/jq/manual/
    # https://notearena.com/lesson/combining-multiple-json-files-using-jq-in-shell-scripting/

Subject="97000" # subject ID
Session="1" # session number
#UnprocFuncDir=/athena/victorialab/scratch/hob4003/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1 # destination for new JSON files
#jsonFn=Rest_S"$Session"_R1_E1.json
UnprocFuncDir=/Users/hollandbrown/Desktop
origJson=Rest_S"$Session"_E1.json
inputJson=UW_scan_params.json
finalJson=Rest_S"$Session"_E1_final.json

# create json file for testing
if ! [ -f "$UnprocFuncDir"/"$origJson" ]; then
    testStr='{ "key1": "value1", "key2": "value2", "EstimatedEffectiveEchoSpacing": 0.000296815 }'
    echo -e "$testStr" >> "$UnprocFuncDir"/"$origJson"
fi

# read json files into bash strings
# origStr=$(cat "$UnprocFuncDir"/"$origJson")
# echo -e "$origStr" # test

# add parameters to original string
# jq '. + { "RepetitionTime": "$trStr" } "$origStr"'

# combine 2 files into final json (this works, but contents of each file are in separate curly brackets in new file)
jq -s '.' "$UnprocFuncDir"/"$origJson" "$UnprocFuncDir"/"$inputJson" > "$UnprocFuncDir"/"$finalJson"
echo -e "Checkpoint: created new json file"

# edit one element of the json file
# "$UnprocFuncDir"/"$finalJson" | jq .EffectiveEchoSpacing = "$UnprocFuncDir"/"$finalJson" | jq .EstimatedEffectiveEchoSpacing
# jq --argfile params "$UnprocFuncDir"/"$origJson" 'select(.EstimatedEffectiveEchoSpacing?)|{(.EstimatedEffectiveEchoSpacing):$params[.EstimatedEffectiveEchoSpacing]}' "$UnprocFuncDir"/"$finalJson" | jq .EffectiveEchoSpacing '[inputs] | add'

# if estimated effective echo spacing is not equal to effective echo spacing...
estimEchoSpacing=$( "$UnprocFuncDir"/"$finalJson" | jq .EstimatedEffectiveEchoSpacing )
echo -e "$estimEchoSpacing"
# "$UnprocFuncDir"/"$finalJson" | jq '.[] | select(.EffectiveEchoSpacing==.EstimatedEffectiveEchoSpacing)'
"$UnprocFuncDir"/"$finalJson" | jq .EffectiveEchoSpacing = "'"$estimEchoSpacing"'"