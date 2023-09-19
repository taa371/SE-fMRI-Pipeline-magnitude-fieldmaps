% Concatenate CIFTIs (main script): part of functional QA
% Hussain Bukhari, Holland Brown
% Updated 2023-09-19

% Produce Nyquist frequency plot, tailored stop band filter, demean and concatenate output CIFTIs, calculate framewise displacement

% clear all;
addpath('/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline/res0urces/Utilities');
% addpath('/athena/powerlab/scratch/syb4001/ChuckHome/MultiEchofMRI-Pipeline_ClusterVersion/res0urces/Utilities');
addpath('/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline/res0urces');

% Read in the subject list text file as a column array
subjectlist_txt = fopen("/athena/victorialab/scratch/hob4003/study_EVO/UW_subjectlist4matlab.txt",'r'); % open text file in read mode
subjects = fscanf(subjectlist_txt,'%f',36) % works for subjectlists with integers only

fclose(subjectlist_txt);

% test
%subjects = ["W006"];

for subnum = 1:length(subjects)
    
    sub = string(subjects(subnum))
    subject = eraseBetween(sub,1,1);
    % subject = sub; % for UW subject IDs; remove first char (added '1' at beginning to preserve string)
    
    Subdir = char(strcat("/athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data/W",string(subject))) % print Subdir
    % Subdir = char(strcat('/athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data/W',string(subject))) % print Subdir
    File =  'Rest_ICAAROMA.nii.gz/denoised_func_data_aggr_s1.7'; % no leading '/' -> gets concatenated into full path in concatenate_scans.m

    % removed try/catch block here and added this selection stmt instead (meant to control for subjects w/o Session 2 data)
    if isfile([Subdir '/func/unprocessed/session_2/run_1/Rest_S2_R1_E1.nii.gz'])
        Sessions = 1:2;
    else
        Sessions = 1:1;
    end

    [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
    mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
    Output.data = Output.data(:,FD<0.3);
    fn = 'denoised_func_data_aggr_s1.7_MotionCensoredFD0.3+Concatenated'
    ft_write_cifti_mod(fn,Output); clear Output FD SessionIdx % apply some spatial smoothing on the surface;

end