function China_hotspot_KR_CSI
%This version is currently suitable for the wireless delsys only.
%Plug the TMS into channel 0 and the EMG channels following this
%Channel list should be
%Channel 0- TMS 1
%Channel 1- FDI (target muscle for MEPs)
%Channel 2- Muscle 2
%Channel 3- Muscle 3
%Channel 4- Muscle 4
%Channel 5- TMS 2
close all
clear all
ListenChar(0);

prompt = {'Desired Intensity:','Show channel...Type 1 to see ch1&2, Type 3 to see ch3&4, Type 5 to see ch 5&6   :'};
dlg_title = 'Input';
num_lines = 1;
answer = inputdlg(prompt,dlg_title,num_lines);

intensity=str2num(answer{1});

show_channel=str2num(answer{2});

if intensity>100;
    intensity=100;
end

if intensity < 100
    intensity_string = ['0' num2str(intensity)];
else
    intensity_string = num2str(intensity);
end

% Seed random number generator
rng('shuffle');

% set experiment parameters
%nChans = 'ai0';  % number of recording channels
nMEPs = 500;  % number of MEPs to collect
emgDuration = 1;  % collect EMG data for this duration
triggerTime = 0.5;  % time after trial start to send TMS trigger
minGap = 6;
maxGap = 9;   % set min and max gap times
gapDurationArray = (rand(nMEPs,1)*(maxGap-minGap)) + minGap;  % array of gap duration between trials
MEPvector1=[];
MEPvector2=[];
MEPvector3=[];
MEPvector4=[];
% MEPvector5=[];
% MEPvector6=[];

%% Call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
% Give Matlab high priority
Priority(2);
KbName('UnifyKeyNames'); % to increase portability of the code between different platforms
% The avaliable keys to press
spaceKey = KbName('SPACE');
upKey =  KbName('UpArrow'); %
downKey = KbName('DownArrow'); %
escapeKey = KbName('ESCAPE');
endKey = KbName('End');
ExtraIntensityKey=KbName('Alt');

%To prevent the key presses showing in the command window
ListenChar(2);
% Dummy calls to make sure functions are ready to go without delay
KbCheck;
[keyIsDown, secs, keyCode] = KbCheck;



% define global variables
global rD
global tS


% setup data acquisition device
s = daq.createSession('ni');
%s.addAnalogInputChannel('Dev1', nChans, 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai0', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai4', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai1', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai5', 'Voltage');
s.addAnalogInputChannel('Dev1', 'ai2', 'Voltage');
% s.addAnalogInputChannel('Dev1', 'ai6', 'Voltage');
% s.addAnalogInputChannel('Dev1', 'ai3', 'Voltage');
% s.addAnalogInputChannel('Dev1', 'ai7', 'Voltage');
set(s.Channels, 'InputType', 'SingleEnded');
set(s.Channels, 'Range', [-10,10]);
s.Rate = 3000;
s.NotifyWhenDataAvailableExceeds = 100;
s.IsContinuous = true;
lh = addlistener(s, 'DataAvailable', @rData);
s.startBackground();

%Define some timings in frames for detecting MEP onset
DelsysDelayFrames=0.016 * round(s.Rate); % The Biopac wireless delay is 15.6ms fixed and 0.5ms variable, rounding to 16ms here
MEP_latencyFrames=0.015 * round(s.Rate);
MEP_duration=0.045 * round(s.Rate);
%Define some timings in frames for background EMG rms calculation


