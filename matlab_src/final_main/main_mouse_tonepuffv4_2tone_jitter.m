fi = fopen('micro-control-data/mike_twotonejitter_030419/mike_twotone_practice_full_2_8000Hz1_0.1amp1_2000Hz2_0.1amp2.txt');
x = textscan(fi,'%s','delimiter','\n');
x2 = cellfun(@(x) textscan(x,'%s','delimiter',','),x{1});
tbl = table([],[],[],[],[],[],[],'variablenames',{'Time','ExpTime','ExpNo','Puff','Tone1','Tone2','LED'});
for i=1:numel(x2)
    tbl = cat(1,tbl,table(str2double(x2{i}{1}), str2double(x2{i}{2}), str2double(x2{i}{3}), ...
        str2double(x2{i}(4)), str2double(x2{i}(5)),str2double(x2{i}(6)),str2double(x2{i}(7)),'variablenames',{'Time','ExpTime','ExpNo','Puff','Tone1','Tone2','LED'}));
end
save('micro-control-data/mike_twotone_practice_full_2_8000Hz1_0.1amp1_2000Hz2_0.1amp2.mat','tbl');

%% now extract data from tdt files
load('micro-control-data/mike_twotone_practice_full_2_8000Hz1_0.1amp1_2000Hz2_0.1amp2.mat','tbl');

d = 'micro-control-data/mike_twotonejitter_030419/Block-2';
data = TDTbin2mat(d);
trial_frame_starts = find([1; diff(tbl.ExpNo) == 1]);
tone_starts1 = find([0; diff(tbl.Tone1) == 1]);
tone_starts2 = find([0; diff(tbl.Tone2) == 1]);
puff_starts = find([0; diff(tbl.Puff) == 1]);

% now filter
%%
%% now get timing for Sound channel and pulse channel
sound_tdt = data.streams.Soun.data;
camera_tdt = data.streams.Puls.data;
%
taxis_tdt = 0:1:(length(camera_tdt)-1);
taxis_tdt = taxis_tdt/data.streams.Puls.fs; % divide through by the sampling frequency
%
taxis_sound_tdt = 0:1:(length(sound_tdt)-1);
taxis_sound_tdt = taxis_sound_tdt/data.streams.Soun.fs;
% %% get all camera frames
%
camera_on_tdt = camera_tdt > 1;
camera_start = find(~~[0 diff(camera_on_tdt) == 1],1,'first'); % find first time point above 1
%
%% truncate recordings by aligning to first pulse
tdt_camera_times = data.epocs.Valu.onset(1:2:end);
camera_on_tdt = camera_on_tdt(camera_start:end);
taxis_tdt = taxis_tdt(camera_start:end);
sound_inds = (taxis_sound_tdt >= taxis_tdt(1)) & (taxis_sound_tdt <= taxis_tdt(end));

taxis_sound_tdt = taxis_sound_tdt(sound_inds);
sound_tdt = sound_tdt(sound_inds);

taxis_tdt = taxis_tdt-taxis_tdt(1); % set first time point equal to timing of first timestamp
taxis_sound_tdt = taxis_sound_tdt-taxis_sound_tdt(1);

%% now get timing of sound and associated statistics
% times recorded on external device
[b,a] = butter(6,[1000/(data.streams.Soun.fs/2) 3000/(data.streams.Soun.fs/2)],'bandpass');

bp1 = filtfilt(b,a,double(sound_tdt'));
amp1 = abs(hilbert(bp1));

sound_inds = [amp1 >0.025]; % then repeat this for every trial, hopefully it works!
sound_on = find([0; diff(sound_inds) == 1]);
sound_off = find([diff(sound_inds) == -1]);

st.sound_start2 = taxis_sound_tdt(sound_on)' - (tdt_camera_times(tone_starts2)-tdt_camera_times(1));
st.sound_length2 = taxis_sound_tdt(sound_off+1)-taxis_sound_tdt(sound_on);

%% now get timing of sound and associated statistics
% times recorded on external device
[b,a] = butter(6,[7000/(data.streams.Soun.fs/2) 9000/(data.streams.Soun.fs/2)],'bandpass');

bp2 = filtfilt(b,a,double(sound_tdt'));
amp2 = abs(hilbert(bp2));

sound_inds = [amp2 >0.025]; % then repeat this for every trial, hopefully it works!
sound_on = find([0; diff(sound_inds) == 1]);
sound_off = find([diff(sound_inds) == -1]);

st.sound_start1 = taxis_sound_tdt(sound_on)' - (tdt_camera_times(tone_starts1)-tdt_camera_times(1));
st.sound_length1 = taxis_sound_tdt(sound_off+1)-taxis_sound_tdt(sound_on);

%%
[b,a] = butter(6,[1000/(data.streams.Soun.fs/2)],'high');
bp3 = filtfilt(b,a,double(sound_tdt'));
figure;
plot((1:1:length(sound_tdt))/data.streams.Soun.fs,bp3);
xlabel('Time [s]');
xlim([0 388]);
ylabel('Amplitude [mV]');
print('figures/two_sounds_all.svg','-dsvg');

%%
figure;
plt1 = plot((1:1:length(sound_tdt))/data.streams.Soun.fs,amp1,'b');
plt1.Color(4) = .5;
hold on;
plt2 = plot((1:1:length(sound_tdt))/data.streams.Soun.fs,amp2,'r');
plt2.Color(4) = .5;
xlim([0 40]);
hold off;
xlabel('Time [s]');
ylabel('Amplitude [mV]');
legend('2000 Hz','8000 Hz');
print('figures/amplitude_examples.svg','-dsvg');


%% now plot individual wave forms
figure;
plt1 = plot((1:1:length(sound_tdt))/data.streams.Soun.fs,bp1,'b');
xlim([8.0036 8.0205])
hold off;
xlabel('Time [s]');
ylabel('Amplitude [mV]');
print('figures/lowfq_examples.svg','-dsvg');

%%
figure;
plt2 = plot((1:1:length(sound_tdt))/data.streams.Soun.fs,bp2,'r');
xlim([29.2051 29.2220]);
hold off;
xlabel('Time [s]');
ylabel('Amplitude [mV]');
print('figures/highfq_examples.svg','-dsvg');
