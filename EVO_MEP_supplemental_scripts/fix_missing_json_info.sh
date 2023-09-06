#!/bin/bash
# Holland Brown
# Updated: 2023-09-06
# NOTE: need jq installed (not installed on cluster)
# NOTE: can get slice timing by running rorden_get_slice_times.m
# Sources:
    # https://stackoverflow.com/questions/24942875/change-json-file-by-bash-script
    # https://jqlang.github.io/jq/manual/
    # https://notearena.com/lesson/combining-multiple-json-files-using-jq-in-shell-scripting/

Subject="" # subject ID
Session="1" # session number
#UnprocFuncDir=/athena/victorialab/scratch/hob4003/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1 # destination for new JSON files
#jsonFn=Rest_S"$Session"_R1_E1.json
UnprocFuncDir=/home/holland/Desktop
json2read=test.json
json2add=UW_scan_params.json
jsonFinal=Rest_S"$Session"_E1.json

# create test json file
# testStr='{ "key1": "value1", "key2": "value2"}'
# echo -e "$testStr" >> "$UnprocFuncDir"/"$json2read"

# fresh json files for testing
rm "$UnprocFuncDir"/"$json2read"
rm "$UnprocFuncDir"/"$json2add"

# create json containing new parameters to be added
jsonInput='{ "RepetitionTime": "$trStr", "PhaseEncodingDirection": "$phaseencodingdirStr", "EchoTime": "$teStr", "SliceTiming": "$slicetimingStr" }'
echo -e "$jsonInput" >> "$UnprocFuncDir"/"$json2add"

# read original json file into a string I can edit
origStr=( cat "$UnprocFuncDir"/"$json2read" )
echo -e origStr # test

# add parameters to json string
# jq '. + { "RepetitionTime": "$trStr" } "$jsonStr"'

# combine 2 json files into final json
jq -s '.'  "$UnprocFuncDir"/"$json2read" "$UnprocFuncDir"/"$json2add" > "$UnprocFuncDir"/"$jsonFinal"