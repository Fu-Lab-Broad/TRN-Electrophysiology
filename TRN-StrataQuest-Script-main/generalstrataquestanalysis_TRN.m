% Script to plot expression of various genes across a brain slice based 
% on StrataQuest results
% 
% 2023-11-22 - Kirsten Levandowski
%
% Tissue validation experiments for Spp1-488, Sst-594, Ecel1-647 in mouse
% TRN for Hartley et al. 'Distinct structural and functional connectivity
% of genetically segregated thalamoreticular subnetworks.' Cell Reports.
%
% Expected outputs are (1) scatter of single gene plotted against dapi,
% (2) dual and triple positive genes plotted against dapi, (3) A/P bar 
% graphs of gene normalized to dapi and certain genes, (4) csvs of event 
% labels, and (5) csvs of normalized values

%% clear variables and close anything

clear variables;

% do not display figures when 'off'

set(0,'DefaultFigureVisible', 'on');

% close everything

close all force
close all hidden
status = close('all','hidden');
disp(strcat('close all status: ', num2str(status)));

%% input information

% directory for output

status = mkdir('Output');
out_path = strcat(pwd, '\Output\');

% plot figures - 0 = no, 1 = yes

plot_channels_dapi = 1;
plot_dual = 1;
plot_normalization = 1;

% channels in association with the target gene

ch488 = 'Spp1';
ch594 = 'Sst';
ch647 = 'Ecel1';

%% define constants

% calculate number of channels used by determining if present in 
% directory (dapi always last set)

on_488 = length(dir('488*'))>0;
on_594 = length(dir('594*'))>0;
on_647 = length(dir('647*'))>0;
num_ch = on_488 + on_594 + on_647 + 1;

% calculate the number of brain slices per channel - 
% can also use num_s = size(dir('dapi*'));

num_s = length(dir('*.csv'))/num_ch;

% determine the brain slices (s) and the section intervals (sm) based on 
% the dapi sections in the directory

a = dir('dapi*');
for z = 1:size(a)
    s(z) = str2num(cell2mat(regexp(a(z).name, '\d+', 'match'))); 
end

% if there is only one section, sm = 0

if num_s > 1
    sm = s(2) - s(1);
else
    sm = 0;
end

s1 = s(1);

% calculate the first entry in the last row (first dapi image) in order
% to compare genes of interested against dapi

dapi_set=((num_ch-1)*num_s);

% set channel order for dual pos plots

if on_488 == 1 && on_594 == 1 && on_647 == 1
    ch1 = ch488;
    ch2 = ch594;
    ch3 = ch647;
elseif on_488 == 1 && on_594 == 1 && on_647 == 0
    ch1 = ch488;
    ch2 = ch594;
elseif on_488 == 1 && on_594 == 0 && on_647 == 1
    ch1 = ch488;
    ch2 = ch647;
elseif on_488 == 0 && on_594 == 1 && on_647 == 1
    ch1 = ch594;
    ch2 = ch647;
end

% dapi channel always last and fourth channel

chdapi='dapi';

% determine the brain area from the file name

b = dir('*.csv');
c = extractAfter(b(1).name,mat2str(s1));
d = extractBefore(c,'.');
a1 = extractAfter(d,'_');

% load spreadsheet column headers

eventlabel = 'EventLabel';
x_pos_488 = 'Set1_GrownMask_AF488_Centroid_X_pixels_';
y_pos_488 = 'Set1_GrownMask_AF488_Centroid_Y_pixels_';
x_pos_594 = 'Set2_GrownMask_A594_Centroid_X_pixels_';
y_pos_594 = 'Set2_GrownMask_A594_Centroid_Y_pixels_';
x_pos_647 = 'Set3_GrownMask_A647_Centroid_X_pixels_';
y_pos_647 = 'Set3_GrownMask_A647_Centroid_Y_pixels_';

%% define plotting constants

% graphing marker colors

mcdapi = [0.9 0.9 0.9];                     % light grey
mc488 = [0/255 255/255 0/255];              % green
mc594 = [255/255 0/255 0/255];              % red
mc647 = [0/255 0/255 255/255];              % blue

cc1 = [0.153 0.098 0.58];                   % navy blue
cc2 = [1 0.804 1];                          % ballet pink

mcdual = [0 0.804 0.784];                   % teal
mcdual488_594 = [255/255 225/255 0/255];    % yellow
mcdual594_647 = [255/255 0/255 255/255];    % purple
mcdual488_647 = [0/255 255/255 255/255];    % cyan
mctrip = [0/255 0/255 0/255];               % black

% graph axis sizing

z = [-1000 7000 -1000 7000];

%% read in excel files and plot

% use tabulartext datastore to read in multiple CSV files from 
% working directory (pwd), select the variables of interest

ds = tabularTextDatastore(pwd,'FileExtensions', ['.csv']);
num_files = length(ds.Files);

% read in files and create a table the total number of cells

for i = 1:num_files
    subds = partition(ds,'Files',i);
    subds.ReadSize = 'file';
%     subds.MultipleDelimitersAsOne = true;
    subds.Delimiter = {','};
    subds.TreatAsMissing = 'AVG=';
    subds.MissingValue = 0;
    
    if num_ch == 4
        subds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488};
    elseif on_488 == 1 && on_594 == 1 && on_647 == 0
        subds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488};
    elseif on_488 == 1 && on_594 == 0 && on_647 == 1
        subds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488};
    elseif on_488 == 0 && on_594 == 1 && on_647 == 1
        subds.SelectedVariableNames = {eventlabel, x_pos_594, y_pos_594};
    elseif on_488 == 1 && on_594 == 0 && on_647 == 0
        subds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488};
    elseif on_488 == 0 && on_594 == 1 && on_647 == 0
        subds.SelectedVariableNames = {eventlabel, x_pos_594, y_pos_594};
    elseif on_488 == 0 && on_594 == 0 && on_647 == 1
        subds.SelectedVariableNames = {eventlabel, x_pos_647, y_pos_647};
    end

    T{i} = read(subds);                 % read in event, x, y data into table T
    T1{i} = T{i}(1:end-2,:);            % table T minus the last row
    E{i} = height(T1{i});               % table of number of events per slice
    E_array(i) = cell2mat(E(i));        % array of number of events per slice
    disp(size(T1{i}));                  % display size of T
