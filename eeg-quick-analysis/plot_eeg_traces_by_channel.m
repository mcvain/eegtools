% 3D Printed EEG Analysis - Alpha waves 
% Pukar Maharjan 
% Modified by Hyonyoung Shin

clear; close all; 
addpath('D:\Research\UT Austin\3D Printed EEG\Code\eeglab_current\eeglab2022.0'); 
addpath('D:\Research\UT Austin\3D Printed EEG\Code\eeglab_current\eeglab2022.0\functions'); 
eeglab;

channels = [1,2,3,4,5,6,7,8,9];
chanlocs = {'CP3', 'C3', 'FC3', 'CZ', 'FCZ', 'FC4','C4','CP4','EOG'};
[eeg_gel_ec, ~] = pop_loadbv('D:\Research\UT Austin\3D Printed EEG\Experiental Data\Human Subject Experiment\Subject B\Gel EEG\brainvision - eoc - motionartifacts\S001', 'gel_ec.vhdr', [], channels);
[eeg_gel_eo, ~] = pop_loadbv('D:\Research\UT Austin\3D Printed EEG\Experiental Data\Human Subject Experiment\Subject B\Gel EEG\brainvision - eoc - motionartifacts\S001', 'gel_eo.vhdr', [], channels);

[eeg_printed_ec, ~] = pop_loadbv('D:\Research\UT Austin\3D Printed EEG\Experiental Data\Human Subject Experiment\Subject B\Printed EEG\brainvision - eoc - motionartifacts\S001', 'printed_ec.vhdr', [], channels);
[eeg_printed_eo, ~] = pop_loadbv('D:\Research\UT Austin\3D Printed EEG\Experiental Data\Human Subject Experiment\Subject B\Printed EEG\brainvision - eoc - motionartifacts\S001', 'printed_eo.vhdr', [], channels);

% Extract data (and transpose) 
data_gel_ec = eeg_gel_ec.data'; 
data_gel_eo = eeg_gel_eo.data'; 
data_printed_ec = eeg_printed_ec.data'; 
data_printed_eo = eeg_printed_eo.data'; 

% Define master dataset 
mdata = {data_gel_ec, data_gel_eo; data_printed_ec, data_printed_eo};

% Apply Filter (and transpose) 
% EEGs = {eeg_gel_ec, eeg_gel_eo; eeg_printed_ec, eeg_printed_eo}; 
% specs = cell(2, 2); 
% specs_filtered = cell(2, 2); 
% for row = 1:size(EEGs, 1)
%     for col = 1:size(EEGs, 2)
%         [spectra, freqs] = pop_spectopo(EEGs{row, col}, 1, [], 'EEG');
%         specs{row, col} = {spectra, freqs}; 
% 
%         [EEG, ~, ~] = pop_eegfiltnew(EEGs{row, col}, 'locutoff', 1, 'hicutoff', 40); % bandpass
%         EEGs{row, col} = EEG; 
% 
%         [spectra, freqs] = pop_spectopo(EEG, 1, [], 'EEG');
%         specs_filtered{row, col} = {spectra, freqs}; 
%     end
% end
% data_gel_ec_filtered = EEGs{1, 1}.data'; 
% data_gel_eo_filtered = EEGs{1, 2}.data'; 
% data_printed_ec_filtered = EEGs{2, 1}.data'; 
% data_printed_eo_filtered = EEGs{2, 2}.data'; 
% % Filtered master dataset
% fdata = {data_gel_ec_filtered, data_gel_eo_filtered; data_printed_ec_filtered, data_printed_eo_filtered};

% figure 1
%%
figure; 
y = data_gel_ec; 
% data_gel_ec =  bandpass(data_gel_ec,[2 59],500);
data_gel_ec = detrend(data_gel_ec); 
x = 1:length(y);
plot(x, y);
title('Gel (EC)')

figure; hold on;
y_min = min(data_gel_ec, [], 'all');
y_max = max(data_gel_ec, [], 'all');

% y_bin = (y_max - y_min) / 7;
y_bin = 300;
y_new = data_gel_ec; 
y_chs = []; 
for ch = 1:size(data_gel_ec, 2)
    y_ch = y_max - y_bin * ch; 
    y_chs = [y_chs y_ch];
    distance = y_ch - mean(data_gel_ec(:, ch));
    disp(distance);
    y_new(:, ch) = data_gel_ec(:, ch) + distance;
end

% debugging code, do not uncomment 
% means = []; 
% for ch = 1:size(y, 2)
%     means = [means, mean(y(:, ch))] ;
% end
% [B, I] = sort(means, 'descend');
% channelnames_sorted = chanlocs(I); 

% new_y = nan(size(y));
% for ch = 1:size(chanlocs, 2)
%     name = chanlocs{ch}; 

% scatter(0.1, y_chs, 100);

x = 1:length(y);
plot(x, y_new);
xlim([0, length(y)])
title('Gel (EC)')
legend(chanlocs);





