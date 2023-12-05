% turn off warnings;
% warning off;

% default is "rest";
if ~exist('FuncName','var')
    FuncName = 'floop';
end
StartSession = 1;
if StartSession == 1
    
    % clean slate;
    system(['rm -rf ' Subdir '/func/' FuncName '/']);
    
    count = 0; % preallocate;
    
    % count the number of sessions;
    sessions = dir([Subdir '/func/unprocessed/task/' FuncName '/session_*']);
    
    % sweep the sessions;
    for s = 1:length(sessions)
        
        % count the number of runs;
        runs = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_*']);
        
        % sweep the runs;
        for r = 1:length(runs)
            
            % make the dir;
            system(['mkdir -p ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/']);
            
            count = count+1;
            
            % define json dir;
            json_dir = ([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/']);
            check_json_name = strcmp(FuncName,'floop'); % compare strings; 0 if not matching, 1 if matching
            if check_json_name == 1
            % find .json file;
                json = dir([json_dir '/f*.json']); % NOTE: change for floop
            else
                json = dir([json_dir '/*.json']);

            end
            
            % preallocate;
            TE = zeros(1,length(json));
            
            % sweep the echoes;
            for e = 1:length(json)
                
                % load data;
                j = loadjson([json_dir '/' json(e).name]);
                
                % echo times;
                TE(e) = j.EchoTime*10^3; % convert to ms;
                
            end
            
            % extract the TR;
            TR = j.RepetitionTime;
            
            % (effective) echo spacing;
            EffectiveEchoSpacing(count) = j.EffectiveEchoSpacing;
            
            % load data
            j = loadjson([json_dir '/'...
                json(1).name]);
            
            % extract slice timing
            slice_times = j.SliceTiming;
            
            % calculate slice order
            [~,slice_order] = sort(slice_times(1:length(unique(slice_times))));
            ref_slice = slice_order(round(length(slice_order)/2)); % select the "reference slice"; i.e., the slice with no slice time correction
            
            % preallocate the output
            timing_file = zeros(length(slice_order),1);
            
            % sweep TRs;
            for i = 1:length(slice_order)
                timing_file(i) = (find(slice_order==ref_slice) - find(slice_order==i)) / length(slice_order);
            end
            
            % factor in multi-band acc; if needed
            if isfield(j,'MultibandAccelerationFactor')
                timing_file = repmat(timing_file,j.MultibandAccelerationFactor,1);
            end
            
            % sweep the remaining TRs
            for i = 1:length(timing_file)
                system(['echo ' num2str(timing_file(i)) ' >> ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/SliceTiming.txt']);
            end
            
            % write out some other files;
            system(['echo ' num2str(TE) ' > ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TE.txt']);
            system(['echo ' num2str(TR) ' > ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TR.txt']);
            system(['echo ' num2str(EffectiveEchoSpacing(count)) ' > ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/EffectiveEchoSpacing.txt']);
            
        end
        
    end
    
    % make "qa" and "xfms" folders;
    system(['mkdir -p ' Subdir '/func/floop/qa/']);
    system(['mkdir -p ' Subdir '/func/xfms/' FuncName '/']);
    
    count = 0; % preallocate;
    
    % sweep all the sessions
    for s = 1:length(sessions)
        
        % count the number of runs;
        runs = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_*']);
        
        % sweep the runs;
        for r = 1:length(runs)
            
            count = count + 1; % tick
            TE = load([Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TE.txt']);
            TR = load([Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TR.txt']);
            system(['echo Session ' num2str(s) ' Run ' num2str(r) ': ' num2str(TE) ' >> ' Subdir '/func/floop/qa/AllTEs.txt']);
            system(['echo Session ' num2str(s) ' Run ' num2str(r) ': ' num2str(TR) ' >> ' Subdir '/func/floop/qa/AllTRs.txt']);
            
        end
        
    end
    
    % log effective echo spacing (used during corrections for spatial distortions);
    system(['echo ' num2str(mode(EffectiveEchoSpacing)) ' >> ' Subdir '/func/xfms/' FuncName '/EffectiveEchoSpacing.txt']);
    
    count = 0; % preallocate
    
    % count the number of sessions;
    sessions = dir([Subdir '/func/unprocessed/task/' FuncName '/session_*']);
    
    % sweep the sessions;
    for s = 1:length(sessions)
        
        % count the number of runs;
        runs = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_*']);
        
        % sweep the runs;
        for r = 1:length(runs)
            
            % define json dir;
            json_dir = ([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/']);
            
            % find .json file;
            json = dir([json_dir '/floop' '*.json']);
            
            % tick;
            count = count + 1;
            
            % sweep the echoes;
            for e = 1:length(json)
                
                % log the number of volumes;
                system(['fslnvols ' Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/floop' '_S' num2str(s) '_R' num2str(r) '_E' num2str(e) '.nii.gz > ' Subdir '/tmp.txt']);
                tmp = load([Subdir '/tmp.txt']);
                NumberOfVolumes(count,e) = tmp;
                
                % log the file sizes;
                tmp = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/floop' '_S' num2str(s) '_R' num2str(r) '_E' num2str(e) '.nii.gz'])
                FileSize(count,e) = tmp.bytes ./ 1000000 % convert from byte to megabyte;
                
            end
            
        end
        
    end
    
    save([Subdir '/func/floop/qa/FileSize.mat'],'FileSize');
    save([Subdir '/func/floop/qa/NumberOfVolumes.mat'],'NumberOfVolumes');

    % remove temporary file;
    system(['rm ' Subdir '/tmp.txt']);
    
else
    
    count = 0; % preallocate;
    
    % count the number of sessions;
    sessions = dir([Subdir '/func/unprocessed/task/' FuncName '/session_*']);
    
    % sweep the sessions;
    for s = StartSession:length(sessions)
        
        % count the number of runs;
        runs = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_*']);
        
        % sweep the runs;
        for r = 1:length(runs)
            
            % make the dir;
            system(['mkdir -p ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/']);
            
            count = count+1;
            
            % define json dir;
            json_dir = ([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/']);
            
            % find .json file;
            json = dir([json_dir '/*.json']);
            
            % preallocate;
            TE = zeros(1,length(json));
            
            % sweep the echoes;
            for e = 1:length(json)
                
                % load data;
                j = loadjson([json_dir '/'...
                    json(e).name]);
                
                % echo times;
                TE(e) = j.EchoTime*10^3; % convert to ms;
                
            end
            
            % extract the TR;
            TR = j.RepetitionTime;
            
            % (effective) echo spacing;
            EffectiveEchoSpacing(count) = j.EffectiveEchoSpacing;
            
            % load data;
            j = loadjson([json_dir '/'...
                json(1).name]);
            
            % extract slice timing;
            slice_times = j.SliceTiming;
            
            % calculate slice order;
            [~,slice_order] = sort(slice_times(1:length(unique(slice_times))));
            ref_slice = slice_order(round(length(slice_order)/2)); % select the "reference slice"; i.e., the slice with no slice time correction;
            
            % preallocate the output;
            timing_file = zeros(length(slice_order),1);
            
            % sweep TRs;
            for i = 1:length(slice_order)
                timing_file(i) = (find(slice_order==ref_slice) - find(slice_order==i)) / length(slice_order);
            end
            
            % factor in multi-band acc; if needed;
            if isfield(j,'MultibandAccelerationFactor')
                timing_file = repmat(timing_file,j.MultibandAccelerationFactor,1);
            end
            
            % sweep the remaining TRs;
            for i = 1:length(timing_file)
                system(['echo ' num2str(timing_file(i)) ' >> ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/SliceTiming.txt']);
            end
            
            % write out some other files;
            system(['echo ' num2str(TE) ' > ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TE.txt']);
            system(['echo ' num2str(TR) ' > ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TR.txt']);
            system(['echo ' num2str(EffectiveEchoSpacing(count)) ' > ' Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/EffectiveEchoSpacing.txt']);
            
        end
        
    end
    
    count = StartSession-1; % preallocate;
    
    % sweep all the sessions;
    for s = StartSession:length(sessions)
        
        % count the number of runs;
        runs = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_*']);
        
        % sweep the runs;
        for r = 1:length(runs)
            
            count = count + 1; % tick;
            TE = load([Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TE.txt']);
            TR = load([Subdir '/func/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/TR.txt']);
            system(['echo Session ' num2str(s) ' Run ' num2str(r) ': ' num2str(TE) ' >> ' Subdir '/func/floop/qa/AllTEs.txt']);
            system(['echo Session ' num2str(s) ' Run ' num2str(r) ': ' num2str(TR) ' >> ' Subdir '/func/floop/qa/AllTRs.txt']);
            
        end
        
    end
    
    % load the previously generated variables;
    load([Subdir '/func/floop/qa/FileSize']);
    load([Subdir '/func/floop/qa/NumberOfVolumes']);
    
    count = StartSession-1; % preallocate;
    
    % count the number of sessions;
    sessions = dir([Subdir '/func/unprocessed/task/' FuncName '/session_*']);
    
    % sweep the sessions;
    for s = StartSession:length(sessions)
        
        % count the number of runs;
        runs = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_*']);
        
        % sweep the runs;
        for r = 1:length(runs)
            
            % define json dir;
            json_dir = ([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/']);
            check_json_name = strcmp(FuncName,'floop'); % compare strings; 0 if not matching, 1 if matching
            if check_json_name == 1
            % find .json file;
            json = dir([json_dir '/f*.json']);
            else
             json = dir([json_dir '/*.json']);

            end
            % tick;
            count = count + 1;
            
            % sweep the echoes;
            for e = 1:length(json)
                
                % log the number of volumes;
                system(['fslnvols ' Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/floop' '_S' num2str(s) '_R' num2str(r) '_E' num2str(e) '.nii.gz > ' Subdir '/tmp.txt']);
                tmp = load([Subdir '/tmp.txt']);
                NumberOfVolumes(count,e) = tmp;
                
                % log the file sizes;
                tmp = dir([Subdir '/func/unprocessed/task/' FuncName '/session_' num2str(s) '/run_' num2str(r) '/floop' '_S' num2str(s) '_R' num2str(r) '_E' num2str(e) '.nii.gz'])
                FileSize(count,e) = tmp.bytes ./ 1000000 % convert from byte to megabyte;
                
            end
            
        end
        
    end
    
    % system([num2str(FileSize) ' >> Subdir '/func/floop/qa/FileSize.txt']);
    save([Subdir '/func/floop/qa/FileSize.mat'],'FileSize');
    save([Subdir '/func/floop/qa/NumberOfVolumes.mat'],'NumberOfVolumes');

    % remove temporary file;
    system(['rm ' Subdir '/tmp.txt']);
    
end