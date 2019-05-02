%% takes as arguments the frame numbers from the beginning of the recording
% session that we want to look at. Using the size of each video recording,
% it finds the corresponding indices in each video file and returns a cell
% of size n x m where n is the number of output files based on the
% stepsize, and m is the number of input videos. Each row should be read
% sequentially for each processing loop of
% motion_correction_std_HT_Jun1817_v4.m
function files_out = file_frames_for_step_size(frames_in_files,nframes_in_files,step_size)

% get number of output files (number of times the number of frames goes in,
% plus extra)
n_outfiles = ceil(length(frames_in_files)/step_size);

%initialize output structure. number outfiles x number infiles
files_out = cell(n_outfiles,numel(nframes_in_files));

%store the number of frames in each input video file
frame_nums_in_file = cell(length(nframes_in_files),1);

% initialize this. Will contain the frame numbers counting from the
% beginning of the recording session that are contained in each input
% video. for example, if input video 1 has 2000 frames, the first frame
% number in input 2 is 2001
frame_nums_in_file{1} = 1:nframes_in_files(1);

for i=2:length(nframes_in_files)
    frame_nums_in_file{i} = frame_nums_in_file{i-1}(end)+(1:nframes_in_files(i));
end

assert(length(unique(diff([frame_nums_in_file{:}]))) == 1,'Frames are not sequential');

for i=1:n_outfiles
    % get the frame numbers that we want to go into output file i
    currframes = frames_in_files(((i-1)*step_size+1):min(i*step_size,length(frames_in_files)));
    % find where these frame numbers intersect with frames in each of the
    % videos
    for j=1:size(files_out,2)
       [~,files_out{i,j}] = intersect(frame_nums_in_file{j},currframes); 
    end
end


end