function is_valid = verify_filenames(fnames)
is_valid = 1;
pattern = '.*\((?<id>[0-9]+)\)\.tif';
for f=1:numel(fnames)
    tok = regexp(fnames{f},pattern,'names');
    if f==1
        curr_val = str2double(tok.id);
    else
        temp_val = str2double(tok.id);
        if curr_val + 1 ~= temp_val
            warning(sprintf('files are not in order!!! %s and %s',fnames{f},fnames{f-1}));
            is_valid = 0;
            return
        end
        curr_val = temp_val;
    end
    
end



end