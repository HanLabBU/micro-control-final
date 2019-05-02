x = csvread('micro-control-data/motor_trial_mouse_1753.txt',1,0);
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

% yl = (yl-yr*cos(sensorAngleRadians))/cos(pi/2-sensorAngleRadians);
yl = (yl-yr*cos(sensorAngleRadians))/sin(sensorAngleRadians);

velocity_cms = sqrt(yl.^2+yr.^2)*100;
%%

figure;
t = t/(10^6);
plot(t,velocity_cms);
xlabel('Time [s]');
ylabel('Speed [cm/s]');
xlim([180 260]);
title('Example session');
print(gcf,sprintf('figures/mouse_1753_speed_example.svg'),'-dsvg');

st.mn = mean(velocity_cms);
st.sd = std(velocity_cms);

%% now examine the timing of the digital pulses

d = 'micro-control-data/9-17-2018-Mike-1753-Virmen/Block-1';
data = TDTbin2mat(d);
fs = data.streams.Puls.fs;
data = data.streams.Puls.data;
taxis = (1:1:(length(data)))/fs; % taxis in seconds;

% find all of the digital ones
camera_on = data > 1;

% now find first on index;
camera_start = find(~~[0 diff(camera_on) == 1],1,'first');

taxis = taxis(camera_start:end); % realign taxis
camera_on = camera_on(camera_start:end); % realign camera on time points

camera_start = [1, diff(camera_on) == 1]; % get camera starts

camera_on_times = taxis(~~camera_start); % find corresponding time points

camera_on_times = camera_on_times(1:end-1)-camera_on_times(1); % set to t=0

t_true = 1:1:length(camera_on_times);
t_true = (t_true-t_true(1))*0.05;

mdl = fitlm(t_true,camera_on_times);

figure;

jitter = rand(length(t_true),1)-.5;

plot(t_true, camera_on_times(:),'.k','MarkerSize',5);
hold on;
plot(t_true,mdl.predict(t_true(:)),'-g');
hold off;
xlabel('Theoretical time [s]');
ylabel('Measured time [s]');
title('Camera times');
print('figures/mouse_1753_timing.svg','-dsvg');

%% now perhaps plot drift?
figure;
plot(t_true,camera_on_times(:)-t_true(:),'.k');
hold on;
plot(t_true,zeros(size(t)),'g');
mdl2 = fitlm(t_true(:),camera_on_times(:)-t_true(:));
ylim([-.2 .2])
xlabel('Theoretical time[s]');
ylabel('Measured time - theoretical time [s]');
print('figures/difference_measured_minus_teensy.svg','-dsvg');     