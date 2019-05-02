function [roi_list, keep_roi_idx] =roi_select_size(roi_list, save_keyword, min_size, max_size)
% Hua-an Tseng, huaantseng at gmail
% modified by Michael Romano 02-13-18

    if nargin<2 || isempty(save_keyword)
        save_keyword = datestr(now,'yyyymmdd');
    end
    
    if nargin<3 || isempty(max_size)
        min_size = 50;
    end
    
    if nargin<4 || isempty(min_size)
        max_size = 500;
    end

    fprintf(['Max pixel size: ',num2str(max_size),'\n']);
    fprintf(['Min pixel size: ',num2str(min_size),'\n']);
    
    keep_roi_idx = [];
    for roi_idx=1:numel(roi_list)
        
        current_roi_size = numel(roi_list(roi_idx).pixel_idx);
        if current_roi_size>=min_size && current_roi_size <=max_size
            keep_roi_idx = cat(1,keep_roi_idx,roi_idx);
        end
        
    end
    roi_list = roi_list(keep_roi_idx);
    % modifications made by Mike
    save(['processed-data/refined_roi_size_',save_keyword],'roi_list');

end