function fnames = order_filenames_processed(fnames)
pattern = '.*_all_(?<id>[0-9]+)\.tif';
val = nan(numel(fnames),1);
for f=1:numel(fnames)
    tok = regexp(fnames{f},pattern,'names');
    val(f) = str2double(tok.id);
end

[~,i] = sort(val);
fnames = fnames(i);


end