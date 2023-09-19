for subnum =1:9

    Subdir = char(strcat('/athena/powerlab/scratch/syb4001/forImmanuel/CovidMri/0',string(subnum)))
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
    
% 
for subnum =[23,29,30]
    
    Subdir = char(strcat('/athena/powerlab/scratch/syb4001/forImmanuel/CovidMri/',string(subnum)))
    File = 'Rest_E1_AROMA.nii.gz/denoised_func_data_aggr+MGTR_s1.75';
    
    try
        Sessions = 1:3
        [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
        mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
        Output.data = Output.data(:,FD<2);
        ft_write_cifti_mod(['Rest_E1+AROMA+MGTR_s1.75_MotionCensoredFD0.3+Concatenated'],Output); clear Output FD SessionIdx % apply some spatial smoothing on the surface;
    catch
        Sessions = 1:2
        [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions);
        mkdir([Subdir '/func/rest/ConcatenatedCiftis/']); cd([Subdir '/func/rest/ConcatenatedCiftis/']); % make dir. for concatenated resting-state fMRI dataset;
        Output.data = Output.data(:,FD<2);
        ft_write_cifti_mod(['Rest_E1+AROMA+MGTR_s1.75_MotionCensoredFD0.3+Concatenated'],Output); clear Output FD SessionIdx
    end
end