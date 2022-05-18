function recruitment_curve
%This version is currently suitable for the wireless delsys only.
%Plug the TMS into channel 1 and the EMG channels following this
clear all
ListenChar(0); %to ensure that the keyboard is responsive

% set experiment parameters
subNum= input('Subject number: ');
subCode = ['nf' num2str(subNum)];
SessNumber = input('Session number: ');
direc = 'C:\Users\csimon\Desktop\2 Stage BCI\';
% Fill in whatever file structure appropriate
assets_direc = [direc 'Code\Assets\'];
rmt= input('What is the resting motor threshold? ');

%% file handling
subDir = [ [direc 'Data'] filesep subCode filesep 'sess' num2str(SessNumber) filesep 'recruitment_curves'];
if ~exist(subDir,'dir')
    mkdir(subDir);
end

dataFilename = [subDir filesep 'RC_ses'  num2str(SessNumber) '.dat'];

%This is protection for overwriting files. Keep commented for programming
%purposes but uncomment during real experiment
if fopen(dataFilename,'rt') ~= -1
    fclose('all');
    error('computer says no: result data file already exists!');
else
    dataFilePointer = fopen(dataFilename,'wt');
end

% this is not needed anymore
nChans = 5;  %number of EMG channels
nMEPs = 60;  % number of MEPs to collect

ninetyPercent= round(rmt*0.9);
hundredPercent= rmt;
hundredTenPercent= round(rmt*1.1);
hundredTwentyPercent= round(rmt*1.2);
hundredThirtyPercent= round(rmt*1.3);
hundredFortyPercent= round(rmt*1.4);
hundredFiftyPercent= round(rmt*1.5);
hundredSixtyPercent= round(rmt*1.6);
hundredSeventyPercent= round(rmt*1.7);
hundredEightyPercent= round(rmt*1.8);
IntensityVector=zeros(60,1);
IntensityVector(1:6,1)=ninetyPercent;
IntensityVector(7:12,1)=hundredPercent;
IntensityVector(13:18,1)=hundredTenPercent;
IntensityVector(19:24,1)=hundredTwentyPercent;
IntensityVector(25:30,1)=hundredThirtyPercent;
IntensityVector(31:36,1)=hundredFortyPercent;
IntensityVector(37:42,1)=hundredFiftyPercent;
IntensityVector(43:48,1)=hundredSixtyPercent;
IntensityVector(49:54,1)=hundredSeventyPercent;
IntensityVector(55:60,1)=hundredEightyPercent;

RandIntensityVector=IntensityVector(randperm(length(IntensityVector)));

%initialise empty vectors to store MEP amplitudes into
ninetyPercentMEPvector=[];
hundredPercentMEPvector=[];
hundredTenPercentMEPvector=[];
hundredTwentyPercentMEPvector=[];
hundredThirtyPercentMEPvector=[];
hundredFortyPercentMEPvector=[];
hundredFiftyPercentMEPvector=[];
hundredSixtyPercentMEPvector=[];
hundredSeventyPercentMEPvector=[];
hundredEightyPercentMEPvector=[];

%Pause to allow experimenter to get in postion
pause(10);

% Seed random number generator
rng('shuffle');
emgDuration = 1;  % collect EMG data for this duration
triggerTime = 0.5;  % time after trial start to send TMS trigger
minGap = 5; maxGap = 8;   % set min and max gap times
gapDurationArray = (rand(nMEPs,1)*maxGap) + minGap;  % array of gap duration between trials
MEPvector1=[];  MEPvector2=[];

%% Call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
% Give Matlab high priority
% Maximum priority level
% for Windoows this should be max -1 (see help on priority for further
% info)
% try to make it platformfriendly:
% comment for debugging
% if ismac
%     topPriorityLevel = MaxPriority(window);
%     Priority(topPriorityLevel);
% elseif isunix
%     %this is not tested
%     topPriorityLevel = 1;
%     Priority(topPriorityLevel);
% elseif ispc
%     topPriorityLevel = MaxPriority(test)-1;
%     Priority(topPriorityLevel);
% else
%     disp('Platform not supported')
% end
Priority(2);

% The avaliable keys to press
spaceKey = KbName('SPACE');
% Dummy calls to make sure functions are ready to go without delay
KbCheck;
[keyIsDown, secs, keyCode] = KbCheck;

%% Make Screen Black
% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
% this will draw to min screen, use max for external
% csi: debug
% to work with 1 screen
% screenNumber = min(screens);
% to work with 2 screens
screenNumber = max(screens);

% Define black and white and red
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
red = [1 0 0];

% csi skip screen sync
Screen('Preference','SkipSyncTests', 1);

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

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window
[centreX, centreY] = RectCenter(windowRect);

% Enable alpha blending for anti-aliasing
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Hide cursor
HideCursor;

% Sync us and get a time stamp
vbl = Screen('Flip', window);
waitframes = 1;

% Set default screen font and size for written messages
Screen('TextSize', window, 50);
Screen('TextFont', window, 'Arial');
dotSizePix=20; %RAPID

%fixation_path= 'C:\Users\localadmin\Documents\MATLAB\Neurofeedback\Assets\white_plus_smaller.png'; %RAPID
fixation_path= [assets_direc 'white_plus_smaller.png'];
[fixation map fixationA] = imread(fixation_path);
fixation(:,:,4) = fixationA;
[fixationX fixationY fixationD] = size(fixation);
fixationTexture = Screen('MakeTexture', window, fixation);
fixation_targetX=centreX;
fixation_targetY=centreY;
greenDot=[0 1 0];

Screen('DrawTexture', window, fixationTexture, [],[fixation_targetX-(fixationX/2) fixation_targetY-(fixationY/2) fixation_targetX+(fixationX/2) fixation_targetY+(fixationY/2)]);
            
Screen('Flip', window);
%% Set up DAQ 
% define global variables
global rD
global tS

% Global flag to start recording
global record

% Global data histories
global Hist_Time
global Hist_Data


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
triggerTimeFrames=triggerTime * round(s.Rate); %as 1000 frames is 0.5s with a 2000hz samplefreq
DelsysDelayFrames=0.016 * round(s.Rate);
MEP_latencyFrames=0.015 * round(s.Rate);
MEP_duration=0.045 * round(s.Rate);
%MEP_onsetFrames=triggerTimeFrames+DelsysDelayFrames+MEP_latencyFrames;
%MEP_offsetFrames=MEP_onsetFrames+MEP_duration;
%Define some timings in frames for background EMG rms calculation
%backgroundEMG_start_relative_to_TMS=0.105 * round(s.Rate) %start calculating 105ms before TMS
%backgroundEMG_end_relative_to_TMS=0.005 * round(s.Rate); %end calculating rms 5ms before TMS pulse
%backgroundEMG_startFrames=(triggerTimeFrames-backgroundEMG_start_relative_to_TMS)+DelsysDelayFrames;
%backgroundEMG_endFrames=(triggerTimeFrames-backgroundEMG_end_relative_to_TMS)+DelsysDelayFrames;
%% SET UP TMS AND SERIAL PORT COMMUNICATION
% Open Connection to DuoMag1
duoMag1 = duoOpen('COM8');

%% START EXPERIMENT
for ii = 1:nMEPs
    disp(['MEP number ' num2str(ii)]);
    %% set power level
    powerLevel=RandIntensityVector(ii,1);
    
    switch powerLevel;
        case ninetyPercent
            intensityString='_90';
            
        case hundredPercent
            intensityString='_100';
            
        case hundredTenPercent
            intensityString='_110';
            
        case hundredTwentyPercent
            intensityString='_120';
            
        case hundredThirtyPercent
            intensityString='_130';
            
        case hundredFortyPercent
            intensityString='_140';
            
        case hundredFiftyPercent
            intensityString='_150';
            
        case hundredSixtyPercent
            intensityString='_160';
            
        case hundredSeventyPercent
            intensityString='_170';
            
        case hundredEightyPercent
            intensityString='_180';
    end
    
    if powerLevel>100;
        powerLevel=100;
    end
    
    % set Intensity
    duoPulse(duoMag1, powerLevel);
    
    % may need to increase jitter, as I took out a pause. Old pause used to
    % allow the machine to adapt to new Power Level.
    
    %Pause to impose random time jitter between successive TMS pulses
    pause(gapDurationArray(ii,1));
    
    rawEpochData = [];
    triggerSent = 0;
    exitTrial = false;
    trialStartTime = GetSecs;
    record = true;
    while exitTrial == false
        
        currentTime = GetSecs;
        
        % send trigger
        if triggerSent == 0 ...
                && currentTime - trialStartTime > triggerTime
            % send trigger via serial port here
            % not exactly sure about success
            % success = Rapid2_TriggerPulse(serialPortObj, 1)
            % set Intensity
            duoPulse(duoMag1);
            triggerSent = 1;
        end
        
        
        if  currentTime - trialStartTime > emgDuration
            exitTrial = true;
            record = false;
        end
        
        %This pause is key. Without this, the loop does not collect data
        %but runs anyway. Waitsecs doesnt work for this, and neither does a
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
            MEPvector1=[];
        end
    end
    % end of while loop
    record = false;
    
    %% process emg data for feedback
    feedbackData = [Hist_Data, Hist_Time];

    save([subDir filesep 'RC_ses'  num2str(SessNumber) '-int' intensityString '-' (num2str(ii)) '.mat'], 'feedbackData');

    TMS=feedbackData(:,1);
    EMG1=feedbackData(:,2);
    EMG2=feedbackData(:,3);
    
    % save([direc filesep 'data' filesep subCode filesep 'Ses' num2str(SesNum) filesep 'expt2_exp_UP11' '-mep' (num2str(ii)) '.mat'], 'feedbackData','rawRMSData' )
    TMS=feedbackData(:,1); %second column of feedback data is TMS channel
    
    % debug catch, breakpiont and warning
    try
        TMS_onset = get_TMS_onset(TMS); %function returns the first frame of the TMS pulse
    catch
        warning('Problem using get_TMS_onset function.  Assigning a value of 0.');
    end
    
    % for plots
    MEP_onset = TMS_onset+MEP_latencyFrames+DelsysDelayFrames;
    MEP_offset = MEP_onset+MEP_duration;
    
    %Calculate MEP amplitude
    % old 1245:1460. with round(s.Rate) 2000. New round(s.Rate) = 3000. new: 0.6225, 0.73
    % or if we change the delsys delay to 0.016 then we might reduce 0.6225
    % so 6193 and 7268.
    % However, this is still assuming a delay of 108ms (or 216 sp), so i
    % don-t know where the additional 9sp come in. Anyway pr7452oceeding to add
    % the new delay of 0.076ms = 152sp to 6301 and 7376 respectively
%     MEP_amp_EMG1=(max(EMG1(0.6225*round(s.Rate):0.73*round(s.Rate))))-(min(EMG1(0.6225*round(s.Rate):0.73*round(s.Rate))));
%     MEP_amp_EMG2=(max(EMG2(0.6225*round(s.Rate):0.73*round(s.Rate))))-(min(EMG2(0.6225*round(s.Rate):0.73*round(s.Rate))));
try
    MEP_amp_EMG1=(max(EMG1(MEP_onset:MEP_offset)))-(min(EMG1(MEP_onset:MEP_offset)));
    MEP_amp_EMG2=(max(EMG2(MEP_onset:MEP_offset)))-(min(EMG2(MEP_onset:MEP_offset)));
catch
    fprintf('stop here')
end

    MEPvector1= [MEPvector1; MEP_amp_EMG1];
    MEPvector2= [MEPvector2; MEP_amp_EMG2];
    MeanMEP1=mean(MEPvector1); MeanMEP2=mean(MEPvector2);
    
    %Put the MEP amplitude measurment in the appropriate vector
    %corresponding to the TMS intensity
    switch powerLevel;
        case ninetyPercent
            ninetyPercentMEPvector=[ninetyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredPercent
            hundredPercentMEPvector=[hundredPercentMEPvector; MEP_amp_EMG1];
            
        case hundredTenPercent
            hundredTenPercentMEPvector=[hundredTenPercentMEPvector; MEP_amp_EMG1];
            
        case hundredTwentyPercent
            hundredTwentyPercentMEPvector=[hundredTwentyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredThirtyPercent
            hundredThirtyPercentMEPvector=[hundredThirtyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredFortyPercent
            hundredFortyPercentMEPvector=[hundredFortyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredFiftyPercent
            hundredFiftyPercentMEPvector=[hundredFiftyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredSixtyPercent
            hundredSixtyPercentMEPvector=[hundredSixtyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredSeventyPercent
            hundredSeventyPercentMEPvector=[hundredSeventyPercentMEPvector; MEP_amp_EMG1];
            
        case hundredEightyPercent
            hundredEightyPercentMEPvector=[hundredEightyPercentMEPvector; MEP_amp_EMG1];
    end
    
    %Calculate background EMG rms in 100 ms up until 5ms before TMS
    %calculate the offset or bias, before rms measurement
    % used to be 100:500.
    bias_EMG1=mean(EMG1((0.05*round(s.Rate)):(0.25*round(s.Rate))));
    bias_EMG2=mean(EMG2((0.05*round(s.Rate)):(0.25*round(s.Rate))));
    
    %remove bias and calculate rms background EMG
    biasCorrectedEMG1=EMG1-bias_EMG1;
    biasCorrectedEMG2=EMG2-bias_EMG2;
    
    % this used to be 915:1115, now round(s.Rate) dependent
    %     backgroundEMG1= rms(biasCorrectedEMG1(0.4575*round(s.Rate):0.5575*round(s.Rate)));
    %     backgroundEMG2= rms(biasCorrectedEMG2(0.4575*round(s.Rate):0.5575*round(s.Rate)));
    bckgnd_EMG_pre_TMS = 0.105 * round(s.Rate); %start measuring background EMG 105ms before TMS
    bckgnd_EMG_duration = 0.1 * round(s.Rate); %num frames needed to estimate backgnd EMG
    backgnd_EMG_onset = (TMS_onset+DelsysDelayFrames)-bckgnd_EMG_pre_TMS;
    backgnd_EMG_offset = backgnd_EMG_onset + bckgnd_EMG_duration;
    backgroundEMG1= rms(biasCorrectedEMG1(backgnd_EMG_onset:backgnd_EMG_offset));
    backgroundEMG2= rms(biasCorrectedEMG2(backgnd_EMG_onset:backgnd_EMG_offset));
    
    MEP_amp_string_EMG1= ['MEP ' num2str(MEP_amp_EMG1)];
    MeanMEP_string_EMG1= ['AVE ' num2str(MeanMEP1)];
    backgroundEMG_string= 'EMG';
    MEP_amp_string_EMG2= ['MEP ' num2str(MEP_amp_EMG2)];
    MeanMEP_string_EMG2= ['AVE ' num2str(MeanMEP2)];
    
    % cleanup plot variables here, so the plot is visible during the experiment
    try
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
    
    % adjust x coordinates by x coordinate/2000 * round(s.Rate)
    %Plotting
    subplot(2,1,1);
    ylim([-0.5 0.5]);
    %xlim([1100 1450]);
    %xlim([0.55*round(s.Rate) 0.7250*round(s.Rate)]);
    MEP_y_thresh_1 = yline(0.25, 'm:');
    
    %set xPlot 100ms before MEP
    % set sampling rate dependant xlims
    srd_xlim_start = TMS_onset - 0.05 * round(s.Rate);
    srd_xlim_end = TMS_onset + 0.125 * round(s.Rate);
    
    xlim([srd_xlim_start srd_xlim_end]);
    hold on
    %hline(0.05);
    %vline(triggerTimeFrames+DelsysDelayFrames);
    
    % just for visualisation, put in TMS onset, MEP_onset and MEP
    % offset
    TMS_x_onset_1 = xline(TMS_onset, 'b');
    MEP_x_onset_1 = xline(MEP_onset, 'r');
    MEP_x_offset_1 = xline(MEP_offset, 'r');
    
    % set sampling rate dependant positions
    srd_x_pos_1 = TMS_onset + 0.075*round(s.Rate);
    srd_x_pos_2 = TMS_onset - 0.045*round(s.Rate);
    %
    %     MEPtext1=text(1350,0.4, MEP_amp_string_EMG1, 'Color', 'red', 'FontSize', 34);
    %     MeanMEPtext1=text(1350,-0.2, MeanMEP_string_EMG1, 'Color', 'red', 'FontSize', 34);
    %     text(1110,0.2, backgroundEMG_string, 'Color', 'red', 'FontSize', 34);
    %     EMGtext1=text(1110,0.4, num2str(backgroundEMG1), 'Color', 'red', 'FontSize', 34);
    %     plot1=plot((biasCorrectedEMG1), 'LineWidth', 2);
    %     subplot(2,1,2);
    
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
    
    % clean global variable for next run
    Hist_Data = [];
    Hist_Time = [];
end

% close figures before plotting new one
close all;

meanNinety=mean(ninetyPercentMEPvector);
meanHundred=mean(hundredPercentMEPvector);
meanHundredTen=mean(hundredTenPercentMEPvector);
meanHundredTwenty=mean(hundredTwentyPercentMEPvector);
meanHundredThirty=mean(hundredThirtyPercentMEPvector);
meanHundredForty=mean(hundredFortyPercentMEPvector);
meanHundredFifty=mean(hundredFiftyPercentMEPvector);
meanHundredSixty=mean(hundredSixtyPercentMEPvector);
meanHundredSeventy=mean(hundredSeventyPercentMEPvector);
meanHundredEighty=mean(hundredEightyPercentMEPvector);
all_means=[meanNinety meanHundred meanHundredTen meanHundredTwenty meanHundredThirty meanHundredForty meanHundredFifty meanHundredSixty meanHundredSeventy meanHundredEighty];
hold on
plot(all_means);
title('Recruitment curve. Find which intensity corresponds to median MEP')
xlabel('TMS intensity level (of rMT)') % x-axis label
xticklabels({'90%' '100%' '110%' '120%' '130%' '140%' '150%' '160%' '170%' '180%'})
ylabel('MEP amplitude') % y-axis label
middle_MEP_size=median(all_means);
disp(['The median MEP amplitude was ' num2str(middle_MEP_size)]);
save([subDir filesep 'WholeRC-ses'  num2str(SessNumber) '.mat'], 'all_means');

%% Cleanup
% Disconnect all objects.
fclose(duoMag1);

% Clean up all objects.
delete(duoMag1);

% Delete from workspace.
clear duoMag1;% csi cleanup part

Screen('Close', window)

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

end