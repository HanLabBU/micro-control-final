function roi_simon(metadata)
% Hua-an Tseng, huaantseng at gmail
% modified by Mike Romano, 02-13-18

%     [selected_filename_list,selected_filefolder] = uigetfile('*.tif','MultiSelect','on');
%     
%     cd(selected_filefolder)
%     switch class(selected_filename_list)
%         case 'char'
%             filename_list{1} = selected_filename_list;
%         case 'cell'
%             filename_list = cell(numel(selected_filename_list),1);
%             for n = 1:numel(selected_filename_list)
%                 filename_list{n} = selected_filename_list{n};
%             end
%     end
    currdir = pwd;
    for m=1:numel(metadata)
        path = fileparts(metadata(m).tiffs{1});
%         cd(path)
        [roi_simon,iteration_simon,imgDiff_simon] = segmentation_simon(metadata(m).tiffs);

        save(['processed-data/roi_simon_',metadata(m).suffix],'roi_simon');
        save(['processed-data/iteration_simon_',metadata(m).suffix],'iteration_simon');
        save(['processed-data/imgDiff_simon_',metadata(m).suffix],'imgDiff_simon');

        trace_simon = extract_trace(roi_simon,metadata(m).tiffs);

        save(['processed-data/trace_simon_',metadata(m).suffix],'trace_simon');
%         cd(currdir);
    end    
end

function matrix2tiff(f_matrix, filename, method)

    % if ~isempty(dir(filename))
    %     overwrite = input('File already exists. Overwrite (0-no/1-yes)?');
    %     if isempty(overwrite) || overwrite==0
    %         load(fnmat)
    %         return
    %     end
    % end

    if isempty(strfind(filename,'.tif'))
        filename = [filename,'.tif'];
    end

    NumberImages = size(f_matrix,3);

    switch method
        case 'w'
            FileOut = Tiff('temp_file','w');

        case 'w8'
            FileOut = Tiff('temp_file','w8');
    end

    tags.ImageLength = size(f_matrix,1);
    tags.ImageWidth = size(f_matrix,2);
    tags.Photometric = Tiff.Photometric.MinIsBlack;
    tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tags.BitsPerSample = 16;
    setTag(FileOut, tags);
    FileOut.write(f_matrix(:,:,1));
    for i=2:NumberImages
        FileOut.writeDirectory();
        setTag(FileOut, tags);
        FileOut.write(f_matrix(:,:,i));
    end
    FileOut.close()

    movefile('temp_file',filename);

end

function [f_matrix] = tiff2matrix(filename)

    InfoImage = imfinfo(filename);
    NumberImages=length(InfoImage);

    f_matrix = zeros(InfoImage(1).Height,InfoImage(1).Width,NumberImages,'uint16');

    for i=1:NumberImages
        f_matrix(:,:,i) = imread(filename,'Index',i,'Info',InfoImage);
    end

end

