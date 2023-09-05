#!/bin/bash
# CJL; (cjl2007)
# HRB; (hob4003)
# Wrapper for the HCP's anatomical preprocessing pipeline (1st wrapper of 3)
# Resources: https://github.com/Washington-University/HCPpipelines/blob/master/PreFreeSurfer/PreFreeSurferPipeline.sh
# Updated 2023-09-05

StudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
TE=$3 # TE differs between 2 collection sites for EVO study (For EVO study, UW TE is 2.399 ms, NKI TE is 2.46 ms)
MagnitudeInputName=$4 # The MagnitudeInputName variable should be set to a 4D magnitude volume with two 3D timepoints or "NONE" if not used
PhaseInputName=$5 # The PhaseInputName variable should be set to a 3D phase difference volume or "NONE" if not used
export NSLOTS=$6 # set number of cores for FreeSurfer
AvgrdcSTRING=$7 # Readout Distortion Correction; for EVO, should be "SiemensFieldMap" or "PhilipsFieldMap"

export PATH='/athena/victorialab/scratch/hob4003/ME_Pipeline/Hb_HCP_master/FreeSurfer/custom:/software/spack/bin:/athena/scu/scratch/shared/bin:/usr/condabin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/opt/ibutils/bin:/home/hob4003/.local/bin:/home/hob4003/bin:/home/software/apps/freesurfer6/6.0/freesurfer/mni/bin:/home/software/spack/opt/spack/linux-centos7-x86_64/gcc-8.2.0/ants-2.4.0-ehibrhis7to7ojl5v4ctspcdwljeyf7l/bin:$PATH'
echo $PATH %IE

# Load modules (for cluster use):
module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load python-3.7.7-gcc-8.2.0-onbczx6
module load fsl/6.0.4
module load matlab/R2021a
module load ants-2.4.0-gcc-8.2.0-ehibrhi
# reformat subject folder path  
if [ "${StudyFolder: -1}" = "/" ]; then
	StudyFolder=${StudyFolder%?};
fi

# Set variable value that sets up environment
EnvironmentScript="/athena/victorialab/scratch/hob4003/ME_Pipeline/Hb_HCP_master/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script; users need to set this 
source ${EnvironmentScript}	# Set up pipeline environment variables and software
PRINTCOM="" # leave empty to run everything; set to "echo" to print everything without actually running any commands, for testing purposes

# I added this for posterity...
echo -e "\nSubject: $Subject" # so subject number is recorded in slurm out file for QC purposes
echo -e "TE: $TE" # make sure the TE is right for UW vs. NKI ppts
echo -e "Magnitude Image: $MagnitudeInputName" # so I can tell if I included fieldmaps or left them as "NONE" for this run
echo -e "Phase Image: $PhaseInputName\n"
echo -e "Averaging and Readout Distortion Correction Method: $AvgrdcSTRING\n"

# Variables related to using Spin Echo Field Maps -> no spin-echo FMs for EVO study
SpinEchoPhaseEncodeNegative="NONE"
SpinEchoPhaseEncodePositive="NONE"
SEEchoSpacing="NONE"
SEUnwarpDir="NONE"
TopupConfig="NONE"
GEB0InputName="NONE" # General Electric field map name (don't use a GE scanner in EVO study)

# define some templates;
T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm.nii.gz" # Hires T1w MNI template
T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm_brain.nii.gz" # Hires brain extracted MNI template
T1wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz" # Lowres T1w MNI template
T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_0.8mm.nii.gz" # Hires T2w MNI Template
T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_0.8mm_brain.nii.gz" # Hires T2w brain extracted MNI Template
T2wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz" # Lowres T2w MNI Template
TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm_brain_mask.nii.gz" # Hires MNI brain mask template
Template2mmMask="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz" # Lowres MNI brain mask template

# Structural Scan Settings
# The values set below are for the HCP-YA Protocol using the Siemens Connectom Scanner
T1wSampleSpacing="NONE" # DICOM field (0019,1018) in s or "NONE" if not used
T2wSampleSpacing="NONE" # DICOM field (0019,1018) in s or "NONE" if not used
UnwarpDir="j" # {x,y,z,x-,y-,z-} OR {i,j,k,i-,j-,k-}' "Readout direction of the T1w and T2w images (according to the *voxel axes); NOTE: for EVO, both NKI and UW scanners have dir 'j'
BrainSize="170" # BrainSize in mm, 150-170 for humans
FNIRTConfig="${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf" # FNIRT 2mm T1w Config
GradientDistortionCoeffs="NONE" # Set to NONE to skip gradient distortion correction

echo -e "\nAnatomical Preprocessing and Surface Registration Pipeline for subject $Subject...\n" 

# clean slate;
 rm -rf ${StudyFolder}/${Subject}/T*w > /dev/null 2>&1 
 rm -rf ${StudyFolder}/${Subject}/MNINonLinear > /dev/null 2>&1 

# build list of full paths to T1w images; 
T1ws=`ls ${StudyFolder}/${Subject}/anat/unprocessed/T1w/T1w*.nii.gz`

T1wInputImages="" # preallocate 

