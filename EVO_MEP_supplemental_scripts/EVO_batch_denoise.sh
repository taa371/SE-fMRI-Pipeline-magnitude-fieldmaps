# Script for batch-denoising single-echo functional data
# Hussain Bukhari
# Holland Brown
# EXAMPLE INPUTS: wrap="/path/to/main_wrapper_script.sh; (1) /path/to/study_data_folder; (2) ${subjectID}; (3) ${NumberOfThreads}; (4) ${StartSession}"
# NOTE: StartSession is usually 1 (it's 1 for the EVO data), unless you onyl want to run the second session or something

for i in $(cat subjectlist.txt); do

  TMP=$(echo $i)

  sbatch --mem=128G --partition=scu-cpu --wrap="/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline/func_denoise_SE_wrapper_EVO.sh /athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data ${TMP} 30 1"

done