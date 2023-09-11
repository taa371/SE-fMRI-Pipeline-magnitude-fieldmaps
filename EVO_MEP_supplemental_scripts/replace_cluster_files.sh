#!/bin/bash
# Holland Brown
# Updated: 2023-09-11

# Replace cluster files with files I preprocessed elsewhere and saved on a HDD

SubjectListTxt=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/subjectlist.txt
SessionsTxt=/Volumes/LACIE-SHARE/EVO_MEP_data/UW_MRI_data/Sessions.txt

for Subject in $(cat "$SubjectListTxt"); do

    for Session in $(cat "$SessionsTxt"); do

        hddFile=/home/hob4003/thinclient_drives/LACIE-SH/EVO_MEP_data/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1/Rest_S"$Session"_R1_E1.json
        clusterSubjectDir=/athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data/"$Subject"/func/unprocessed/rest/session_"$Session"/run_1
        clusterFile="$clusterSubjectDir"/Rest_S"$Session"_R1_E1.json

        rm "$clusterFile"
        cp "$hddFile" "$clusterSubjectDir"

    done

done