end

% read in intersection event labels into cell array I

if num_ch > 2   % must have more than one channel and dapi in order to run loop
    for u = 1:num_s

        % find any dual pos (potentially pos for third gene)

        Total_Dual{u} = intersect(T1{u}, T1{u+num_s});                          % intersection of first and second gene
        num_Total_Dual{u} = height(Total_Dual{u});                              % this value functions are the Total_Dual for 4 channels and the True_Dual for 3 channels
    
        if num_ch == 4
            Total_Dual{u+num_s} = intersect(T1{u}, T1{u+2*num_s});              % intersection of first and third gene, if 4 channels
            Total_Dual{u+num_s*2} = intersect(T1{u+num_s}, T1{u+2*num_s});      % intersection of second and third gene, if 4 channels
            
            % find triple pos using intersectn script

            Trip{u} = intersectn(T1{u}, T1{u+num_s}, T1{u+2*num_s}, 3);         % intersection of first, second, third gene, if 4 channels
            
            % triple positive counts

            num_Trip{u} = height(Trip{u});
            
            % dual positives that are not also pos for third gene by using 
            % 'setdiff' to return data in first array that is not in second

            singonly647{u} = setdiff(T1{u+num_s*2}, Total_Dual{u+num_s*2});     % intersection of T1(647) aka gad and total dual for second and third (pcpb3 and gad2)

            True_Dual{u} = setdiff(Total_Dual{u}, Trip{u});                     % intersection of first and second gene - negative for third gene
            True_Dual{u+num_s} = setdiff(Total_Dual{u+num_s}, Trip{u});         % intersection of first and third gene - negative for second gene
            True_Dual{u+num_s*2} = setdiff(Total_Dual{u+num_s*2}, Trip{u});     % intersection of second and third gene - negative for first gene
            
            % Save the height of True_Dual and Total_Dual arrays - dual
            % positive counts

            num_Total_Dual{u+num_s} = height(Total_Dual{u+num_s});
            num_Total_Dual{u+num_s*2} = height(Total_Dual{u+num_s*2});
            
            num_True_Dual{u} = height(True_Dual{u});
            num_True_Dual{u+num_s} = height(True_Dual{u+num_s});
            num_True_Dual{u+num_s*2} = height(True_Dual{u+num_s*2});
        end
    end
end

% save numerical arrays of triple and dual positives

if num_ch > 2
    num_Total_Dual = cell2mat(num_Total_Dual);      % save Total_Dual as normal array
end