function [roi_dataset,iteration,imgDiff] = segmentation_simon(filename_list)
% Simon's code

    stop_threshold = 0.05;
    iteration_threshold = 2;

    imgDiff = getImageDiff(filename_list);

    disp('Generating template image');

    figure; imagesc(imgDiff); title('Raw template image');axis image;

    totall_roi_count = 0;
    current_roi_count = 0;
    iteration_idx = 0;

    % Continue running clearing + thresholding + splitting until number of new ROIs < stop_threshold
    while (totall_roi_count==0 || (current_roi_count/totall_roi_count)>=stop_threshold) && iteration_idx<iteration_threshold
        iteration_idx = iteration_idx+1;
        fprintf(['Iteration ',num2str(iteration_idx),'....ratio: ',num2str((current_roi_count/totall_roi_count),2),'\n']);
        fprintf('Thresholding....');
        if iteration_idx==1
            current_imgDiff = imgDiff;
        else
            temp_imgThresh = iteration(iteration_idx-1).imgThresh;
            temp_imgThresh = dilate(temp_imgThresh);
            current_imgDiff = clearSegmented(iteration(iteration_idx-1).image, temp_imgThresh);
            temp_removed_mask = iteration(iteration_idx-1).removed_mask;
            temp_removed_mask = dilate(temp_removed_mask);
            current_imgDiff = clearSegmented(current_imgDiff, iteration(iteration_idx-1).removed_mask);
        end
        iteration(iteration_idx).image = current_imgDiff;
        iteration(iteration_idx).val = calculateThresh(current_imgDiff);
        fprintf([num2str(iteration(iteration_idx).val),'\n']);
        imgThresh = applyThresh(imgDiff, iteration(iteration_idx).val);
        iteration(iteration_idx).pre_imgThresh = imgThresh;
        imgThresh = removeSmall(imgThresh);
        imgThresh = morphologicalOps(imgThresh);

        % Recursively split overlapping ROIs
        disp('Separating overlapping ROIs');
        imgSep = splitOverlapRec(current_imgDiff, imgThresh,[num2str(iteration_idx),' |']);

    %   Need to add dilation here otherwise small ROIs that actually are ROIs
    %   will be removed.

        iteration(iteration_idx).imgSep = imgSep;

    %     imgSep = dilate(imgSep);

        imgThresh = imgSep;

    %     imgThresh = removeSmall(imgThresh);
        imgThresh = removeSmallSelective(current_imgDiff, imgThresh, iteration(iteration_idx).val);
        [imgThresh,removed_mask] = removeStrings(current_imgDiff,imgThresh);
        imgThresh = morphologicalOps(imgThresh);

%         plotPerim(current_imgDiff, imgThresh,'bw'); title(['Iteration ',num2str(iteration_idx)]);axis image;

        iteration(iteration_idx).imgThresh = imgThresh;
        iteration(iteration_idx).removed_mask = removed_mask;

        [imgLabel, num] = bwlabel(imgThresh);

        iteration(iteration_idx).roi_count = num;

        for roi_idx=1:num
            iteration(iteration_idx).roi(roi_idx,1).pixel_idx = find(imgLabel==roi_idx);
            iteration(iteration_idx).roi(roi_idx,1).iteration = iteration_idx;
        end

        current_roi_count = iteration(iteration_idx).roi_count;
        totall_roi_count = totall_roi_count+current_roi_count;

        % End after 5th iteration
%         if iteration_idx >= 3
%             break;
%         end

    end

    %figure;plot(cat(1,iteration.roi_count));

    roi_dataset = cat(1,iteration.roi);

    final_img = imgDiff;
    max_i = max(final_img(:));
%     for roi_idx=1:numel(roi_dataset)
%         current_mask = zeros(size(final_img));
%         current_mask(roi_dataset(roi_idx).pixel_idx) = 1;
%         final_img(bwperim(current_mask)) = rand(1)*max_i;
% 
%     end
% 
%     figure; imagesc(final_img); title('Final image');axis image;
end

function [imgDiff] = getImageDiff(selected_files)
%% GETIMAGEDIFF Returns 2-dimensional representation of an image sequence.
% 
%   I = getImageDiff(IMG), where IMG is a 3-dimensional matrix
%   containing a sequence of input images, and where the value of each
%   pixel in I is the difference between the maximum value and the mean 
%   value of that pixel in the image sequence.
% 
%   Simon Shen 2016

    if class(selected_files)=='char'
        file_list(1).name = selected_files;
    else
%         file_list = cell2struct(selected_files,'name',2);
        % this line added by Michael Romano. not sure why it was set to
        % two...
        file_list = cell2struct(selected_files,'name',numel(selected_files));
    end
    
    for file_idx=1:3

        filename = file_list(file_idx).name;
        fprintf(['Processing ',filename,'....\n']);
        
        InfoImage = imfinfo(filename);
        frame_number = length(InfoImage);

        f_matrix = zeros(InfoImage(1).Height,InfoImage(1).Width,frame_number,'uint16');
        for image_idx=1:frame_number
            f_matrix(:,:,image_idx) = imread(filename,'Index',image_idx,'Info',InfoImage);
        end
        file_ifno(file_idx).frame_number = frame_number;
        file_ifno(file_idx).max = max(f_matrix,[],3);
        file_ifno(file_idx).mean = mean(f_matrix,3);
    end

    whole_max = double(max(cat(3,file_ifno.max),[],3));
    mean_weight = cat(1,file_ifno.frame_number)/sum(cat(1,file_ifno.frame_number));
    whole_mean = sum(bsxfun(@times,cat(3,file_ifno.mean),reshape(mean_weight,1,1,[])),3);
    imgDiff = whole_max-whole_mean;
    
