function filename = appendTiff(filename)

    if class(filename) == 'cell'
        for c=1:numel(filename)
            if isempty(regexp(filename{c},'.*\.tif'))
                filename{c} = [filename{c} '.tif'];
            end
        end
    elseif class(filename) == 'string'
            if isempty(regexp(filename,'.*\.tif'))
                filename = [filename '.tif'];
            end
    end
end