%% SET UP TMS AND SERIAL PORT COMMUNICATION
% delete(instrfindall);  % to clear any pre existing COM port activities
% %Set up serial port connection
% ser = serial('COM8');  % COM number is machine specific!
%
% % initialise serial port
% set(ser, 'BaudRate', 115200);
% set(ser, 'Parity', 'none');
% set(ser, 'DataBits', 8);
% set(ser, 'StopBit', 1);
%
% % open serial port
% fopen(ser);
% fwrite(ser,'0,0,1*'); % unlock stimulator
% WaitSecs(1);
% fwrite(ser,'0,0,2*'); % enable boost mode
% WaitSecs(1);
% fwrite(ser,'1,1,0*'); % arm stimulator
% WaitSecs(1);
% fwrite(ser,['1,3,' intensity_string '*']); % set power to required intensity
% WaitSecs(1);
%
%% CSI: This is the part that needs to change: Open Communication to the new Brainbox device
%Opening communication to both devices, called DuoMag1 and DuoMag2
DuoMag1 = duoOpen('COM8');
%Second not connected
%DuoMag2 = duoOpen('COM4');

%Set Intensity
duoPulse(DuoMag1, intensity)
%Second not connected
%duoPulse(DuoMag2, intensity_string)


%keep this statement
end_Trial=false;

