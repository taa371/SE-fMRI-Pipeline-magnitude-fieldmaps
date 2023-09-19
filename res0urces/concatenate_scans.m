% Concatenate CIFTIs (function): part of functional QA
% Hussain Bukhari, Holland Brown
% Updated 2023-09-19

% Produce Nyquist frequency plot, tailored stop band filter, demean and concatenate output CIFTIs, calculate framewise displacement
% NOTE: need fieldtrip installed (uses ft_read_cifti_mod.m)

function [Output,SessionIdx,FD] = concatenate_scans(Subdir,File,Sessions)

    % preallocate 
    ConcatenatedData = []; % concatenated dataset
    SessionIdx = []; % index of what frames belong to which session
    FD = []; % framewise displacement (head movement)
    
    % sweep the sessions
    for s = 1:length(Sessions)
    
        % count the number of runs for this session
        runs = dir([Subdir '/func/rest/session_' num2str(Sessions(s)) '/run_*']);
    
        % sweep the runs
        for r = 1:length(runs)
            
            % load head motion parameters (MCP.par)
            rp = load([Subdir '/func/rest/session_' num2str(Sessions(s)) '/run_' num2str(r) '/MCF.par']);
            
            % define the repetition time (TR.txt)
            TR = load([Subdir '/func/rest/session_' num2str(Sessions(s)) '/run_' num2str(r) '/TR.txt']);
    
            % calculate framewise displacement (FD)
            [fd] = calc_fd(rp,TR);
                 
            % load the cifti file (*.dtseries.nii)
            Output = ft_read_cifti_mod([Subdir '/func/rest/session_' num2str(Sessions(s)) '/run_' num2str(r) '/' File '.dtseries.nii']);
            Output.data = Output.data - mean(Output.data,2); % demean
            
            % log the data
            ConcatenatedData = [ConcatenatedData Output.data]; % concatenate the demeaned CIFTIs
            SessionIdx = [SessionIdx ; ones(size(Output.data,2),1) * s ones(size(Output.data,2),1) * r]; %  session index
            FD = [FD ; fd]; %  save framewise displacement

            % Output = c; % this is the output cifti
            Output.data = ConcatenatedData;
     
        end
            
    end
    
    % Output = c; % this is the output cifti
    % Output.data = ConcatenatedData;

end