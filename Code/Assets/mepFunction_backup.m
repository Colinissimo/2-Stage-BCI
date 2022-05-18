function mepFunction
rmt= input('Desired Intensity');
mean_MEP=2;
% Seed random number generator
rng('shuffle');

% set experiment parameters
subCode = 'S05';
blockNumber = 1;

nChans = 4;  % number of EMG channels
nMEPs = 3;  % number of MEPs to collect
emgDuration = 1;  % collect EMG data for this duration
triggerTime = 0.5;  % time after trial start to send TMS trigger
feedbackDuration = 4;  % visual feedback duration
minGap = 3; maxGap = 6;   % set min and max gap times
gapDurationArray = (rand(nMEPs,1)*maxGap) + minGap;  % array of gap duration between trials

% file handling
subDir = ['data' filesep subCode filesep];
if ~exist(subDir,'dir')
    mkdir(subDir);
end

dataFilename = ['data' filesep subCode filesep 'b'  num2str(blockNumber) '-m' num2str(nMEPs) '-c' num2str(nChans) '.dat'];

%This is protection for overwriting files. Keep commented for programming
%purposes but uncomment during real experiment
% if fopen(dataFilename,'rt') ~= -1
%     fclose('all');
%     error('computer says no: result data file already exists!');
% else
dataFilePointer = fopen(dataFilename,'wt');
% end

% define global variables
global rD
global tS

%%% configure TMS serial port communication here %%%

% setup data acquisition device
s = daq.createSession('ni');
s.addAnalogInputChannel('Dev2', 0:(nChans-1), 'Voltage');
set(s.Channels, 'InputType', 'SingleEnded');
set(s.Channels, 'Range', [-5,5]);
s.Rate = 2000;
s.NotifyWhenDataAvailableExceeds = 100;
s.IsContinuous = true;
lh = addlistener(s, 'DataAvailable', @rData);
s.startBackground();

