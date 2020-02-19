function TPx_calib_output = TPxCalibrationValidationRichardsFunction(windowPtr, scrBG, ...
    scr_ppd, ...
    n_calibration_points, eccentricity_points_x, eccentricity_points_y, ...
    duration_points, duration_shrinking, ...
    led_intensity, iris_size)
% Performs Calibration on the TrackPixx.
% Richard Schweitzer, 10/2018, heavily based on Danny's TPxCalibrationTesting
% function, but including a Validation procedure.

switch nargin % there are currently 10 arguments
    case 0
        windowPtr = []; % pointer to the screen to be used, if empty, then screen is created
        scrBG = 255/2; % screen background color
        scr_ppd = 50.9; % ppd for trackpixx setup at full HD, 380 cm viewing distance with 250.2 cm screen width
        n_calibration_points = 13;
        eccentricity_points_x = 600; % at full HD around 12 dva
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8; % value from 1 to 8, default 8
        iris_size = 140;
    case 1
        scrBG = 255/2;
        scr_ppd = 50.9;
        n_calibration_points = 13;
        eccentricity_points_x = 600; 
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 2
        scr_ppd = 50.9;
        n_calibration_points = 13;
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 3
        n_calibration_points = 13;
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 4
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 5
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 6
        duration_points = 1.5;
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 7
        duration_shrinking = 0.5;
        led_intensity = 8;
        iris_size = 140;
    case 8
        led_intensity = 8;
        iris_size = 140;
    case 9
        iris_size = 140;
end


%% Step 1.1, Initialize TRACKPixx, if we have not already
TPx_calib_output = []; % initialize output from this function
TPx_calib_output.happy_val = NaN;
single_point_collect_time = duration_points - duration_shrinking;

if isempty(windowPtr)
    Datapixx('Open');
    Datapixx('HideOverlay');
    Datapixx('RegWrRd');
    Datapixx('SetTPxAwake');
    Datapixx('RegWrRd');
    Datapixx('SetLedIntensity', led_intensity);
    Datapixx('SetExpectedIrisSizeInPixels', iris_size)
    Datapixx('RegWrRd');
end


%% Step 1.2, open the Window, if we have not already
if isempty(windowPtr)
    demo_mode = 1;
    %Screen('Preference', 'SkipSyncTests', 1)
    [windowPtr, windowRect]=PsychImaging('OpenWindow', Screen('Screens'), scrBG);
    Screen('BlendFunction', windowPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    KbName('UnifyKeyNames');
else
    demo_mode = 0;
    windowRect = Screen('Rect', windowPtr);
end




%% Step 2, show the eye for focus
[left_rec, left_rec_pixel_coordinates, right_rec, right_rec_pixel_coordinates, escape_this_calib, calib_type] = ...
    select_eyes(windowPtr, windowRect, scrBG);
WaitSecs(0.2);

if escape_this_calib == 0 % only if we didn't press escape
    
    % clear last calibration if we have decided to run a calibration
    Datapixx('ClearCalibration');
    Datapixx('RegWrRd');
    
    %% Step 3, Calibrations and calibrations results.
    
    % !!!! rectangle disposition !!!!!
    %
    %       x           x           x
    %
    %             x           x
    %
    %       x           x           x
    %
    %             x           x
    %
    %       x           x           x
    %
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    cx = 1920/2; % Point center in x
    cy = 1080/2; % Point center in y
    dx = eccentricity_points_x; % How big of a range to cover in X
    dy = eccentricity_points_y; % How big of a range to cover in Y
    xy = [  cx cy;...
        cx cy+dy;...
        cx+dx cy;...
        cx cy-dy;...
        cx-dx cy;...
        cx+dx cy+dy;...
        cx-dx cy+dy;...
        cx+dx cy-dy;...
        cx-dx cy-dy;...
        cx+dx/2 cy+dy/2;...
        cx-dx/2 cy+dy/2;...
        cx-dx/2 cy-dy/2;...
        cx+dx/2 cy-dy/2;...
        ];
    % select number of calibration points. max is 13.
    if n_calibration_points > 2 && n_calibration_points < 13
        xy = xy(1:n_calibration_points, :);
    end;
    xyCartesian = Datapixx('ConvertCoordSysToCartesian', xy);
    xyCartesian = xyCartesian';
    xy = xy';
    nmb_pts = size(xy);
    nmb_pts = nmb_pts(2);
    
    % preallocate the dots for calibration
    i = 0;
    t = 0;
    showing_dot = 0;
    Sx = 0;
    Sy = 0;
    raw_vector = zeros(nmb_pts,4);
    raw_vector_sc = zeros(nmb_pts,4);
    finish_calibration = 0;
    t2 = t;
    
    % before the calibration loop starts, we want to present the central dot
    % for one second for the eyes to settle there
    DrawFillRect(windowPtr, scrBG); % make screen background
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [33;18]', [255 255 255; 200 0 0]', [], 1);
    Screen('Flip', windowPtr);
    if i == 0 % the very first dot should be presented a little longer
        WaitSecs(1);
    end
    
    % this is the CALIBRATION loop
    while ~finish_calibration
        
        if ((t2 - t) > duration_points) % points presented every 2 sec initially
            Sx = xyCartesian(1,mod(i,nmb_pts)+1);
            Sy = xyCartesian(2,mod(i,nmb_pts)+1);
            DrawFillRect(windowPtr, scrBG); % make screen background
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [35;20]', [255 255 255; 200 0 0]', [], 1);
            Screen('Flip', windowPtr);
            showing_dot = 1;
            t = t2;
        else
            Datapixx('RegWrRd');
            t2 = Datapixx('GetTime');
        end
        
        % this is this fancy and inefficient shrinking dot type of calibration
        if showing_dot
            shrinking_dot(windowPtr, scrBG, duration_shrinking, xy, nmb_pts, i, t, t2);
        end
        
        % once the dot has its small form, we collect data
        if (showing_dot && (t2 - t) > 0.95*duration_shrinking) 
            % Get some samples!
            if demo_mode
                fprintf('\nNow getting samples for screen position (%d,%d)\n', Sx, Sy);
            end
            if (calib_type == 1) % If in manual mode wait for a keypress
                KbWait;
            end
            i = i + 1; % Next point
            fprintf('\ni: %d\n', i);
            % Send the screen coordinates and acquire data from TPx.
            [xRawRight, yRawRight, xRawLeft, yRawLeft] = ...
                Datapixx('GetEyeDuringCalibrationRaw', Sx, Sy); % Raw Values from TPx to verify
            raw_vector(i,:) = [xRawRight yRawRight xRawLeft yRawLeft];
            disp(raw_vector);
            showing_dot = 0;
        end
        
        % once we have data for all points, the data are fitted
        if (i == nmb_pts) %% We showed all the points, now we evaluate.
            % Plot the results of the calibrations...
            WaitSecs(0.2);
            if demo_mode % save the raw calibration data as figures
                figure('Name','raw_data_right');
                H = scatter(raw_vector(:,1), raw_vector(:,2));
                grid on;
                grid minor;
                saveas(H, 'raw_data_right.fig', 'fig')
                figure('Name','raw_data_left');
                H = scatter(raw_vector(:,3), raw_vector(:,4));
                grid on;
                grid minor;
                saveas(H, 'raw_data_left.fig', 'fig')
            end
            
            %% THE BLACK BOX
            % remap data to proper range. This is only to display the raw values relative to screen.
            Datapixx('FinishCalibration');
