function jitterplot(data,y,SUBJECT,varargin)
%
% INTRODUCTION
% Function to create jitter plots showing the mean, mean - 1 standard
% deviation, mean + 1 standard deviation and the distribution of the
% individual data points
%
% INPUT
% jitterplot(data,y)
% data:     N x 1 vector containing the data points to be plotted
% y:        N x 1 vector representing the corresponding groups of the data
%           points
% SUBJECT: N x 1 vector representing the corresponding subject of the data
% added by Shin 
% 
% jitterplot(...,'meanWidth',meanWidthValue)
% Value for the width of the line to indicate the mean in the plot. Default
% is 0.2
%
% jitterplot(...,'stdWidth',stdWithValue)
% Value for the width of the lines to indicate the standard deviation in
% the plot. Default is 0.3
%
% jitterplot(...,'scatterSize',scatterSizeValue)
% Value for the marker size to show the individual data points. Default
% value is 20
%
% Created:      8/7/2020
% Version:      1.0
% Last update:  8/7/2020
% Developer:    Joris Meurs

if nargin < 2
   error('Not enough input arguments'); 
end

nsubj = max(max(SUBJECT)); 
% Supported colors
% (https://colorbrewer2.org/#type=qualitative&scheme=Paired&n=12)
c = [
    166,206,227
    31,120,180
    178,223,138
    51,160,44
    251,154,153
    227,26,28
    253,191,111
    255,127,0
    202,178,214
    106,61,154
    255,255,153
    177,89,40
    ];
c = c./255;
Colors = nan(size(data,1), 3);
if ~isempty(varargin) 
c = c(varargin{1}, :); 
Colors = nan(size(c,1), 3);
nsubj = size(c,1);

data = data(ismember(SUBJECT, varargin{1}), :);
y = y(ismember(SUBJECT, varargin{1}), :); 
end

for n = 1:nsubj 
    [row, ~] = find(SUBJECT == n); 
    % row
    for i = [row] 
    Colors(i, :) = repmat(c(n, :), length(unique(y)), 1); 
    end
end
% Colors

meanWidth = [];
stdWidth = [];
scatterSize = [];

for j = 1:length(varargin)
   if isequal(varargin{j},'meanWidth')
      meanWidth = varargin{j+1}; 
   end
   if isequal(varargin{j},'stdWidth')
      stdWidth = varargin{j+1}; 
   end
   if isequal(varargin{j},'scatterSize')
      scatterSize = varargin{j+1}; 
   end
end

if isempty(meanWidth)
   meanWidth = 0.2; 
end

if isempty(stdWidth)
   stdWidth = 0.3; 
end

if isempty(scatterSize)
   scatterSize = 20; 
end

if length(data) ~= length(y)
   error('Data and group vector should be the same length'); 
end

uniqueGroups = unique(y,'stable');

hold on;
for j = 1:length(uniqueGroups)
    param = y(j); 
    % Calculate mean and standard deviation for group
    mu = nanmean(data(uniqueGroups(j)==y));
    sd = nanstd(data(uniqueGroups(j)==y));
    
    % standard error 
    se = sd / sqrt(nsubj); 
    
    % Plot mean line
    plot([j-meanWidth/2 j+meanWidth/2],[mu mu],'-','Color',[0 0 0],'LineWidth',1);
    
    % Plot mean-standard deviation
    plot([j j],[mu-se mu],'-','Color',[0 0 0],'LineWidth',1);
    
    % Plot mean+standard deviation
    plot([j j],[mu mu+se],'-','Color',[0 0 0],'LineWidth',1);
    
    % Plot mean-standard deviation end
    plot([j-stdWidth/2 j+stdWidth/2],[mu-se mu-se],'-','Color',[0 0 0],'LineWidth',1);
    
    % Plot mean+standard deviation end
    plot([j-stdWidth/2 j+stdWidth/2],[mu+se mu+se],'-','Color',[0 0 0],'LineWidth',1);
    
    % Scatter plot for data points
    x = 0.05.*rand(length(find(uniqueGroups(j)==y)),1)+j;
    % SUBJECT
    % y
    % j
    scatter(x,data(uniqueGroups(j)==y),scatterSize,Colors(find(y==param), :),'filled');
    xlim([1 - 0.5, length(unique(y)) + 0.5]);
    
    % [p1,S1] = polyfit(y, data, 1); 
    % [y_fit,delta] = polyval(p1,y,S1);
    % plot(y,y_fit,'r-'); 
    % plot(y,y_fit+2*delta,'m--',y,y_fit-2*delta,'m--');
end

hold off

end