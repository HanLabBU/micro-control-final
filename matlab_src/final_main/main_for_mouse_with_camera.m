% first get tiff file names

[fi,dir] = uigetfile('*.tif','multiselect','on');
for f=1:numel(fi)
    fi{f} = [dir fi{f}];
end
save('motor_file_names.mat','fi');

%%
clear
load('motor_file_names.mat');
motion_correct_mike_v1(fi,'motor_102518',[0 nan],'all'); % will leave last, single frame alone

%%
metadata.suffix = 'motor_102518';
[fi,dir] = uigetfile('*.tif','multiselect','on');


for f=1:numel(fi)
    fi{f} = [dir fi{f}];
end
fi2 = order_filenames_processed(fi);
metadata.tiffs = fi2;



save('metadata_motor_102518.mat','metadata');
%%
clear
load('metadata_motor_102518.mat')

%%
roi_simon_new(metadata);

%%
load('micro-control-data/processed-data/imgDiff_simon_motor_102518.mat')
load('micro-control-data/processed-data/roi_simon_motor_102518.mat')
roi_overlay(roi_simon,imgDiff_simon);

xlim([114 114+172]);
ylim([487 487+172]);
print('figures/roi_overlay_motor.svg','-dsvg');
%%
roi_overlay('',imgDiff_simon);
xlim([114 114+172]);
ylim([487 487+172]);
print('figures/max_minus_mean_motor.svg','-dsvg');


%% prune rois
bb = [114 487 172 172];
R = rois_in_bb(trace_simon,bb);
save('micro-control-data/processed-data/roi_simon_motor_trimmed_102518','R');
%%
roi_overlay(R,imgDiff_simon);
print('figures/roi_overlay_motor_trimmed.svg','-dsvg');
%%
x = csvread('micro-control-data/motor_control_v3_1247_102518.txt',1,0);
%% now compute distance travelled in sum

yl = x(:,3);
tl = x(:,4);

yr = x(:,6);
tr = x(:,7);

t = x(:,1);

yl = yl./tl;
yr = yr./tr;

sensorAngleDegrees = 75; % measured by kyle
sensorAngleRadians = (sensorAngleDegrees/360)*2*pi;
velocity_cms = sqrt((yr.^2+yl.^2-2*yl.*yr.*cos(sensorAngleRadians))/sin(sensorAngleRadians).^2)*100;

yl = (yl-yr*cos(sensorAngleRadians))/sin(sensorAngleRadians);

velocity2 = sqrt(yl.^2+yr.^2)*100;

taxis = x(:,1)/1e6;
%%
plot(taxis(1:2000),velocity2(1:2000));
print('figures/example_movement_mouse_imaging.svg','-dsvg');
%%
load('micro-control-data/processed-data/roi_simon_motor_trimmed_102518.mat');
R = R([2 5 6 8 12 14 32 35]);
trace = cat(1,R.trace);
trace = trace';
trace = (bsxfun(@rdivide,bsxfun(@minus,trace,mean(trace)),mean(trace)));
figure;
for r=1:numel(R)
plot(taxis(1:2000),trace(1:2000,r)+r*1.5,'color',R(r).color);
hold on;
end

%    title(sprintf('Trace # %d',r));
   print(sprintf('figures/example_trace_motor.svg',r),'-dsvg');
