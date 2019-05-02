%%
fi = fopen('micro-control-data/tonepuff_practice_10-06-18/mike_tone_tonepuff2_10-06-18_v0.txt'); 
x = textscan(fi,'%s','delimiter','\n');
x2 = cellfun(@(x) textscan(x,'%s','delimiter',','),x{1});
tbl = table([],[],[],[],[],[],'variablenames',{'Time','ExpTime','ExpNo','Puff','Tone','LED'});
for i=1:numel(x2)-1
    tbl = cat(1,tbl,table(str2double(x2{i}{1}), str2double(x2{i}{2}), str2double(x2{i}{3}), ...
        str2double(x2{i}(4)), str2double(x2{i}(5)),str2double(x2{i}(6)),'variablenames',{'Time','ExpTime','ExpNo','Puff','Tone','LED'}));
end

save('micro-control-data/tone_puff_table_tone_10-06-18.mat','tbl');

%%

load('micro-control-data/tone_puff_table_tone_10-06-18.mat','tbl');
timestamps_orig = tbl.Time;
trial_timestamps = [1; find([0; diff(tbl.ExpNo) == 1]); length(tbl.ExpNo)+1];

toneinds = [0; diff(tbl.Tone) == 1];
d = 'micro-control-data/tonepuff_practice_10-06-18/Block-1';
data = TDTbin2mat(d);

first_frame_time = data.epocs.Valu.onset(1);

sound_data = data.streams.Soun.data;
taxis = (1:length(sound_data))/data.streams.Soun.fs;
invalid_inds = taxis < first_frame_time;
taxis(invalid_inds) = [];
taxis = taxis-taxis(1);
sound_data(invalid_inds) = [];

% [b,a] = butter(6,[9000 10000]/(data.streams.Soun.fs/2),'bandpass');
[b,a] = butter(6,[1000]/(data.streams.Soun.fs/2),'high');
bp = filtfilt(b,a,double(sound_data'));
amp = abs(hilbert(bp));

sound_inds = [0; amp >0.005]; % then repeat this for every trial, hopefully it works!
sound_on = find([0; diff(sound_inds) == 1]);
sound_off = find([diff(sound_inds) == -1]);

%%

% find times in trial for LED on, LED off, Puff on, Puff off
st.led_length = [];
st.puff_length = [];
st.intermission = [];
st.led_length = data.epocs.Sund.offset-data.epocs.Sund.onset;
st.led_length = st.led_length(1:2:end);
st.puff_length = data.epocs.Eval.offset-data.epocs.Eval.onset;
st.puff_length = st.puff_length(1:2:end);
st.intermission = data.epocs.Eval.onset-data.epocs.Sund.offset;
st.intermission = st.intermission(1:2:end);

dp = find([0;diff(tbl.LED) ==1]);

st.ledontimes = tbl.ExpTime(dp);

%% plot and save

subplot(2,2,1);
plot(1:50,st.ledontimes/(10^6),'.','MarkerSize',5);
ylim([11.099 11.101]);
ylabel('LED start [s]');
xlabel('Trial');
xlim([0 51])

subplot(2,2,2)
plot(1:50,st.led_length,'.','MarkerSize',5)
ylim([0.699 0.701]);
ylabel('LED length [s]');
xlabel('Trial');
xlim([0 51])

subplot(2,2,3);
plot(1:50,st.intermission,'.','MarkerSize',5);
ylim([0.249 0.251]);
ylabel('Break interval [s]');
xlabel('Trial');
xlim([0 51])

subplot(2,2,4);
plot(1:50,st.puff_length,'.','MarkerSize',5);
ylim([0.099 0.101]);
ylabel('Puff length [s]');
xlabel('Trial');
xlim([0 51])

print(gcf,'figures/tone_puff_v2.pdf','-dpdf');

fi = fopen('statistics_for_tonepuff.txt','w');
fprintf(fi,'mean led start: %0.9f +/- %0.9f sec\n',mean(st.ledontimes/(10^6)), std(st.ledontimes/(10^6)));
fprintf(fi,'mean led length: %0.9f +/- %0.9f sec\n',mean(st.led_length), std(st.led_length));
fprintf(fi,'mean intermission length: %0.9f +/- %0.9f sec\n',mean(st.intermission), std(st.intermission));
fprintf(fi,'mean puff length: %0.9f +/- %0.9f sec\n',mean(st.puff_length), std(st.puff_length));
fclose(fi);

%%
st.frames = data.epocs.Valu.onset(1:2:end);
st.frames = st.frames-st.frames(1);
theoretical = 0.05*(0:1:(length(st.frames)-1));
mdl = fitlm(theoretical, st.frames);
fprintf('%0.9f\n',mdl.Coefficients.Estimate(2));
figure;
plot(theoretical, st.frames,'.k');
hold on;
plot(theoretical(:), mdl.predict(theoretical(:)),'g');
xlabel('Theoretical time [s]');
ylabel('Measured time [s]');
legend('Data','Model fit','location','northwest');
print(gcf,'figures/tone_puff_model_fit.pdf','-dpdf');

