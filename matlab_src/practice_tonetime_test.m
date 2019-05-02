d = 'micro-control-data/mike_pintimetest_102718/Block-1'
data = TDTbin2mat(d);

%%
close all
xlimpulse = (1:length(data.streams.Puls.data))/data.streams.Puls.fs;
plot(xlimpulse,data.streams.Puls.data);
yyaxis right;
xlimsound = (1:length(data.streams.Soun.data))/data.streams.Soun.fs;
plot(xlimsound,data.streams.Soun.data);

%%

d = 'micro-control-data/mike_pintimetest_102718/Block-3'
data = TDTbin2mat(d);


close all
xlimpulse = (1:length(data.streams.Puls.data))/data.streams.Puls.fs;
plot(xlimpulse,data.streams.Puls.data);
yyaxis right;
xlimsound = (1:length(data.streams.Soun.data))/data.streams.Soun.fs;
plot(xlimsound,data.streams.Soun.data);


    [b,a] = butter(6,[1000]/(data.streams.Soun.fs/2),'high');
bp = filtfilt(b,a,double(data.streams.Soun.data'));
amp = abs(hilbert(bp));

sound_inds = [0; amp >0.005]; % then repeat this for every trial, hopefully it works!
sound_on = [diff(sound_inds) == 1];


pulseon = [0, diff(data.streams.Puls.data > 1) == 1];

c = xlimpulse(find(pulseon));
d = xlimsound(find(sound_on));


%%

d2 = 'micro-control-data/mike_pintimetest_102718/Block-4'
data = TDTbin2mat(d2);


close all
xlimpulse = (1:length(data.streams.Puls.data))/data.streams.Puls.fs;
plot(xlimpulse,data.streams.Puls.data);
yyaxis right;
xlimsound = (1:length(data.streams.Soun.data))/data.streams.Soun.fs;
plot(xlimsound,data.streams.Soun.data);


    [b,a] = butter(6,[1000]/(data.streams.Soun.fs/2),'high');
bp = filtfilt(b,a,double(data.streams.Soun.data'));
amp = abs(hilbert(bp));

sound_inds = [0; amp >0.005]; % then repeat this for every trial, hopefully it works!
sound_on = [diff(sound_inds) == 1];


pulseon = [0, diff(data.streams.Puls.data > 1) == 1];

c2 = xlimpulse(find(pulseon));
d2 = xlimsound(find(sound_on));


%%

d3 = 'micro-control-data/mike_pintimetest_102718/Block-5'
data = TDTbin2mat(d3);


close all
xlimpulse = (1:length(data.streams.Puls.data))/data.streams.Puls.fs;
plot(xlimpulse,data.streams.Puls.data);
yyaxis right;
xlimsound = (1:length(data.streams.Soun.data))/data.streams.Soun.fs;
plot(xlimsound,data.streams.Soun.data);


    [b,a] = butter(6,[1000]/(data.streams.Soun.fs/2),'high');
bp = filtfilt(b,a,double(data.streams.Soun.data'));
amp = abs(hilbert(bp));

sound_inds = [0; amp >0.005]; % then repeat this for every trial, hopefully it works!
sound_on = [diff(sound_inds) == 1];


pulseon = [0, diff(data.streams.Puls.data > 1) == 1];

c3 = xlimpulse(find(pulseon));
d3 = xlimsound(find(sound_on));