
clear
clear global
time = 0;
global MEP_amp_string_EMG1
MEP_amp_string_EMG1 = ['Bckgnd EMG = 0'];
global MEP_amp_string_EMG2
MEP_amp_string_EMG2 = ['Bckgnd EMG = 0'];
global MEP_amp_string_EMG3
MEP_amp_string_EMG3 = ['Bckgnd EMG = 0'];
global MEP_amp_string_EMG4
MEP_amp_string_EMG4 = ['Bckgnd EMG = 0'];

% nChans=1;
% channel names with daq.getDevices
nChans = [0,4];

% define global variables
global rD
global tS
global Hist_Time
global Hist_Data

global bias_ch2
global bias_ch3
global bias_ch4
global bias_ch5

bias_ch2 = 0;
bias_ch3= 0;
bias_ch4= 0;
bias_ch5= 0;

%most basic data acquisition from NI board

s = daq.createSession('ni');
s.addAnalogInputChannel('Dev1', 'ai0', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai4', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai1', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai5', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai2', 'Voltage');

set(s.Channels, 'InputType', 'SingleEnded');
set(s.Channels, 'Range', [-10,10]);
s.Rate = 3000;
s.NotifyWhenDataAvailableExceeds = 100;
s.IsContinuous = true;
lh = addlistener(s, 'DataAvailable', @rData);
s.startBackground();

loop_status=1;
rawEpochData = [];
plotting = [];
tic;
titles = {s.Channels.ID};
duration = 120;
n = 0;

global record

memory_size = 10*round(s.Rate);
% memory_size = 30000;
bias_starttime=0;
Hist_Time =[];
Hist_Data =[];
bias_estimation_duration = GetSecs + 3;

while bias_starttime < bias_estimation_duration
    %it doesn't seem to record anything unless i set the pause
    pause(0.01)
    bias_starttime = GetSecs;
end

% take means
uniqueChunkData = ([Hist_Time, Hist_Data]);

% now clear global data
% Hist_Data = [];
% Hist_Time = []

bias_ch2 = mean(uniqueChunkData((size(uniqueChunkData,1)-2*round(s.Rate)),3));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
bias_ch3 = mean(uniqueChunkData((size(uniqueChunkData,1)-2*round(s.Rate)),4));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
bias_ch4 = mean(uniqueChunkData((size(uniqueChunkData,1)-2*round(s.Rate)),5));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
bias_ch5 = mean(uniqueChunkData((size(uniqueChunkData,1)-2*round(s.Rate)),6));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc

while time < duration
    %  create variables from globals
    timeStamps = tS;
    rawData = rD;
    
    %            currentTime = GetSecs;
    rawEpochData = [rawEpochData; timeStamps rawData];
    
    
    %This pause is key. Without this, the loop does not collect data
    %but runs anyway. Waitsecs doesnt work for this, and neither does a
    %while loop imposing timing using Getsecs > a criterion. Needs to
    %be pause. Also, ensure the pause time is below the amount of time
    %needed to collect one bunch of samples, in this case 200 samples
    %in the listener so 100ms. Anything lower than this is ok. Larger
    %will mean there are gaps in the data acquisition
    pause(0.01)
    time = toc;
    
    uniqueRMSData = [Hist_Time, Hist_Data];
    earliest_emg_data = max(1, length(uniqueRMSData) - round(0.5*s.Rate));
    RMS_chunk_ch2=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),3); %second channel is TMS. First is timestamp. Third is first EMG. Takes last 1000 samples for the chunk to take rms
    RMS_chunk_ch2=RMS_chunk_ch2-bias_ch2;
    rms_ch2=rms(RMS_chunk_ch2);
    MEP_amp_string_EMG1 = ['Bckgnd EMG rFDI = ' num2str(round(rms_ch2, 5))];
    RMS_chunk_ch3=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),4); %second channel is TMS. First is timestamp. Third is first EMG. Takes last 1000 samples for the chunk to take rms
    RMS_chunk_ch3=RMS_chunk_ch3-bias_ch3;
    rms_ch3=rms(RMS_chunk_ch3);
    MEP_amp_string_EMG2 = ['Bckgnd EMG rADM = ' num2str(round(rms_ch3, 5))];
    RMS_chunk_ch4=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),5); %second channel is TMS. First is timestamp. Third is first EMG. Takes last 1000 samples for the chunk to take rms
    RMS_chunk_ch4=RMS_chunk_ch4-bias_ch4;
    rms_ch4=rms(RMS_chunk_ch4);
    MEP_amp_string_EMG3 = ['Bckgnd EMG lFDI = ' num2str(round(rms_ch4, 5))];
    RMS_chunk_ch5=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),6); %second channel is TMS. First is timestamp. Third is first EMG. Takes last 1000 samples for the chunk to take rms
    RMS_chunk_ch5=RMS_chunk_ch5-bias_ch5;
    rms_ch5=rms(RMS_chunk_ch5);
    MEP_amp_string_EMG4 = ['Bckgnd EMG lADM = ' num2str(round(rms_ch5, 5))];
    
    if (size(Hist_Data, 1) > memory_size)
        Hist_Data = Hist_Data((end-memory_size):end,:);
        Hist_Time = Hist_Time((end-memory_size):end,:);
        
        % take means
        uniqueChunkData = ([Hist_Time, Hist_Data]);
        % take 2secs
        uniqueChunkData = uniqueChunkData(round(2*s.Rate), :);
        
        % now clear global data
        % Hist_Data = [];
        % Hist_Time = [];
        
        bias_ch2 = mean(uniqueChunkData(:,3));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
        bias_ch3 = mean(uniqueChunkData(:,4));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
        bias_ch4 = mean(uniqueChunkData(:,5));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
        bias_ch5 = mean(uniqueChunkData(:,6));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
    end
    
    %     n = n+1;
    %     k = size(rawEpochData,1);
    %     fprintf('I have run %i times, and collected %i samples \n', n, k)
    
    
    if time > duration
        figure('name', 'separate')
        tiled_size = size(titles,2);
        switch tiled_size
            case 2
                tiledlayout(1,2)
            case 3
                tiledlayout(2,2)
            case 4
                tiledlayout(2,2)
            case 5
                tiledlayout(2,3)
            case 6
                tiledlayout(2,3)
            case 7
                tiledlayout(2,4)
            case 8
                tiledlayout(2,4)
        end
        
        for i = 0:(size(titles,2)-1)
            nexttile
            plot(rawEpochData(:,1), rawEpochData(:,i+2))
            ylim([-5 5])
            xlim([0 duration])
            title(titles{i+1})
        end
    end
    
    
