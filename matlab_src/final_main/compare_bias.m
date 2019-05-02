%% now examine the timing of the digital pulses

d = 'micro-control-data/mike_practice_20Hz_adns4_10-5-18/Block-1';
data = TDTbin2mat(d);

camera_on_times = data.epocs.Valu.onset(1:end-1);

camera_on_times = camera_on_times-camera_on_times(1); % set to t=0

t_true = 1:1:length(camera_on_times);
t_true = (t_true-t_true(1))*0.05;

mdl = fitlm(t_true,camera_on_times);

%% now load 50 Hz

d50 = 'micro-control-data/mike_motor_adns4_10-5-18_50hz/Block-1';

data50 = TDTbin2mat(d50);

camera_on_times50 = data50.epocs.Valu.onset(1:end-1);

camera_on_times50 = camera_on_times50-camera_on_times50(1); % set to t=0

t_true50 = 1:1:length(camera_on_times50);
t_true50 = (t_true50-t_true50(1))*0.02;

mdl50 = fitlm(t_true50,camera_on_times50);

%% now load 100 Hz

d100 = 'micro-control-data/mike_motor_adns4_10-5-18_100hz/Block-1';

data100 = TDTbin2mat(d100);

camera_on_times100 = data100.epocs.Valu.onset(1:end-1);

camera_on_times100 = camera_on_times100-camera_on_times100(1); % set to t=0

t_true100 = 1:1:length(camera_on_times100);
t_true100 = (t_true100-t_true100(1))*0.01;

mdl100 = fitlm(t_true100,camera_on_times100);

%% compare bias

bias20 = mdl.Coefficients.Estimate(2)-1;
bias50 = mdl50.Coefficients.Estimate(2)-1;
bias100 = mdl100.Coefficients.Estimate(2)-1;

% timing bias is similar for all of these

%% actual frequencies
