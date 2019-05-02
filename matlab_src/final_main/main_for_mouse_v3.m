x = csvread('micro-control-data/mikepracticev3_092618/motor_output_v3_take2_092618.txt',1,0);
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

% yl = (yl-yr*cos(sensorAngleRadians))/cos(pi/2-sensorAngleRadians);
yl = (yl-yr*cos(sensorAngleRadians))/sin(sensorAngleRadians);

velocity2 = sqrt(yl.^2+yr.^2)*100;
%%

figure;
t = t/(10^6);
plot(t,velocity_cms);
xlabel('Time [s]');
ylabel('Speed [cm/s]');
xlim([53.6199  208.3710]);
title('Example session');
print(gcf,sprintf('figures/mouse_v3_speed_example.svg'),'-dsvg');

st.mn = mean(velocity_cms);
st.sd = std(velocity_cms);

%% now examine the timing of the digital pulses

d = 'micro-control-data/mikepracticev3_092618/Block-2';
data = TDTbin2mat(d);

camera_on_times = data.epocs.Valu.onset(1:end-1);

camera_on_times = camera_on_times-camera_on_times(1); % set to t=0

t_true = 1:1:length(camera_on_times);
t_true = (t_true-t_true(1))*0.05;

mdl = fitlm(t_true,camera_on_times);

figure;
subsampleinds = (1:200:length(t_true))';
plot(t_true(subsampleinds), camera_on_times(subsampleinds)','.k','MarkerSize',15);
hold on;
plot(t_true(subsampleinds),mdl.predict(t_true(subsampleinds)'),'-g','LineWidth',2);
hold off;
xlabel('Theoretical time [s]');
ylabel('Measured time [s]');
title('Camera times');
print('figures/mouse_mvmt_v3_timing.svg','-dsvg');

%% now perhaps plot drift?
figure;
plot(t_true,camera_on_times(:)-t_true(:),'.k');
hold on;
plot(t_true,zeros(size(t)),'g');
mdl2 = fitlm(t_true(:),camera_on_times(:)-t_true(:));
ylim([-.2 .2])
xlabel('Theoretical time[s]');
ylabel('Measured time - theoretical time [s]');
print('figures/difference_measured_minus_teensy_v3.svg','-dsvg');     