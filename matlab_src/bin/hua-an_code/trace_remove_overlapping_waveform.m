function roi_list =  trace_remove_overlapping_waveform(roi_list, save_keyword)
    
    for roi_idx=1:numel(roi_list)
       
       curr_roi = roi_list(roi_idx);
       taxis = (1:length(curr_roi.trace))/20;
       events = curr_roi.event_idx;
       event_traces = zeros(1,length(curr_roi.trace));
       for e=1:size(events,1)
           event_traces(events(e,1):events(e,2)) = 1;
       end
       event_idx = activeSegmentsSE(event_traces(:));
       event_idx = event_idx{1};
       event_time = taxis(event_idx);
       event_amp = nan(size(event_idx,1),1);
       curr_trace = curr_roi.trace;
       for e=1:size(event_idx,1)
           curr_segment = (curr_trace(event_idx(e,1):event_idx(e,2)));
           event_amp(e) = max(curr_segment)-min(curr_segment);
       end
       roi_list(roi_idx).event_idx = event_idx;
       roi_list(roi_idx).event_time = event_time;
       roi_list(roi_idx).event_amp = event_amp;
    end
    
    save(['processed-data/trace_event_nooverlap_',save_keyword],'roi_list');
    



end