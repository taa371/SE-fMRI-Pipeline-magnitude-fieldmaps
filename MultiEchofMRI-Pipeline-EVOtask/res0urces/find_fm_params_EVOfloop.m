

% turn off
% warnings
warning off;
if StartSession == 1
    
    % clean slate; NOTE: for EVO, do this outside of Matlab (in func_coreg_EVOtask.sh) bc of permissions
    % system(['rm -rf ' Subdir '/func/floop/qa/']);
    % system(['mkdir ' Subdir '/func/floop/qa/']);
    % system(['rm -rf ' Subdir '/func/field_maps/']);
    % system(['mkdir ' Subdir '/func/field_maps/']);
    
    % define the field maps;
    ap = dir([Subdir '/func/unprocessed/field_maps/AP*.nii.gz']);
    pa = dir([Subdir '/func/unprocessed/field_maps/PA*.nii.gz']);
    system(['echo Number of AP Field Maps: ' num2str(length(ap)) ' >> ' Subdir '/func/floop/qa/AvgFieldMap.txt']);
    system(['echo Number of PA Field Maps: ' num2str(length(ap)) ' >> ' Subdir '/func/floop/qa/AvgFieldMap.txt']);

    % preallocate arrays
    trt_ap = NaN(length(ap));
    trt_pa = NaN(length(ap));

    % sweep the
    % ap field maps;
    for i = 1:length(ap)
        
        % split the text;
        tmp_a = strsplit(ap(i).name,'.');
        
        % load data
        if exist([Subdir '/func/unprocessed/field_maps/' tmp_a{1} '.json'],'file')
            j = loadjson([Subdir '/func/unprocessed/field_maps/' tmp_a{1} '.json']);
            trt_ap(i) = j.TotalReadoutTime; % extract the total readouttime
            pe_ap = j.PhaseEncodingDirection; % confirm phase encode dir.
        else
            trt_ap(i) = NaN ; % extract the total readout time
            pe_ap = 'Unknown'; % confirm phase encode dir (NOTE: for EVO, preprocessed FMs outside of pipeline -> no FM jsons)
        end
        
        % split the text;
        tmp_b = strsplit(pa(i).name,'.');
        
        % load data
        if exist([Subdir '/func/unprocessed/field_maps/' tmp_b{1} '.json'],'file')
            j = loadjson([Subdir '/func/unprocessed/field_maps/' tmp_b{1} '.json']);
            trt_pa(i) = j.TotalReadoutTime; % extract the total readouttime
            pe_pa = j.PhaseEncodingDirection; % confirm phase encode dir.
        else
            trt_pa(i) = NaN ; % extract the total readout time
            pe_pa = 'Unknown'; % confirm phase encode dir.
        end
        
        % write out the pair of field maps and associated phase encode directions;
        system(['echo Pair ' num2str(i) ' : ' tmp_a{1} ' [' pe_ap '] + ' tmp_b{1}...
            ' [' pe_pa '] >> ' Subdir '/func/floop/qa/AvgFieldMap.txt']);
        
    end
    
    % create acqparams.txt file;
    system(['echo 0 -1 0 ' num2str(nanmean(trt_ap)) ' >> ' Subdir '/func/field_maps/acqparams.txt']);
    system(['echo 0 1 0 ' num2str(nanmean(trt_pa)) ' >> ' Subdir '/func/field_maps/acqparams.txt']);
    
else
    
    % define the field maps;
    ap = dir([Subdir '/func/unprocessed/field_maps/AP*.nii.gz']);
    pa = dir([Subdir '/func/unprocessed/field_maps/PA*.nii.gz']);
    system(['echo Number of AP Field Maps: ' num2str(length(ap)) ' >> ' Subdir '/func/floop/qa/AvgFieldMap.txt']);
    system(['echo Number of PA Field Maps: ' num2str(length(ap)) ' >> ' Subdir '/func/floop/qa/AvgFieldMap.txt']);
    
    % sweep the
    % ap field maps;
    for i = 1:length(ap)
        
        % split the text;
        tmp_a = strsplit(ap(i).name,'.');
        
        % load data
        if exist([Subdir '/func/unprocessed/field_maps/' tmp_a{1} '.json'],'file')
            j = loadjson([Subdir '/func/unprocessed/field_maps/' tmp_a{1} '.json']);
            trt_ap(i) = j.TotalReadoutTime; % extract the total readouttime
            pe_ap = j.PhaseEncodingDirection; % confirm phase encode dir.
        else
            trt_ap(i) = NaN; % extract the total readout time
            pe_ap = 'Unknown'; % confirm phase encode dir.
        end
        
        % split the text;
        tmp_b = strsplit(pa(i).name,'.');
        
        % load data
        if exist([Subdir '/func/unprocessed/field_maps/' tmp_b{1} '.json'],'file')
            j = loadjson([Subdir '/func/unprocessed/field_maps/' tmp_b{1} '.json']);
            trt_pa(i) = j.TotalReadoutTime; % extract the total readouttime
            pe_pa = j.PhaseEncodingDirection; % confirm phase encode dir.
        else
            trt_pa(i) = NaN; % extract the total readout time
            pe_pa = 'Unknown'; % confirm phase encode dir.
        end
        
        % write out the pair of field maps and associated phase encode directions;
        system(['echo Pair ' num2str(i) ' : ' tmp_a{1} ' [' pe_ap '] + ' tmp_b{1}...
            ' [' pe_pa '] >> ' Subdir '/func/floop/qa/AvgFieldMap.txt']);
        
    end
    
    % create acqparams.txt file;
    system(['echo 0 -1 0 ' num2str(nanmean(trt_ap)) ' >> ' Subdir '/func/field_maps/acqparams.txt']);
    system(['echo 0 1 0 ' num2str(nanmean(trt_pa)) ' >> ' Subdir '/func/field_maps/acqparams.txt']);
     
end