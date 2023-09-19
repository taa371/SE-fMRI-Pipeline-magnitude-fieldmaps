% Concatenate CIFTIs (main script): part of functional QA
% Hussain Bukhari, Holland Brown
% Updated 2023-09-19

% Produce Nyquist frequency plot, tailored stop band filter, demean and concatenate output CIFTIs, calculate framewise displacement



% Read in the subject list text file as a column array
subjectlist_txt = fopen('/athena/victorialab/scratch/hob4003/study_EVO/NKI_subjectlist.txt','r'); % open text file in read mode
subjects = fscan(subjectlist_txt,'%s','delimiter','\n') % specify read lines as strings, delimiter=newline
fclose(subjectlist_txt);

% test
subjects = ['97018','W004']

for subnum = 1:length(subjects)

    subject = subjects(subnum)
    Subdir = char(strcat('/athena/victorialab/scratch/hob4003/study_EVO/NKI_MRI_data/',string(subject))) % print Subdir
    % Subdir = char(strcat('/athena/victorialab/scratch/hob4003/study_EVO/UW_MRI_data/W',string(subject))) % print Subdir
    File =  'Rest_E1_AROMA.nii.gz/denoised_func_data_aggr+MGTR_s1.75';

    try
        Sessions = 1:3
        [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
        mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
        Output.data = Output.data(:,FD<0.3);
        ft_write_cifti_mod(['Rest_E1+AROMA+MGTR_s1.75_MotionCensoredFD0.3+Concatenated'],Output); clear Output FD SessionIdx % apply some spatial smoothing on the surface;
    catch
        Sessions = 1:2
        [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
        mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
        Output.data = Output.data(:,FD<0.3);
        ft_write_cifti_mod(['Rest_E1+AROMA+MGTR_s1.75_MotionCensoredFD0.3+Concatenated'],Output); clear Output FD SessionIdx
    end

end