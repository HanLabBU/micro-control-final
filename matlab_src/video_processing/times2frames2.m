%% this function converts the times to the frame numbers counting from the beginning of the video
function [frames, file_lengths] = times2frames2(filename,timestart,timeend)
if all(class(filename) == 'char') % if only one filename, convert it to a cell
    filename = {filename};
end
nfiles = numel(filename); % number of files
file_lengths = nan(nfiles,1); % find total length of each of the files
t = [];
for f=1:nfiles
    info = imfinfo(filename{f}); % get info for all frames for first file
    currt = arrayfun(@getHcTimeStamp2,info); % get time in seconds for each frame
    t = cat(1,t,currt(:)); % ocncatenate
    file_lengths(f) = length(info); % get file length for this one
end
if any(t >= timeend) % if the sequence goes longer than the end
% get last instance in which a frame is less than or equal to start time.
% First instance in which it the time exceeds the last time
    frames = find(t <= timestart,1,'last'):find(t >=timeend,1,'first');
% assert statement
    assert(~any((t(frames) > t(frames(1))) & (t(frames) <= timestart)),'T value after the first frame is less than or equal to start time');
    assert(~any((t(frames) < t(frames(end))) & (t(frames) >= timeend)),'T value before the last frame is greater than end time');
elseif isinf(timeend)
    fprintf('using end to end-timestart\n')
    frames = find(t <= t(end)-timestart,1,'last'):length(t);
    if t(frames(1)) < 900
        warning(sprintf('First frame is less than time point 900: %f\n',t(frames(1))));
    end
else
    fprintf('Using timestart:nframes\n'); % otherwise, just use length of remaining film
    frames = find(t <= timestart,1,'last'):length(t);
end


end
