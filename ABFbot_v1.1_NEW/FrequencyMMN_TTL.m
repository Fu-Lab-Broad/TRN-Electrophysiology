
%% Tone maker
clear
fs = 48000;
duration = 0.05
225;

disp('Oddball pair... 1 (4000 Hz targ) or 2 (2000 Hz targ) ? ');
session_option = input('pair = ');
switch(session_option)
    case(1)
        targ = sin(2*pi*4000*(1:duration*fs)/fs); % 4K High Freq Distractor  
        dist= sin(2*pi*2000*(1:duration*fs)/fs);
    case(2)
        targ = sin(2*pi*2000*(1:duration*fs)/fs); % 2K Low Freq Distractor  
        dist= sin(2*pi*4000*(1:duration*fs)/fs);
end

amp = 5; % Target, Distractor amplitudes

targ = (targ - min(targ));
targ = targ / max(targ) * amp;
targ(end) = 0;

dist = (dist - min(dist));
dist = dist / max(dist) * amp;
dist(end) = 0;

% xx = 1:length(targ);
% plot(xx/fs * 1000,targ, 'b-'); hold on; plot(xx/fs *1000,dist, 'r-');
% legend('deviant(4kHz)','standard(2kHz)')
% xlim([0 21]); xlabel('Time (ms)'); ylabel('Voltage (V)')
% ylim([-.1 .6]); hold off;
% drawnow;

%% seq
clear seq ti c l psue y x ki
seq=ones(1,1000);
ti=randperm(1000);
[c,l]=find(ti<101);

counter=1;
psue=find(diff(l)<3)+1;
while ~isempty(psue)
    l(psue)=l(psue)+1;
    psue=find(diff(l)<3)+1;
    counter=counter+1;
end

seq(l)=2;

length(find(seq==2))
length(find(seq==1))
%% soud output (to DAQ)

daq.reset
daq.getDevices;      % confirm DAQ connection and channel names
    
for ntrial=1:length(seq)
    
    clear outDATA outDATAs
    outDATA  = zeros(fix(fs*(1+0.01*round(50*rand(1)))),1);
    outDATAs = outDATA;
    
    if seq(ntrial)==1
        outDATAs(0.5*fs+1:0.5*fs+duration*fs)=dist;
        outDATA(0.5*fs+1:0.5*fs+duration*fs)=amp;
    else
        outDATAs(0.5*fs+1:0.5*fs+duration*fs)=targ;
        outDATA(0.5*fs+1:0.5*fs+duration*0.1*fs)=amp;
        outDATA(0.5*fs+duration*0.5*fs:0.5*fs+duration*0.6*fs)=amp;
    end
    
    disp(['trial #' ,num2str(ntrial) ,' : ' ,num2str(seq(ntrial))]);

%     figure; plot(outDATAs,'-'); ylim([0 2.2])
%     s = daq.createSession(daq.getVendors().ID);
%     devid = daq.getVendors().ID;
    s = daq.createSession('ni');
    s.Rate = fs;
    s.addAnalogOutputChannel('cDAQ1Mod1',0,'Voltage');     
    s.addAnalogOutputChannel('cDAQ1Mod1',1,'Voltage');      

    s.queueOutputData( [outDATAs outDATA]  );
    s.prepare;                          % prepare for start (reduce lag)
    s.startForeground;
    s.stop;
    clear s;

end

    