%             ShowCursor();
            raw_vector_sc(:,1) = (raw_vector(:,1)-min(raw_vector(:,1)))/(max(raw_vector(:,1))-min(raw_vector(:,1)))*(1800-120)+120;
            raw_vector_sc(:,2) = (raw_vector(:,2)-min(raw_vector(:,2)))/(max(raw_vector(:,2))-min(raw_vector(:,2)))*(1000-80)+80;
            raw_vector_sc(:,3) = (raw_vector(:,3)-min(raw_vector(:,3)))/(max(raw_vector(:,3))-min(raw_vector(:,3)))*(1800-120)+120;
            raw_vector_sc(:,4) = (raw_vector(:,4)-min(raw_vector(:,4)))/(max(raw_vector(:,4))-min(raw_vector(:,4)))*(1000-80)+80;
            
            % Now we need to acquire the coefficients of the calibration.
            calibrations_coeff = Datapixx('GetCalibrationCoeff');
            coeff_x = calibrations_coeff(1:9);
            coeff_y = calibrations_coeff(10:18);
            coeff_x_L = calibrations_coeff(19:27);
            coeff_y_L = calibrations_coeff(28:36);
            
            % Now we want to evaluate raw_vector's values using the polynomials.
            % Lets use a function for that. Or 2 for X and Y. Will need to seperate in
            % groups of 9 terms.
            [x_eval_cartesian,y_eval_cartesian] = ...
                evaluate_bestpoly(raw_vector(:,1)', raw_vector(:,2)', coeff_x, coeff_y);
            [x_eval_L_cartesian,y_eval_L_cartesian] = ...
                evaluate_bestpoly(raw_vector(:,3)', raw_vector(:,4)', coeff_x_L, coeff_y_L);
            right_eye_eval = [x_eval_cartesian' y_eval_cartesian'];
            left_eye_eval = [x_eval_L_cartesian' y_eval_L_cartesian'];
            xy_eval = Datapixx('ConvertCoordSysToCustom', right_eye_eval);
            xy_eval_L = Datapixx('ConvertCoordSysToCustom', left_eye_eval);
            x_eval = xy_eval(:,1)';
            y_eval = xy_eval(:,2)';
            x_eval_L = xy_eval_L(:,1)';
            y_eval_L = xy_eval_L(:,2)';
            
            % Now we have evaluations of "raw_vectors". Here we make
            % interpolations...
            p_p = [9 4; 4 8; 9 5; 4 1; 8 3; 5 1; 1 3; 5 7; 1 2; 3 6; 7 2; 2 6];
            n_points = 10;
            x_interpol_raw = zeros(12, n_points); % we have 12 segments, we create 10 points each for now
            y_interpol_raw = zeros(12, n_points);
            x_interpol_raw_L = zeros(12, n_points);
            y_interpol_raw_L = zeros(12, n_points);
            x_interpol = zeros(12, n_points);
            y_interpol = zeros(12, n_points);
            x_interpol_L = zeros(12, n_points);
            y_interpol_L = zeros(12, n_points);
            x_interpol_cartesian = zeros(12, n_points);
            y_interpol_cartesian = zeros(12, n_points);
            x_interpol_L_cartesian = zeros(12, n_points);
            y_interpol_L_cartesian = zeros(12, n_points);
            right_eye_interpol = zeros(n_points,2,12);
            left_eye_interpol = zeros(n_points,2,12);
            xy_interpol = zeros(n_points,2,12);
            xy_interpol_L = zeros(n_points,2,12);
            for i = 1:12
                x_interpol_raw(i,:) = linspace(raw_vector(p_p(i,1),1),raw_vector(p_p(i,2),1), n_points);
                y_interpol_raw(i,:) = linspace(raw_vector(p_p(i,1),2),raw_vector(p_p(i,2),2), n_points);
                x_interpol_raw_L(i,:) = linspace(raw_vector(p_p(i,1),3),raw_vector(p_p(i,2),3), n_points);
                y_interpol_raw_L(i,:) = linspace(raw_vector(p_p(i,1),4),raw_vector(p_p(i,2),4), n_points);
            end
            
            % Ok all interpolated data created in raw coordinates. Need to evaluate in
            % polynomial.
            for i = 1:12
                [x_interpol_cartesian(i,:),y_interpol_cartesian(i,:)] = ...
                    evaluate_bestpoly(x_interpol_raw(i,:)', y_interpol_raw(i,:)', coeff_x, coeff_y);
                [x_interpol_L_cartesian(i,:),y_interpol_L_cartesian(i,:)] = ...
                    evaluate_bestpoly(x_interpol_raw_L(i,:)', y_interpol_raw_L(i,:)', coeff_x_L, coeff_y_L);
                right_eye_interpol(:,:,i) = [x_interpol_cartesian(i,:)' y_interpol_cartesian(i,:)'];
                left_eye_interpol(:,:,i) = [x_interpol_L_cartesian(i,:)' y_interpol_L_cartesian(i,:)'];
                xy_interpol(:,:,i) = Datapixx('ConvertCoordSysToCustom', right_eye_interpol(:,:,i));
                xy_interpol_L(:,:,i) = Datapixx('ConvertCoordSysToCustom', left_eye_interpol(:,:,i));
                x_interpol(i,:) = xy_interpol(:,1,i);
                y_interpol(i,:) = xy_interpol(:,2,i);
                x_interpol_L(i,:) = xy_interpol_L(:,1,i);
                y_interpol_L(i,:) = xy_interpol_L(:,2,i);
            end
            
            % Fill proper display vector from my 12x10 matrix (make 2x120)
            interpolated_dots = zeros(2,n_points*12);
            interpolated_dots_L = zeros(2,n_points*12);
            for i=1:12
                interpolated_dots(1,(i-1)*n_points+1:(i-1)*n_points+n_points) = x_interpol(i,:);
                interpolated_dots(2,(i-1)*n_points+1:(i-1)*n_points+n_points) = y_interpol(i,:);
                interpolated_dots_L(1,(i-1)*n_points+1:(i-1)*n_points+n_points) = x_interpol_L(i,:);
                interpolated_dots_L(2,(i-1)*n_points+1:(i-1)*n_points+n_points) = y_interpol_L(i,:);
            end
            
            % Done.
            show_results = 1;
            while (1) % loop across presentation of results
                switch show_results
                    case 1
                        %% Calibration results 1 of 3
                        DrawFillRect(windowPtr, scrBG); % make screen background
                        DrawFormattedText(windowPtr, '\n Calibration results 1 of 3. \n Showing raw data results. If one dot seems off, calibration might be bad.\n Press V to validate, Y to follow gaze, N to restart.', 'center',...
                            100, 255);
                        % draw position to screen
                        Screen('DrawDots', windowPtr, [raw_vector_sc(:,1)'; raw_vector_sc(:,2)'], [10]', [255 0 0]', [], 1);
                        Screen('DrawDots', windowPtr, [raw_vector_sc(:,3)'; raw_vector_sc(:,4)'], [10]', [0 0 255]', [], 1);
                        Screen('Flip', windowPtr);
                        if demo_mode
                            % To save pictures
                            imageArray = Screen('GetImage', windowPtr);
                            imwrite(imageArray, 'ScaledRawData.jpg');
                        end
                        WaitSecs(1);
                        
                    case 2
                        %% Calibration results 2 of 3: right eye
                        DrawFillRect(windowPtr, scrBG); % make screen background
                        DrawFormattedText(windowPtr, '\n Calibration results 2 of 3. \n Showing calibration dots and screen from polynomial for left eye (right eye on screen). \n If the dots are off or the lines are not well connected, calibration for this eye might be off. \n Press V to validate, Y to follow gaze, N to restart.', 'center', 100, 255);
                        Screen('DrawDots', windowPtr, [xy(1,:)' xy(2,:)']', [30]', [255 255 255]', [], 1);
                        Screen('DrawDots', windowPtr, [x_eval' y_eval']', [20]', [255 0 255]', [], 1);
                        Screen('DrawDots', windowPtr, interpolated_dots, [8]', [255 0 0]', [], 1);
                        Screen('Flip', windowPtr);
                        WaitSecs(1);
                        if demo_mode
                            imageArray = Screen('GetImage', windowPtr);
                            imwrite(imageArray, 'PolyResponse_R.jpg')% For debug
                        end
                        
                    case 3
                        %% Calibration results 3 of 3: left eye
                        DrawFillRect(windowPtr, scrBG); % make screen background
                        DrawFormattedText(windowPtr, '\n Calibration results 3 of 3. \n Showing calibration dots and screen from polynomial for right eye (left eye on screen). \n If the dots are off or the lines are not well connected, calibration for this eye might be off. \n Press V to validate, Y to follow gaze, N to restart.', 'center', 100, 255);
                        Screen('DrawDots', windowPtr, [xy(1,:)' xy(2,:)']', [30]', [255 255 255]', [], 1);
                        Screen('DrawDots', windowPtr, [x_eval_L' y_eval_L']', [20]', [0 255 255]', [], 1);
                        Screen('DrawDots', windowPtr, interpolated_dots_L, [8]', [0 0 255]', [], 1);
                        Screen('Flip', windowPtr);
                        WaitSecs(1);
                        if demo_mode
                            imageArray = Screen('GetImage', windowPtr);
                            imwrite(imageArray, 'PolyResponse_L.jpg')% For debug
                        end
                        
                    case 4
                        show_results = 0;
                end % of switch
                
                % wait for response
                [~, keyCode, ~] = KbWait;
                if keyCode(KbName('Y')) % good calib: accept and go to gaze follower
                    finish_calibration = 1;
                    validation_requested = 0;
                    break;
                elseif keyCode(KbName('V')) % good calib: look at validation
                    finish_calibration = 1;
                    validation_requested = 1;
                    break
                elseif keyCode(KbName('N')) % bad calib: start again!   
                    % reset values
                    i = 0;
                    t = 0;
                    showing_dot = 0;
                    Sx = 0;
                    Sy = 0;
                    raw_vector = zeros(nmb_pts,4);
                    raw_vector_sc = zeros(nmb_pts,4);
                    finish_calibration = 0;
                    t2 = t;
                    % clear last calibration if we have decided to run a calibration
                    Datapixx('ClearCalibration');
                    Datapixx('RegWrRd');
                    % select eye again
                    KbReleaseWait;
                    WaitSecs(0.5);
                    [left_rec, left_rec_pixel_coordinates, right_rec, right_rec_pixel_coordinates, escape_this_calib] = ...
                        select_eyes(windowPtr, windowRect, scrBG);
                    if escape_this_calib % we pressed Escape during eye selection
                        finish_calibration = 1;
                    else
                        % display the center dot once more for 1 second
                        DrawFillRect(windowPtr, scrBG); % make screen background
                        Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                            [33;18]', [255 255 255; 200 0 0]', [], 1);
                        Screen('Flip', windowPtr);
                        if i == 0 % the very first dot should be presented a little longer
                            WaitSecs(1);
                        end
                    end
                    % return to main calibration loop
                    break;
                else
                    show_results = show_results + 1;
                end
            end % of loop across presentation of results
            
        end % of evaluation of calibration: if (i == nmb_pnts)
        
        
        % escape from calibration during calibration
        [pressed, ~, keycode] = KbCheck;
        if pressed
            if keycode(KbName('escape')) 
                validation_requested = 1; %%% TO DO: change to NaN!
                if demo_mode
                    Datapixx('Uninitialize');
                    Screen('CloseAll')
                    Datapixx('Close');
                    return;
                end
                break;
            end
        end
        
        % successful calibration, continue with next step
        if (finish_calibration == 1)
%             DrawFormattedText(windowPtr, 'Calculating Calibration results', 'center', 700, 255);
%             Screen('Flip', windowPtr);
            Datapixx('FinishCalibration');
            Datapixx('SaveCalibration'); % save this calibration!
            % output from calibration:
            TPx_calib_output.calib_dots = xy;
            TPx_calib_output.searchLimits_left_rec = left_rec;
            TPx_calib_output.searchLimits_left_rec_pixel_coordinates = left_rec_pixel_coordinates;
            TPx_calib_output.searchLimits_right_rec = right_rec;
            TPx_calib_output.searchLimits_right_rec_pixel_coordinates = right_rec_pixel_coordinates;
            TPx_calib_output.raw_vector = raw_vector;
            TPx_calib_output.raw_vector_sc = raw_vector_sc;
            TPx_calib_output.calibrations_coeff = calibrations_coeff;
            TPx_calib_output.xy_eval = xy_eval;
            TPx_calib_output.xy_eval_L = xy_eval_L;
            TPx_calib_output.xy_interpol = xy_interpol;
            TPx_calib_output.xy_interpol_L = xy_interpol_L;
            break;
        end
    end % of calibration
    KbReleaseWait;
    WaitSecs(0.2);
    
    
    
    
    %% Step 4.1 -- Gaze follower. A small demo that verifies calibration
    % by following your gaze.
    if ~isnan(validation_requested) && validation_requested == 0 % no validation requested
        DrawFillRect(windowPtr, scrBG); % make screen background
        DrawFormattedText(windowPtr, '\n Gaze Follower. \n ', 'center', windowRect(4)/2);
        Screen('Flip', windowPtr);
        WaitSecs(0.3);
        
        if demo_mode % error data will be saved only in demo mode
            fileID = fopen('error_measure.csv', 'a');
            fileID2 = fopen('raw_compare.csv', 'a');
            fprintf(fileID, 'mouse X,mouse Y,right eye x,right eye y,left eye x,left eye y,error rigth x,error right y,error left x,error left y\n');
        end
        visible = 1;
        mfilter = 0;
        xAvgRight = [];
        yAvgRight = [];
        xAvgLeft = [];
        yAvgLeft = [];
        xErrRight = [];
        
        yErrRight = [];
        xErrLeft = [];
        yErrLeft = [];
        while (1) % gaze follower starts
            % draw the fixation reference dots
            DrawFillRect(windowPtr, scrBG); % make screen background
            DrawFormattedText(windowPtr, ['Following your gaze now!\nBlue = Physical Right Eye\nRed = Physical Left Eye\n',... 
                '\nPress Y to accept this calibration, press N to start again.'],...
                'center', 700, 255);
            Screen('DrawDots', windowPtr, [xy(1,:)' xy(2,:)']', [20]', [255 255 255]', [], 1); % the calibration dots
            % Get Eye position
            [rightEyeTopLeft, leftEyeTopLeft] = getEyePosition_Screen;
            xScreenRight = rightEyeTopLeft(1);
            yScreenRight = rightEyeTopLeft(2);
            xScreenLeft = leftEyeTopLeft(1);
            yScreenLeft = leftEyeTopLeft(2);
            % in case we'd like to use a 10-sample running average, use this:
            if (size(xAvgRight,1) < 10)
                xAvgRight = [xScreenRight;xAvgRight];
                yAvgRight = [yScreenRight;yAvgRight];
                xAvgLeft = [xScreenLeft;xAvgLeft];
                yAvgLeft = [yScreenLeft;yAvgLeft];
            else
                xAvgRight = circshift(xAvgRight,1);
                xAvgRight(1) = xScreenRight;
                yAvgRight = circshift(yAvgRight,1);
                yAvgRight(1) = yScreenRight;
                xAvgLeft = circshift(xAvgLeft,1);
                xAvgLeft(1) = xScreenLeft;
                yAvgLeft = circshift(yAvgLeft,1);
                yAvgLeft(1) = yScreenLeft;
            end
            % present the current position: either the raw most recent sample or a
            % mean of the last 10 samples
            if visible
                if mfilter
                    Screen('DrawDots', windowPtr, [mean(xAvgRight); mean(yAvgRight)], [15]', [255 0 0]', [], 1);
                    Screen('DrawDots', windowPtr, [mean(xAvgLeft); mean(yAvgLeft)], [15]', [0 0 255]', [], 1);
                else
                    Screen('DrawDots', windowPtr, [xScreenRight; yScreenRight], [15]', [255 0 0]', [], 1);
                    Screen('DrawDots', windowPtr, [xScreenLeft; yScreenLeft], [15]', [0 0 255]', [], 1);
                end
            end
            
            %% we can use the mouse in the demo mode to display errors etc
            if demo_mode
                ShowCursor;
                [X, Y, buttons] = GetMouse(windowPtr);
                if buttons(1)
                    if reset_error
                        xErrRight = [];
                        yErrRight = [];
                        xErrLeft = [];
                        yErrLeft = [];
                        reset_error = 0;
                    end
                    fprintf(fileID, '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',...
                        X, Y, xScreenRight, yScreenRight, xScreenLeft, yScreenLeft,...
                        (X - xScreenRight), (Y - yScreenRight), (X - xScreenLeft), (Y - yScreenLeft));
                    fprintf(fileID2, '%f,%f,%f,%f,%f,%f,\n', X, Y, xRawRight, yRawRight, xRawLeft, yRawLeft);
                    if (size(xErrRight,1) < 20)
                        xErrRight = [X - xScreenRight;xErrRight];
                        yErrRight = [Y - yScreenRight;yErrRight];
                        xErrLeft = [X - xScreenLeft;xErrLeft];
                        yErrLeft = [Y - yScreenLeft;yErrLeft];
                    else
                        xErrRight = circshift(xErrRight,1);
                        xErrRight(1) = X - xScreenRight;
                        yErrRight = circshift(yErrRight,1);
                        yErrRight(1) = Y - yScreenRight;
                        xErrLeft = circshift(xErrLeft,1);
                        xErrLeft(1) = X - xScreenLeft;
                        yErrLeft = circshift(yErrLeft,1);
                        yErrLeft(1) = Y - yScreenLeft;
                    end
                    Screen('TextSize', windowPtr, 16);
                    Screen('Preference', 'TextAlphaBlending', 1);
                    Screen('TextBackgroundColor', windowPtr, [250 248 200]);
                    DrawFormattedText(windowPtr, sprintf('    %f  |  %f\n    %f  |  %f', mean(xErrRight),mean(yErrRight),mean(xErrLeft),mean(yErrLeft)), 'right', [], 10);
                    Screen('Preference', 'TextAlphaBlending', 0);
                elseif buttons(3)
                    Screen('TextSize', windowPtr, 16);
                    Screen('Preference', 'TextAlphaBlending', 1);
                    Screen('DrawText', windowPtr, sprintf('    %d  |  %d', X,Y), X, Y, 10, [250 248 200]);
                    Screen('Preference', 'TextAlphaBlending', 0);
                else
                    reset_error = 1;
                end
                
                % WHAT's this part?
                Screen('TextSize', windowPtr, 14);
                Screen('Preference', 'TextAlphaBlending', 1);
                Screen('TextBackgroundColor', windowPtr, [250 248 200]);
                if (size(xErrRight,1) > 10)
                    newX = 10;
                    newY = 920;
                    for i=1:10
                        [newX,newY] = DrawFormattedText(windowPtr, sprintf('  %7.2f  |  %7.2f  |  %7.2f  |  %7.2f\n', xErrRight(i), yErrRight(i), xErrLeft(i), yErrLeft(i)), newX, newY, 5);
                    end
                end
                Screen('TextBackgroundColor', windowPtr, [0 0 0 0]);
                Screen('Preference', 'TextAlphaBlending', 0);
                Screen('TextSize', windowPtr, 24);
            end
            
            % here the flip occurs
            Screen('Flip', windowPtr);
            [pressed, ~, keycode] = KbCheck;
            if pressed
                if keycode(KbName('Y')) || keycode(KbName('N')) || ...
                    keycode(KbName('escape')) 
                    % write out validation results
                    TPx_calib_output.screen_vector = [];
                    TPx_calib_output.error_vector = [];
                    TPx_calib_output.error_vector_dva = [];
                    % happy with validation?
                    if keycode(KbName('Y'))
                        TPx_calib_output.happy_val = 1;
                    elseif keycode(KbName('N'))
                        TPx_calib_output.happy_val = 0;
                    else
                        TPx_calib_output.happy_val = NaN;
                    end
                    if demo_mode
                        Datapixx('Uninitialize');
                        Screen('CloseAll');
                        Datapixx('Close');
                        
                        fclose(fileID);
                        fclose(fileID2);
                    end
                    break;
                end
                
                if keycode(KbName('h'))
                    visible = 0;
                end
                if keycode(KbName('u'))
                    visible = 1;
                end
                if keycode(KbName('f'))
                    mfilter = 1;
                end
                if keycode(KbName('d'))
                    mfilter = 0;
                end
            end
            
        end % of while of gaze follower
        
    elseif ~isnan(validation_requested) && validation_requested == 1
        %% Step 4.2 -- Validation that also returns error values
        % same procedure as during calibration follows...
        DrawFillRect(windowPtr, scrBG); % make screen background
        DrawFormattedText(windowPtr, '\n Validation. \n ', 'center', windowRect(4)/2);
        Screen('Flip', windowPtr);
        WaitSecs(0.3);
        
        % reset values
        horizontal_space_for_text = 20;
        i = 0;
        t = 0;
        showing_dot = 0;
        screen_vector = zeros(nmb_pts,4);
        screen_vector_sd = zeros(nmb_pts,4);
        error_vector = zeros(nmb_pts,4);
        error_vector_dva = zeros(nmb_pts,4);
        finish_validation = 0;
        t2 = t;
        
        % before the calibration loop starts, we want to present the central dot
        % for one second for the eyes to settle there
        Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
            [33;18]', [255 255 255; 200 0 0]', [], 1);
        Screen('Flip', windowPtr);
        if i == 0 % the very first dot should be presented a little longer
            WaitSecs(1);
        end
        
        while ~finish_validation
            if (i < nmb_pts) && (t2 - t) > duration_points % points presented every X sec
                validation_dot_pos = [xy(:,mod(i,nmb_pts)+1), xy(:,mod(i,nmb_pts)+1)];
                disp(validation_dot_pos)
                DrawFillRect(windowPtr, scrBG); % make screen background
                Screen('DrawDots', windowPtr, validation_dot_pos,...
                    [35;20]', [255 255 255; 200 0 0]', [], 1);
                Screen('Flip', windowPtr);
                showing_dot = 1;
                t = t2;
                % pre-allocate gaze position vectors
                ValidationRightData = NaN(single_point_collect_time*2000,2);
                ValidationLeftData = NaN(single_point_collect_time*2000,2);
                ValidationSample_i = 0;
            else
                Datapixx('RegWrRd');
                t2 = Datapixx('GetTime');
            end
            
            % this is this fancy and inefficient shrinking dot type of calibration
            if (i < nmb_pts) && showing_dot
                shrinking_dot(windowPtr, scrBG, duration_shrinking, xy, nmb_pts, i, t, t2);
            end
            
            % once the dot has its small form, we collect data
            if (i < nmb_pts) && showing_dot && (t2 - t) > 0.95*duration_shrinking 
                % Get some samples!
                if (calib_type == 1) % If in manual mode wait for a keypress
                    KbWait;
                end
                i = i + 1; % Next point
                fprintf('\ni: %d\n', i);
                % for a certain amount of time, take all the samples we can
                % get and save them in the vectors previously pre-allocated
                while (t2 - t) < duration_points 
                    % get new time
                    Datapixx('RegWrRd');
                    t2 = Datapixx('GetTime');
                    % Get Eye position
                    [rightEyeTopLeft, leftEyeTopLeft] = getEyePosition_Screen;
                    ValidationSample_i = ValidationSample_i + 1;
                    ValidationRightData(ValidationSample_i,:) = rightEyeTopLeft;
                    ValidationLeftData(ValidationSample_i,:) = leftEyeTopLeft;
                end    
                % compute mean gaze position and error
                screen_vector(i,:) = [mean(ValidationRightData, 'omitnan'), ...
                    mean(ValidationLeftData, 'omitnan')];
                screen_vector_sd(i,:) = [std(ValidationRightData, 'omitnan'), ...
                    std(ValidationLeftData, 'omitnan')];
                error_vector(i,:) = [validation_dot_pos(:,1)', validation_dot_pos(:,1)'] - ...
                    screen_vector(i,:);
                error_vector_dva(i,:) = error_vector(i,:) ./ scr_ppd;
                screen_vector
                screen_vector_sd
                error_vector
                showing_dot = 0;
            end
            
            % once we have data for all points, the data are fitted
            if (i == nmb_pts) %% We showed all the points, now we evaluate.
%                 while (1)
                    % Plot the results of the calibrations...
                    WaitSecs(0.2);
                    DrawFillRect(windowPtr, scrBG); % make screen background
                    % draw validation dots
                    Screen('DrawDots', windowPtr, [xy(1,:)' xy(2,:)']', [30]', [255 255 255]', [], 1);
                    % draw measured means
                    Screen('DrawDots', windowPtr, screen_vector(:,1:2)', [15]', [255 0 0]', [], 1);
                    Screen('DrawDots', windowPtr, screen_vector(:,3:4)', [15]', [0 0 255]', [], 1);
                    % draw measured SDs
                    Screen('FrameOval', windowPtr, [255 0 0]', ...
                        [screen_vector(:,1:2)'-screen_vector_sd(:,1:2)'; screen_vector(:,1:2)'+screen_vector_sd(:,1:2)'], ...
                        1);
                    Screen('FrameOval', windowPtr, [0 0 255]', ...
                        [screen_vector(:,3:4)'-screen_vector_sd(:,3:4)'; screen_vector(:,3:4)'+screen_vector_sd(:,3:4)'], ...
                        1);
                    % draw measured errors in this dirty loop
                    distRight = sqrt(error_vector_dva(:,1).^2 + error_vector_dva(:,2).^2);
                    distLeft = sqrt(error_vector_dva(:,3).^2 + error_vector_dva(:,4).^2);
                    assert(length(distRight)==length(distLeft));
                    for w = 1:length(distRight)
                        DrawFormattedText(windowPtr, [num2str(round(distRight(w),1)), '\n', ...
                            num2str(round(distLeft(w),1))], ...
                            xy(1,w)+horizontal_space_for_text, xy(2,w));
                    end
                    % mean error
                    DrawFormattedText(windowPtr, ['\n Validation results. \n Mean error left: ',...
                        num2str(round(mean(distRight, 'omitnan'),1)),...
                        ', right: ', num2str(round(mean(distLeft, 'omitnan'),1)),...
                        '\n Press Y to accept this calibration, press N to start again.'],...
                        'center', 100, 255);
                    Screen('Flip', windowPtr);
%                 end
            end
            
            % check keyboard after each flip
            [pressed, ~, keycode] = KbCheck;
            if pressed
                if keycode(KbName('Y')) || keycode(KbName('N'))  || ...
                        keycode(KbName('escape'))
                    finish_validation = 1;
                    % write out validation results
                    TPx_calib_output.screen_vector = screen_vector;
                    TPx_calib_output.screen_vector_sd = screen_vector_sd;
                    TPx_calib_output.error_vector = error_vector;
                    TPx_calib_output.error_vector_dva = error_vector_dva;
                    % happy with validation?
                    if keycode(KbName('Y'))
                        TPx_calib_output.happy_val = 1;
                    elseif keycode(KbName('N'))
                        TPx_calib_output.happy_val = 0;
                    else
                        TPx_calib_output.happy_val = NaN;
                    end
                    if demo_mode
                        Datapixx('Uninitialize');
                        Screen('CloseAll');
                        Datapixx('Close');
                    end
%                     break;
                end
            end
            
        end % of validation loop
        
    end % of question whether gaze-follower of validation
    
end % of not pressed escape
KbReleaseWait;
DrawFillRect(windowPtr, scrBG); % make screen background
Screen('Flip', windowPtr);
WaitSecs(0.2);
    
end % of the whole calibration function




%% getEyePosition
function [rightEyeTopLeft, leftEyeTopLeft, run_time] = getEyePosition_Screen(is_remote)
t1 = GetSecs;
if nargin == 0
    is_remote = 0;
end
% Get Eye position
[xScreenRightCartesian, yScreenRightCartesian, xScreenLeftCartesian, yScreenLeftCartesian] = ...
    Datapixx('GetEyePosition', is_remote);
% convert eye position
rightEyeCartesian = [xScreenRightCartesian, yScreenRightCartesian];
leftEyeCartesian = [xScreenLeftCartesian, yScreenLeftCartesian];
rightEyeTopLeft = Datapixx('ConvertCoordSysToCustom', rightEyeCartesian);
leftEyeTopLeft = Datapixx('ConvertCoordSysToCustom', leftEyeCartesian);
run_time = (GetSecs - t1)*1000;
end

%% make Fill Rect 
function DrawFillRect(windowPtr, scrBG)
Screen('FillRect',windowPtr, [scrBG, scrBG, scrBG, 0]); % clear screen
end

%% shrinking dot function
function shrinking_dot(windowPtr, scrBG, duration_shrinking, xy, nmb_pts, i, t, t2)
DrawFillRect(windowPtr, scrBG); % make screen background
% cool shrinking animation
if((t2 - t) > 0.9*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [15;5]', [255 255 255; 200 0 0]', [], 1);
elseif((t2 - t) > 0.8*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [17;6]', [255 255 255; 0 0 0]', [], 1);
elseif((t2 - t) > 0.7*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [20;8]', [255 255 255; 200 0 0]', [], 1);
elseif((t2 - t) > 0.6*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [22;10]', [255 255 255; 0 0 0]', [], 1);
elseif((t2 - t) > 0.5*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [25;12]', [255 255 255; 200 0 0]', [], 1);
elseif((t2 - t) > 0.4*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [27;14]', [255 255 255; 0 0 0]', [], 1);
elseif((t2 - t) > 0.3*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [30;16]', [255 255 255; 200 0 0]', [], 1);
elseif((t2 - t) > 0.2*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [31;17]', [255 255 255; 0 0 0]', [], 1);
elseif((t2 - t) > 0.1*duration_shrinking)
    Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
        [33;18]', [255 255 255; 200 0 0]', [], 1);
end
Screen('Flip', windowPtr);
end


%% function to evaluate polynomials
function [x,y] = evaluate_bestpoly(xi,yi,cx,cy)
% Helper function for TPxCalibration
% 1 = Cst
% 2 = x
% 3 = y
% 4 = x^2
% 5 = y^2
% 6 = x^3 || xy^2
% 7 = xy
% 8 = x^2y
% 9 = x^2y^2
x = cx(1)+...
    cx(2).*xi+...
    cx(3).*yi+...
    cx(4).*xi.*xi+...
    cx(5).*yi.*yi+...
    cx(6).*xi.*xi.*xi+...
    cx(7).*xi.*yi+...
    cx(8).*xi.*xi.*yi+...
    cx(9).*xi.*xi.*yi.*yi;
y = cy(1)+...
    cy(2).*xi+...
    cy(3).*yi+...
    cy(4).*xi.*xi+...
    cy(5).*yi.*yi+...
    cy(6).*xi.*yi.*yi+...
    cy(7).*xi.*yi+...
    cy(8).*xi.*xi.*yi+...
    cy(9).*xi.*xi.*yi.*yi;
end


%% auxiliary function: select eyes
function [left_rec, left_rec_pixel_coordinates, right_rec, right_rec_pixel_coordinates, escape_selection, calib_type] = ...
    select_eyes(windowPtr, windowRect, scrBG)

ShowCursor;
% where should the camera image be shown?
cam_rect = [windowRect(3)/2-1280/2 0 windowRect(3)/2+1280/2 1024];
calib_type = 0;

% initialize structures that show where the eyes are
left_rec = [0 0 0 0];
left_rec_pixel_coordinates = [0 0 0 0];
right_rec = [0 0 0 0];
right_rec_pixel_coordinates = [0 0 0 0];
region_width = 100;
Datapixx('RegWrRd');
t = Datapixx('GetTime');
Datapixx('RegWrRd');
t2 = Datapixx('GetTime');
disp(['RegWrRd took ', num2str(round((t2-t)*1000, 2)), ' ms']);

Screen('TextSize', windowPtr, 24);
while (1) % This is the eye selection loop
    if ((t2 - t) > 1/60) % Just refresh at 60Hz.
        DrawFillRect(windowPtr, scrBG); % make screen background
        Datapixx('RegWrRd');
        image = Datapixx('GetEyeImage');
        textureIndex=Screen('MakeTexture', windowPtr, image'); % fliplr(image')
        Screen('DrawTexture', windowPtr, textureIndex, [], cam_rect);
        
        % present selections
        if left_rec(1) ~= 0
            Screen('FrameRect', windowPtr, [0 0 255], left_rec);
        end
        if right_rec(1) ~= 0
            Screen('FrameRect', windowPtr, [255 0 0], right_rec);
        end
        % present instructions and then options
        if left_rec(1) ~= 0
            if right_rec(1) ~= 0
                text_to_draw = ' Press Enter when ready to calibrate (M for manual). Escape to exit';
            else
                text_to_draw =  ' Right click (red) on the right eye on the screen (physical left eye).\nC or middle mouse to clear\nA or D to decrease or increase search limits size.\nEscape to exit.';
            end
        else
            text_to_draw = ' Left click (blue) on the left eye on the screen (physical right eye).\nC or middle mouse to clear\nA or D to decrease or increase search limits size.\nEscape to exit.';
        end
        % draw Focus the eyes in any case
        DrawFormattedText(windowPtr, strcat('Instructions:\n\n 1- Focus the eyes.\n\n 2- ',text_to_draw), 'center', 700, 255);
        Screen('Flip', windowPtr);
        t = t2;
        Screen('Close',textureIndex);
    else
        Datapixx('RegWrRd');
        t2 = Datapixx('GetTime');
    end
    
    % Keypress goes to next step of demo
    [pressed_here, ~, keycode_here] = KbCheck;
    if pressed_here
        if keycode_here(KbName('escape'))
            escape_selection = 1;
            return;
        else
            escape_selection = 0;
            if keycode_here(KbName('M'))
                calib_type = 1;
            end
            if keycode_here(KbName('C')) || keycode_here(KbName('A')) || keycode_here(KbName('D'))
                if keycode_here(KbName('A')) && region_width > 20
                    region_width = region_width - 1;
                elseif keycode_here(KbName('D')) && region_width < cam_rect(4)/2
                    region_width = region_width + 1;
                end
                right_rec = [0 0 0 0];
                left_rec = [0 0 0 0];
                Datapixx('ClearSearchLimits');
                Datapixx('RegWrRd');
                continue;
            end
            break;
        end
    end
    % Here we get the mouse position and register the clicks
    [X, Y, buttons] = GetMouse(windowPtr);
    if buttons(1) % left button, left eye
        % Check that the click was inside the Camera image
        if (X > cam_rect(1) + region_width) && (X < cam_rect(3) - region_width)
            if (Y > cam_rect(2) + region_width) && (Y < cam_rect(4)/2 - region_width)
                left_rec = [X-region_width Y-region_width X+region_width Y+region_width];
                % Now we need to convert the value [0 1920] to [0 1280]
                left_rec_pixel_coordinates = [left_rec(1)-cam_rect(1) left_rec(2) left_rec(3)-cam_rect(1) left_rec(4)];
                Datapixx('SetSearchLimits', left_rec_pixel_coordinates, right_rec_pixel_coordinates);
                Datapixx('RegWrRd');
            end
        end
    end
    if buttons(2)
        right_rec = [0 0 0 0];
        left_rec = [0 0 0 0];
        Datapixx('ClearSearchLimits');
        Datapixx('RegWrRd');
    end
    if buttons(3) % right button, right eye
        % Check that the click was inside the Camera image
        if (X > cam_rect(1) + region_width) && (X < cam_rect(3) - region_width)
            if (Y > cam_rect(2) + region_width) && (Y < cam_rect(4)/2 - region_width)
                right_rec = [X-region_width Y-region_width X+region_width Y+region_width];
                right_rec_pixel_coordinates = [right_rec(1)-cam_rect(1) right_rec(2) right_rec(3)-cam_rect(1) right_rec(4)];
                Datapixx('SetSearchLimits', left_rec_pixel_coordinates, right_rec_pixel_coordinates);
                Datapixx('RegWrRd');
            end
        end
    end
end % of the eye selection loop
HideCursor; 
KbReleaseWait;

end
