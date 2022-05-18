
function Collect_Post_MEPs
clear all
%This version is currently suitable for the wireless delsys only.
%Plug the TMS into channel 1 and the EMG channels following this
ListenChar(0); %to ensure that the keyboard is responsive
% set experiment parameters
subNum= input('Subject number ');
subCode = ['nf' num2str(subNum)];

% Every Session is now both up and down
% SessionType= input('Is this an UP or DOWN session? Answer UP or DN    ', 's');
EEG_Sess = 'EEG_';

SesNum=input('Session number? ');
% blockNum = input('Block number?     ','s');
% 
% if blockNum>4 && blockNum<9
%     FirstOrSecondDay=2;
% elseif blockNum>8
%      FirstOrSecondDay=3;
% else
%     FirstOrSecondDay=1;
% end

nChans = 5;  % number of recording channels
nMEPs = 20;  % number of MEPs to collect
direc = 'C:\Users\csimon\Desktop\2 Stage BCI\Data\';

recruit_curve_multiplier = input('Recruitement Curve Multiplier? ');

intensity1= input('Desired Intensity- TMS1 ');
if intensity1>110;
    intensity1=110;
end

if intensity1 < 100
    intensity_string1 = [ '0' num2str(intensity1)];
else
    intensity_string1 = num2str(intensity1);
end

%{
intensity2= input('Desired Intensity- TMS2 ');
if intensity2>100;
    intensity2=99;
end
intensity_string2 = [ '0' num2str(intensity2)];
%}

delete(instrfindall);

% Seed random number generator
rng('shuffle');

%State options
% 1 single pulse, TMS1
% 2 SICI TMS2 first (100% AMT) then TMS1 (at supra thresh intensity)
% 3 LICI (protocol to be decided) 100ms interval
% 4 LCD (protocol to be decided) 200ms interval
State_options=[1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ];
TMS_State_selector=State_options(randperm(length(State_options)));


emgDuration = 1;  % collect EMG data for this duration
triggerTime = 0.5;  % time after trial start to send TMS trigger
minGap = 6; maxGap = 9;   % set min and max gap times
gapDurationArray = (rand(nMEPs,1)*(maxGap-minGap)) + minGap;  % array of gap duration between trials
MEPvector1=[];  MEPvector2=[]; MEPvector3=[];  MEPvector4=[];

%% Call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% csi skip screen sync
Screen('Preference','SkipSyncTests', 1);

% Get the screen numbers
screens = Screen('Screens');
% Draw to the external screen if avaliable

% screenNumber = min(screens);
% to work with 2 screens
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
red = [1 0 0];
% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 40;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
[xCenter, yCenter] = RectCenter(windowRect);
% Set the line width for our fixation cross
lineWidthPix = 4;
Screen('TextSize', window, 50);
Screen('TextFont', window, 'Arial');
dotSizePix=80;
% Query the frame duration
ifi = Screen('GetFlipInterval', window);
% Get the centre coordinate of the window
[centreX, centreY] = RectCenter(windowRect);
% Enable alpha blending for anti-aliasing
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Hide cursor
HideCursor;
% Sync us and get a time stamp
vbl = Screen('Flip', window);
waitframes = 1;
% Maximum priority level
% topPriorityLevel = MaxPriority(window);
% Priority(topPriorityLevel);
% end of psychtoolbox setup
Priority(2);

%% The avaliable keys to press
spaceKey = KbName('SPACE');
escapeKey = KbName('ESCAPE');
% Dummy calls to make sure functions are ready to go without delay
KbCheck;
[keyIsDown, secs, keyCode] = KbCheck;

%% file handling
% if FirstOrSecondDay ==1
%     SesNum='Ses1';
%     subDir = [direc filesep 'data' filesep '2018' filesep subCode filesep 'Ses1'];
%     if ~exist(subDir,'dir')
%         mkdir(subDir);
%     end
% 
% else
%     SesNum='Ses2';
%     subDir = [direc filesep 'data' filesep '2018' filesep subCode filesep 'Ses2'];
%     if ~exist(subDir,'dir')
%         mkdir(subDir);
%     end
% end

    subDir = [direc filesep subCode filesep 'sess' num2str(SesNum) filesep 'post-mep'];
    if ~exist(subDir,'dir')
        mkdir(subDir);
    end



dataFilename = [subDir filesep 'post-' 'm' num2str(nMEPs) '-eeg.dat']

%This is protection for overwriting files. Keep commented for programming
%purposes but uncomment during real experiment
if fopen(dataFilename,'rt') ~= -1
    fclose('all');
    error('computer says no: result data file already exists!');
else
    dataFilePointer = fopen(dataFilename,'wt');
end

% define global variables
global rD
global tS

% Global flag to start recording
global record

% Global data histories
global Hist_Time
global Hist_Data