if num_ch == 4
    num_Trip = cell2mat(num_Trip);                  % save triple positives as normal array from cell array
    num_True_Dual = cell2mat(num_True_Dual);        % save True_Dual as normal array
end

%% plot genes against dapi

for k = 0:num_ch-1
    for j = 1:num_s
        b = dir('*.csv');
        f = b(num_s*k+j).name;
        slice = num2str(s(j));

        % plot channels against dapi

        if plot_channels_dapi == 1
            if contains(f,'488')
                scatter_dapi(T1{j+dapi_set}, mcdapi, T1{num_s*k+j}, mc488, chdapi, ...
                    ch488, slice, a1, z);
                saveas(gcf, strcat(out_path,'scatter-dapi_', ch488, ...
                    '_slice_', slice ,'_', a1, '.png'));
            end
            if contains(f,'594')
                scatter_dapi(T1{j+dapi_set}, mcdapi, T1{num_s*k+j}, mc594, chdapi, ...
                    ch594, slice, a1, z);
                saveas(gcf, strcat(out_path,'scatter-dapi_', ch594, ...
                    '_slice_', slice ,'_', a1, '.png'));
            end
            if contains(f,'647')
                scatter_dapi(T1{j+dapi_set}, mcdapi, T1{num_s*k+j}, mc647, chdapi, ...
                    ch647, slice, a1, z);
                saveas(gcf, strcat(out_path,'scatter-dapi_', ch647, ...
                    '_slice_', slice ,'_', a1, '.png'));
            end
        end

        % create normalized arrays

        if plot_normalization == 1
            if contains(f, '488')
                N_488(j) = (E_array(num_s*k+j)/E_array(j+dapi_set)*100);
            end
            if contains(f, '594')
                N_594(j) = (E_array(num_s*k+j)/E_array(j+dapi_set)*100);
            end
            if contains(f, '647')
                N_647(j) = (E_array(num_s*k+j)/E_array(j+dapi_set)*100);
            end

            % create normalized tables for dual pos normalized to dapi

            if num_ch > 2
                N_Total_Dual_dapi(j) = (num_Total_Dual(j)/E_array(j+dapi_set)*100);
%                 N_Total_Dual_647(j) = (num_Total_Dual(j)/E_array(num_s*k+j)*100);
            end

            if num_ch == 4
                N_Total_Dual_dapi(j+num_s) = (num_Total_Dual(j+num_s)/E_array(j+dapi_set)*100);
                N_Total_Dual_dapi(j+num_s*2) = (num_Total_Dual(j+num_s*2)/E_array(j+dapi_set)*100);

                N_True_Dual_dapi(j) = (num_True_Dual(j)/E_array(j+dapi_set)*100);
                N_True_Dual_dapi(j+num_s) = (num_True_Dual(j+num_s)/E_array(j+dapi_set)*100);
                N_True_Dual_dapi(j+num_s*2) = (num_True_Dual(j+num_s*2)/E_array(j+dapi_set)*100);
               
                % create normalized tables for triple pos normalized to dapi

                N_Trip_dapi(j) = (num_Trip(j)/E_array(j+dapi_set)*100);
            end

            % create normalized tables for triple pos normalized to 488
            % gene (ch488)

            if contains(f,'488') && num_ch == 4
                N_Total_Dual_488(j) = (num_Total_Dual(j)/E_array(num_s*k+j)*100);
                N_Total_Dual_488(j+num_s) = (num_Total_Dual(j+num_s)/E_array(num_s*k+j)*100);
                N_Total_Dual_488(j+num_s*2) = (num_Total_Dual(j+num_s*2)/E_array(num_s*k+j)*100);

                N_True_Dual_488(j) = (num_True_Dual(j)/E_array(num_s*k+j)*100);                     % genes 1,2 (neg for 3)
                N_True_Dual_488(j+num_s) = (num_True_Dual(j+num_s)/E_array(num_s*k+j)*100);         % genes 1,3 (neg for 2)
                N_True_Dual_488(j+num_s*2) = (num_True_Dual(j+num_s*2)/E_array(num_s*k+j)*100);     % genes 2,3 (neg for 1)
                N_Trip_488(j) = (num_Trip(j)/E_array(num_s*k+j)*100);                               % genes 1,2,3
            end

            % create normalized tables for triple pos normalized to 594
            % gene (ch594)

            if contains(f,'594') && num_ch == 4
                N_Total_Dual_594(j) = (num_Total_Dual(j)/E_array(num_s*k+j)*100);
                N_Total_Dual_594(j+num_s) = (num_Total_Dual(j+num_s)/E_array(num_s*k+j)*100);
                N_Total_Dual_594(j+num_s*2) = (num_Total_Dual(j+num_s*2)/E_array(num_s*k+j)*100);

                N_True_Dual_594(j) = (num_True_Dual(j)/E_array(num_s*k+j)*100);                     % genes 1,2 (neg for 3)
                N_True_Dual_594(j+num_s) = (num_True_Dual(j+num_s)/E_array(num_s*k+j)*100);         % genes 1,3 (neg for 2)
                N_True_Dual_594(j+num_s*2) = (num_True_Dual(j+num_s*2)/E_array(num_s*k+j)*100);     % genes 2,3 (neg for 1)
                N_Trip_594(j) = (num_Trip(j)/E_array(num_s*k+j)*100);                               % genes 1,2,3
            end

            % create normalized tables for triple pos normalized to 647
            % gene (ch647)

            if contains(f,'647') && num_ch == 4
                N_Total_Dual_647(j) = (num_Total_Dual(j)/E_array(num_s*k+j)*100);
                N_Total_Dual_647(j+num_s) = (num_Total_Dual(j+num_s)/E_array(num_s*k+j)*100);
                N_Total_Dual_647(j+num_s*2) = (num_Total_Dual(j+num_s*2)/E_array(num_s*k+j)*100);

                N_True_Dual_647(j) = (num_True_Dual(j)/E_array(num_s*k+j)*100);                     % genes 1,2 (neg for 3)
                N_True_Dual_647(j+num_s) = (num_True_Dual(j+num_s)/E_array(num_s*k+j)*100);         % genes 1,3 (neg for 2)
                N_True_Dual_647(j+num_s*2) = (num_True_Dual(j+num_s*2)/E_array(num_s*k+j)*100);     % genes 2,3 (neg for 1)
                N_Trip_647(j) = (num_Trip(j)/E_array(num_s*k+j)*100);                               % genes 1,2,3
            end
        end        
    end
