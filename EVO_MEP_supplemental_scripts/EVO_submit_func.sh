# Submit a slurm job to run the functional pipeline
# Hussain Bukhari
# Holland Brown
# EXAMPLE INPUTS: wrap="/path/to/main_wrapper_script.sh /path/to/study_data_folder ${subjectID} ${NumberOfThreads} ${StartSession}"
# NOTE: StartSession is usually 1 (it's 1 for the EVO data)

for i in $(cat subjectlist.txt); do

  TMP=$(echo $i)

  sbatch --mem=128G --partition=scu-cpu --wrap="/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline/func_preproc_ME_wrapper_EVO.sh /athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data ${TMP} 30 1"

done