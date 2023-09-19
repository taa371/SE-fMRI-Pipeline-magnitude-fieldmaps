% Concatenate CIFTIs (main script): part of functional QA
% Hussain Bukhari, Holland Brown
% Updated 2023-09-19

% Produce Nyquist frequency plot, tailored stop band filter, demean and concatenate output CIFTIs, calculate framewise displacement
% NOTE: need fieldtrip installed (uses ft_read_cifti_mod.m)

% addpath('/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline/res0urces/Utilities');
addpath('/athena/powerlab/scratch/syb4001/ChuckHome/MultiEchofMRI-Pipeline_ClusterVersion/res0urces/Utilities');

% Read in the subject list text file as a column array
subjectlist_txt = fopen("/athena/victorialab/scratch/hob4003/study_EVO/UW_subjectlist.txt",'r'); % open text file in read mode
% subjects_test = fscanf(subjectlist_txt,'%f',35); % works for NKI sublist only
subjects_test = fscanf(subjectlist_txt,'%f',100); % works for UW sublist only
% subjects = fscan(subjectlist_txt,'%s','delimiter','\n') % specify read lines as strings, delimiter=newline
fclose(subjectlist_txt);

% test
subjects = ["97018","W004"];

for subnum = 1:length(subjects)

    subject = subjects(subnum);
    Subdir = char(strcat("/athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/",string(subject))) % print Subdir
    % Subdir = char(strcat('/athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data/W',string(subject))) % print Subdir
    File =  'Rest_ICAAROMA.nii.gz/denoised_func_data_aggr';

    try
        Sessions = 1:2;
        [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
        mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
        Output.data = Output.data(:,FD<0.3);
        fn = strcat('denoised_func_data_aggr.7_MotionCensoredFD0.3+Concatenated')
        ft_write_cifti_mod(fn,Output); clear Output FD SessionIdx % apply some spatial smoothing on the surface;
    catch
        Sessions = 1;
        [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
        mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
        Output.data = Output.data(:,FD<0.3);
        fn = strcat('denoised_func_data_aggr.7_MotionCensoredFD0.3+Concatenated')
        ft_write_cifti_mod(fn,Output); clear Output FD SessionIdx
    end

end