end

%% plot dual positive cells

if plot_dual == 1
    for w = 1:num_s
        slice = num2str(s(w));
        
        if num_ch == 3

            % TOTAL DUAL

            scatter_dapi(T1{w+dapi_set}, mcdapi, Total_Dual{w}, mcdual, chdapi, ...
                strcat('total dual pos - ', ch1, '&', ch2), slice, a1, z);
            saveas(gcf, strcat(out_path,'scatter_total_dual-', ch1, '-', ch2, ...
                '_slice_', slice ,'_', a1, '.png'));
        end

        if num_ch == 4

            % plot intersecting values for ch1 and ch2
            % TOTAL DUAL

            scatter_dapi(T1{w+dapi_set}, mcdapi, Total_Dual{w}, mcdual488_594, chdapi, ...
                strcat('total dual pos - ', ch1, '&', ch2), slice, a1, z);
            saveas(gcf, strcat(out_path,'scatter_total_dual-', ch1, '-', ch2, ...
                '_slice_', slice ,'_', a1, '.png'));
            
%             % TRUE DUAL (NOT TRIP POS)
%             scatter_dapi(T1{w+dapi_set}, mcdapi, True_Dual{w}, mcdual488_594, chdapi, ...
%                 strcat('true dual pos - ', ch1, '&', ch2), slice, a1, z);
%             saveas(gcf, strcat(out_path,'scatter_true_dual-', ch1, '-', ch2, ...
%                 '_slice_', slice ,'_', a1, '.png'));

            % plot intersecting values for ch1 and ch3
            % TOTAL DUAL
            
            scatter_dapi(T1{w+dapi_set}, mcdapi, Total_Dual{w+num_s}, mcdual488_647, chdapi, ...
                strcat('total dual pos - ', ch1, '&', ch3), slice, a1, z);
            saveas(gcf, strcat(out_path,'scatter_total_dual-', ch1, '-', ch3, ...
                '_slice_', slice ,'_', a1, '.png'));
            