% Call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Give Matlab high priority
Priority(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% The avaliable keys to press
escapeKey = KbName('ESCAPE');
spaceKey = KbName('SPACE');

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
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Dummy calls to make sure functions are ready to go without delay
KbCheck;
[keyIsDown, secs, keyCode] = KbCheck;
WaitSecs(0.1);
GetSecs;

% Set default screen font and size for written messages
Screen('TextSize', window, 20);
Screen('TextFont', window, 'Arial');

% Trial state indicator feedback
redDot = [1 0 0];
greenDot = [0 1 0];
blueDot = [0 0 1];

% Dot position
dotXpos = 150;
dotYpos = 150;

% Dot size in pixels
dotSizePix = 20;

%% SET UP TMS AND SERIAL PORT COMMUNICATION
delete(instrfindall);  % to clear any pre existing COM port activities
%Set up serial port connection
serialPortObj=serial('COM1', 'BaudRate',9600,'DataBits',8,'Stopbits',1,'Parity','none','FlowControl','none','inputbuffersize',1024,'outputbuffersize',1024,'Terminator','?');
% Callback function to execute every 500 ms to ensure that the stimulator
% is in the remote control mode and will stay armed. Otherwise,
% stimulator will disarm itself automatically in about 1 sec.
serialPortObj.TimerPeriod = 0.5; % period of executing the callback function in sec
fopen(serialPortObj);
serialPortObj.TimerFcn = {'Rapid2_MaintainCommunication'};
Rapid2_Delay(1000, serialPortObj);
pause on;
%arm stimulator
success = Rapid2_ArmStimulator(serialPortObj)
%set power level
powerLevel=rmt;

if powerLevel>100;
    powerLevel=100;
end

success = Rapid2_SetPowerLevel(serialPortObj, powerLevel, 1);
if ~success
    display 'Error: Cannot set the power level';
    return
else
    % Display power level;
    display(powerLevel);
    % Introduce delay to allow the  stimulator to adjust to the new power level
    %Rapid2_Delay(4000, serialPortObj);
end
%%Prepare the sounds
% load sounds
soundsPath= 'C:\Users\big lab\Documents\MATLAB\MEP\sounds';
winWavPath = [soundsPath filesep 'better.wav'];
winSoundData = audioread(winWavPath);

loseWavPath = [soundsPath filesep 'worse.wav'];
loseSoundData = audioread(loseWavPath);

% Perform basic initialization of the sound driver:
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', 3, [], 2, 44100, 2, 0, 0.015);

%% Create a line that will be drawn at the mean MEP size
%Calculate the range of MEP sizes
min_MEP_value=0; max_MEP_value=4; Range=max_MEP_value-min_MEP_value;
barColour=[0 1 0];
%Format is left, top, right, bottom
lineYpos=screenYpixels-round(screenYpixels*(mean_MEP/Range));
line=[0 lineYpos screenXpixels lineYpos+10];
lineColour=[0 1 1];
MEP_amp=0;

%Add textures
tick_path= 'C:\Users\big lab\Documents\MATLAB\MEP\tick_transparent_smaller.png';
[tick map tickA] = imread(tick_path);
tick(:,:,4) = tickA;
[tickX tickY tickD] = size(tick);
tickTexture = Screen('MakeTexture', window, tick);
cross_path= 'C:\Users\big lab\Documents\MATLAB\MEP\cross2_small.png';
[cross map crossA] = imread(cross_path);
cross(:,:,4) = crossA;
[crossX crossY crossD] = size(cross);
crossTexture = Screen('MakeTexture', window, cross);
targetX=200;
targetY=200;


%% START EXPERIMENT

DrawFormattedText(window, 'press the spacebar to begin experiment', 'center', 'center', white);
Screen('Flip', window);
while (keyCode(spaceKey) == 0) [keyIsDown, secs, keyCode] = KbCheck; end
keyCode(spaceKey) = 0;
WaitSecs(0.5);
nSuccess=0;
mepCount = 0;
for ii = 1:nMEPs
    
    rawEpochData = [];
    triggerSent = 0;
    soundOccured=0;
    trialState = 1;
    exitTrial = false;
    flag=0;
    trialStartTime = GetSecs;
    while exitTrial == false
        
        % Check the keyboard to see if a button has been pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        
        % check for exit request
        if keyCode(escapeKey)
            exitTrial = true;
        end
        
        %  create variables from globals
        timeStamps = tS;
        rawData = rD;
        
        % send trigger if required
        if trialState == 2 && triggerSent == 0 ...
                && vbl - emgStartTime > triggerTime
            % send trigger via serial port here
            success = Rapid2_TriggerPulse(serialPortObj, 1)
            triggerSent = 1;
            mepCount = mepCount + 1;
        end
        
        
        
        
        %Caclulate the position of the feedback bar
        barYpos=screenYpixels-round(screenYpixels*(MEP_amp/Range));
        bar=[400 barYpos 800 screenYpixels];
        if MEP_amp>mean_MEP 
            barColour=[0 1 0];
        else
            barColour=[1 0 0];
        end
        
        if MEP_amp>mean_MEP && flag==0 && triggerSent==1
           nSuccess=nSuccess+1;
           flag=1;
        end
        
        
        % display settings for each trial state
        if trialState == 1  % rest
            %Screen('DrawDots', window, [dotXpos dotYpos], dotSizePix, greenDot, [], 2);  % trial state dot
        elseif trialState == 2  % emg
            rawEpochData = [rawEpochData; timeStamps rawData];
            %Screen('DrawDots', window, [dotXpos dotYpos], dotSizePix, redDot, [], 2);  % trial state dot
        elseif trialState == 3  % show feedback
            Screen('FillRect', window, barColour, bar);
            Screen('FillRect', window, lineColour, line);
            if MEP_amp>mean_MEP
        Screen('DrawTexture', window, tickTexture, [],[targetX-(tickX/2) targetY-(tickY/2) targetX+(tickX/2) targetY+(tickY/2)]);
            else
             Screen('DrawTexture', window, crossTexture, [],[targetX-(crossX/2) targetY-(crossY/2) targetX+(crossX/2) targetY+(crossY/2)]);
            end
        end
        % temporary display of trigger info + gap duration
        DrawFormattedText(window, ['Success= ' num2str(nSuccess) '/' num2str(mepCount)], 140, 450, white);
        %DrawFormattedText(window, ['GAP: ' num2str(gapDurationArray(ii,1))], 140, 350, white);
        
        % Flip to the screen
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        
        % write results file
        writeData = [timeStamps, repmat(ii,[size(timeStamps),1]) ...
            rawData, repmat(trialState,[size(timeStamps),1])]';
        fprintf(dataFilePointer, [repmat('%i ', 1, size(writeData,1)-1) '%i\n'], writeData);
        
        % determine trial state
        if trialState == 1 && vbl - trialStartTime > gapDurationArray(ii,1)
            trialState = 2;
            emgStartTime = GetSecs;
        elseif trialState  == 2 && vbl - emgStartTime > emgDuration
            trialState = 3;
            feedbackStartTime = GetSecs;
            % process emg data for feedback
            uniqueEpochData = unique(rawEpochData, 'rows');
            feedbackData = uniqueEpochData(:,2:end);
            save(['data' filesep subCode filesep 'b' num2str(blockNumber) '-mep' (num2str(ii)) '.mat'], 'feedbackData')
            MEP_segment=feedbackData(1300:1500,1);
            MEP_amp=peak2peak(MEP_segment);
            %%% calculate feedback here and display in trial state 3 display settings %%%
        elseif trialState == 3 && vbl - feedbackStartTime > feedbackDuration
            exitTrial = true;
        end
        %Provide auditory feedback
%         if MEP_amp>mean_MEP && soundOccured ==0;
%             PsychPortAudio('FillBuffer', pahandle, winSoundData);
%             PsychPortAudio('Start', pahandle, 1, 0, 0);
%             soundOccured=1;
%         else
%             PsychPortAudio('FillBuffer', pahandle, loseSoundData);
%             PsychPortAudio('Start', pahandle, 1, 0, 0);
%             soundOccured=1;
%         end
        
    end
    
    % check for exit request
    if keyCode(escapeKey)
        break
    end
    
end

    function rData(src,event)
        rD = event.Data;
        tS = event.TimeStamps;
    end
%Clear serial port
delete(instrfindall);
PsychPortAudio('Stop', pahandle);
PsychPortAudio('Close', pahandle);
fclose('all');
close all;
clear all;

end