function roi_list=trace_event_detection(roi_list, save_keyword, sample_freq)
% Hua-an Tseng, huaantseng at gmail

    whole_tic = tic;

    if nargin<3 || isempty(sample_freq) 
        sample_freq = 20;
    end
    
    if nargin<2 || isempty(save_keyword) 
        save_keyword = datestr(now,'yyyymmdd');
    end
    
    params.Fs = sample_freq;
    params.tapers = [2 3];
    std_threshold = 4;
    window_size = 1;
    pre_window = 20;
    
    for roi_idx=1:numel(roi_list)
        fprintf(['ROI ',num2str(roi_idx),'/',num2str(numel(roi_list)),'\n']);
        whole_trace = roi_list(roi_idx).trace;

        x_axis = [1:numel(whole_trace)]/20;

        [S,t,f]=mtspecgramc(whole_trace,[window_size 0.05],params);
        normalized_S = bsxfun(@minus, S, mean(S,1));
        normalized_S  = bsxfun(@rdivide, normalized_S , std(S,[],1));
        f_idx = find(f>=0 & f<=2);
        power=mean(normalized_S(:,f_idx),2);
        d_power=diff(power);
        
        up_power_idx_list = find(isoutlier(d_power,'median'));
        up_power_idx_list = [up_power_idx_list(1);up_power_idx_list(find(diff(up_power_idx_list)>1)+1)];
        up_power_idx_list = up_power_idx_list(d_power(up_power_idx_list)>mean(d_power));

%         up_threshold = mean(d_power)+std_threshold(1)*std(d_power);
% 
%         up_power_idx_list = diff(sign(d_power-up_threshold));
%         up_power_idx_list = find(up_power_idx_list>0);

        down_power_idx_list = ones(size(up_power_idx_list))*length(d_power);
        
        for up_power_idx=1:numel(up_power_idx_list)

            current_d_power = d_power(up_power_idx_list(up_power_idx):end);
            try
                down_power_idx_list(up_power_idx) = up_power_idx_list(up_power_idx)+find(current_d_power<=0,1,'first');
            catch
                down_power_idx_list(up_power_idx) = up_power_idx_list(up_power_idx);
            end

        end

        event_time = [t(up_power_idx_list)' t(down_power_idx_list)'];
        event_idx = nan(size(event_time));
        event_amp = nan(size(event_time,1),1);
        pre_event_threshold = nan(size(event_time,1),1);

        for spike_time_idx=1:size(event_time,1)
            start_time = event_time(spike_time_idx,1);
            [~,start_idx] = min(abs(x_axis-start_time));
            end_time = event_time(spike_time_idx,2);
            [~,end_idx] = min(abs(x_axis-end_time));

            current_trace = whole_trace(end_idx:end);
            d_current_trace = diff(current_trace);
            extra_end_idx = find(d_current_trace<=0,2);
            end_idx = end_idx+extra_end_idx(2);

            current_trace = whole_trace(start_idx:end_idx);
            ref_idx = start_idx-1;
            [max_amp,max_idx] = max(current_trace);
            end_idx = ref_idx+max_idx(1);
            [min_amp,min_idx] = min(current_trace(1:max_idx));
            start_idx = ref_idx+min_idx(1);

            pre_start_idx = max(1,start_idx-pre_window*sample_freq);
            pre_event_threshold(spike_time_idx) = std_threshold*std(whole_trace(pre_start_idx:start_idx));
            event_amp(spike_time_idx) = max_amp-min_amp;
            event_time(spike_time_idx,1) = x_axis(start_idx);
            event_time(spike_time_idx,2) = x_axis(end_idx);
            event_idx(spike_time_idx,1) = start_idx;
            event_idx(spike_time_idx,2) = end_idx;
        end

        event_time(event_amp<pre_event_threshold,:) = [];
        event_idx(event_amp<pre_event_threshold,:) = [];
        event_amp(event_amp<pre_event_threshold,:) = [];

        roi_list(roi_idx).event_time = event_time;
        roi_list(roi_idx).event_idx = event_idx;
        roi_list(roi_idx).event_amp = event_amp;
    end
    
    save(['processed-data/trace_event_',save_keyword],'roi_list'); % this line modified by Mike
    fprintf(['Total loading time: ',num2str(round(toc(whole_tic),2)),' seconds.\n']);

end