# find all T1w images
for i in $T1ws ; do
	T1wInputImages=`echo "${T1wInputImages}$i@"`
done

# build list of full paths to T1w images;
T2ws=`ls ${StudyFolder}/${Subject}/anat/unprocessed/T2w/T2w*.nii.gz`  
T2wInputImages="" # preallocate 

# find all 
# T2w images;
for i in $T2ws ; do
	T2wInputImages=`echo "${T2wInputImages}$i@"`
done

# NOTE: EVO data should be in "LegacyStyleData" processing mode
# determine if T2w images exist & adjust "processing mode" accordingly
if [ "$T2wInputImages" = "" ]; then
	T2wInputImages="NONE" # script will proceed in "legacy" mode
	ProcessingMode="LegacyStyleData"
else
	ProcessingMode="HCPStyleData"
fi

# make "QA" folder
 mkdir ${StudyFolder}/${Subject}/qa/ > /dev/null 2>&1 

 echo -e "\nRunning PreFreeSurferPipeline for subject $Subject...\n" 

# run the Pre FreeSurfer pipeline
 ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
 --path="$StudyFolder" \
 --subject="$Subject" \
 --t1="$T1wInputImages" \
 --t2="$T2wInputImages" \
 --t1template="$T1wTemplate" \
 --t1templatebrain="$T1wTemplateBrain" \
 --t1template2mm="$T1wTemplate2mm" \
 --t2template="$T2wTemplate" \
 --t2templatebrain="$T2wTemplateBrain" \
 --t2template2mm="$T2wTemplate2mm" \
 --templatemask="$TemplateMask" \
 --template2mmmask="$Template2mmMask" \
 --brainsize="$BrainSize" \
 --fnirtconfig="$FNIRTConfig" \
 --fmapmag="$MagnitudeInputName" \
 --fmapphase="$PhaseInputName" \
 --fmapgeneralelectric="$GEB0InputName" \
 --echodiff="$TE" \
 --SEPhaseNeg="$SpinEchoPhaseEncodeNegative" \
 --SEPhasePos="$SpinEchoPhaseEncodePositive" \
 --seechospacing="$SEEchoSpacing" \
 --seunwarpdir="$SEUnwarpDir" \
 --t1samplespacing="$T1wSampleSpacing" \
 --t2samplespacing="$T2wSampleSpacing" \
 --unwarpdir="$UnwarpDir" \
 --gdcoeffs="$GradientDistortionCoeffs" \
 --avgrdcmethod="$AvgrdcSTRING" \
 --topupconfig="$TopupConfig" \
 --processing-mode="$ProcessingMode" \
 --printcom=$PRINTCOM > ${StudyFolder}/${Subject}/qa/PreFreeSurfer.txt

# define some input variables for FreeSurfer
SubjectID="$Subject" #FreeSurfer Subject ID Name
SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to Put FreeSurfer Subject's Folder
T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)

# determine if T2w images exist & 
# adjust "T2wImage" input accordingly
if [ "$T2wInputImages" = "NONE" ]; then
	T2wImage="NONE" # no T2w image
else
	T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)
fi

echo -e "\nRunning FreeSurferPipeline for subject $Subject\n" 

# run the FreeSurfer pipeline
 ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
 --subject="$Subject" \
 --subjectDIR="$SubjectDIR" \
 --t1="$T1wImage" \
 --t1brain="$T1wImageBrain" \
 --t2="$T2wImage" \
 --processing-mode="$ProcessingMode" > ${StudyFolder}/${Subject}/qa/FreeSurfer.txt

# define some input variables for "Post" FreeSurfer
SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/91282_Greyordinates"
GrayordinatesResolutions="2" #Usually 2mm, if multiple delimit with @, must already exist in templates dir
HighResMesh="164" #Usually 164k vertices
LowResMeshes="32" #Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
RegName="MSMSulc" #MSMSulc is recommended, if binary is not available use FS (FreeSurfer)

echo -e "\nRunning PostFreeSurferPipeline for subject $Subject\n" 

# run the Post FreeSurfer pipeline
${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh \
--path="$StudyFolder" \
--subject="$Subject" \
--surfatlasdir="$SurfaceAtlasDIR" \
--grayordinatesdir="$GrayordinatesSpaceDIR" \
--grayordinatesres="$GrayordinatesResolutions" \
--hiresmesh="$HighResMesh" \
--lowresmesh="$LowResMeshes" \
--subcortgraylabels="$SubcorticalGrayLabels" \
--freesurferlabels="$FreeSurferLabels" \
--refmyelinmaps="$ReferenceMyelinMaps" \
--regname="$RegName" \
--processing-mode="$ProcessingMode" > ${StudyFolder}/${Subject}/qa/PostFreeSurfer.txt

# move output folders into "anat"
mv ${StudyFolder}/${Subject}/T*w ${StudyFolder}/${Subject}/anat # T1w & T2w folders
mv ${StudyFolder}/${Subject}/MNINonLinear ${StudyFolder}/${Subject}/anat # MNINonLinear folder
mv ${StudyFolder}/${Subject}/qa ${StudyFolder}/${Subject}/anat # QA folder

echo -e "\nAnatomical preprocessing done for subject $Subject.\n"