%Set this up as a function that takes as an input only a vector of data containing one TMS pulse, and returns only the time in frames of the pulse 
function pulse_onset_frame = get_TMS_onset(TMS)
%%Parameters for pulse detection
    tolerance=1;
    target=4;
    
    if TMS(1) > 4
        target = 1;
    end
    

        %TMS_Data = TMS;
        
        hits = find( (TMS < (target + tolerance)) &  (TMS > (target - tolerance)) );
        
        pulse_onset_frame = hits(1);


end
        
        