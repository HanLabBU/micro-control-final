%modified by michael romano. written originally by Mark Bucklin, modified by Kyle and Hua-an
%pass in a cell of tiff filenames, the suffix that you want to use to write
%the file, and a 1x2 matrix of start and end times. Pref is also for simply
%labelling the output videos.
function [err] = motion_correct_mike_v2(filename, suffix, timespan, pref) 

%% motion correct each file and save it with 'm_' at the beginning for raw  data and 'm_f_' for homomorphic filtered version
    err = 0;
    whole_tic = tic;
    
    %% get timestamp limits of frame
    if nargin < 3
        timestart = 0; timeend = nan;
    else
        timestart = timespan(1);
        timeend = timespan(2);
    end
    
    filename = appendTiff(filename); % add tiff to the end of the filenames

    %%  verify filenames and make sure that they are in order.
    % ensure that frames in each video are in proper order
    if all(class(filename) == 'cell')
        val = verify_filenames(filename);
        if ~val
            filename = order_filenames(filename);
        end
        sprintf('%s\n',filename{:})
    end
    
    % get frame numbers corresponding to our time sequence
    [frames_in_files, nframes_in_files] = times2frames2(filename,timestart,timeend); 

    % set step size going through the videos
    step_size = 2000;
    
    % given the step size, find the frame numbers in each video that will
    % be analyzed in each loop. file_frames is a 2-d cell where each row
    % corresponds to each video to be written, and each column corresponds
    % each video to be read from
    file_frames = file_frames_for_step_size(frames_in_files,nframes_in_files,step_size);

    % test this in a number of ways. Raises an error if file_frames doesn't
    % meet certain requirements
    test_file_frames_for_step_size_2(file_frames, nframes_in_files, step_size);
    
    folder = ['/hdd2/microcontrol/' suffix ' /'];
    mkdir(folder);
    %% for each output file, get necessary input frames, process, and save
    for n=1:size(file_frames,1)
        % get data and info for current 2000 frame chunk
        [data, currinfo] = generate_tiff_frames(filename,file_frames(n,:));
        
        % PRE-FILTER TO CORRECT FOR UNEVEN ILLUMINATION (HOMOMORPHIC FILTER)
        if n == 1
            [data_h, procstart_m_f.hompre] = homomorphicFilter(data);
            [~, procstart_m_f.xc,procstart_m_f.prealign] = correctMotion2(data_h);
        else
            [data_h, procstart_m_f.hompre] = homomorphicFilter(data,procstart_m_f.hompre);
            [~, procstart_m_f.xc,procstart_m_f.prealign] = correctMotion2(data_h,procstart_m_f.prealign);
        end
        
        data_m = apply_correctMotion_huaan(data,procstart_m_f.prealign);
        
        %mike added this piece
        save_filename = [folder 'm_',suffix,'_',pref];
        save([ folder 'procstartdata' suffix '_' pref '_' num2str(n) '.mat'],'procstart_m_f');
        matrix2tiff(data_m, currinfo, [save_filename '_' num2str(n)], 'w');
        
        
        if n == 1
            [data_mn, procstart_m_f.norm] = normalizeData2(data_m);
        else
            [data_mn, procstart_m_f.norm] = normalizeData2(data_m,procstart_m_f.norm);
        end
        
        %mike added this piece
        save_filename = [ folder 'm_n2_',suffix,'_',pref];
        save([folder 'procstartdata' suffix '_' pref '_' num2str(n) '.mat'],'procstart_m_f');
        matrix2tiff(data_mn, currinfo, [save_filename '_' num2str(n)], 'w');
        
        clear data_mn data_m data
    end
        
    fprintf(['Total processing time: ',num2str(round(toc(whole_tic)/60,2)),' minutes.\n']);
end

function filename = appendTiff(filename)

    if all(class(filename) == 'cell')
        for c=1:numel(filename)
            if isempty(regexp(filename{c},'.*\.tif'))
                filename{c} = [filename{c} '.tif'];
            end
        end
    elseif all(class(filename) == 'char')
            if isempty(regexp(filename,'.*\.tif'))
                filename = [filename '.tif'];
            end
    end
end


function matrix2tiff(f_matrix, info, filename, method)
        
    if isempty(strfind(filename,'.tif'))
        filename = [filename,'.tif'];
    end

    NumberImages = size(f_matrix,3);
    try
    switch method
        case 'w'
            FileOut = Tiff('temp_file','w');

        case 'w8'
            FileOut = Tiff('temp_file','w8');
    end

    tags.ImageLength = size(f_matrix,1);
    tags.ImageWidth = size(f_matrix,2);
    tags.Photometric = Tiff.Photometric.MinIsBlack;
    tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tags.BitsPerSample = 16;
    % new line added by Mike
    tags.ImageDescription = info(1).ImageDescription;
    setTag(FileOut, tags);
    FileOut.write(f_matrix(:,:,1));
    for i=2:NumberImages
        FileOut.writeDirectory();
        % new line added by Mike
        tags.ImageDescription = (info(i).ImageDescription);
        setTag(FileOut, tags);
        FileOut.write(f_matrix(:,:,i));
    end
    FileOut.close()
    catch
        keyboard
    end
    movefile('temp_file',filename);
end