% set up output daq
o = daq.createSession('ni');
% add output channels
addAnalogOutputChannel(o, 'Dev1','ao0','Voltage');
o.Rate=3000;
% set output to 0 Volt to not send a pulse right away
outputSingleScan(o,0);

% setup data acquisition device
s = daq.createSession('ni');

% csi: change naming
% our channels are
% a0: TMS
% a4: FDI1
% a1: ADM1
% a2: FDI2
% a5: ADM2
% set up the NI board and channels
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


%Define some timings in frames for detecting MEP onset
DelsysDelayFrames=0.016 * round(s.Rate);
MEP_latencyFrames=0.015 * round(s.Rate);
MEP_duration=0.045 * round(s.Rate);

%% SET UP TMS AND SERIAL PORT COMMUNICATION
% SET UP TMS AND SERIAL PORT COMMUNICATION
% Open Connection to DuoMag1
duoMag1 = duoOpen('COM8');

% set Intensity
duoPulse(duoMag1, str2num(intensity_string1));



%%Press spacebar to continue
DrawFormattedText(window, 'press the spacebar to begin experiment', 'center', 'center', white);
Screen('Flip', window);
while (keyCode(spaceKey) == 0) [keyIsDown, secs, keyCode] = KbCheck; end
keyCode(spaceKey) = 0;

Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
%Pause to allow experimenter to get in postion
pause(5);

%% START EXPERIMENT
for ii = 1:nMEPs

    %Pause to impose random time jitter between successive TMS pulses
    pause(gapDurationArray(ii,1));

    triggerSent = 0;
    exitTrial = false;
    trialStartTime = GetSecs;
    record = true;
    while exitTrial == false
         Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
         vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

        % check for exit request
        if keyCode(escapeKey)
            exitTrial = true;
        end

        currentTime = GetSecs;
        % send trigger
        if triggerSent == 0 ...
                && currentTime - trialStartTime > triggerTime
            % send trigger via serial port here
            % duoPulse(duoMag1);
            outputSingleScan(o,4);
            outputSingleScan(o,4);
            outputSingleScan(o,4);
            outputSingleScan(o,0);
            
            triggerSent = 1;
        end


        if  currentTime - trialStartTime > emgDuration
            exitTrial = true;
            record = false;
        end

        %This pause is key. Without this, the loop does not collect data
        %but runs anyway. pause doesnt work for this, and neither does a
        %while loop imposing timing using Getsecs > a criterion. Needs to
        %be pause. Also, enure the pause time is below the amount of time
        %needed to collect one bunch of samples, in this case 200 samples
        %in the listener so 100ms. Anything lower than this is ok. Larger
        %will mean there are gaps in the data acquisition
        pause(0.0001)

        %% Check the keyboard to see if a button has been pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        % check for exit request
        if keyCode(spaceKey)
            MEPvector1=[];
            MEPvector2=[];
            MEPvector3=[];
            MEPvector4=[];
        end
    end
    record = false;

    %% process emg data for feedback
    feedbackData = [Hist_Data, Hist_Time];
    %feedbackData = [uniqueEpochData(:,2:end), uniqueEpochData(:,1)]; % Because the first column is timestamp
    save([subDir filesep 'post-' 'mep' (num2str(ii)) '-eeg.mat'], 'feedbackData');
    
    Hist_Data = [];
    Hist_Time = [];
    
    TMS1=feedbackData(:,1); %first column of feedback data is TMS channel
    TMS2=feedbackData(:,6); %first column of feedback data is TMS channel
    EMG1=feedbackData(:,2);
    EMG2=feedbackData(:,3);
    EMG3=feedbackData(:,4);
    EMG4=feedbackData(:,5);

    %Calculate MEP amplitude

    try
        TMS_onset = get_TMS_onset(TMS1); %function returns the first frame of the TMS pulse
    catch
        warning('Problem using get_TMS_onset function.  Assigning a value of 0.');
    end
    % TMS_onset = get_TMS_onset(TMS1); %function returns the first frame of the TMS pulse


    MEP_onset = TMS_onset+MEP_latencyFrames+DelsysDelayFrames;
    MEP_offset = MEP_onset+MEP_duration;


    MEP_amp_EMG1=peak2peak(EMG1(MEP_onset:MEP_offset));
    MEP_amp_EMG2=peak2peak(EMG2(MEP_onset:MEP_offset));
    MEP_amp_EMG3=peak2peak(EMG3(MEP_onset:MEP_offset));
    MEP_amp_EMG4=peak2peak(EMG4(MEP_onset:MEP_offset));

    MEPvector1= [MEPvector1; MEP_amp_EMG1];
    MEPvector2= [MEPvector2; MEP_amp_EMG2];
    MEPvector3= [MEPvector3; MEP_amp_EMG3];
    MEPvector4= [MEPvector4; MEP_amp_EMG4];
    MeanMEP1=mean(MEPvector1); MeanMEP2=mean(MEPvector2); MeanMEP3=mean(MEPvector3); MeanMEP4=mean(MEPvector4);
    
    All_ch_mean=mean([MeanMEP1,MeanMEP2,MeanMEP3]);
    %Calculate background EMG rms in 100 ms up until 5ms before TMS
    %calculate the offset or bias, before rms measurement
    bias_EMG1=mean(EMG1(0.05*round(s.Rate):0.25*round(s.Rate)));
    bias_EMG2=mean(EMG2(0.05*round(s.Rate):0.25*round(s.Rate)));
    bias_EMG3=mean(EMG3(0.05*round(s.Rate):0.25*round(s.Rate)));
    bias_EMG4=mean(EMG4(0.05*round(s.Rate):0.25*round(s.Rate)));
    %remove bias and calculate rms background EMG
    biasCorrectedEMG1=EMG1-bias_EMG1;
    biasCorrectedEMG2=EMG2-bias_EMG2;
    biasCorrectedEMG3=EMG3-bias_EMG3;
    biasCorrectedEMG4=EMG4-bias_EMG4;
    
    bckgnd_EMG_pre_TMS = 0.105 * round(s.Rate); %start measuring background EMG 105ms before TMS
    bckgnd_EMG_duration = 0.1 * round(s.Rate); %num frames needed to estimate backgnd EMG
    backgnd_EMG_onset = (TMS_onset+DelsysDelayFrames)-bckgnd_EMG_pre_TMS;
    backgnd_EMG_offset = backgnd_EMG_onset + bckgnd_EMG_duration;

    backgroundEMG1= rms(biasCorrectedEMG1(backgnd_EMG_onset:backgnd_EMG_offset)); %change this to be relative to TMS timing at some point if needed
    backgroundEMG2= rms(biasCorrectedEMG2(backgnd_EMG_onset:backgnd_EMG_offset));
    backgroundEMG1= rms(biasCorrectedEMG1(backgnd_EMG_onset:backgnd_EMG_offset));
    backgroundEMG2= rms(biasCorrectedEMG2(backgnd_EMG_onset:backgnd_EMG_offset));