end

function r_out=extract_trace(r_in,selected_files)

    
    whole_tic = tic;
    
    if class(selected_files)=='char'
        file_list(1).name = selected_files;
    else
        % commented out by mike
%         file_list = cell2struct(selected_files,'name',2);
        file_list = cell2struct(selected_files,'name',numel(selected_files));
    end
    
    for file_idx=1:length(file_list)
            
        filename = file_list(file_idx).name;
        fprintf(['Processing ',filename,'....\n']);
        
        InfoImage = imfinfo(filename);
        NumberImages=length(InfoImage);

        f_matrix = zeros(InfoImage(1).Height,InfoImage(1).Width,NumberImages,'uint16');
        for i=1:NumberImages
            f_matrix(:,:,i) = imread(filename,'Index',i,'Info',InfoImage);
        end
        
        f_matrix = double(reshape(f_matrix,InfoImage(1).Height*InfoImage(1).Width,NumberImages));
        
        for roi_idx=1:numel(r_in)
            current_mask = zeros(1,InfoImage(1).Height*InfoImage(1).Width);
            try
                current_mask(r_in(roi_idx).pixel_idx) = 1;
                r_out(roi_idx).pixel_idx = r_in(roi_idx).pixel_idx;
            catch
                current_mask(r_in(roi_idx).PixelIdxList) = 1;
                r_out(roi_idx).pixel_idx = r_in(roi_idx).PixelIdxList;
            end
            current_trace = (current_mask*f_matrix)/sum(current_mask);
            r_out(roi_idx).file(file_idx).filename = filename;
            r_out(roi_idx).file(file_idx).trace = current_trace;
            
            if file_idx==1
                r_out(roi_idx).trace = current_trace;
            else
                r_out(roi_idx).trace = cat(2,r_out(roi_idx).trace,current_trace);
            end
            
        end
        
    end
    
    for roi_idx=1:numel(r_in)
        r_out(roi_idx).color = rand(1,3);
    end
        
    fprintf(['Total loading time: ',num2str(round(toc(whole_tic),2)),' seconds.\n']);
    
end

function imageDataThresh = applyThresh(imageData, threshlow, threshhigh)
%% APPLYTHRESH Segmented image based on threshold value.
% 
%   T = applyThresh(IMG, LOW) returns a binary image of pixels in IMG with values greater than LOW.
% 
%   T = applyThresh(IMG, LOW, HIGH) returns a binary image of pixels in IMG with values between LOW and HIGH. 
% 
%   Simon Shen 2016

    if nargin < 3
        threshhigh = inf;
    end
    imageDataThresh=zeros(size(imageData,1),size(imageData,2));
    imageDataThresh(imageData >= threshlow & imageData <= threshhigh)=1;

end

