%% Midline_timeseries

% plot timeseries from midline data (choreography results)
% applicable to all choreograpgy data - just change the 'chore' value

%% Set parameters

choredir = ['/Users/alexandremorin/Downloads/GMR_SS01075@UAS_Chrimson/r_LED05_30s2x15s30s#n#n#n@100']; % specify the "choreography-results"
outdir = fullfile(pwd,'figures');

Exclusion_required = true; % Exlcusion required

file_extension = ['.midline.dat']; % Extension to base exclusion on

minimum = 2; % Exclusion parameters
maximum = 4;

exclusion_type = 1;

fileTypes = {'midline','curve','kink','x','y','bias','speed','crabspeed','cast'};
chore = {'midline','cast','speed085','crabspeed'}; % SET MANUALLY  

%% Get filelist

full = dir(choredir);
filt = [full.isdir];
full = full(filt); % select directories only
names = {full.name}';

expr = ['^\d\d\d\d\d\d\d\d_\d\d\d\d\d\d'];
line_width = 1;
filt = regexp(names,expr);
filt = cellfun(@(x) ~isempty(x), filt);
d = full(filt); % select directories with the right name

%% Group genotypes

names = {d.folder}';
splits = cellfun(@(x) strsplit(x,'/'), names, 'UniformOutput', false);
splits = cellfun(@(x) [x{end-1},'/',x{end}], splits, 'UniformOutput', false);
[uname,na,nb] = unique(splits);

%% plot loop

delimiter = ' ';
startRow = 0;
formatSpec = '%s%f%f%f%[^\n\r]';

subplot_index = 1;

file_index_removal = containers.Map; % Dictionary to store filenames and corresponding lines where the condition is not met

if (Exclusion_required)
    for ii = 1:numel(uname)
        idx = find(nb == ii);
        for jj = idx'
            dirname = fullfile(d(jj).folder, d(jj).name);
            matching_file = "";
            indexes_with_invalid_lines = [];
            fname = dir(fullfile(dirname, ['*', file_extension]));
            fname = fullfile(fname.folder, fname.name);

            fileID = fopen(fname, 'r');
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow, 'ReturnOnError', false);
            fclose(fileID);

            if (exclusion_type == 1)
                [C,ia,ic] = unique(dataArray{:,2});

                % Initialize a cell array to store animal data
                animal_data = cell(1, numel(ia));
                
                % Iterate over unique indices
                for i = 1:numel(ia)
                    if i == numel(ia)
                        % If it's the last unique index, extract data from that index to the end
                        animal_data{i} = dataArray{4}(ia(i):end, :);
                    else
                        % Extract data between the current and next unique indices
                        animal_data{i} = dataArray{4}(ia(i):ia(i+1)-1, :);
                    end
                end

                for i = 1:numel(animal_data)
                    animal_data_current = animal_data{i};  % Get current animal_data
                    nanmean_value = mean(animal_data_current, "omitnan");  % Calculate the nanmean for the fourth values
                    
                    % Check if nanmean is within range
                    if ~(minimum <= nanmean_value && nanmean_value <= maximum)
                        if i == numel(animal_data)  % Check if it's the last animal_data
                            indexes_with_invalid_lines = [indexes_with_invalid_lines, ia(i):size(dataArray, 1)];  % Add all indices for the last animal
                        else
                            indexes_with_invalid_lines = [indexes_with_invalid_lines, ia(i):ia(i+1)-1];  % Add all indices for this animal
                        end
                    end
                end
            end

            if (exclusion_type == 2)
            
                % Iterate over each row in dataArray
                for row_idx = 1:numel(dataArray{1})
                    % Check if the 4th value is not within the given range
                    if ~(minimum <= dataArray{4}(row_idx) && dataArray{4}(row_idx) <= maximum)
                        % If not, add the index to the list
                        indexes_with_invalid_lines(end+1) = row_idx;
                    end
                end
            end
            
            % Store indexes with invalid lines
            file_index_removal(d(jj).name) = indexes_with_invalid_lines;
        end
    end
end

for i=1:numel(chore)
    for ii = 1:length(uname)
        idx = find(nb == ii);
        
        et = {};
        dat = {};

        for jj = idx'
            dirname = fullfile(d(jj).folder,d(jj).name);
            fname = dir(fullfile(dirname,['*' chore{i} '.dat']));
            fname = fullfile(fname.folder,fname.name);
            
            fileID = fopen(fname,'r');
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,'MultipleDelimsAsOne', true, 'HeaderLines' ,startRow, 'ReturnOnError', false);
            fclose(fileID);
            
            [C,ia,ic] = unique(dataArray{:,2});
            del = arrayfun(@(x) ia(x):1:min(ia(x)+39,length(ic)),1:length(ia),'UniformOutput',false);
            del = horzcat(del{:});
            del = unique(del);
            if ~isempty(file_index_removal)
                temp = file_index_removal(d(jj).name);
                del = union(del, file_index_removal(d(jj).name));
            end
            dataArray{1,3}(del) = [];
            dataArray{1,4}(del) = [];
            
            et = vertcat(et,dataArray{:,3});
            dat = vertcat(dat,dataArray{:,4});
            clear dataArray C ia ic del
        end
        
        et = vertcat(et{:});
        dat = vertcat(dat{:});
        et(dat==0)=[];
        dat(dat==0)=[];
        
        bins = 0:0.5:ceil(max(et));
        nanarr = nan(1,length(bins));
        Y = discretize(et,bins);
        
        switch chore{i}
            case 'speed'
                time_win = [5 10];
                ind = find(bins >= time_win(1) & bins <= time_win(2));
                dat_base = dat(ismember(Y,ind));
                baseline = mean(dat_base, "omitnan");
                dat = dat/baseline;
            case 'speed085'
                time_win = [0 5];
                ind = find(bins >= time_win(1) & bins <= time_win(2));
                dat_base = dat(ismember(Y,ind));
                for x=1:10
                    baseline (x) = mean(dat(ismember(Y,ind(x))), "omitnan");
                end
                baseline = mean(dat_base, "omitnan");
                dat = dat/baseline;
        end
        
        seri = accumarray(Y,dat,[],@mean);
        nanarr(1:length(seri)) = seri;
        seri = nanarr;

        subplot(2,2,i);
        p = plot(bins,seri,'linewidth',line_width);
        drawnow

        sem = accumarray(Y,dat,[],@(x) std(x)/sqrt(length(x)));
        nanarr(1:length(sem)) = sem;
        sem = nanarr;

        fileName = strrep(uname{ii},'/','@');
        ax = gca;
        ax.YLabel.String = chore{i};
        ax.XLabel.String = 'Time (s)';
        box off

        if ~isdir(outdir)
            mkdir(outdir);
        end

        outname = strcat(fileName,'@',chore{i}); %% SET THIS YOURSELF

        filepath=strcat(outdir,'/',outname);

        hold on
    end
    

lgd = legend({"attp2", "2064", "918", "863", "883", "660", "1075"}, 'Location','southeast');
set(lgd,'FontSize',7)
end