%% START EXPERIMENT
while end_Trial == false
    
    for ii = 1:nMEPs
        
        rawEpochData = [];
        triggerSent = 0;
        exitTrial = false;
        
        
        
        %% Check the keyboard to see if a button has been pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        
        % check for exit request
        if keyCode(spaceKey)
            MEPvector1=[];
            MEPvector2=[];
            MEPvector3=[];
            MEPvector4=[];
            %             MEPvector5=[];
            %             MEPvector6=[];
            
        elseif keyCode(upKey) | keyCode(ExtraIntensityKey)
            ListenChar(0);
            MEPvector1=[];
            MEPvector2=[];
            MEPvector3=[];
            MEPvector4=[];
            prompt = {'Enter TMS intensity '};
            dlg_title = 'Input';
            num_lines = 1;
            defaultans = {'30'};
            answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
            ListenChar(2);
            intensity=str2num(answer{1});
            figure(1);
            
            if intensity>100;
                intensity=100;
            end
            
            if intensity < 100
                intensity_string = [ '0' num2str(intensity)];
            else
                intensity_string = num2str(intensity);
            end
            
            % fwrite(ser,['1,3,' intensity_string '*']); % set power to required intensity
            % Display power level;
            
            %New command for Intensity
            duoPulse(DuoMag1, intensity);
            
            display(intensity);
            
        elseif keyCode(endKey)
            end_Trial = true;
            
        elseif keyCode(downKey)
            ListenChar(0);
            prompt = {'Show channel ... Type 1 or 3:'};
            dlg_title = 'Input';
            num_lines = 1;
            answer = inputdlg(prompt,dlg_title,num_lines);
            show_channel=str2num(answer{1});
            figure(1);
            ListenChar(2);
            
        elseif keyCode(escapeKey)
            end_Trial = true;
            ListenChar(0);
            %Clear serial port
            %             delete(instrfindall);
            %             fclose(ser);
            %             delete(ser)
            %             clear all
            break
        end
        %% Collect Data and send TMS trigger
        
        trialStartTime = GetSecs;
        
        while exitTrial == false
            
            %  create variables from globals
            timeStamps = tS;
            rawData = rD;
            
            currentTime = GetSecs;
            
            rawEpochData = [rawEpochData; timeStamps rawData];
            % send trigger
            if triggerSent == 0 ...
                    && currentTime - trialStartTime > triggerTime
                % send trigger via serial port here
                % fwrite(ser,'1,4,0*'); % trigger single pulse
                % new pulse commands
                duoPulse(DuoMag1)
                TMS_time = GetSecs;
                triggerSent = 1;
            end
            
            %exit if longer in while loop than emg duration
            if  currentTime - trialStartTime > emgDuration
                exitTrial = true;
            end
            
            %This pause is key. Without this, the loop does not collect data
            %but runs anyway. Waitsecs doesnt work for this, and neither does a
            %while loop imposing timing using Getsecs > a criterion. Needs to
            %be pause. Also, ensure the pause time is below the amount of time
            %needed to collect one bunch of samples, in this case 200 samples
            %in the listener so 100ms. Anything lower than this is ok. Larger
            %will mean there are gaps in the data acquisition
            pause(0.0001)
            
            
        end
        
        %% for TMStrigger Timing
        % Not needed anymore
        % create time array that is same length as sample
        % TMS = zeros(round(s.Rate)*emgDuration,1);
        % delay from when time is checked to pulse command, 1ms
        % TMS_delay = 0.01;
        % calculate time from start of data collection to trigger time
        % TMS_onset =  round(round(s.Rate)*(TMS_delay + TMS_time - trialStartTime));
        % sampling rate of 2000Hz, so time in s * 2000 should give intex
        % of when trigger timing needs to be positive
        % TMS(TMS_onset) = 4;
        % get_TMS_onset(TMS)
        
        %% process emg data for feedback
        uniqueEpochData = unique(rawEpochData, 'rows');
        
        TMS=uniqueEpochData(:,2);
        EMG1=uniqueEpochData(:,3);
        EMG2=uniqueEpochData(:,4);
        EMG3=uniqueEpochData(:,5);
        EMG4=uniqueEpochData(:,6);
        %          EMG5=uniqueEpochData(:,7);
        %         EMG6=uniqueEpochData(:,8);
        
        TMS_onset = get_TMS_onset(TMS); %function returns the first frame of the TMS pulse
        MEP_onset = TMS_onset+MEP_latencyFrames+DelsysDelayFrames;
        MEP_offset = MEP_onset+MEP_duration;
        
        %Calculate MEP amplitude
        MEP_amp_EMG1=(max(EMG1(MEP_onset:MEP_offset)))-(min(EMG1(MEP_onset:MEP_offset)));
        MEP_amp_EMG2=(max(EMG2(MEP_onset:MEP_offset)))-(min(EMG2(MEP_onset:MEP_offset)));
        MEP_amp_EMG3=(max(EMG3(MEP_onset:MEP_offset)))-(min(EMG3(MEP_onset:MEP_offset)));
        MEP_amp_EMG4=(max(EMG4(MEP_onset:MEP_offset)))-(min(EMG4(MEP_onset:MEP_offset)));
        %          MEP_amp_EMG5=(max(EMG5(MEP_onset:MEP_offset)))-(min(EMG5(MEP_onset:MEP_offset)));
        %         MEP_amp_EMG6=(max(EMG6(MEP_onset:MEP_offset)))-(min(EMG6(MEP_onset:MEP_offset)));
        MEPvector1= [MEPvector1; MEP_amp_EMG1];
        MEPvector2= [MEPvector2; MEP_amp_EMG2];
        MEPvector3= [MEPvector3; MEP_amp_EMG3];
        MEPvector4= [MEPvector4; MEP_amp_EMG4];
        %          MEPvector5= [MEPvector5; MEP_amp_EMG5];
        %         MEPvector6= [MEPvector6; MEP_amp_EMG6];
        
        % This now disregards first MEP-value
        MeanMEP1=mean(MEPvector1(2:end));
        MeanMEP2=mean(MEPvector2(2:end));
        MeanMEP3=mean(MEPvector3(2:end));
        MeanMEP4=mean(MEPvector4(2:end));
        %         MeanMEP5=mean(MEPvector5);
        %         MeanMEP6=mean(MEPvector6);
        %
        %Calculate background EMG rms in 100 ms up until 5ms before TMS
        %calculate the offset or bias, before rms measurement
        % set a sampling rate dependant onset and offset
        srd_bias_start = 0.05*round(s.Rate);
        srd_bias_end = 0.25*round(s.Rate);
        bias_EMG1=mean(EMG1(srd_bias_start:srd_bias_end));
        bias_EMG2=mean(EMG2(srd_bias_start:srd_bias_end));
        bias_EMG3=mean(EMG3(srd_bias_start:srd_bias_end));
        bias_EMG4=mean(EMG4(srd_bias_start:srd_bias_end));
        %          bias_EMG5=mean(EMG5(100:500));
        %         bias_EMG6=mean(EMG6(100:500));
        %remove bias and calculate rms background EMG
        biasCorrectedEMG1=EMG1-bias_EMG1;
        biasCorrectedEMG2=EMG2-bias_EMG2;
        biasCorrectedEMG3=EMG3-bias_EMG3;
        biasCorrectedEMG4=EMG4-bias_EMG4;
        %           biasCorrectedEMG5=EMG5-bias_EMG5;
        %         biasCorrectedEMG6=EMG6-bias_EMG6;
        
        bckgnd_EMG_pre_TMS = 0.105 * round(s.Rate); %start measuring background EMG 105ms before TMS
        bckgnd_EMG_duration = 0.1 * round(s.Rate); %num frames needed to estimate backgnd EMG
        
        backgnd_EMG_onset = (TMS_onset+DelsysDelayFrames)-bckgnd_EMG_pre_TMS;
        backgnd_EMG_offset = backgnd_EMG_onset + bckgnd_EMG_duration;
        backgroundEMG1= rms(biasCorrectedEMG1(backgnd_EMG_onset:backgnd_EMG_offset));
        backgroundEMG2= rms(biasCorrectedEMG2(backgnd_EMG_onset:backgnd_EMG_offset));
        backgroundEMG3= rms(biasCorrectedEMG3(backgnd_EMG_onset:backgnd_EMG_offset));
        backgroundEMG4= rms(biasCorrectedEMG4(backgnd_EMG_onset:backgnd_EMG_offset));
        %           backgroundEMG5= rms(biasCorrectedEMG5(backgnd_EMG_onset:backgnd_EMG_offset));
        %         backgroundEMG6= rms(biasCorrectedEMG6(backgnd_EMG_onset:backgnd_EMG_offset));
        
        backgroundEMG_string= 'EMG';
        MEP_amp_string_EMG1= ['MEP ' num2str(MEP_amp_EMG1)];
        MeanMEP_string_EMG1= ['AVE ' num2str(MeanMEP1)];
        MEP_amp_string_EMG2= ['MEP ' num2str(MEP_amp_EMG2)];
        MeanMEP_string_EMG2= ['AVE ' num2str(MeanMEP2)];
        MEP_amp_string_EMG3= ['MEP ' num2str(MEP_amp_EMG3)];
        MeanMEP_string_EMG3= ['AVE ' num2str(MeanMEP3)];
        MEP_amp_string_EMG4= ['MEP ' num2str(MEP_amp_EMG4)];
        MeanMEP_string_EMG4= ['AVE ' num2str(MeanMEP4)];
        %         MEP_amp_string_EMG5= ['MEP ' num2str(MEP_amp_EMG5)];
        %         MeanMEP_string_EMG5= ['AVE ' num2str(MeanMEP5)];
        %         MEP_amp_string_EMG6= ['MEP ' num2str(MEP_amp_EMG6)];
        %         MeanMEP_string_EMG6= ['AVE ' num2str(MeanMEP6)];
        
        %% Plot Plots
        if show_channel == 1;
            %Plotting
            subplot(2,1,1);
            %set(gcf,'position', [10 10 1240 900]);
            %ylim([-0.5, 0.5])];
            ylim([-0.5 0.5]);
            % include line at y=0.5
            MEP_y_thresh_1 = yline(0.25, 'm:');
            
            %set xPlot 100ms before MEP
            %xlim([1100 1450]);
            % set sampling rate dependant xlims
            srd_xlim_start = TMS_onset - 0.05 * round(s.Rate);
            srd_xlim_end = TMS_onset + 0.125 * round(s.Rate);
            
            xlim([srd_xlim_start srd_xlim_end]);
            hold on
            % just for visualisation, put in TMS onset, MEP_onset and MEP
            % offset
            TMS_x_onset_1 = xline(TMS_onset, 'b');
            MEP_x_onset_1 = xline(MEP_onset, 'r');
            MEP_x_offset_1 = xline(MEP_offset, 'r');
            
            % set sampling rate dependant positions
            srd_x_pos_1 = TMS_onset + 0.075*round(s.Rate);
            srd_x_pos_2 = TMS_onset - 0.045*round(s.Rate);
            
            %topright text 'mep'
            MEPtext=text(srd_x_pos_1,0.4, MEP_amp_string_EMG1, 'Color', 'red', 'FontSize', 34);
            % bottomright text 'ave'
            MeanMEPtext=text(srd_x_pos_1,-0.2, MeanMEP_string_EMG1, 'Color', 'red', 'FontSize', 34);
            % EMG text
            EMG_txt1 = text(srd_x_pos_2,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
            EMGtext=text(srd_x_pos_2,0.4, num2str(backgroundEMG1), 'Color', 'red', 'FontSize', 34);
            plot1=plot((biasCorrectedEMG1), 'LineWidth', 2);
            
            subplot(2,1,2);
            %set(gcf,'position', [10 10 1240 900]);
            %ylim([-0.5, 0.5])];
            ylim([-0.5 0.5]);
            % include line at y=0.5
            MEP_y_thresh_2 = yline(0.25, 'm:');
            
            %set xPlot 100ms before MEP
            %xlim([1100 1450]);
            % set sampling rate dependant xlims
            srd_xlim_start = TMS_onset - 0.05 * round(s.Rate);
            srd_xlim_end = TMS_onset + 0.125 * round(s.Rate);
            
            xlim([srd_xlim_start srd_xlim_end]);
            hold on
            TMS_x_onset_2 = xline(TMS_onset, 'b');
            MEP_x_onset_2 = xline(MEP_onset, 'r');
            MEP_x_offset_2 = xline(MEP_offset, 'r');
            
            MEPtext2=text(srd_x_pos_1,0.4, MEP_amp_string_EMG2, 'Color', 'red', 'FontSize', 34);
            MeanMEPtext2=text(srd_x_pos_1,-0.2, MeanMEP_string_EMG2, 'Color', 'red', 'FontSize', 34);
            EMG_txt2 = text(srd_x_pos_2,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
            EMGtext2=text(srd_x_pos_2,0.4, num2str(backgroundEMG2), 'Color', 'red', 'FontSize', 34);
            plot2=plot((biasCorrectedEMG2), 'LineWidth', 2);
            
            hold off
            
        elseif show_channel==3;
            %Plotting
            subplot(2,1,1);
            % Cleaned up version from channel 1 & 2
            ylim([-0.5 0.5]);
            % include line at y=0.5
            MEP_y_thresh_1 = yline(0.25, 'm:');
            
            % set xPlot 50ms before MEP and 125 ms after
            % set sampling rate dependant xlims
            srd_xlim_start = TMS_onset - 0.05 * round(s.Rate);
            srd_xlim_end = TMS_onset + 0.125 * round(s.Rate);
            xlim([srd_xlim_start srd_xlim_end]);
            hold on
            
            % just for visualisation, put in TMS onset, MEP_onset and MEP
            % offset
            TMS_x_onset_1 = xline(TMS_onset, 'b');
            MEP_x_onset_1 = xline(MEP_onset, 'r');
            MEP_x_offset_1 = xline(MEP_offset, 'r');
            
            % set sampling rate dependant positions
            srd_x_pos_1 = TMS_onset + 0.075*round(s.Rate);
            srd_x_pos_2 = TMS_onset - 0.045*round(s.Rate);
            %topright text 'mep'
            MEPtext=text(srd_x_pos_1,0.4, MEP_amp_string_EMG3, 'Color', 'red', 'FontSize', 34);
            % bottomright text 'ave'
            MeanMEPtext=text(srd_x_pos_1,-0.2, MeanMEP_string_EMG3, 'Color', 'red', 'FontSize', 34);
            % EMG text
            EMG_txt1 = text(srd_x_pos_2,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
            EMGtext=text(srd_x_pos_2,0.4, num2str(backgroundEMG3), 'Color', 'red', 'FontSize', 34);
            plot1=plot((biasCorrectedEMG3), 'LineWidth', 2);
            
            subplot(2,1,2);
            ylim([-0.5 0.5]);
            % include line at y=0.5
            MEP_y_thresh_2 = yline(0.25, 'm:');
            
            % set xPlot 50ms before and 125ms after
            % set sampling rate dependant xlims
            srd_xlim_start = TMS_onset - 0.05 * round(s.Rate);
            srd_xlim_end = TMS_onset + 0.125 * round(s.Rate);
            xlim([srd_xlim_start srd_xlim_end]);
            hold on
            
            % offer visualisatoion of TMS onset and MEP onset & offset
            TMS_x_onset_2 = xline(TMS_onset, 'b');
            MEP_x_onset_2 = xline(MEP_onset, 'r');
            MEP_x_offset_2 = xline(MEP_offset, 'r');
            
            MEPtext2=text(srd_x_pos_1,0.4, MEP_amp_string_EMG4, 'Color', 'red', 'FontSize', 34);
            MeanMEPtext2=text(srd_x_pos_1,-0.2, MeanMEP_string_EMG4, 'Color', 'red', 'FontSize', 34);
            EMG_txt2 = text(srd_x_pos_2,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
            EMGtext2=text(srd_x_pos_2,0.4, num2str(backgroundEMG4), 'Color', 'red', 'FontSize', 34);
            plot2=plot((biasCorrectedEMG4), 'LineWidth', 2);
            
            hold off
        elseif show_channel==5;
            subplot(2,1,1);
            %set(gcf,'position', [10 10 1240 900]);
            ylim([-0.5 0.5]);
            xlim([1100 1450]);
            hold on
            
            MEPtext=text(1350,0.4, MEP_amp_string_EMG5, 'Color', 'red', 'FontSize', 34);
            MeanMEPtext=text(1350,-0.2, MeanMEP_string_EMG5, 'Color', 'red', 'FontSize', 34);
            text(1110,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
            EMGtext=text(1110,0.4, num2str(backgroundEMG5), 'Color', 'red', 'FontSize', 34);
            plot1=plot((biasCorrectedEMG5), 'LineWidth', 2);
            
            
            subplot(2,1,2);
            %set(gcf,'position', [10 10 1240 900]);
            ylim([-0.5 0.5]);
            xlim([1100 1450]);
            hold on
            
            MEPtext2=text(1350,0.4, MEP_amp_string_EMG6, 'Color', 'red', 'FontSize', 34);
            MeanMEPtext2=text(1350,-0.2, MeanMEP_string_EMG6, 'Color', 'red', 'FontSize', 34);
            text(1110,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
            EMGtext2=text(1110,0.4, num2str(backgroundEMG6), 'Color', 'red', 'FontSize', 34);
            plot2=plot((biasCorrectedEMG6), 'LineWidth', 2);
            
            hold off
            
        end
        
        %Pause to impose random time jitter between successive TMS pulses
        
        pause(gapDurationArray(ii,1));
        delete(EMGtext);
        delete(MEPtext);
        delete(MeanMEPtext);
        delete(EMGtext2);
        delete(MEPtext2);
        delete(MeanMEPtext2);
        delete(plot1);
        delete(plot2);
        delete(EMG_txt1);
        delete(EMG_txt2);
        
        % close all x and y lines
        delete(MEP_y_thresh_1);
        delete(TMS_x_onset_1);
        delete(MEP_x_onset_1);
        delete(MEP_x_offset_1);
        
        % close all x and y lines
        delete(MEP_y_thresh_2);
        delete(TMS_x_onset_2);
        delete(MEP_x_onset_2);
        delete(MEP_x_offset_2);
        
        
        
    end
end
%%
    function rData(src,event)
        %% Function to read in Data
        rD = event.Data;
        tS = event.TimeStamps;
        
    end

ListenChar(0);
%Clear serial port
% fclose(ser);
% delete(ser)
% delete(instrfindall);

%%Clean up communication protocolls with brainbox devices
%% Cleanup

% Disconnect all objects.
fclose(DuoMag1);
%fclose(DuoMag2);
% Clean up all objects.
delete(DuoMag1);
%delete(DuoMag2);


clear all
%clear all;

end