function [threshValFinal, imgThresh] = calculateThresh(inputImg, roiCriteria)
%% CALCULATETHRESH Calculates and applies threshold value that maximizes the
% number of outputted segmented ROIs in an image.
% 
%   T = calculateThresh(IMG), where IMG is a 3-dimensional matrix
%   containing a sequence of input images.
% 
%   T = calculateThresh(IMG), where IMG is a 2-dimensional
%   representation of an image sequence. The value of each pixel in
%   IMG is the maxiumum value of that pixel across the image sequence. IMG
%   can be obtained using getImageMax.
% 
%   [T, S] = calculateThresh(...) also returns the segmented image.
% 
%   calculateThresh(..., C), where C is a struct containing criteria that
%   define which ROIs are cells.
%       C.minSize    minimum number of pixels in the ROI (default: 50)
%       C.maxSize    maximum number of pixels in the ROI (default: 300)
% 
%   Simon Shen 2016

    %% Prepare inputs i.e. handle optional arguments
    if ismatrix(inputImg)
        imgMax = inputImg;
    else
        imgMax = getImageMax(inputImg);
    end
    if nargin < 2
        roiCriteria.minSize = 50;
        roiCriteria.maxSize = 300;
    end
    numBins = 10;

    %% Feedback loop that finds a threshold value that maximizes the number of ROIs segmented
    minVal = max([min(min(imgMax(imgMax > 0))) 0]);
    maxVal = max(max(imgMax));
    counter = 1;
    while maxVal > minVal
        binSize = (maxVal - minVal) / numBins;
        binVals = minVal:binSize:maxVal;
        binResults = zeros(1, numBins + 1);

        for binNum = 1:numel(binVals)%(numBins + 1)
            threshVal = binVals(binNum);
            imgThresh = applyThresh(imgMax, threshVal, inf);
            imgThresh = morphologicalOps(imgThresh);

            % Apply criteria to remove ROIs that are not cells
            if roiCriteria.maxSize == inf
                imgThresh = bwareaopen(imgThresh, roiCriteria.minSize);
            else
                imgThresh = xor(bwareaopen(imgThresh, roiCriteria.minSize),bwareaopen(imgThresh, roiCriteria.maxSize));
            end

            % Collect threshold result
            [~, numRoisImg] = bwlabel(imgThresh);
    %         fprintf([num2str(threshVal),':',num2str(numRoisImg),'\n']);
            binResults(binNum) = numRoisImg;
            counter = counter + 1;
        end

        % Find max ROIs segmented
        binMax = max(binResults);
    %     figure(2);plot(binVals,binResults);
    %     pause;

        % Find bins that result in max ROIs
        binMaxInd = find(binResults == binMax);

        % Find right-tail end of bins range
        binMaxIndMax = max(binMaxInd);

        % Find left-tail end of bins range
        if numel(binMaxInd) > 1
            binMaxIndMin = min(binMaxInd);
        else
            binMaxIndMin = binMaxIndMax;
        end

        binMaxIndMin = max([1, binMaxIndMin - 1]);
        binMaxIndMax = min([numBins + 1, binMaxIndMax + 1]);

        % Further searching will result in the same range so force end here
        if binMaxIndMax - binMaxIndMin >= numBins - 1
            if binMax > 1 || binSize < 100
                binMaxIndMin = binMaxIndMin + 1;
                binMaxIndMax = binMaxIndMin;
            else
                numBins = numBins * 2;
            end
        end

        minVal = binVals(binMaxIndMin);
        maxVal = binVals(binMaxIndMax);

        if maxVal - minVal < 100 % && binMax > 1
            break;
        end

    end

    %% Find threshold value that produced the best result i.e. most segmented ROIs
    threshValFinal = mean([minVal, maxVal]);
    if nargout == 2
        imgThresh = applyThresh(imgMax, threshValFinal, inf);
        imgThresh = morphologicalOps(imgThresh);
        % Apply criteria to remove ROIs that are not cells
        if roiCriteria.maxSize == inf
            imgThresh = bwareaopen(imgThresh, roiCriteria.minSize);
        else
            imgThresh = xor(bwareaopen(imgThresh, roiCriteria.minSize),bwareaopen(imgThresh, roiCriteria.maxSize));
        end
    end
end

function imgCleared = clearSegmented(img, imgThresh)

    imgCleared = img;
    imgCleared(logical(imgThresh)) = 0;

end

function imgOut = dilate(img)

    se = strel('disk', 1, 0);
    imgOut = imdilate(img,se);

end

