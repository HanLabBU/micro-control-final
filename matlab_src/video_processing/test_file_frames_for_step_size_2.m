function test_file_frames_for_step_size_2(f,vid_lengths, step_size)

for i=1:numel(vid_lengths)
    if ~isempty(cat(1,f{:,i}))
        assert(max(cat(1,f{:,i})) <= vid_lengths(i),'index exceeds max dimension');
    end
end

for j=1:(size(f,1)-1)
    if ~isempty(cat(2,f(j,:)))
       assert(sum(cellfun(@length,f(j,:))) == step_size,'length of indices not equal to step size') 
    end
end


for i=1:size(f,1)
    for j=2:size(f,2)
        if ~isempty(f{i,j-1})
            if f{i,j-1}(end) == vid_lengths(j-1)
                assert(isempty(f{i,j}) || f{i,j}(1) == 1,'messed up ordering');
            end
        end
    end
end
end