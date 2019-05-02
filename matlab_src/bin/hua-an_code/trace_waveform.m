function roi_list=trace_waveform(roi_list, save_keyword, waveform_window, sample_freq)
% modified by mike
    if nargin<4 || isempty(sample_freq) 
        sample_freq = 20;
    end
    
    if nargin<3 || isempty(waveform_window) 
        waveform_window = [-5 5];
    end
    
    if nargin<2 || isempty(save_keyword) 
        save_keyword = datestr(now,'yyyymmdd');
    end
    
    whole_tic = tic;
    waveform_window_idx = waveform_window*sample_freq;
    
    for roi_idx=1:numel(roi_list)
        trace = roi_list(roi_idx).trace;
        event_end_list = roi_list(roi_idx).event_idx(:,2);
        waveforms = nan(size(event_end_list,1),waveform_window_idx(2)-waveform_window_idx(1)+1);        
        for event_end_idx=1:numel(event_end_list)
            current_event_end = event_end_list(event_end_idx);
            current_event_window = waveform_window_idx+current_event_end;
            if current_event_window(1)>0 && current_event_window(2)<=numel(trace)
                waveform = trace(current_event_window(1):current_event_window(2));
                waveform = waveform-min(waveform);
                waveforms(event_end_idx,:) = waveform;
                
            end
        end
        
        
        
        avg_waveform = nanmean(waveforms,1);
        
        [waveform_max,waveform_max_idx] = max(avg_waveform);
        activation_threshold = (waveform_max-mean(avg_waveform))/2+mean(avg_waveform);
        % activation_threshold = mean(avg_waveform)+std(avg_waveform);
        
        pre_waveform = avg_waveform(1:waveform_max_idx);
        pre_idx = find(fliplr(pre_waveform-activation_threshold)<=0,1);
        post_waveform = avg_waveform(waveform_max_idx:end);
        post_idx = find((post_waveform-activation_threshold)<=0,1);
        
        roi_list(roi_idx).waveforms = waveforms;
        roi_list(roi_idx).avg_waveform = avg_waveform;
        roi_list(roi_idx).rising_time = (pre_idx-1)/sample_freq;
        roi_list(roi_idx).falling_time = (post_idx-1)/sample_freq;
        roi_list(roi_idx).activation_threshold = activation_threshold;
        roi_list(roi_idx).waveform_window = waveform_window;
    end
    
    save(['processed-data/trace_waveform_',save_keyword],'roi_list');
    fprintf(['Total loading time: ',num2str(round(toc(whole_tic),2)),' seconds.\n']);
    
end