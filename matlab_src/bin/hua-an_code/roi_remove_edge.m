function [roi_list, new_roi_idx]=roi_remove_edge(roi_list, save_keyword, edge_pixel)
% Hua-an Tseng, huaantseng at gmail
% edited by Michael Romano, 02-13-18

    if nargin<2 || isempty(save_keyword)
        save_keyword = datestr(now,'yyyymmdd');
    end

    if nargin<3 || isempty(edge_pixel)
        edge_pixel = 10;
    end

    fprintf(['Edge pixel: ',num2str(edge_pixel),'\n']);
    
    % put all ROIs in a mask
    all_mask = zeros(1024,1024);
    for roi_idx=1:numel(roi_list)
        all_mask(roi_list(roi_idx).pixel_idx)=roi_idx;
    end
    
    % clear up ROIs at the edges
    all_mask(1:edge_pixel,:) = 0;
    all_mask(end-edge_pixel:end,:) = 0;
    all_mask(:,1:edge_pixel) = 0;
    all_mask(:,end-edge_pixel:end) = 0;
    
    new_roi_idx = unique(all_mask);
    new_roi_idx(1) = [];
    
    roi_list = roi_list(new_roi_idx);
    
    save(['processed-data/refined_roi_edge_',save_keyword],'roi_list');

end