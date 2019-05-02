function trace_event_plot(roi_list, roi_idx_list, sample_freq)
% Hua-an Tseng, huaantseng at gmail

    if nargin<3 || isempty(sample_freq) 
        sample_freq = 20;
    end
    
    if nargin<2 || isempty(roi_idx_list) 
        roi_idx_list = 1:numel(roi_list);
    end

    for roi_idx_list_idx=1:numel(roi_idx_list)
        try
            fig_1 = figure;
            roi_idx = roi_idx_list(roi_idx_list_idx);
            trace = roi_list(roi_idx).trace;
            subplot(2,1,1)
            x_axis = [1:numel(trace)]/sample_freq;
            hold on
            plot(x_axis,trace,'b');
            title(['ROI: ',num2str(roi_idx)]);
            xlim([0 x_axis(end)])
            if ~isempty(roi_list(roi_idx).event_idx)
                for event_idx=1:size(roi_list(roi_idx).event_idx,1)
                    event_start_idx = roi_list(roi_idx).event_idx(event_idx,1);
                    event_end_idx = roi_list(roi_idx).event_idx(event_idx,2);
                    plot(x_axis(event_start_idx:event_end_idx),trace(event_start_idx:event_end_idx),'r');
                end
            end
            hold off

            subplot(2,1,2)
            x_axis = ([-1+(1:numel(roi_list(roi_idx).avg_waveform))]/sample_freq)+roi_list(roi_idx).waveform_window(1);
            hold on;
            plot(x_axis,roi_list(roi_idx).waveforms','color',[0.8 0.8 0.8]);
            plot(x_axis,roi_list(roi_idx).avg_waveform','k');
            try
                line([x_axis(1) x_axis(end)], [roi_list(roi_idx).activation_threshold roi_list(roi_idx).activation_threshold],'color','r')
            end
            xlim([x_axis(1) x_axis(end)])
            hold off;
            pause
            close(fig_1);
        catch
            fig_1 = figure;
            roi_idx = roi_idx_list(roi_idx_list_idx);
            trace = roi_list(roi_idx).trace;
            subplot(2,1,1)
            x_axis = [0:(numel(trace)-1)]/sample_freq;
            hold on
            plot(x_axis,trace,'b');
            title(['ROI: ',num2str(roi_idx)]);
            xlim([0 x_axis(end)])
            if ~isempty(roi_list(roi_idx).event_idx)
                for event_idx=1:size(roi_list(roi_idx).event_idx,1)
                    event_start_idx = roi_list(roi_idx).event_idx(event_idx,1);
                    event_end_idx = roi_list(roi_idx).event_idx(event_idx,2);
                    plot(x_axis(event_start_idx:event_end_idx),trace(event_start_idx:event_end_idx),'r');
                end
            end
            hold off
            pause;
            close(fig_1);
        end
    end

end