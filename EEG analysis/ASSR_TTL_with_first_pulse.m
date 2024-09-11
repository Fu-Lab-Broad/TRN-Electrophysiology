%% stimulation parameters
fs = 48000;          % sample rate (Hz)
Swidth = 0.001;      % pulse width (s), sound stim -> 1 ms %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lenON = 1;           % length of stimulation period (s), in case of 2 Hz & continuous stim lenON differs
pre = 1;           % length of pre-stim period (s) -> 1 s
post = 0.5;          % length of post-stim period (s) 
amp = 5;             % output voltage (V)
ntrial = 100;        % number of trials for a stimulatino frequency
quefrq = [10 20 30 40 50];     % a set of stim frequencies 
len = length(quefrq);          % size of stim frequency set

fac = 15;                   % sound intensity control factor (fac = 5 with random car-r -> 80-90 dB)
fac = 15;                   % sound intensity control factor (fac = 5 with random car-r -> 80-90 dB)

%% pulse train generation  

counter = 1;
clear QFstim;
for n = 1:ntrial        % a trial with whole set of stim frequency ramdom permutated
 
    close all;

    outDATAS = zeros(fs,1);          % data to be queued to device with 1-s delay for each set        
    outDATA_Amp = zeros(fs,1);          % data to be queued to device with 1-s delay for each set        

    for fstim = quefrq(randperm(length(quefrq)))       % in-phase to sound stim

        frqoutS = zeros((pre+lenON+post)*fs,1);         % output data for a single stim frequency, sound 
        lencycle = 1/fstim;                                
        for ind = 1:fstim*lenON     % in-phase
            frqoutS(pre*fs +(ind-1)*round(lencycle*fs) +1:pre*fs +(ind-1)*round(lencycle*fs) + Swidth*fs) = amp;     % sound (1 ms pulse)        
        end            
        
        frqoutAmp = zeros((pre+lenON+post)*fs,1);         % output data for a single stim frequency, sound 
        lencycle = 1/fstim;                                
        for ind = 1     % in-phase
            frqoutAmp(pre*fs +(ind-1)*round(lencycle*fs) +1:pre*fs +(ind-1)*round(lencycle*fs) + Swidth*fs) = amp;     % sound (1 ms pulse)        
        end            
        
        disp(['trial #' num2str(n) ' : ' num2str(fstim) ' Hz']);     
%             figure; plot(frqout,'o-'); ylim([0 1.2])
        
        outDATAS = [outDATAS; frqoutS];     
        outDATA_Amp = [outDATA_Amp; frqoutAmp];     
        
        QFstim(counter,:) = [n fstim]; 
        counter = counter + 1;
    end
    
    figure; plot(outDATAS,'r-'); 
    hold on; plot(outDATA_Amp,'b-'); 
    ylim([0 4])
    
    % DAQ control 
    daq.reset
    daq.getDevices;      % confirm DAQ connection and channel names

    s = daq.createSession('ni');            
    s.Rate = fs;  
%     s.addAnalogOutputChannel('cDAQ2Mod1',0,'Voltage');     
    s.addAnalogOutputChannel('cDAQ1Mod1',0,'Voltage');     
    s.addAnalogOutputChannel('cDAQ1Mod1',1,'Voltage');     
    
    carrier = 1; %rand(size(outDATAS));      % no sound carrier
%     a = sin(2*pi*200*[0:1/fs:16]);
%     a = sin(2*pi*2000*[0:1/fs:16]);
%     carrier = a(1:160000)';
    
    s.queueOutputData([carrier.*outDATAS/fac outDATA_Amp]);      % queue output data to device
    s.prepare;                          % prepare for start (reduce lag)
    s.startBackground;
    
    pause(13+rand(1));
    s.stop;
    clear s;    
   
    close all
end

%% save frequency sequence 

tmp = clock;
save(['ASSR_QFstim_' num2str(tmp(1)) '_' num2str(tmp(2)) '_' num2str(tmp(3)) '_' num2str(tmp(4)) '_' num2str(tmp(5))], 'QFstim');