function imgMask = getImageMask(imgLabel, roiNumber)
%% GETIMAGEMASK Returns a 2-dimensional representation of an image sequence.
% 
%   I = getImageMask(IMG, N), where IMG is a 2-dimensional labeled image
%   outputted by bwlabel, and N is the label corresponding to the desired
%   ROI.
% 
%   Simon Shen 2016

    imgMask = zeros(size(imgLabel));
    imgMask(imgLabel == roiNumber) = 1;
    
end

function maxval = getNearMax(data)

    sz = size(data);
    nFrames = sz(end);
    sampSize = min(nFrames, 500);
    % maxval = max(data(:));
    maxSamp = zeros(sampSize,1);
    sidx = ceil(linspace(1, nFrames, sampSize))';
    for ks=1:sampSize
       maxSamp(ks) = double(max(max(data(:,:,sidx(ks)))));
    end

    sampval = mean(maxSamp) + exp(1)*std(double(maxSamp));
    % maxval = min( double(maxval), double(sampval));
    dataRange = getrangefromclass(data);
    maxval = min(sampval, dataRange(2));
end

function out = morphologicalOps(img)
%% MORPHOLOGICALOPS Refines segmented image.
% 
%   I = morphologicalOps(IMG), where I is the result of standard 
%   morphological operations including filling up holes, breaking H-
%   connected sections, and removing spur pixels.
% 
%   Simon Shen 2016

    out = imfill(img, 'holes');
    out = bwmorph(out, 'hbreak');
    out = bwmorph(out, 'spur');

end

function imgOut = removeSmall(imgIn, cutoff)

    if nargin < 2
        cutoff = 50;
    end

    imgOut = bwareaopen(imgIn, cutoff);

end

function imgOut = removeSmallSelective(imgRaw, imgIn, thresh, cutoff)

    if nargin < 4
        cutoff = 50;
    end

    imgOut = bwareaopen(imgIn, cutoff);
    [imgRemoved, num] = bwlabel(imgIn - imgOut);

    for i=1:num
        imgMask = getImageMask(imgRemoved,i);
        imgMaskDilate = dilate(imgMask);
        imgMaskRing = imgMaskDilate - imgMask;
        ringThreshPct=sum(sum(imgMaskRing.*imgRaw > thresh))/sum(sum(imgMaskRing));
        if ringThreshPct >= 0.9
            imgOut(imgMaskDilate==1) = 1;
        end
    end

end

function [clean_mask, removed_mask] = removeStrings(img,mask)
%% REMOVESTRINGS Removes thin objects.
% 
%   I = removeStrings(IMG), where I is IMG with thin objects removed. 
%   If the ratio of the area of the convex hull of an object to the area
%   of that object is greater than 1.7, then it is removed.
% 
%   Simon Shen 2016

    clean_mask = mask;
    removed_mask = zeros(size(mask));
%     mask = removeBig(mask);
    [imgLabel, numRois] = bwlabel(mask);

    for i=1:numRois
        imgMask = imgLabel == i;
        imgMaskConv = bwconvhull(imgMask);
        ratio = sum(sum(imgMaskConv)) / sum(sum(imgMask));
        if ratio > 1.7
            clean_mask(imgMask) = 0;
        end

        roiStats = regionprops(imgMask,'Centroid');
        roi_centroid = round(roiStats.Centroid);

        if img(roi_centroid(2),roi_centroid(1))==0
            clean_mask(imgMask) = 0;
            removed_mask(imgMask) = 1;
        end
    end

end

