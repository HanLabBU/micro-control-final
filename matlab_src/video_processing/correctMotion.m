function [data, xc, prealign] = correctMotion(data, prealign)
fprintf('Correcting Motion \n')
sz = size(data);
nFrames = sz(3);
if nargin < 2
	prealign.cropBox = selectWindowForMotionCorrection(data,sz(1:2)./2);
	prealign.n = 0;
end
ySubs = round(prealign.cropBox(2): (prealign.cropBox(2)+prealign.cropBox(4)-1)');
xSubs = round(prealign.cropBox(1): (prealign.cropBox(1)+prealign.cropBox(3)-1)');
croppedVid = gpuArray(data(ySubs,xSubs,:));
cropSize = size(croppedVid);
maxOffset = floor(min(cropSize(1:2))/10);
ysub = maxOffset+1 : cropSize(1)-maxOffset;
xsub = maxOffset+1 : cropSize(2)-maxOffset;
yPadSub = maxOffset+1 : sz(1)+maxOffset;
xPadSub = maxOffset+1 : sz(2)+maxOffset;
if ~isfield(prealign, 'template')
	vidMean = im2single(croppedVid(:,:,1));
	templateFrame = vidMean(ysub,xsub);
else
	templateFrame = gpuArray(prealign.template);
end
offsetShift = min(size(templateFrame)) + maxOffset;
validMaxMask = [];
N = nFrames;
xc.cmax = zeros(N,1);
xc.xoffset = zeros(N,1);
xc.yoffset = zeros(N,1);

% ESTIMATE IMAGE DISPLACEMENT USING NORMXCORR2 (PHASE-CORRELATION)
for k = 1:N
	movingFrame = im2single(croppedVid(:,:,k));
	c = normxcorr2(templateFrame, movingFrame);
	
	% RESTRICT VALID PEAKS IN XCORR MATRIX
	if isempty(validMaxMask)
		validMaxMask = false(size(c));
		validMaxMask(offsetShift-maxOffset:offsetShift+maxOffset, offsetShift-maxOffset:offsetShift+maxOffset) = true;
	end
	c(~validMaxMask) = false;
	c(c<0) = false;
	
	% FIND PEAK IN CROSS CORRELATION
	[cmax, imax] = max(abs(c(:)));
	[ypeak, xpeak] = ind2sub(size(c),imax(1));
	xoffset = xpeak - offsetShift;
	yoffset = ypeak - offsetShift;
	
	% APPLY OFFSET TO TEMPLATE AND ADD TO VIDMEAN
	adjustedFrame = movingFrame(ysub+yoffset , xsub+xoffset);
	nt = prealign.n / (prealign.n + 1);
	na = 1/(prealign.n + 1);
	templateFrame = templateFrame*nt + adjustedFrame*na;
	prealign.n = prealign.n + 1;
	xc.cmax(k) = gather(cmax);
	dx = gather(xoffset);
	dy = gather(yoffset);
	xc.xoffset(k) = dx;
	xc.yoffset(k) = dy;
	
	% APPLY OFFSET TO FRAME
	padFrame = padarray(data(:,:,k), [maxOffset maxOffset], 'replicate', 'both');
	data(:,:,k) = padFrame(yPadSub+dy, xPadSub+dx);
	
end
prealign.template = gather(templateFrame);

end