% Pause Execution of Script at a specific point
function waiting_room(left_control_key)

    % set waiting variable (true = key has not been pressed to continue)
    no_keypress = true;
    
    % enter wait loop
    while(no_keypress)
        
        % check if key was pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        pause(1);
                
        % check for exit request
        if keyCode(left_control_key)
            
            % correct key was pressed, exit break function
            no_keypress = false;
        end
    end
end