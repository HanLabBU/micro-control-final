%% now examine the timing of the digital pulses

d = 'micro-control-data/mikepracticev3_092618/Block-2';
data = TDTbin2mat(d);

camera_on_times = data.epocs.Valu.onset(1:end-1);

camera_on_times = camera_on_times-camera_on_times(1); % set to t=0

t_true = 1:1:length(camera_on_times);
t_true = (t_true-t_true(1))*0.05;

mdl = fitlm(t_true,camera_on_times);
%%
d2 = 'micro-control-data/mike_motor_adns5_10-5-18_20hz/Block-1';
data2 = TDTbin2mat(d2);

camera_on_times_adns5 = data2.epocs.Valu.onset(1:end-1);
camera_on_times_adns5 = camera_on_times_adns5-camera_on_times_adns5(1);


t_true2 = 1:1:length(camera_on_times_adns5);
t_true2 = (t_true2-t_true2(1))*0.05;

mdl2 = fitlm(t_true2,camera_on_times_adns5);

bias_2 = mdl2.Coefficients.Estimate(2)-1;
bias_1 = mdl.Coefficients.Estimate(2)-1;

% biases are very close to one another