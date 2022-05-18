%% Comments:
% While in traffic lights mode, left control (left_control_key) will stop
% the experiment. pressing left control will restart the current trial.
%
% Pressing escape at any point during the experiment will 

%% Code
function mepFunction_UP
%% Initialise
clear all
%Channel list should be
% Channel 0- TMS
% Channel 1- cFDI (Contralateral: target muscle for MEPs)
% Channel 2- cADM
% Channel 3- iFDI
% Channel 4- iADM
clear all;


delete(instrfindall);
ListenChar(0); %to ensure that the keyboard is responsive

nMEPs = 20;  % number of MEPs to collect
backgnd_EMG_threshold = 0.007; %Above this it cant move from state 1 to 2 or 2 to 3

% set experiment parameters
subNum= input('Subject number ');
subCode = ['nf' num2str(subNum)];

dayNumber = input('Session Number? ');
dayNumber_str = ['_day' num2str(dayNumber) '_'];

blockNumber = input('Block Number? ');
blockNumber_str = ['block' num2str(blockNumber)];

%% Get User Information %%
intensity= input('Desired Intensity ');
if intensity>110;
    intensity=110;
end
if intensity < 100
    intensity_string = [ '0' num2str(intensity)];
else
    intensity_string = num2str(intensity);
end

% Fill in whatever file structure appropriate
parent_direc = 'C:\Users\csimon\Desktop\2 Stage BCI\';
data_direc = [parent_direc 'Data\'];
% colin_direc = [parent_direc 'Colin\'];
assets_direc = [parent_direc 'Code\Assets\'];

% EEG snippet to true in this EEG-version
EEG_Sess = 'EEG_';

%% set important variables %%
mean_MEP=input('Baseline MEP size of 2 muscles? ');
min_MEP_value=0;
max_MEP_value=mean_MEP*2;
Range=max_MEP_value-min_MEP_value;

% csi: this creates a vector with TMS commands. Then it jumbles them up
% by randomly selecting a command from said vector
% State_options=[1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]; %1 is for SP. etc
% Seed random number generator
rng('shuffle');
State_options=[2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]; %1 is for SP. etc
TMS_State_selector=State_options(randperm(length(State_options)));

nChans = 5;  % number of EMG channels
emgDuration = 1;  % collect EMG data for this duration
triggerTime = 0.5;  % time after trial start to send TMS trigger
feedbackDuration = 3;  % visual feedback duration
minGap = 2;
maxGap = 5;   % set min and max gap times
gapDurationArray = (rand(nMEPs,1)*(maxGap-minGap)) + minGap;  % array of gap duration between trials
minfixGap = 0.5;
maxfixGap = 1;   % I set these small becasue the main gap will occur AFTER the TMS machines have armed and made their noises- to help avoid anticipation
fixgapDurationArray = (rand(nMEPs,1)*maxfixGap) + minfixGap;  % array of gap duration between trials
minWaitGap = 0.5;
maxWaitGap = 1;
WaitgapDurationArray = (rand(nMEPs,1)*maxfixGap) + minfixGap;  % array of gap duration between trials in trialstate 2


%% File Handling %%

%% Check if Participant folder exists, if not create
% create participant folder path
subDir = [data_direc subCode];
% check existance & create if nonexistant
if (exist(subDir, 'dir') == 0)
    mkdir(subDir)
end

%% Check if Subfolder for day/sessione exists, if not create
% create participant folder path
SesNum = ['sess' num2str(dayNumber)];
subDir = [data_direc subCode filesep SesNum];
% check existance & create if nonexistant
if (exist(subDir, 'dir') == 0)
    mkdir(subDir)
end

%% Check if subfolder for block exists, if yes ask for blocknumber, if not
% create participant folder path
subDir = [data_direc subCode filesep SesNum filesep blockNumber_str];
% check existance & create if nonexistant
if (exist(subDir, 'dir') == 0)
    mkdir(subDir)
elseif (exist(subDir, 'dir') == 7)
    uiwait(msgbox({'This Block has already been started, script will proceed by adding subscript.'}));
    % increase subscript until it doesn't exist anymore
    new_blocknr = 1;
    while (exist(subDir, 'dir') == 7)
        new_blocknr = new_blocknr + 1;
        subDir = [data_direc subCode filesep SesNum filesep blockNumber_str '-' num2str(new_blocknr)];
    end
    blockNumber = new_blocknr;
    blockNumber_str = [blockNumber_str '-' num2str(blockNumber)];
    mkdir(subDir)
    clear new_blocknr;
end

%% create correct data-filename
dataFilename = [subDir filesep 'sub-' num2str(subNum) '-up-nmeps' num2str(nMEPs) '-' SesNum '-' blockNumber_str '-eeg-tmsnf.dat'];

%This is protection for overwriting files. Keep commented for programming
%purposes but uncomment during real experiment
if fopen(dataFilename,'rt') ~= -1
    fclose('all');
    error('computer says no: result data file already exists!');
else
    dataFilePointer = fopen(dataFilename,'wt');
end


% Remind to turn off sounds.
% Also check that all variables are correctly set
uiwait(msgbox({'This is the EEG-Script'; 'Disable Computer Sounds'}));
uiwait(msgbox({'Settings for this session:' 'Stimulation:' num2str(intensity_string) 'Filename: ' dataFilename}));
uiwait(msgbox({'# Meps' num2str(nMEPs) 'Background EMG Threshold' num2str(backgnd_EMG_threshold) '2 Muscle Baseline' num2str(mean_MEP)}));



% define global variables for real time data acquisition
global rD
global tS

% Global flag to start recording
global record

% Global data histories
global Hist_Time
global Hist_Data

%% configure TMS and NI communication here %%
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

%Variable to calculate mean of all channels
Ch1_MEP_vector=[];
Ch2_MEP_vector=[];
Ch3_MEP_vector=[];

%Define some timings in frames for detecting MEP onset
DelsysDelayFrames   = round(0.016 * s.Rate);
MEP_latencyFrames   = round(0.015 * s.Rate);
MEP_duration        = round(0.045 * s.Rate);


% SET UP TMS AND SERIAL PORT COMMUNICATION
% Open Connection to DuoMag1
duoMag1 = duoOpen('COM8');

% set Intensity
duoPulse(duoMag1, str2num(intensity_string));
TMS_last_used = GetSecs;

%% Setup Psychtoolbox %%
% Call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% debug: this makes it impossible to debug and doesn't work correctly on
% mac. It makes me only able to interact with the main window of matlab,
% and I cannot observe key commands from psychtoolbox
% Give Matlab high priority
Priority(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
% this will draw to min screen, use max for external
% csi: debug
% screenNumber = min(screens);
screenNumber = max(screens);
% screenNumber = 1;

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

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% The avaliable keys to press
escapeKey = KbName('ESCAPE');
spaceKey = KbName('SPACE');
left_control_key = KbName('LeftControl');

% Get the centre coordinate of the window
[centreX, centreY] = RectCenter(windowRect);

% Configure feedback circles
baseRect = [0,0,150,150];
maxDiameter = max(baseRect) * 1.01;
centredRect1 = CenterRectOnPointd(baseRect, screenXpixels*0.2, centreY);
centredRect2 = CenterRectOnPointd(baseRect, screenXpixels*0.4, centreY);
centredRect3 = CenterRectOnPointd(baseRect, screenXpixels*0.6, centreY);
centredRect4 = CenterRectOnPointd(baseRect, screenXpixels*0.8, centreY);

% Movie code %
% Get Movie Path
moviename =  [assets_direc 'shortmovie.mov'];

% Load Movie
[movie,duration,fps,width,height,count,aspectRatio] = Screen('OpenMovie', window, moviename);
counter=0;
% duration is seconds, fps is frames per second (usually 30), count is total amount of frames

% Enable alpha blending for anti-aliasing
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Hide cursor
HideCursor;

% Sync us and get a time stamp
vbl = Screen('Flip', window);
waitframes = 1;

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
%     topPriorityLevel = MaxPriority(window)-1;
%     Priority(topPriorityLevel);
% else
%     disp('Platform not supported')
% end
Priority(2);

% Dummy calls to make sure functions are ready to go without delay
KbCheck;
[keyIsDown, secs, keyCode] = KbCheck;
pause(0.1);
GetSecs;

% Set default screen font and size for written messages
Screen('TextSize', window, 50);
Screen('TextFont', window, 'Arial');
dotSizePix=20; %RAPID


%%Prepare the sounds
% load sounds
soundsPath= [assets_direc 'sounds']; %RAPID

winWavPath = [soundsPath filesep 'better.wav'];
winSoundData = audioread(winWavPath);
winSoundData=winSoundData';

loseWavPath = [soundsPath filesep 'worse.wav'];
loseSoundData = audioread(loseWavPath);
loseSoundData = loseSoundData';

% Perform basic initialization of the sound driver:
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', [], [], 0, 48000, 2);

%% Create a line that will be drawn at the mean MEP size
%Calculate the range of MEP sizes
barColour=[0 1 0];

%Format is left, top, right, bottom
lineYpos=screenYpixels-round(screenYpixels*(mean_MEP/Range)); %Bar size
line=[0 lineYpos screenXpixels lineYpos+10];
lineColour=[1 1 1];
MEP_amp=0;
All_ch_mean=0;

%Add textures
tick_path= [assets_direc 'tick_transparent_smaller.png'];

%tick_path= 'C:\Users\localadmin\Documents\MATLAB\Neurofeedback\Assets\tick_transparent_smaller.png'; %RAPID
[tick map tickA] = imread(tick_path);
tick(:,:,4) = tickA;
[tickX tickY tickD] = size(tick);
tickTexture = Screen('MakeTexture', window, tick);
cross_path= [assets_direc 'cross2_small.png'];

%cross_path= 'C:\Users\localadmin\Documents\MATLAB\Neurofeedback\Assets\cross2_small.png'; %RAPID
[cross map crossA] = imread(cross_path);
cross(:,:,4) = crossA;
[crossX crossY crossD] = size(cross);
crossTexture = Screen('MakeTexture', window, cross);
targetX=200;
targetY=200;
dollar_path= [assets_direc 'Doublebarred_dollar_sign.png'];

%dollar_path= 'C:\Users\localadmin\Documents\MATLAB\Neurofeedback\Assets\Doublebarred_dollar_sign.png'; %RAPID
[dollar map dollarA] = imread(dollar_path);
dollar(:,:,4) = dollarA;
[dollarX dollarY dollarD] = size(dollar);
dollarTexture = Screen('MakeTexture', window, dollar);
dollar_targetX=centreX+300;
dollar_targetY=900;
fixation_path= [assets_direc 'white_plus_smaller.png'];

%fixation_path= 'C:\Users\localadmin\Documents\MATLAB\Neurofeedback\Assets\white_plus_smaller.png'; %RAPID
[fixation map fixationA] = imread(fixation_path);
fixation(:,:,4) = fixationA;
[fixationX fixationY fixationD] = size(fixation);
fixationTexture = Screen('MakeTexture', window, fixation);
fixation_targetX=centreX;
fixation_targetY=centreY;
greenDot=[0 1 0];

%% START EXPERIMENT
% Start once Spacebar is pressed
DrawFormattedText(window, 'press the spacebar to begin experiment', 'center', 'center', white);
Screen('Flip', window);
while (keyCode(spaceKey) == 0)
    [keyIsDown, secs, keyCode] = KbCheck;
end
keyCode(spaceKey) = 0;
pause(0.5);

% Initialise variables
nSuccess = 0;
mepCount = 0;

rawRMSData = [];

% csi: adjusted to 500ms. 0.5(seconds) * Sampling rate. nChans+1 because of
% timestamp data, and set default data to 0.005
dummyData=zeros(round(0.5 * s.Rate),nChans+1);
dummyData(:,:)=0.005;

% I added this becasue when I later use the Unique function for the
% first time on the raw data, if the timestamps are all identical, it
% cancels out all data as they are not unique. This is only needed
% for the dummy samples that initialise the matrix that later gets
% filled with rms data
dummyData(:,1)=rand(1,length(dummyData));
rawRMSData=[rawRMSData; dummyData];
FDIrmsgood=1;
ch3rmsgood=1;
ch4rmsgood=1;
ch5rmsgood=1;

% Here I added code to collect a small chunk of data to estimate the
% bias that needs to be removed from each EMG channel. Very important to
% do this for accurate RMS measurements
% csi: How small? The way I understood the code, it would have run exactly
% once, collecting 100 samples. I set it to collect two seconds. CWK
% pause(0.1);
% Pause not needed in global variant
DrawFormattedText(window, 'Baseline EMG in: 3s', 'center', 'center', white);
Screen('Flip', window);
pause(1);
DrawFormattedText(window, 'Baseline EMG in: 2s', 'center', 'center', white);
Screen('Flip', window);
pause(1);
DrawFormattedText(window, 'Baseline EMG in: 1s', 'center', 'center', white);
Screen('Flip', window);
pause(1);

bias_starttime=0;
rawchunkData =[];
bias_estimation_duration = GetSecs + 2;

DrawFormattedText(window, 'Baseline EMG recording ...', 'center', 'center', white);
Screen('Flip', window);

% collect data
record = true;
while bias_starttime < bias_estimation_duration
    %it doesn't seem to record anything unless i set the pause
    pause(0.001)
    bias_starttime = GetSecs;
end
record = false;

DrawFormattedText(window, 'Baseline EMG recording done.', 'center', 'center', white);
Screen('Flip', window);

% take means
uniqueChunkData = ([Hist_Time, Hist_Data]);

% now clear global data
% Hist_Data = [];
% Hist_Time = [];

bias_ch2 = mean(uniqueChunkData(:,3));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
bias_ch3 = mean(uniqueChunkData(:,4));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
bias_ch4 = mean(uniqueChunkData(:,5));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
bias_ch5 = mean(uniqueChunkData(:,6));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc

%% start core loop (actual experiment)
% start recording data
record = true;
for ii = 1:nMEPs
    
    % Initialise Variables
    rawEpochData = [];
    triggerSent = 0;
    soundOccured = 0;
    trialState = 1;
    exitTrial = false;
    flag=0;
    
    trialStartTime = GetSecs;
    
    %% while trial is ongoing
    while exitTrial == false
        % Check the keyboard to see if a button has been pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        
        % start recording
        record = true;
        
        % check for exit request
        if keyCode(escapeKey)
            exitTrial = true;
            
            % stop recording
            record = false;
        end
        
        %% have a break if leftcontrol is pressed
        if keyCode(left_control_key) && trialState == 1
            % set previous record so we can turn off recording for break
            previous_record = record;
            record = false;
            % clear keypresses, so it does actually stop
            pause(1);
            Hist_Data = [];
            Hist_Time = [];
            clear keyIsDown secs keyCode;
            
            % explain what happened
            DrawFormattedText(window, 'experiment paused', 'center', 'center', white);
            Screen('Flip', window);
            pause(3);
            DrawFormattedText(window, 'experiment paused \n to resume experiment, press left control', 'center', 'center', white);
            Screen('Flip', window);
            
            
            % go into the waiting room
            waiting_room(left_control_key)
            trialStartTime = GetSecs;
            pause(1);
            
            % retake basline measurements.
            DrawFormattedText(window, 'Baseline EMG in: 3s', 'center', 'center', white);
            Screen('Flip', window);
            pause(1);
            DrawFormattedText(window, 'Baseline EMG in: 2s', 'center', 'center', white);
            Screen('Flip', window);
            pause(1);
            DrawFormattedText(window, 'Baseline EMG in: 1s', 'center', 'center', white);
            Screen('Flip', window);
            pause(1);
            
            bias_starttime=0;
            rawchunkData =[];
            bias_estimation_duration = GetSecs + 2;
            
            DrawFormattedText(window, 'Baseline EMG recording ...', 'center', 'center', white);
            Screen('Flip', window);
            
            % collect data
            record = true;
            while bias_starttime < bias_estimation_duration
                %it doesn't seem to record anything unless i set the pause
                pause(0.001)
                bias_starttime = GetSecs;
            end
            record = false;
            
            DrawFormattedText(window, 'Baseline EMG recording done.', 'center', 'center', white);
            Screen('Flip', window);
            
            % take means
            uniqueChunkData = ([Hist_Time, Hist_Data]);
            
            % now clear global data
            % Hist_Data = [];
            % Hist_Time = [];
            
            bias_ch2 = mean(uniqueChunkData(:,3));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
            bias_ch3 = mean(uniqueChunkData(:,4));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
            bias_ch4 = mean(uniqueChunkData(:,5));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
            bias_ch5 = mean(uniqueChunkData(:,6));%ch1 is timestamp, ch2 TMS, ch3 first muscle etc
            
            record = previous_record;
            clear previous_record keyIsDown secs keyCode;
        end
        
        %% Quick check to keep TMS machine armed
        TMS_armed_check = GetSecs;
        if (TMS_armed_check > TMS_last_used + 45)
            % set Intensity again to keep TMS active
            duoPulse(duoMag1, str2num(intensity_string));
            TMS_last_used = GetSecs;
            
            % Check if recordings have a certain size. if yes, cut down to
            % more manageable size
            if (size(Hist_Data, 1) > 15*round(s.Rate))
                Hist_Data = Hist_Data((end-8*round(s.Rate)):end,:);
                Hist_Time = Hist_Time((end-8*round(s.Rate)):end,:);
            end
        end
        
        % create variables from globals
        pause(0.001);
        % not needed in global
        %         timeStamps = tS;
        %         rawData = rD;
        
        %% Trialstate 3 loops (sends pulses)
        % Trialstate 3 = send pulse. Also checks if EMG good. CWK the state
        % selector stuff
        if trialState == 3 && triggerSent == 0  ...
                && vbl - emgStartTime > triggerTime && TMS_State_selector(ii) == 1;
            
            % send pulse
            % duoPulse(duoMag1);
            outputSingleScan(o,4);
            outputSingleScan(o,4);
            outputSingleScan(o,4);
            outputSingleScan(o,0);
            
            triggerSent = 1;
            Trigger_time=GetSecs;
            TMS_last_used = GetSecs;
            
            % if the TMS pulse was a Single Pulse, add one counter, but how
            % is this necessary? we check this condition before entering the loop CWK
            if TMS_State_selector(ii) == 2;
                mepCount = mepCount + 1;
            end
        end
        
        % another Send Pulse block, if state selector is == 2. again see
        % comments made further up about state selector (CWK)
        if trialState == 3 && triggerSent == 0  ...
                && vbl - emgStartTime > triggerTime && TMS_State_selector(ii) == 2;
            
            % collect Data
            pause(0.001)
            
            % start time of Trialstate 3
            TMS_exp_start = GetSecs;
            
            % jitter 200ms around TMS time 
            num_1_to_3=randi([1 3]);
            execute_vector=[2.800 3.000 3.200];
            execute=execute_vector(num_1_to_3);
            
            % Here we enter the loop, at 3 Seconds the pulse will be
            % delivered with a jitter of 200ms, the loop will exit
            % after 4s (full video time)
            time_counter = GetSecs - TMS_exp_start;
            
            % Playback loop: Runs for 4 seconds:
            while (time_counter < 4)

                pause(0.001)
                
                %this updates the timing information
                time_counter = GetSecs - TMS_exp_start;
            
                if time_counter > execute && triggerSent == 0
                    
                    % send pulse
                    %duoPulse(duoMag1);
                    outputSingleScan(o,4);
                    outputSingleScan(o,4);
                    outputSingleScan(o,4);
                    outputSingleScan(o,0);
                    

                    
                    Trigger_time=GetSecs;
                    pause(0.001)
                    triggerSent = 1;
                    TMS_last_used = GetSecs;
                    
                    % CWK again why check for selector, if we check this as
                    % entry condition?
                    if TMS_State_selector(ii) == 2;
                        mepCount = mepCount + 1;
                    end
                end
            end
        end
        
        %Caclulate the position of the feedback bar
        barYpos=screenYpixels-round(screenYpixels*(All_ch_mean/Range));
        bar=[centreX-200 barYpos centreX+200 screenYpixels];
        
        %I include this just so a massive MEP doesnt crash the program if
        %it tries to plot it off the screen
        if barYpos<0
            barYpos=0;
        end
        
        if All_ch_mean>mean_MEP
            barColour=[0 1 0];
        else
            barColour=[1 0 0];
        end
        
        
        % collect Data as it might run too fast
        pause(0.01)
        %% Trialstate 1
        % display settings for each trial state
        if trialState == 1  % rest
            %             rawRMSData = [rawRMSData; timeStamps rawData];
            %             uniqueRMSData = unique(rawRMSData, 'rows');
            pause(0.01)
            uniqueRMSData = [Hist_Time, Hist_Data];
            
            % here, on the first run through global has less data than the previous iteration of the
            % code, so let's take the biggest amount of data up to 0.5ms
            earliest_emg_data = max(1, length(uniqueRMSData)- round(0.5*s.Rate));
            RMS_chunk_ch2=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),3); %second channel is TMS. First is timestamp. Third is first EMG. Takes last 1000 samples for the chunk to take rms
            RMS_chunk_ch2=RMS_chunk_ch2-bias_ch2;
            rms_ch2=rms(RMS_chunk_ch2);
            RMS_chunk_ch3=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),4); %second channel is TMS. First is timestamp. Third is first EMG
            RMS_chunk_ch3=RMS_chunk_ch3-bias_ch3;
            rms_ch3=rms(RMS_chunk_ch3);
            RMS_chunk_ch4=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),5); %second channel is TMS. First is timestamp. Third is first EMG
            RMS_chunk_ch4=RMS_chunk_ch4-bias_ch4;
            rms_ch4=rms(RMS_chunk_ch4);
            RMS_chunk_ch5=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),6); %second channel is TMS. First is timestamp. Third is first EMG
            RMS_chunk_ch5=RMS_chunk_ch5-bias_ch5;
            rms_ch5=rms(RMS_chunk_ch5);
            
            if rms_ch2<backgnd_EMG_threshold
                DotColourCh2=[0 1 0];
                FDIrmsgood=1;
                timerflag=1;
                startgood=GetSecs;
            else
                DotColourCh2=[1 0 0];
                FDIrmsgood=0;
            end
            
            if rms_ch3<backgnd_EMG_threshold
                DotColourCh3=[0 1 0];
                ch3rmsgood=1;
            else
                DotColourCh3=[1 0 0];
                ch3rmsgood=0;
            end
            
            if rms_ch4<backgnd_EMG_threshold
                DotColourCh4=[0 1 0];
                ch4rmsgood=1;
            else
                DotColourCh4=[1 0 0];
                ch4rmsgood=0;
            end
            
            if rms_ch5<backgnd_EMG_threshold
                DotColourCh5=[0 1 0];
                ch5rmsgood=1;
            else
                DotColourCh5=[1 0 0];
                ch5rmsgood=0;
            end
            
            Screen('FillOval', window, DotColourCh2, centredRect1, maxDiameter)
            Screen('FillOval', window, DotColourCh3, centredRect2, maxDiameter)
            Screen('FillOval', window, DotColourCh4, centredRect3, maxDiameter)
            Screen('FillOval', window, DotColourCh5, centredRect4, maxDiameter)
            
            %% Trialstate 2
        elseif trialState == 2 %fixation cross cue on screen
            %             rawRMSData = [rawRMSData; timeStamps rawData];
            %             uniqueRMSData = unique(rawRMSData, 'rows');
            pause(0.01)
            uniqueRMSData = [Hist_Time, Hist_Data];
            
            % here, on the first run through global has less data than the previous iteration of the
            % code, so let's take the biggest amount of data up to 0.5ms
            earliest_emg_data = max(1, length(uniqueRMSData)- round(0.5*s.Rate));
            RMS_chunk_ch2=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),3); %second channel is TMS. First is timestamp. Third is first EMG. Takes last 1000 samples for the chunk to take rms
            RMS_chunk_ch2=RMS_chunk_ch2-bias_ch2;
            rms_ch2=rms(RMS_chunk_ch2);
            RMS_chunk_ch3=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),4); %second channel is TMS. First is timestamp. Third is first EMG
            RMS_chunk_ch3=RMS_chunk_ch3-bias_ch3;
            rms_ch3=rms(RMS_chunk_ch3);
            RMS_chunk_ch4=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),5); %second channel is TMS. First is timestamp. Third is first EMG
            RMS_chunk_ch4=RMS_chunk_ch4-bias_ch4;
            rms_ch4=rms(RMS_chunk_ch4);
            RMS_chunk_ch5=uniqueRMSData(earliest_emg_data:length(uniqueRMSData),6); %second channel is TMS. First is timestamp. Third is first EMG
            RMS_chunk_ch5=RMS_chunk_ch5-bias_ch5;
            rms_ch5=rms(RMS_chunk_ch5);
            
            if rms_ch2<backgnd_EMG_threshold
                FDIrmsgood=1;
            else
                DotColourCh2=[1 0 0];
                FDIrmsgood=0;
            end
            
            if rms_ch3<backgnd_EMG_threshold
                DotColourCh3=[0 1 0];
                ch3rmsgood=1;
            else
                DotColourCh3=[1 0 0];
                ch3rmsgood=0;
            end
            
            if rms_ch4<backgnd_EMG_threshold
                DotColourCh4=[0 1 0];
                ch4rmsgood=1;
            else
                DotColourCh4=[1 0 0];
                ch4rmsgood=0;
            end
            
            if rms_ch5<backgnd_EMG_threshold
                DotColourCh5=[0 1 0];
                ch5rmsgood=1;
            else
                DotColourCh5=[1 0 0];
                ch5rmsgood=0;
            end
            
            Screen('DrawTexture', window, fixationTexture, [],[fixation_targetX-(fixationX/2) fixation_targetY-(fixationY/2) fixation_targetX+(fixationX/2) fixation_targetY+(fixationY/2)]);
            
            %% Trialstate 3
        elseif trialState == 3  % emg
            pause(0.001)
            %             timeStamps = tS;
            %             rawData = rD;
            %             rawEpochData = [rawEpochData; timeStamps rawData]; %aquiring the data to use for MEP measurement
            if TMS_State_selector(ii)==1;
                Screen('DrawTexture', window, fixationTexture, [],[fixation_targetX-(fixationX/2) fixation_targetY-(fixationY/2) fixation_targetX+(fixationX/2) fixation_targetY+(fixationY/2)]);
            end
            %             rawEpochData = [rawEpochData; timeStamps rawData]; %aquiring the data to use for MEP measurement
            Screen('DrawTexture', window, fixationTexture, [],[fixation_targetX-(fixationX/2) fixation_targetY-(fixationY/2) fixation_targetX+(fixationX/2) fixation_targetY+(fixationY/2)]);
            
            
            %% Trialstate 4
        elseif trialState == 4  % show feedback
            if TMS_State_selector(ii) == 2;
                Screen('FillRect', window, barColour, bar);
                Screen('FillRect', window, lineColour, line);
                if All_ch_mean>mean_MEP
                    Screen('DrawTexture', window, tickTexture, [],[targetX-(tickX/2) targetY-(tickY/2) targetX+(tickX/2) targetY+(tickY/2)]);
                    %Screen('DrawTexture', window, dollarTexture, [],[dollar_targetX-(dollarX/2) dollar_targetY-(dollarY/2) dollar_targetX+(dollarX/2) dollar_targetY+(dollarY/2)]);
                    DrawFormattedText(window,[num2str(nSuccess) '/' num2str(mepCount)], centreX+350, 840, white);
                else
                    Screen('DrawTexture', window, crossTexture, [],[targetX-(crossX/2) targetY-(crossY/2) targetX+(crossX/2) targetY+(crossY/2)]);
                end
            elseif TMS_State_selector(ii) == 1;
                Screen('DrawLines', window, allCoords, lineWidthPix, red, [xCenter yCenter], 2);
                %DrawFormattedText(window, num2str(mepCount), centreX+350, 840, white);
            end
        end
        
        if TMS_State_selector(ii) == 2 && All_ch_mean>mean_MEP && flag==0 && trialState==4
            nSuccess=nSuccess+1;
            flag=1;
        end
        
        % Flip to the screen
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        
        % write results file
        writeData = [Hist_Time, repmat(ii,[size(Hist_Time),1]) ...
            Hist_Data, repmat(trialState,[size(Hist_Time),1])]';
        fprintf(dataFilePointer, [repmat('%i ', 1, size(writeData,1)-1) '%i\n'], writeData);
        
        % determine trial state
        % When we determine trial state is when we need to clear our global
        % recordings
        if trialState == 1 && vbl - trialStartTime > gapDurationArray(ii,1) && FDIrmsgood==1 && ch3rmsgood==1 && ch4rmsgood==1 && ch5rmsgood==1;
            trialState = 2;
            
            %clear global variables
            record = false;
            Hist_Data = [];
            Hist_Time = [];
            
            fixStartTime = GetSecs;
            
        elseif trialState == 2 && vbl - fixStartTime > fixgapDurationArray(ii,1) && FDIrmsgood==1 && ch3rmsgood==1 && ch4rmsgood==1 && ch5rmsgood==1;
            pause(WaitgapDurationArray(ii,1));
            
            %clear global variables
            record = false;
            Hist_Data = [];
            Hist_Time = [];
            
            emgStartTime = GetSecs;
            trialState = 3;
            
        elseif trialState  == 3   && triggerSent==1 && vbl - emgStartTime > Trigger_time - emgStartTime + 1
            
            %pause(1);
            trialState = 4;
            feedbackStartTime = GetSecs;
            % process emg data for feedback
            %             rawEpochData = [rawEpochData; timeStamps rawData]; %aquiring the data to use for MEP measurement
            %
            %             uniqueEpochData = unique(rawEpochData, 'rows');
            
            % here we get the global data back
            feedbackData = [Hist_Data, Hist_Time];
            %             feedbackData = [uniqueEpochData(:,2:end), uniqueEpochData(:,1)]; %first channel is timestamps
            
            % cut feedbackdata to a manageable piece of 0.5s on each side
            % of TMS trigger
            TMS_timing = feedbackData(get_TMS_onset(feedbackData(:,1)),6);
            feedbackData_shortened = and(feedbackData(:,6)> TMS_timing - 0.5, feedbackData(:,6) < TMS_timing + 0.5);
            feedbackData = feedbackData(feedbackData_shortened, :);
            

            % We don't need to save rawepochdata, as this is unnecessary
            % with global approach
            if TMS_State_selector(ii)==2
                if execute==2.800
                    TMS_time='2.8seconds';
                elseif execute==3.000
                    TMS_time='3seconds';
                elseif execute==3.200
                    TMS_time='3.2seconds';
                end
                save([subDir filesep 'sub-' num2str(subNum) '-up-' SesNum '-' blockNumber_str '-TMStime-' TMS_time '-mep' (num2str(ii)) '-eeg.mat'], 'feedbackData');
                % old: save([data_direc filesep subCode filesep SesNum filesep EEG_Sess 'exp_UP' dayNumber_str blockNumber_str '_TMS_time_' TMS_time '_state' num2str(TMS_State_selector(ii)) '-mep' (num2str(ii)) '.mat'], 'feedbackData')
            elseif TMS_State_selector(ii)==1
                save([subDir filesep 'sub-' num2str(subNum) '-up-' SesNum '-' blockNumber_str '-mep' (num2str(ii)) '-eeg.mat'], 'feedbackData');
                % old: save([data_direc filesep subCode filesep SesNum filesep EEG_Sess 'exp_UP' dayNumber_str blockNumber_str '_state' num2str(TMS_State_selector(ii)) '-mep' (num2str(ii)) '.mat'], 'feedbackData')
            end
            
            %feedbackData = [uniqueEpochData(:,2:end), uniqueEpochData(:,1)]; %first channel is timestamps
            %save([direc filesep 'data' filesep '2018' filesep subCode filesep SesNum filesep 'exp_UP' num2str(blockNumber) '_TMS_time' TMS_time '_state' num2str(TMS_State_selector(ii)) '-mep' (num2str(ii)) '.mat'], 'feedbackData','rawEpochData' )
            
            %save([direc filesep 'data' filesep subCode filesep 'Ses' num2str(SesNum) filesep 'expt2_exp_UP11' '-mep' (num2str(ii)) '.mat'], 'feedbackData','rawRMSData' )
            % debug catch, breakpiont and warning
            
            TMS=feedbackData(:,1);
            try
                TMS_onset = get_TMS_onset(TMS); %function returns the first frame of the TMS pulse
            catch
                warning('Problem using get_TMS_onset function.  Assigning a value of 0.');
            end
            
            MEP_onset = TMS_onset+MEP_latencyFrames+DelsysDelayFrames;
            MEP_offset = MEP_onset+MEP_duration;
            MEP_segment=feedbackData(MEP_onset:MEP_offset,2);%first EMG channel,ch2 on NI board
            MEP_amp=peak2peak(MEP_segment);
            
            MEP_segment_1=feedbackData(MEP_onset:MEP_offset,2);%first EMG channel,ch2 on NI board
            %MEP_amp _1=sqrt(mean(MEP_segment_1.^2));
            MEP_amp_1=peak2peak(MEP_segment_1);
            
            MEP_segment_2=feedbackData(MEP_onset:MEP_offset,3);%first EMG channel,ch2 on NI board
            %MEP_amp_2=sqrt(mean(MEP_segment_2.^2));
            MEP_amp_2=peak2peak(MEP_segment_2);
            
            MEP_segment_3=feedbackData(MEP_onset:MEP_offset,4);%first EMG channel,ch2 on NI board
            %MEP_amp_3=sqrt(mean(MEP_segment_3.^2));
            MEP_amp_3=peak2peak(MEP_segment_3);
            
            Ch1_MEP_vector=[Ch1_MEP_vector;MEP_amp_1];
            Ch2_MEP_vector=[Ch2_MEP_vector;MEP_amp_2];
            Ch3_MEP_vector=[Ch3_MEP_vector;MEP_amp_3];
            
            MeanMEP1=mean(Ch1_MEP_vector);
            MeanMEP2=mean(Ch2_MEP_vector);
            MeanMEP3=mean(Ch3_MEP_vector);
            
            %All_ch_mean=mean([MeanMEP1,MeanMEP2,MeanMEP3]); %ERNESTS
            %METHOD
            
            All_ch_mean=mean([MEP_amp_1,MEP_amp_2]); %Kathys method
            
            % adjust to sampling rate dependant ms
            bias_ch2=mean(feedbackData(0.05*round(s.Rate):0.25*round(s.Rate),2));
            bias_ch3=mean(feedbackData(0.05*round(s.Rate):0.25*round(s.Rate),3));
            bias_ch4=mean(feedbackData(0.05*round(s.Rate):0.25*round(s.Rate),4));
            bias_ch5=mean(feedbackData(0.05*round(s.Rate):0.25*round(s.Rate),5));
            
            %remove bias and calculate rms background EMG
            biasCorrectedCh2=feedbackData(:,2)-bias_ch2;
            biasCorrectedCh3=feedbackData(:,3)-bias_ch3;
            biasCorrectedCh4=feedbackData(:,4)-bias_ch4;
            biasCorrectedCh5=feedbackData(:,5)-bias_ch5;
            
            %Provide auditory feedback
            if TMS_State_selector(ii)==2;
                if All_ch_mean>mean_MEP && soundOccured ==0 && trialState == 4;
                    PsychPortAudio('FillBuffer', pahandle, winSoundData);
                    PsychPortAudio('Start', pahandle, 1, 0, 0);
                    soundOccured=1;
                elseif All_ch_mean<mean_MEP && soundOccured ==0;
                    PsychPortAudio('FillBuffer', pahandle, loseSoundData);
                    PsychPortAudio('Start', pahandle, 1, 0, 0);
                    soundOccured=1;
                end
                
            elseif TMS_State_selector(ii)==1;
                soundOccured=1;
            end
            % clear global variables
            record = false;
            Hist_Data = [];
            Hist_Time = [];
            
            %%% End while loop when time is up
        elseif trialState == 4 && vbl - feedbackStartTime > feedbackDuration
            exitTrial = true;
            
            % stop recording, technacilly we always go trialstate 3 to
            % trialstate 4, so we should never have to stop recording and
            % clear global data. but let's do anyway to be sure.
            record = false;
            Hist_Data = [];
            Hist_Time = [];
        end
    end
    
    % check for exit request
    if keyCode(escapeKey)
        %stop recording
        record = false;
        
        break
    end
