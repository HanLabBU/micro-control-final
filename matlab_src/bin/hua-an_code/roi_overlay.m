function roi_overlay(roi_list, video_matrix)
% Hua-an Tseng, huaantseng at gmail

%     if isempty(roi_list)
%         [roi_file,roi_filedir] = uigetfile(['*.mat'],'MultiSelect','off');
%         load(fullfile(roi_filedir,roi_file));
%         if exist('roi_list','var')
%             roi_list = r_out;
%         end
%     end
    
    if isempty(video_matrix)
        [video_file_list_temp,video_filedir] = uigetfile(['*.tif'],'MultiSelect','on');
        switch class(video_file_list_temp)
            case 'char'
                video_file_list{1} = video_file_list_temp;
            case 'cell'
                video_file_list = video_file_list_temp;
        end
        
        
        frame_number = zeros((length(video_file_list)+1),1);

        for video_file_idx=1:length(video_file_list)
            filename = fullfile(video_filedir,video_file_list{video_file_idx});
            InfoImage = imfinfo(filename);
            frame_number(video_file_idx+1) = length(InfoImage);
        end

        total_frame = sum(frame_number);

        video_matrix = zeros(InfoImage(1).Height,InfoImage(1).Width,total_frame,'uint16');
        
        for video_file_idx=1:length(video_file_list)
            filename = fullfile(video_filedir,video_file_list{video_file_idx});
            fprintf(['Loading ',video_file_list{video_file_idx},'\n']);
            InfoImage = imfinfo(filename);
            NumberImages = length(InfoImage);
            frame_zero = sum(frame_number(1:video_file_idx));
            for i=1:NumberImages
                video_matrix(:,:,i+frame_zero) = imread(filename,'Index',i,'Info',InfoImage);
            end
        end
        
    end
    
    projected_image = max(video_matrix,[],3);
    
    projected_image = projected_image/(mean(projected_image(:)+10*std(projected_image(:))));
    
    final_image = repmat(projected_image,[1,1,3]);
    se = strel('disk', 1, 0);
    
    for roi_idx=1:numel(roi_list)
        roi_mask = zeros(1024,1024);
        try
            roi_mask(roi_list(roi_idx).pixel_idx)=1;
        catch
            roi_mask(roi_list(roi_idx).PixelIdxList)=1;
        end
        roi_boundary = imdilate(roi_mask,se)-roi_mask;
        final_image(logical(roi_boundary)) = 0;
        for color_idx=1:3
            color_image = final_image(:,:,color_idx);
            try
                color_image(logical(roi_boundary)) = roi_list(roi_idx).color(color_idx);
            catch
                color_image(logical(roi_boundary)) = rand;
            end
            final_image(:,:,color_idx) = color_image;
        end     
    end
    
    figure;
    imagesc(final_image);
    axis image

end