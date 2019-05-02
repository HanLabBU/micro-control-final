%% main for mouse 
[n, ts, sv] = plx_event_ts('micro-control-data/2min_01ms.plx', 4);
ts = ts-ts(1);

x = csvread('micro-control-data/2min_1ms.txt',1,0);
ts = ts/40000;
t_teensy = (0:1:119999)/1000;

mdl = fitlm(t_teensy,ts);

fprintf('%0.9f\n',mdl.Coefficients.Estimate(2))
% 11 microseconds: 1.000011366


%%

[n, ts, sv] = plx_event_ts('micro-control-data/2min_50ms.plx', 4);
ts = ts-ts(1);

ts = ts/40000;

t_teensy = (0:50:119999)/1000;

mdl = fitlm(t_teensy,ts);

fprintf('%0.9f\n',mdl.Coefficients.Estimate(2))

% drift is 1.000011106