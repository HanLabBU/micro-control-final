dat = 'D:\research\micro-control\micro-control-data\motorcontrol_withstop\motion_with_pause.plx';
[fq, ts_plx] = plx_event_ts(dat,8);
ts_plx = ts_plx(1:end-1)-ts_plx(1);

dat = csvread('D:\research\micro-control\micro-control-data\motorcontrol_withstop\1minuterecording.csv',1,0);

mdl = fitlm(dat(:,1)/(10^6),ts_plx);

fprintf('%f\n',mdl.Coefficients.Estimate(2))
mdl.Coefficients.SE(2)
mean(mdl.Residuals.Raw.^2)
 