end
stop(s)


function rData(src, event)
emg_thresh = 0.007;
global rD
global tS
global Hist_Time
global Hist_Data
global record
global MEP_amp_string_EMG1
global MEP_amp_string_EMG2
global MEP_amp_string_EMG3
global MEP_amp_string_EMG4
global bias_ch2
global bias_ch3
global bias_ch4
global bias_ch5

rD = event.Data;
tS = event.TimeStamps;
Hist_Time = [Hist_Time; tS];
Hist_Data = [Hist_Data; rD];
record = [record;[tS rD]];

maxTime = max(Hist_Time);
Plot_Dat = Hist_Data;
% Plot_Dat(:,2) = [Hist_Data(:,2)-bias_ch2];
% Plot_Dat(:,3) = [Hist_Data(:,3)-bias_ch3];
% Plot_Dat(:,4) = [Hist_Data(:,4)-bias_ch4];
% Plot_Dat(:,5) = [Hist_Data(:,5)-bias_ch5];
% [Hist_Data(:,2)-bias_ch3] [Hist_Data(:,3)-bias_ch4] [Hist_Data(:,4)-bias_ch5]]

plot(Hist_Time, Plot_Dat,'-')

ylim([-0.5 0.5])
xlim([maxTime-10 maxTime])
% duration here
% yline(0.007, 'r')

% topright text 'mep'
emg1 = strsplit(MEP_amp_string_EMG1);
emg1 = str2num(emg1{length(emg1)});
if emg1 > emg_thresh
    text(maxTime-4,0.4, MEP_amp_string_EMG1, 'Color', 'red', 'FontSize', 15);
else
    text(maxTime-4,0.4, MEP_amp_string_EMG1, 'Color', 'green', 'FontSize', 15);
end

% topright text 'mep'
emg2 = strsplit(MEP_amp_string_EMG2);
emg2 = str2num(emg2{length(emg2)});
if emg2 > emg_thresh
    text(maxTime-9,0.4, MEP_amp_string_EMG2, 'Color', 'red', 'FontSize', 15);
else
    text(maxTime-9,0.4, MEP_amp_string_EMG2, 'Color', 'green', 'FontSize', 15);
end

% topright text 'mep'
emg3 = strsplit(MEP_amp_string_EMG3);
emg3 = str2num(emg3{length(emg3)});
if emg3 > emg_thresh
    text(maxTime-4,-0.4, MEP_amp_string_EMG3, 'Color', 'red', 'FontSize', 15);
else
    text(maxTime-4,-0.4, MEP_amp_string_EMG3, 'Color', 'green', 'FontSize', 15);
end


% topright text 'mep'
emg4 = strsplit(MEP_amp_string_EMG4);
emg4 = str2num(emg4{length(emg4)});
if emg4 > emg_thresh
    text(maxTime-9,-0.4, MEP_amp_string_EMG4, 'Color', 'red', 'FontSize', 15);
else
    text(maxTime-9,-0.4, MEP_amp_string_EMG4, 'Color', 'green', 'FontSize', 15);
end
end


