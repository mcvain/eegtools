% Script to plot SIGNAL QUALITY METRICS over CONDITIONS (e.g. recording time, experimental condition)
% Hyonyoung Shin (hyonyoung.shin@utexas.edu)

clear; close all; 
addpath('C:\Users\hs32732\Documents\eeglab2022.0_old'); 
addpath('C:\Users\hs32732\Documents\eeglab2022.0_old\functions'); 
addpath('D:\eeglab2022.0')
addpath('D:\eeglab2022.0\functions')
eeglab;

% Configuration variables
PLOT_EACH_METRIC_SEPARATELY = true;
NAIVE_SPIKE_COUNT = true; 

% channels = [2 3 4 5];
[EEG1, ~] = pop_loadbv('C:\Users\mcvai\pedot-foam-vr-eeg\20221026-PEDOT Foam EEG Recording', 'Eye open and close-F1 F2, Cz Oz.vhdr', 10000, [1 2 3 4 6]);
[EEG2, ~] = pop_loadbv('C:\Users\mcvai\pedot-foam-vr-eeg\20221026-PEDOT Foam EEG Recording', 'Eye open and close-F1 F2, Cz Oz-20 min.vhdr', 10000, [1 2 3 4 5]);
[EEG3, ~] = pop_loadbv('C:\Users\mcvai\pedot-foam-vr-eeg\20221026-PEDOT Foam EEG Recording', 'Eye open and close-F1 F2, Cz Oz-40min.vhdr', 10000, [1 2 3 4 5]);

% Define master dataset (trials x condition) 
data = {EEG1.data', EEG2.data', EEG3.data'}; 

%% Kurtosis 
kurt = cell(size(data, 1),size(data, 2)); 
for row = 1:size(data, 1) % for each experimental condition 
    for col = 1:size(data, 2) % for each electrode type 
        dat = data{row, col}; 
        k = kurtosis(dat);
        kurt{row, col} = k;
    end
end

%% Spike count (original implementation i.e. naive counting of datapoints above mean + n s.d. threshold)
% updated 9/29/22: spike count is normalized as a percentage of time
% samples 
nspikes = cell(size(data, 1),size(data, 2)); 
for row = 1:size(data, 1) % for each experimental condition 
    for col = 1:size(data, 2) % for each electrode type 
        dat = data{row, col}; 
        n = spike_count(dat, NAIVE_SPIKE_COUNT, 3);
        nspikes{row, col} = n;
    end
end


%% Baseline wander (take first 15 secs of data as baseline. then wander is defined as mean of remaining data - mean of baseline data)
wander_mean = cell(size(data, 1),size(data, 2));
wander_sd = cell(size(data, 1),size(data, 2));
wander_sum = cell(size(data, 1),size(data, 2));
fs = 500; 
for row = 1:size(data, 1) % for each experimental condition 
    for col = 1:size(data, 2) % for each electrode type 
        dat = data{row, col}; 
        [w_mean, w_sd, w_sum] = baseline_drift(dat, 0.1, 0.05); 
        wander_mean{row, col} = w_mean;
        wander_sd{row, col} = w_sd;
        wander_sum = w_sum; 
    end
end


%% Powerline noise 
% pnoise = cell(size(data, 1),size(data, 2)); 
% for row = 1:size(data, 1) % for each experimental condition 
%     for col = 1:size(data, 2) % for each electrode type 
%         dat = data{row, col}; 
%         [pxx,f] = pwelch(dat,fs,0,fs, fs);  % pwelch computes PSD for each column (channel) separately and keeps it in pxx 
% 
%         % [eegspecdB,freqs,compeegspecdB,resvar,specstd] = pop_spectopo(
%         
%         pwr = pxx(find(f==60), :);  % pxx at index of 60 Hz for all channels 
%         pwr = 10 * log10(pwr); 
%         pnoise{row, col} = pwr; 
%     end
% end
% % Output unit of pwelch: The units of the PSD estimate are in squared magnitude units of the time series data per unit frequency
% % So now it should be 10*log_{10}(\muV^{2}/Hz), same as spectopo in EEGLAB 

%% Plotting
names = {'kurtosis'; 'proportion of time samples beyond 3 s.d.'; 'baseline wander (\muV)'};
outputs = {kurt, nspikes, wander_mean};
stds = {[], [], wander_sd};
channel_names = {'Fz Gel', 'Fz Foam', 'F2 Foam', 'Cz Foam', 'Oz Foam'};
condition_labels = {'0', '20', '40'};
n_figs = length(names); 
n_conditions = size(data, 2);
n_trials = size(data, 1); 
n_ch = 5; 

cl = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250],...
    [0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880], [0.3010 0.7450 0.9330],...
    [0.6350 0.0780 0.1840]};
close all; 


for f = 1:n_figs
    figure(f); hold on; h = legend('show','location','best');
    
    y = []; 
    for tr = 1:n_trials
        for ch = 1:n_ch
            y = [];
            for cond = 1:n_conditions
                plotdat = outputs{f};
                y = [y, plotdat{tr, cond}(ch)];
            end
            x=1:length(y); 

            plot(x, y, '-o', 'DisplayName', channel_names{ch}, 'color', cl{ch});

            if ~isempty(stds{f})  
                stdplot = [];
                for c = 1:n_conditions
                    stdplot = [stdplot, stds{f}{c}(ch)];
                end

                er = errorbar(x,y,stdplot,stdplot, 'HandleVisibility','off');
                er.Color = cl{ch};
            end
            
        end
    end
   
    set(gca,'xtick',[1, 2, 3],'xticklabel',condition_labels); 
    xlabel('time elapsed (min)');
    xlim([0.5 3.5])
    ylabel(names{f});

end

function [drift_mean, drift_sd, drift_sum] = baseline_drift(data, window_size, overlap_size)
    n = [];

    window_numel = floor(window_size .* size(data, 1));
    overlap_numel = floor(overlap_size .* size(data, 1));

    i = 0;

    means = []; 
    while (i+1)*window_numel- i*overlap_numel < size(data, 1)
        window = data(1 + i*window_numel - i*overlap_numel:(i+1)*window_numel- i*overlap_numel, :);
        means = [means; mean(window)]; 
        i = i + 1;
    end

    for i = size(means, 1) 
        drift_sum = sum(abs(diff(means)));
        drift_mean = mean(abs(diff(means)));
        drift_sd = std(abs(diff(means)));
    end
end

function n = spike_count(data, NAIVE_SPIKE_COUNT, n_sd)
    n = [];
    for ch = 1:size(data, 2) % for each ch 
        chdat = data(:,ch); 

        if NAIVE_SPIKE_COUNT
        mu = mean(chdat); 
        sd = std(chdat); 
        pos_threshold = mu + n_sd*sd; 
        neg_threshold = mu - n_sd*sd; 

        n_ch = numel(find(chdat > pos_threshold)) + numel(find(chdat < neg_threshold));

        elseif ~NAIVE_SPIKE_COUNT
        n_ch = length(findpeaks(chdat));

        end
        disp(size(chdat)); 

        n_ch = n_ch / size(chdat, 1);  % percentage time sample 

        n = [n, n_ch]; 
    end
end