function imgSep = splitOverlap(imgMax, imgThresh)
%% SPLITOVERLAP Separates overlapping ROIs.
% 
%   I = splitOverlap(IMG, BW), where IMG is the output of getImageDiff, 
%   and BW is the segmented IMG.
% 
%   Simon Shen 2016

    % waitbarUpdateFreq = 3;
    imgSep = imgThresh;
    imgOverlaps = bwareaopen(imgThresh, 0);
    [imgLabel, num] = bwlabel(imgOverlaps);

    C.minSize = 20;
    C.maxSize = inf;

    % disp([num2str(num) ' ROIs need to be separated']);

    tic;
    % hWait=waitbar(0,'Processing...');
    % set(hWait,'Name','Processing');
    for i=1:num
        % Update waitbar every waitbarUpdateFreq iterations
        %disp([num2str(i) ' out of ' num2str(num)]);
    %     if mod(i,waitbarUpdateFreq) == 0
    %         rate = toc/waitbarUpdateFreq;
    %         tic;
    %         waitbar(i/num, hWait, ['Processing: about ',num2str((num - i)*rate),' second(s) remaining']);
    %     end
        imgMaskBW = getImageMask(imgLabel, i);
        imgMask = imgMaskBW .* imgMax;
        [~, imgMaskSep] = calculateThresh(imgMask, C);
        % Hua-an: dilate the ROI a little bit so it won't keep shrinking :(
    %     se = strel('disk', 1, 0);
    %     imgMaskSep = imdilate(imgMaskSep,se);
        %
        [~, numSeparated] = bwlabel(imgMaskSep);
        if numSeparated == 0 || numSeparated == 1
            continue;
        end
        imgDifferent = imgMaskBW ~= imgMaskSep;
        imgSep(imgDifferent) = 0;
    end
    % waitbar(1, hWait, 'Done');
    % set(hWait,'Name','Done');
    % close(hWait);

end

function imgSep = splitOverlapRec(imgMax, imgThresh, tree_id)
%% SPLITOVERLAP Separates overlapping ROIs.
% 
%   I = splitOverlap(IMG, BW), where IMG is the output of getImageDiff, 
%   and BW is the segmented IMG.
% 
%   Simon Shen 2016

    imgSep = zeros(size(imgThresh));

    [imgLabel, num] = bwlabel(imgThresh);

    for i=1:num
        if isempty(tree_id)
            current_tree_id = [num2str(i),'(',num2str(num),')'];
        else
            current_tree_id = [tree_id,'->',num2str(i),'(',num2str(num),')'];
        end
        fprintf(['\t',current_tree_id,'\n']);
        imgMaskBW = getImageMask(imgLabel, i);
        se = strel('disk', 1, 0);
        imgMaskBW = imdilate(imgMaskBW,se);
        roiStats = regionprops(imgMaskBW,'BoundingBox');
        rect = roiStats.BoundingBox;

        row_min = max(floor(rect(2)),1);
        row_max = min(floor(rect(2)+ceil(rect(4))),size(imgThresh,1));
        col_min = max(floor(rect(1)),1);
        col_max = min(floor(rect(1)+ceil(rect(3))),size(imgThresh,2));

        imgMaskBW = logical(imgMaskBW);
        imgSep(imgMaskBW) = 0;

        new_imgMax = zeros(size(imgMax));
        new_imgMax(imgMaskBW) = imgMax(imgMaskBW);
        new_imgMax = imgMax(row_min:row_max, col_min:col_max);
        new_imgThresh = imgMaskBW(row_min:row_max, col_min:col_max);
        new_imgSep = splitOverlap(new_imgMax, new_imgThresh);

    % %     Plot old and separated
    %     perimeter1=bwperim(new_imgThresh)==0;
    %     imageDisp1=double(new_imgMax).*(perimeter1);
    %     perimeter2=bwperim(new_imgSep)==0;
    %     imageDisp2=double(new_imgMax).*(perimeter2);
    %     figure(11);subplot(1,2,1);
    %     imagesc(imageDisp1);
    %     subplot(1,2,2);
    %     imagesc(imageDisp2);
    %     
    %     pause;

        [~, new_num] = bwlabel(new_imgSep);
    %     fprintf(['Split into: ',num2str(new_num),'\n']);
        if new_num>1
            imgSep(row_min:row_max, col_min:col_max) = splitOverlapRec(new_imgMax, new_imgSep, current_tree_id);
        else
            imgSep(row_min:row_max, col_min:col_max) = imgSep(row_min:row_max, col_min:col_max) | imgThresh(row_min:row_max, col_min:col_max);
        end
    end

end
