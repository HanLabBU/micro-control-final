function [data, pre] = homomorphicFilter(data,pre)
% Implemented by Mark Bucklin 6/12/2014
%
% FROM WIKIPEDIA ENTRY ON HOMOMORPHIC FILTERING
% Homomorphic filtering is a generalized technique for signal and image
% processing, involving a nonlinear mapping to a different domain in which
% linear filter techniques are applied, followed by mapping back to the
% original domain. This concept was developed in the 1960s by Thomas
% Stockham, Alan V. Oppenheim, and Ronald W. Schafer at MIT.
%
% Homomorphic filter is sometimes used for image enhancement. It
% simultaneously normalizes the brightness across an image and increases
% contrast. Here homomorphic filtering is used to remove multiplicative
% noise. Illumination and reflectance are not separable, but their
% approximate locations in the frequency domain may be located. Since
% illumination and reflectance combine multiplicatively, the components are
% made additive by taking the logarithm of the image intensity, so that
% these multiplicative components of the image can be separated linearly in
% the frequency domain. Illumination variations can be thought of as a
% multiplicative noise, and can be reduced by filtering in the log domain.
%
% To make the illumination of an image more even, the high-frequency
% components are increased and low-frequency components are decreased,
% because the high-frequency components are assumed to represent mostly the
% reflectance in the scene (the amount of light reflected off the object in
% the scene), whereas the low-frequency components are assumed to represent
% mostly the illumination in the scene. That is, high-pass filtering is
% used to suppress low frequencies and amplify high frequencies, in the
% log-intensity domain.[1]
%
% More info HERE: http://www.cs.sfu.ca/~stella/papers/blairthesis/main/node35.html
%% DEFINE PARAMETERS and PROCESS INPUT
% gpu = gpuDevice(1);
% CONSTRUCT HIGH-PASS (or Low-Pass) FILTER
sigma = 50;
filtSize = 2 * sigma + 1;
hLP = gpuArray(fspecial('gaussian',filtSize,sigma));
% GET RANGE FOR CONVERSION TO FLOATING POINT INTENSITY IMAGE
if nargin < 2
	%    pre.dmax = getNearMax(data); %TODO: move into file as subfunction
	%    pre.dmin = getNearMin(data);
	pre.dmax = max(data(:));
	pre.dmin = min(data(:));
end
inputScale = single(pre.dmax - pre.dmin);
inputOffset = single(pre.dmin);
outputRange = [0 65535];
outputScale = outputRange(2) - outputRange(1);
outputOffset = outputRange(1);
% PROCESS FRAMES IN BATCHES TO AVOID PAGEFILE SLOWDOWN??TODO?
sz = size(data);
N = sz(3);
nPixPerFrame = sz(1) * sz(2);
nBytesPerFrame = nPixPerFrame * 2;

% multiWaitbar('Applying Homomorphic Filter',0);

for k=1:N
	%    if nBytesPerFrame > gpu.AvailableMemory
	% 	  wait(gpu);
	%    end
	% 	multiWaitbar('Applying Homomorphic Filter', 'Increment', 1/N);
	data(:,:,k) = homFiltSingleFrame(data(:,:,k));
end
% multiWaitbar('Applying Homomorphic Filter','Close');

	function im = homFiltSingleFrame(im)
		persistent ioLast
		% TRANSFER TO GPU AND CONVERT TO DOUBLE-PRECISION INTENSITY IMAGE
		imGray =  (single(gpuArray(im)) - inputOffset)./inputScale   + 1;					% {1..2}
		% USE MEAN TO DETERMINE A SCALAR BASELINE ILLUMINATION INTENSITY IN LOG DOMAIN
		io = log( mean(imGray(imGray<median(imGray(:))))); % mean of lower 50% of pixels		% {0..0.69}
		if isnan(io)
			if ~isempty(ioLast)
				io = ioLast;
			else
				io = .1;
			end
		end
		% LOWPASS-FILTERED IMAGE (IN LOG-DOMAIN) REPRESENTS UNEVEN ILLUMINATION
		imGray = log(imGray);																				% log(imGray) -> {0..0.69}
		imLp = imfilter( imGray, hLP, 'replicate');														%  imLp -> ?
		% SUBTRACT LOW-FREQUENCY "ILLUMINATION" COMPONENT
		imGray = exp( imGray - imLp + io) - 1;			% {0..2.72?} -> {-1..1.72?}
		% RESCALE FOR CONVERSION BACK TO ORIGINAL DATATYPE
		imGray = imGray .* outputScale  + outputOffset;
		% CLEAN UP LOW-END (SATURATE TO ZERO OR 100)
		% 	  im(im<outputRange(1)) = outputRange(1);
		% CAST TO ORIGINAL DATATYPE (UINT16) AND RETURN
		im = gather(uint16(imGray));
		ioLast = io;
	end
end