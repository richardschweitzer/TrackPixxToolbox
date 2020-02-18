function TPx_calib_output = TPxCalibrationRichardsFunction(windowPtr, scrBG, ...
    n_calibration_points, led_intensity, iris_size, ...
    eccentricity_points_x, eccentricity_points_y, ...
    duration_points, duration_shrinking)
% TPxCalibrationTesting()
%
% This demo calibrates the current session for the TRACKPixx tracker and
% shows you the results of the calibration. Once the calibration is
% finished, a gaze follower is started to know the results of the
% calibrations. If you wish to reuse the same calibrations, they are
% availible in Matlab as long as you do not call a "clear all; close all;"
%
% Steps are as follow:
% 1- Initialize the TRACKPixx. You need to set the LED itensity and the
% Iris size in pixel. Usual values are 70 for 25mm lens, 140 for 50mm lens
% and 150 for MRI.
% 2- Open the Psychtoolbox Window and show the Eye Picture for focusing of
% the TRACKPixx. To go to the next step, press any key. Escape will exit.
% M will trigger manual calibration (key press between fixations)
% 3- Show the calibration dots and the calibration results.
% 4- Gaze following demo to show that the calibration worked fine.
%
% Once this demo is done, if you call the data recording schedule, the eye
% data will be calibrated.
%
%
% History:
%
% Nov 1, 2017  dml     Written
% Oct, 2018  richard schweitzer, cleaned up and optimized for lab usage
% 
%WaitSecs(10);

switch nargin % there are currently 9 arguments
    case 0
        windowPtr = []; % pointer to the screen to be used, if empty, then screen is created
        scrBG = 255/2; % screen background color
        n_calibration_points = 9;
        led_intensity = 8; % value from 1 to 8, default 8
        iris_size = 140;
        eccentricity_points_x = 600; 
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 1
        scrBG = 255/2;
        n_calibration_points = 9;
        led_intensity = 8; 
        iris_size = 140;
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 2
        n_calibration_points = 9;
        led_intensity = 8; 
        iris_size = 140;
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 3
        led_intensity = 8;
        iris_size = 140;
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 4
        iris_size = 140;
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 5
        eccentricity_points_x = 600;
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 6
        eccentricity_points_y = 350;
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 7
        duration_points = 1.5;
        duration_shrinking = 0.5;
    case 8
        duration_shrinking = 0.5;
end


%% Step 1.1, Initialize TRACKPixx 

if isempty(windowPtr)
    Datapixx('Initialize', 0);
    Datapixx('Open');
    Datapixx('HideOverlay');
    Datapixx('RegWrRd');
    Datapixx('SetTPxAwake');
    Datapixx('RegWrRd');
    Datapixx('SetLedIntensity', led_intensity);
    Datapixx('SetExpectedIrisSizeInPixels', iris_size)
    Datapixx('RegWrRd');
end
image = zeros(512*2,1280,1);
image(1:512,:,1) = linspace(30,200,512)'*ones(1,1280);
image = image';


%% Step 1.2, open the Window
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
[left_rec, left_rec_pixel_coordinates, right_rec, right_rec_pixel_coordinates, escape_this_calib] = ...
    select_eyes(windowPtr, windowRect);
WaitSecs(0.2);