%             % TRUE DUAL (NOT TRIP POS)
%             scatter_dapi(T1{w+dapi_set}, mcdapi, True_Dual{w+num_s}, mcdual488_647, chdapi, ...
%                 strcat('true dual pos - ', ch1, '&', ch3), slice, a1, z);
%             saveas(gcf, strcat(out_path,'scatter_true_dual-', ch1, '-', ch3, ...
%                 '_slice_', slice ,'_', a1, '.png'));

            % plot intersecting values for ch2 and ch3
            % TOTAL DUAL

            scatter_dapi(T1{w+dapi_set}, mcdapi, Total_Dual{w+num_s*2}, mcdual594_647, chdapi, ...
                strcat('total dual pos - ', ch2, '&', ch3), slice, a1, z);
            saveas(gcf, strcat(out_path,'scatter_total_dual-', ch2, '-', ch3, ...
                '_slice_', slice ,'_', a1, '.png'));
            
%             % TRUE DUAL (NOT TRIP POS)
%             scatter_dapi(T1{w+dapi_set}, mcdapi, True_Dual{w+num_s*2}, mcdual594_647, chdapi, ...
%                 strcat('true dual pos - ', ch2, '&', ch3), slice, a1, z);
%             saveas(gcf, strcat(out_path,'scatter_true_dual-', ch2, '-', ch3, ...
%                 '_slice_', slice ,'_', a1, '.png'));
    
            % plot intersecting values for ch1 and ch2 and ch3
            % TRIPLE POS

            scatter_dapi(T1{w+dapi_set}, mcdapi, Trip{w}, mctrip, chdapi, ...
                strcat('triple pos - ',ch1, '&', ch2, '&', ch3), slice, a1, z);
            saveas(gcf, strcat(out_path,'scatter_triple-', ch1, '-', ch2, '-', ...
                ch3, '_slice_', slice ,'_', a1, '.png'));
        end
    end
end

%% plot normalized counts against dapi

