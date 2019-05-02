function roi_list=trace_remove_empty_waveform(roi_list, save_keyword)

    remove_idx = [];
    for roi_idx=1:numel(roi_list)
        if isempty(roi_list(roi_idx).rising_time) || isempty(roi_list(roi_idx).falling_time)
            remove_idx = [remove_idx roi_idx];
        end
    end
    
    roi_list(remove_idx) = [];
    
    save(['processed-data/refined_trace_waveform_',save_keyword],'roi_list');
    fprintf(['Remove: ',num2str(numel(remove_idx)),'\n']);
    

end