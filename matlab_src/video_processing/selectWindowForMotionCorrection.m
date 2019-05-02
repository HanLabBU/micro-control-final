function winRectangle = selectWindowForMotionCorrection(data, winsize)
if numel(winsize) <2
	winsize = [winsize winsize];
end
sz = size(data);
win.edgeOffset = round(sz(1:2)./4);
win.rowSubs = win.edgeOffset(1):sz(1)-win.edgeOffset(1);
win.colSubs =  win.edgeOffset(2):sz(2)-win.edgeOffset(2);
stat.Range = range(data, 3);
stat.Min = min(data, [], 3);
win.filtSize = min(winsize)/2;
imRobust = double(imfilter(rangefilt(stat.Min),fspecial('average',win.filtSize))) ./ double(imfilter(stat.Range, fspecial('average',win.filtSize)));
% gaussmat = gauss2d(sz(1), sz(2), sz(1)/2.5, sz(2)/2.5, sz(1)/2, sz(2)/2);
gaussmat = fspecial('gaussian', size(imRobust), 1);
gaussmat = gaussmat * (mean2(imRobust) / max(gaussmat(:)));
imRobust = imRobust .*gaussmat;
imRobust = imRobust(win.rowSubs, win.colSubs);
[~, maxInd] = max(imRobust(:));
[win.rowMax, win.colMax] = ind2sub([length(win.rowSubs) length(win.colSubs)], maxInd);
win.rowMax = win.rowMax + win.edgeOffset(1);
win.colMax = win.colMax + win.edgeOffset(2);
win.rows = win.rowMax-winsize(1)/2+1 : win.rowMax+winsize(1)/2;
win.cols = win.colMax-winsize(2)/2+1 : win.colMax+winsize(2)/2;
winRectangle = [win.cols(1) , win.rows(1) , win.cols(end)-win.cols(1) , win.rows(end)-win.rows(1)];
end