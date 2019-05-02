x = csvread('micro-control-data/motor_forwardroll_1.txt',1,0);
%% now compute distance travelled in sum

yl = x(:,3);
yr = x(:,6);
sensorAngleDegrees = 74; % measured by kyle
sensorAngleRadians = (sensorAngleDegrees/360)*2*pi;

yl = (yl-yr*cos(sensorAngleRadians))/cos(pi/2-sensorAngleRadians);

distance = sqrt(yl.^2+yr.^2);

%% now identify each of the rotations
startend = [202 339;...
    399 544; ...
    641 756; ...
    810 909; ...
    990 1097; ...
    1182 1277; ...
    1377 1478; ...
    1554 1659; ...
    1714 1826; ...
    1872 1930; ...
    2015 2106; ...
    2179 2264];
%%

startend = num2cell(startend,2);
distances = cellfun(@(x) sum(distance(x(1):x(2))),startend);
distances = distances/(10^4);
hist(distances)

ball_circumference = 25.125; % in
ball_circumference_cm = ball_circumference*2.54;

%%
[h,p,st] = ttest(distances, ball_circumference_cm);