if plot_normalization == 1
    if on_488 == 1

        % plot gene 488 normalized to DAPI

        normalized_plot(s, N_488, mc488, ch488, a1, chdapi);
        yline(mean(N_488));
        if num_s > 1
            xticks([s(1):sm:s(num_s)]);
        elseif s == 1
            xticks([s(1)]);
        end
        saveas(gcf, strcat(out_path,'norm-dapi_', ch488, '_slice_', slice , ...
            '_', a1, '.png'));
        filename = strcat('normalization-dapi_', ch488, '_', a1, '_num-slices_', num2str(num_s), '.csv');
        file_path = strcat(out_path, filename);
        writematrix(N_488, file_path, 'WriteMode', 'overwrite');
    end

    if on_594 == 1

        % plot gene 594 normalized to DAPI

        normalized_plot(s, N_594, mc594, ch594, a1, chdapi);
        yline(mean(N_594));
        if num_s > 1
            xticks([s(1):sm:s(num_s)]);
        elseif s == 1
            xticks([s(1)]);
        end
        saveas(gcf, strcat(out_path,'norm-dapi_', ch594, '_slice_', slice , ...
            '_', a1, '.png'));
        filename = strcat('normalization-dapi_', ch594, '_', a1, '_num-slices_', num2str(num_s), '.csv');
        file_path = strcat(out_path, filename);
        writematrix(N_594, file_path, 'WriteMode', 'overwrite');
    end

    if on_647 == 1

        % plot gene 647 normalized to DAPI

        normalized_plot(s, N_647, mc647, ch647, a1, chdapi);
        yline(mean(N_647));
        if num_s > 1
            xticks([s(1):sm:s(num_s)]);
        elseif s == 1
            xticks([s(1)]);
        end
        saveas(gcf, strcat(out_path,'norm-dapi_', ch647, '_slice_', slice , ...
            '_', a1, '.png'));
        filename = strcat('normalization-dapi_', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
        file_path = strcat(out_path, filename);
        writematrix(N_647, file_path, 'WriteMode', 'overwrite');
        
        % graphs of triple and dual pos normalized to DAPI

        if num_ch == 3    % if there are more than one channel and dapi
            normalized_plot(s, N_Total_Dual_dapi, mcdual, strcat(ch1, ...
                '&', ch2), a1, chdapi);
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path,'norm-',ch647, '_total_dual-', ch1, ...
                '-', ch2, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-dapi_TotalDual_', ch1, '-', ch2, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_dapi, file_path, 'WriteMode', 'overwrite');
        end

        % graphs of triple and dual pos normalized to DAPI (gene - ch647)

        if num_ch == 4 

            % triple positive normalized to DAPI

            normalized_plot(s, N_Trip_dapi, mctrip, strcat(ch488, '&', ch594, ...
                '&', ch647), a1, chdapi);
            yline(mean(N_Trip_dapi));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path,'norm-',chdapi, '_trip-', ch488, '-', ...
                ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-dapi_Trip_', ch488, '-', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Trip_dapi, file_path, 'WriteMode', 'overwrite');

            % genes ch488 and ch594
%             % TRUE DUAL (not positive for third gene) normalized to dapi
%             normalized_plot(s, N_True_Dual_dapi(1:num_s), mcdual488_594, strcat(ch488, ...
%                 '&', ch594), a1, chdapi);
%             if num_s > 1
%                 xticks([s(1):sm:s(num_s)]);
%             elseif s == 1
%                 xticks([s(1)]);
%             end
%             saveas(gcf, strcat(out_path, 'norm-', chdapi, '_true_dual-', ...
%                 ch488, '-', ch594, '_slice_', slice ,'_', a1, '.png'));
%             filename = strcat('normalization-dapi_TrueDual_', ch488, '-', ch594, '_', a1, '_num-slices_', num2str(num_s), '.csv');
%             file_path = strcat(out_path, filename);
%             writematrix(N_True_Dual_dapi(1:num_s), file_path, 'WriteMode', 'overwrite');
            
            % TOTAL DUAL

            normalized_plot(s, N_Total_Dual_dapi(1:num_s), mcdual488_594, strcat(ch488, ...
                '&', ch594), a1, chdapi);
            yline(mean(N_Total_Dual_dapi(1:num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', chdapi, '_total_dual-', ...
                ch488, '-', ch594, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-dapi_TotalDual_', ch488, '-', ch594, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_dapi(1:num_s), file_path, 'WriteMode', 'overwrite');

            % genes ch488 and ch647
%             % TRUE DUAL
%             normalized_plot(s, N_True_Dual_dapi(num_s+1:2*num_s), mcdual488_647, strcat(ch488, ...
%                 '&', ch647), a1, chdapi);
%             if num_s > 1
%                 xticks([s(1):sm:s(num_s)]);
%             elseif s == 1
%                 xticks([s(1)]);
%             end
%             saveas(gcf, strcat(out_path, 'norm-', chdapi, '_true_dual-', ...
%                 ch488, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
%             filename = strcat('normalization-dapi_TrueDual_', ch488, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
%             file_path = strcat(out_path, filename);
%             writematrix(N_True_Dual_dapi(num_s+1:2*num_s), file_path, 'WriteMode', 'overwrite');
            
            % TOTAL DUAL

            normalized_plot(s, N_Total_Dual_dapi(num_s+1:2*num_s), mcdual488_647, strcat(ch488, ...
                '&', ch647), a1, chdapi);
            yline(mean(N_Total_Dual_dapi(num_s+1:2*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', chdapi, '_total_dual-', ...
                ch488, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-dapi_TotalDual_', ch488, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_dapi(num_s+1:2*num_s), file_path, 'WriteMode', 'overwrite');

            % genes ch594 and ch647
%             % TRUE DUAL
%             normalized_plot(s, N_True_Dual_dapi(2*num_s+1:3*num_s), mcdual594_647, strcat(ch594, ...
%                 '&', ch647), a1, chdapi);
%             if num_s > 1
%                 xticks([s(1):sm:s(num_s)]);
%             elseif s == 1
%                 xticks([s(1)]);
%             end
%             saveas(gcf, strcat(out_path, 'norm-', chdapi, '_true_dual-', ...
%                 ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
%             filename = strcat('normalization-dapi_TrueDual_', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
%             file_path = strcat(out_path, filename);
%             writematrix(N_True_Dual_dapi(2*num_s+1:3*num_s), file_path, 'WriteMode', 'overwrite');
            
            % TOTAL DUAL

            normalized_plot(s, N_Total_Dual_dapi(2*num_s+1:3*num_s), mcdual594_647, strcat(ch594, ...
                '&', ch647), a1, chdapi);
            yline(mean(N_Total_Dual_dapi(2*num_s+1:3*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', chdapi, '_total_dual-', ...
                ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-dapi_TotalDual_', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_dapi(2*num_s+1:3*num_s), file_path, 'WriteMode', 'overwrite');
            
            % TRIPLE POS NORMALIZED TO ch594

            normalized_plot(s, N_Trip_594, mctrip, strcat(ch488, '&', ch594, ...
                '&', ch647), a1, ch594);
            yline(mean(N_Trip_594));
%             ylim([0 30]);
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path,'norm-',ch594, '_trip-', ch488, ...
                '-', ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch594, '-Trip_', ch488, '-', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Trip_594, file_path, 'WriteMode', 'overwrite');

            % genes ch488 and ch594
%             % TRUE DUAL (not positive for third gene) normalized to ch647
%             normalized_plot(s, N_True_Dual_594(1:num_s), mcdual488_594, strcat(ch488, ...
%                 '&', ch594), a1, ch594);
%             if num_s > 1
%                 xticks([s(1):sm:s(num_s)]);
%             elseif s == 1
%                 xticks([s(1)]);
%             end
%             saveas(gcf, strcat(out_path, 'norm-', ch594, '_true_dual-', ...
%                 ch488, '-', ch594, '_slice_', slice ,'_', a1, '.png'));
%             filename = strcat('normalization-', ch594, '-TrueDual_', ch488, '-', ch594, '_', a1, '_num-slices_', num2str(num_s), '.csv');
%             file_path = strcat(out_path, filename);
%             writematrix(N_True_Dual_594(1:num_s), file_path, 'WriteMode', 'overwrite');

            % TOTAL DUAL

            normalized_plot(s, N_Total_Dual_594(1:num_s), mcdual488_594, strcat(ch488, ...
                '&', ch594), a1, ch594);
            yline(mean(N_Total_Dual_594(1:num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch594, '_total_dual-', ...
                ch488, '-', ch594, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch594, '-TotalDual_', ch488, '-', ch594, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_594(1:num_s), file_path, 'WriteMode', 'overwrite');

            % genes ch488 and ch647
%             % TRUE DUAL
%             normalized_plot(s, N_True_Dual_594(num_s+1:2*num_s), mcdual488_647, strcat(ch488, ...
%                 '&', ch647), a1, ch594);
%             if num_s > 1
%                 xticks([s(1):sm:s(num_s)]);
%             elseif s == 1
%                 xticks([s(1)]);
%             end
%             saveas(gcf, strcat(out_path, 'norm-', ch594, '_true_dual-', ...
%                 ch488, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
%             filename = strcat('normalization-', ch594, '-TrueDual_', ch488, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
%             file_path = strcat(out_path, filename);
%             writematrix(N_True_Dual_594(num_s+1:2*num_s), file_path, 'WriteMode', 'overwrite');

            % TOTAL DUAL

            normalized_plot(s, N_Total_Dual_594(num_s+1:2*num_s), mcdual488_647, strcat(ch488, ...
                '&', ch647), a1, ch594);
            yline(mean(N_Total_Dual_594(num_s+1:2*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch594, '_total_dual-', ...
                ch488, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch594, '-TotalDual_', ch488, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_594(num_s+1:2*num_s), file_path, 'WriteMode', 'overwrite');

            % genes ch594 and ch647
%             % TRUE DUAL
%             normalized_plot(s, N_True_Dual_594(2*num_s+1:3*num_s), mcdual594_647, strcat(ch594, ...
%                 '&', ch647), a1, ch594);
%             if num_s > 1
%                 xticks([s(1):sm:s(num_s)]);
%             elseif s == 1
%                 xticks([s(1)]);
%             end
%             saveas(gcf, strcat(out_path, 'norm-', ch594, '_true_dual-', ...
%                 ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
%             filename = strcat('normalization-', ch594, '-TrueDual_', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
%             file_path = strcat(out_path, filename);
%             writematrix(N_True_Dual_594(2*num_s+1:3*num_s), file_path, 'WriteMode', 'overwrite');

            % TOTAL DUAL

            normalized_plot(s, N_Total_Dual_594(2*num_s+1:3*num_s), mcdual594_647, strcat(ch594, ...
                '&', ch647), a1, ch594);
            yline(mean(N_Total_Dual_594(2*num_s+1:3*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch594, '_total_dual-', ...
                ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch594, '-TotalDual_', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_594(2*num_s+1:3*num_s), file_path, 'WriteMode', 'overwrite');

            % FOR NOLAN - Ecel1+Sst+/Ecel1 and Spp1+Sst+/Spp1 - TOTAL DUAL
            % NORMALIZED TO 488 or 647

            % 488+594+/488+ - Nolan - Spp1+Sst+/Spp1+

            normalized_plot(s, N_Total_Dual_488(1:num_s), mcdual488_594, strcat(ch488, ...
                '&', ch594), a1, ch488);
            yline(mean(N_Total_Dual_488(1:num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch488, '_total_dual-', ...
                ch488, '-', ch594, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch488, '-TotalDual_', ch488, '-', ch594, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_488(1:num_s), file_path, 'WriteMode', 'overwrite');
            
            % 647+594+/647+ - Nolan - Ecel1+Sst+/Ecel1+

            normalized_plot(s, N_Total_Dual_647(2*num_s+1:3*num_s), mcdual594_647, strcat(ch594, ...
                '&', ch647), a1, ch647);
            yline(mean(N_Total_Dual_647(2*num_s+1:3*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch647, '_total_dual-', ...
                ch594, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch647, '-TotalDual_', ch594, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_647(2*num_s+1:3*num_s), file_path, 'WriteMode', 'overwrite');

            % 488+647+/488+ - Nolan - Spp1+Ecel1+/Spp1+

            normalized_plot(s, N_Total_Dual_488(num_s+1:2*num_s), mcdual488_647, strcat(ch488, ...
                '&', ch647), a1, ch488);
            yline(mean(N_Total_Dual_488(num_s+1:2*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch488, '_total_dual-', ...
                ch488, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch488, '-TotalDual_', ch488, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_488(num_s+1:2*num_s), file_path, 'WriteMode', 'overwrite');
            
            % 647+488+/647+ - Nolan - Ecel1+Sst+/Ecel1+

            normalized_plot(s, N_Total_Dual_647(num_s+1:2*num_s), mcdual488_647, strcat(ch488, ...
                '&', ch647), a1, ch647);
            yline(mean(N_Total_Dual_647(num_s+1:2*num_s)));
            if num_s > 1
                xticks([s(1):sm:s(num_s)]);
            elseif s == 1
                xticks([s(1)]);
            end
            saveas(gcf, strcat(out_path, 'norm-', ch647, '_total_dual-', ...
                ch488, '-', ch647, '_slice_', slice ,'_', a1, '.png'));
            filename = strcat('normalization-', ch647, '-TotalDual_', ch488, '-', ch647, '_', a1, '_num-slices_', num2str(num_s), '.csv');
            file_path = strcat(out_path, filename);
            writematrix(N_Total_Dual_647(num_s+1:2*num_s), file_path, 'WriteMode', 'overwrite');
        end
    end
end

%% save output as csv file in output folder

% write csv files for event labels

if num_ch == 4
    filename = strcat(ch488,'_', ch594, '_', ch647, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
end

if on_488 == 1 && on_594 == 1 && on_647 == 0
    filename = strcat(ch488, '_', ch594, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 1 && on_594 == 0 && on_647 == 1
    filename = strcat(ch488, '_', ch647, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 0 && on_594 == 1 && on_647 == 1
    filename = strcat(ch594, '_', ch647, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 1 && on_594 == 0 && on_647 == 0
    filename = strcat(ch488, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 0 && on_594 == 1 && on_647 == 0
    filename = strcat(ch594, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 0 && on_594 == 0 && on_647 == 1
    filename = strcat(ch647, '_', slice, '_', a1, '_EventLabels.csv');
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
end


%% functions

% function to plot channels against dapi

function scatter_dapi_out = scatter_dapi(f_in1, f_in2, ...
     f_in3, f_in4, f_in5, f_in6, f_in7, f_in8, f_in9)

figure;
hold on;
scatter(f_in1, 2, 3, 'filled', 'MarkerFaceColor', f_in2,'Marker', 'o', ...
    'SizeData', 10, 'MarkerFaceAlpha',1);
scatter(f_in3, 2, 3, 'filled', 'MarkerFaceColor', f_in4,'Marker', 'o', ...
    'SizeData', 10, 'MarkerFaceAlpha',1);
title(strcat(f_in5, '&', f_in6,' - slice ',f_in7,'-',f_in8));
xlabel('x position');
ylabel('y position');
legend(f_in5, f_in6,'Location','best');
axis(f_in9);
hold off;

end

% function to plot normalized values

function normalized_plot_out = normalized_plot(f_in1, f_in2, f_in3, ...
    f_in4, f_in5, f_in6)

figure;
hold on;
bar(f_in1, f_in2, 'FaceColor',f_in3, 'EdgeColor','none');
title(strcat(f_in4, ' - normalized counts - ', f_in5));
xlabel('sections a --> p');
ylabel(strcat('% of ', f_in4, '+ cells/', f_in6));
hold off;

end
