function [data, pre] = normalizeData2(data, pre)
fprintf('Normalizing Fluorescence Signal \n')
% assignin('base','dataprenorm',data);
% fprintf('\t Input MINIMUM: %i\n',min(data(:)))
% fprintf('\t Input MAXIMUM: %i\n',max(data(:)))
% fprintf('\t Input RANGE: %i\n',range(data(:)))
% fprintf('\t Input MEAN: %i\n',mean(data(:)))

if nargin < 2
	pre.fmin = min(data,[],3);
	pre.fmean = single(mean(data,3));
	pre.fmax = max(data,[],3);
	pre.minval = min(data(:));
end
N = size(data,3);
data = bsxfun( @minus, data+1024, imclose(pre.fmin, strel('disk',5))); % subtract a smoothed version of the min map
% fprintf('\t Post-Min-Subtracted MINIMUM: %i\n',min(data(:)))
% fprintf('\t Post-Min-Subtracted MAXIMUM: %i\n',max(data(:)))
% fprintf('\t Post-Min-Subtracted RANGE: %i\n',range(data(:)))
% fprintf('\t Post-Min-Subtracted MEAN: %i\n',mean(data(:)))

% SEPARATE ACTIVE CELLULAR AREAS FROM BACKGROUND (NEUROPIL)
if nargin < 2
	activityImage = imfilter(range(data,3), fspecial('average',101), 'replicate'); % get average max minus min (filter averages data)
	pre.npMask = double(activityImage) < mean2(activityImage); %find places where activity is less than average
	pre.npPixNum = sum(pre.npMask(:)); %find number of pixels where activity is less than average
	pre.cellMask = ~pre.npMask; %find pixels where activity is greater than or equal to average
	pre.cellPixNum = sum(pre.cellMask(:));
end
pre.npBaseline = sum(sum(bsxfun(@times, data, cast(pre.npMask,'like',data)), 1), 2) ./ pre.npPixNum; %average of pixels in mask
pre.cellBaseline = sum(sum(bsxfun(@times, data, cast(pre.cellMask,'like',data)), 1), 2) ./ pre.cellPixNum;

% % REMOVE BASELINE SHIFTS BETWEEN FRAMES (TODO: untested, maybe move to subtractBaseline)

if nargin < 2
	pre.baselineOffset = median(pre.npBaseline);
end
data = cast( bsxfun(@minus,...
	single(data), single(pre.npBaseline))+pre.baselineOffset, ... %modified this line
	'like', data);

% SCALE TO FULL RANGE OF INPUT (UINT16)
% if nargin < 2
% 	pre.scaleval = 65535/double(1.1*getNearMax(data));
% end
% data = data*pre.scaleval;

% fprintf('\t Output MINIMUM: %i\n',min(data(:)))
% fprintf('\t Output MAXIMUM: %i\n',max(data(:)))
% fprintf('\t Output RANGE: %i\n',range(data(:)))
% fprintf('\t Output MEAN: %i\n',mean(data(:)))



end