end

%Display the overall mean from the session, disregarding the first MEP
EndMeanMEP1=mean(MEPvector1(2:end));
EndMeanMEP2=mean(MEPvector2(2:end));
EndMeanMEP3=mean(MEPvector3(2:end));
EndMeanMEP4=mean(MEPvector4(2:end));

All_Ch_EndMean=mean([EndMeanMEP1,EndMeanMEP2]);

EndSDMEP1=std(MEPvector1(2:end));

% create a txt file and save all information to it

file_ID = fopen([subDir filesep 'Profile-post-eeg.txt'], 'a');

prof = ['The chosen multiplier was ' num2str(recruit_curve_multiplier) '\n'];
disp(prof);
fprintf(file_ID, prof);

prof_0 = ['The chosen intensity was ' num2str(intensity1) '\n'];
disp(prof_0);
fprintf(file_ID, prof_0);

prof_1 = ['The mean Ch1 MEP amplitude was ' num2str(EndMeanMEP1) '\n'];
disp(prof_1);
fprintf(file_ID, prof_1);

prof_2 = (['The standard deviation for Ch1 was ' num2str(EndSDMEP1) '\n']);
disp(prof_2);
fprintf(file_ID, prof_2);

prof_3 = (['The mean Ch2 MEP amplitude was ' num2str(EndMeanMEP2) '\n']);
disp(prof_3);
fprintf(file_ID, prof_3);

prof_4 = (['The mean Ch3 MEP amplitude was ' num2str(EndMeanMEP3) '\n']);
disp(prof_4);
fprintf(file_ID, prof_4);

prof_5 = (['The mean Ch4 MEP amplitude was ' num2str(EndMeanMEP4) '\n']);
disp(prof_5);
fprintf(file_ID, prof_5);

prof_6 = (['The mean of 2 hand muscles was ' num2str(All_Ch_EndMean) '\n']);
disp(prof_6);
fprintf(file_ID, prof_6);

% close file
fclose(file_ID);

    function rData(src,event)
        rD = event.Data;
        tS = event.TimeStamps;
        
        % Here is the code that makes this the "Global Variant" Here we set
        % a flagging variable "record". If record is true, it will start
        % creating a global history of the timeseries and dataseries. This
        % means that in the code we can turn on "recording" whenever we
        % want to record data, and turn off "recording" when we are done.
        % Keep in mind that if you don't want to reuse the data, you have
        % to clear the global variables after use.
        if record
            Hist_Time = [Hist_Time; tS];
            Hist_Data = [Hist_Data; rD];
        end
    end
% Disconnect all objects.
fclose(duoMag1);

% Clean up all objects.
delete(duoMag1);

% Delete from workspace.
clear duoMag1;% csi cleanup part

fclose('all');
close all;
clear all;
end