end

percentage_success=(nSuccess/(nMEPs))*100
save([subDir filesep 'sub-' num2str(subNum) '-up-' SesNum '-' blockNumber_str '-success-' (num2str(nSuccess)) '-eeg.mat'], 'nSuccess', 'percentage_success');
% old: save([data_direc filesep subCode filesep SesNum filesep EEG_Sess 'UP_b'  dayNumber_str  blockNumber_str '-success' (num2str(nSuccess)) '.mat'], 'nSuccess', 'percentage_success')%save the num of successful trials

file_ID = fopen([subDir filesep 'sub-' num2str(subNum) '-up-' SesNum '-' blockNumber_str '-profile-eeg.txt'], 'a');
% old: file_ID = fopen([data_direc filesep subCode filesep SesNum filesep EEG_Sess 'Exp_UP_b'  dayNumber_str  blockNumber_str '_Profile.txt'], 'a');

prof_0 = ['The chosen intensity was ' num2str(intensity) '\n'];
fprintf(file_ID, prof_0);

prof_1 = ['The mean MEP amplitude was ' num2str(mean_MEP) '\n'];
fprintf(file_ID, prof_1);

prof_2 = ['The threshold was ' num2str(backgnd_EMG_threshold) '\n'];
fprintf(file_ID, prof_2);

fclose(file_ID);

%% Cleanup
% Disconnect all objects.
fclose(duoMag1);

% Clean up all objects.
delete(duoMag1);

% Delete from workspace.
clear duoMag1;% csi cleanup part

PsychPortAudio('Stop', pahandle);
PsychPortAudio('Close', pahandle);
fclose('all');
close all;
clear all;

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
