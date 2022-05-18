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


%Add textures
tick_path= 'C:\Users\big lab\Documents\MATLAB\MEP\tick_transparent.png';
[tick map tickA] = imread(tick_path);
tick(:,:,4) = tickA;
[tickX tickY tickD] = size(tick);
tickTexture = Screen('MakeTexture', window, tick);


exitTrial=false;
while exitTrial==false;
 
     % Check the keyboard to see if a button has been pressed
        [keyIsDown,secs,keyCode] = KbCheck;
    % check for exit request
        if keyCode(escapeKey)
            exitTrial = true;
        end
        
        targetX=200;
        targetY=200;
        
        Screen('DrawTexture', window, tickTexture, [],[targetX-(tickX/2) targetY-(tickY/2) targetX+(tickX/2) targetY+(tickY/2)]);
        
        % Flip to the screen
        vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
end
ShowCursor;
Priority(0);
sca;
fclose('all');
close all;
