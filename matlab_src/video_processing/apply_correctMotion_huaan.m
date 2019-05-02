
function [data, prealign] = apply_correctMotion_huaan(data, prealign)
fprintf('Applying Correcting Motion \n')
nFrames = size(data,3);


% ESTIMATE IMAGE DISPLACEMENT USING NORMXCORR2 (PHASE-CORRELATION)
    for k = 1:nFrames

        maxOffset = prealign.offset(k).maxOffset;
        yPadSub_dy = prealign.offset(k).yPadSub_dy;
        xPadSub_dx = prealign.offset(k).xPadSub_dx;

        % APPLY OFFSET TO FRAME
        padFrame = padarray(data(:,:,k), [maxOffset maxOffset], 'replicate', 'both');
        data(:,:,k) = padFrame(yPadSub_dy, xPadSub_dx);



    end


end