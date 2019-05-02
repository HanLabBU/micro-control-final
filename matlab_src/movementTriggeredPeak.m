
function peakActivity = movementTriggeredPeak(activationState, events, radius)
    assert(size(events,2) == 1);
    events = events(:);
    activeRegions = find(events);
    nevents = length(activeRegions);
    index_range = repmat(-radius:radius,nevents,1);
    peak_indices = bsxfun(@plus,index_range,activeRegions)'; % get locations around each event
    peaksvect = activationState(peak_indices(:),:); %get fluorescence around these points
    peakActivity = reshape(peaksvect,2*radius+1,nevents,size(activationState,2)); %correctly reshape
    
    %% try a different way
    out = [];
    for i=1:numel(activeRegions)
       curr_segment = activeRegions(i) + (-radius:radius); 
        out = cat(3,out,activationState(curr_segment,:));
    end
    
    if ~isempty(peakActivity)
        out = permute(out,[1 3 2]);
        assert(isequaln(out,peakActivity));
    end
    
end