if escape_this_calib == 0 % only if we didn't press escape
    
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
    calib_type = 0;
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
        if(showing_dot && (t2 - t) > 0.9*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [15;5]', [255 255 255; 200 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.8*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [17;6]', [255 255 255; 0 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.7*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [20;8]', [255 255 255; 200 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.6*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [22;10]', [255 255 255; 0 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.5*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [25;12]', [255 255 255; 200 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.4*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [27;14]', [255 255 255; 0 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.3*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [30;16]', [255 255 255; 200 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.2*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [31;17]', [255 255 255; 0 0 0]', [], 1);
            Screen('Flip', windowPtr);
        elseif(showing_dot && (t2 - t) > 0.1*duration_shrinking)
            Screen('DrawDots', windowPtr, [xy(:,mod(i,nmb_pts)+1) xy(:,mod(i,nmb_pts)+1)],...
                [33;18]', [255 255 255; 200 0 0]', [], 1);
            Screen('Flip', windowPtr);
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
            % remap data to proper range. To do: How to explain the formula?
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
                        DrawFormattedText(windowPtr, '\n Calibration results 1 of 3. \n Showing raw data results. If one dot seems off, calibration might be bad.\n Press any key to continue. Y to acccept, N to restart.', 'center',...
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
                        DrawFormattedText(windowPtr, '\n Calibration results 2 of 3. \n Showing calibration dots and screen from polynomial for left eye (right eye on screen). \n If the dots are off or the lines are not well connected, calibration for this eye might be off. \n Press any key to continue. Y to acccept, N to restart.', 'center', 100, 255);
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
                        DrawFormattedText(windowPtr, '\n Calibration results 3 of 3. \n Showing calibration dots and screen from polynomial for right eye (left eye on screen). \n If the dots are off or the lines are not well connected, calibration for this eye might be off. \n Press any key to continue. Y to acccept, N to restart.', 'center', 100, 255);
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
                if keyCode(KbName('Y')) % good calib
                    finish_calibration = 1;
                    break;
                elseif keyCode(KbName('N')) % bad calib: start again!   
                    % reset values
                    i = 0;
                    calib_type = 0;
                    t = 0;
                    showing_dot = 0;
                    Sx = 0;
                    Sy = 0;
                    raw_vector = zeros(nmb_pts,4);
                    raw_vector_sc = zeros(nmb_pts,4);
                    finish_calibration = 0;
                    t2 = t;
                    % select eye again
                    KbReleaseWait;
                    WaitSecs(0.5);
                    [left_rec, left_rec_pixel_coordinates, right_rec, right_rec_pixel_coordinates, escape_this_calib] = ...
                        select_eyes(windowPtr, windowRect);
                    if escape_this_calib % we pressed Escape during eye selection
                        finish_calibration = 1;
                    else
                        % display the center dot once more for 1 second
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
            DrawFormattedText(windowPtr, 'Calculating Calibration results', 'center', 700, 255);
            Datapixx('FinishCalibration');
            Datapixx('SaveCalibration'); % save this calibration?
            Screen('Flip', windowPtr);
            break;
        end
    end % of calibration
    
    
    %% Step 4 -- Gaze follower. A small demo that verifies calibration
    % by following your gaze.
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
    retrieval_times = NaN(1,1000000);
    sample_i = 0;
    while (1)
        % draw the fixation reference dots
        DrawFormattedText(windowPtr, 'Following your gaze now!\nBlue = Physical Right Eye\nRed = Physical Left Eye', 'center', 700, 255);
        Screen('DrawDots', windowPtr, [xy(1,:)' xy(2,:)']', [20]', [255 255 255]', [], 1); % the calibration dots
        % Get Eye position
        %     Datapixx('RegWrRd');
        t_ret_start = GetSecs;
        [xScreenRightCartesian, yScreenRightCartesian, xScreenLeftCartesian, yScreenLeftCartesian,...
            xRawRight, yRawRight, xRawLeft, yRawLeft] = ...
            Datapixx('GetEyePosition', 0);
        t_ret_end = GetSecs;
        sample_i = sample_i + 1;
        retrieval_times(sample_i) = (t_ret_end - t_ret_start)*1000;
        
        rightEyeCartesian = [xScreenRightCartesian yScreenRightCartesian];
        leftEyeCartesian = [xScreenLeftCartesian yScreenLeftCartesian];
        rightEyeTopLeft = Datapixx('ConvertCoordSysToCustom', rightEyeCartesian);
        leftEyeTopLeft = Datapixx('ConvertCoordSysToCustom', leftEyeCartesian);
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
        [pressed dum keycode] = KbCheck;
        if pressed
            if keycode(KbName('escape'))
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
            if keycode(KbName('s'))
                Datapixx('SaveCalibration');
            end
            
        end
        
    end
    
    % TO DO: useful output from calibration?
    TPx_calib_output = [];
    TPx_calib_output.retrieval_times = retrieval_times(~isnan(retrieval_times));
    TPx_calib_output.searchLimits_left_rec = left_rec;
    TPx_calib_output.searchLimits_left_rec_pixel_coordinates = left_rec_pixel_coordinates;
    TPx_calib_output.searchLimits_right_rec = right_rec;
    TPx_calib_output.searchLimits_right_rec_pixel_coordinates = right_rec_pixel_coordinates;
    
else % if we pressed escape during eye selection
    TPx_calib_output = [];
end

end % end of calibration function


%% auxiliary function: select eyes
function [left_rec, left_rec_pixel_coordinates, right_rec, right_rec_pixel_coordinates, escape_selection] = ...
    select_eyes(windowPtr, windowRect)

ShowCursor;
% where should the camera image be shown?
cam_rect = [windowRect(3)/2-1280/2 0 windowRect(3)/2+1280/2 1024];

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
                text_to_draw =  ' Right click (red) on the right eye on the screen (physical left eye).\nC or middle mouse to clear. Escape to exit.';
            end
        else
            text_to_draw = ' Left click (blue) on the left eye on the screen (physical right eye).\nC or middle mouse to clear. Escape to exit.';
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
    [pressed, ~, keycode] = KbCheck;
    if pressed
        if keycode(KbName('escape'))
            escape_selection = 1;
            return;
        else
            escape_selection = 0;
            if keycode(KbName('M'))
                calib_type = 1;
            end
            if keycode(KbName('C'))
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