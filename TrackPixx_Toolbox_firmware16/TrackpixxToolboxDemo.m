% Demo Script for TrackPixx usage
% by Richard Schweitzer, 10/2018

clear all
close all

%% global parameters for recording and display
average_across_n_samples = 8; % how many samples to use for GetTPxLatestSample
simple_version = 1; % 0: uses a big buffer that's passed to ReadTPxData, 1: without pre-allocation
se_version = 1; % 0: display oval of fixed radius, 1: display oval of variable width (SE-based)
% screen parameters
scr.resx = 1920;
scr.dist = 380;
scr.width = 250.2; % in cm
scr.ppd = scr.dist*tan(1*pi/180)/(scr.width/scr.resx);
scr.lum_fac = 1;
% Trackpixx-related
led_intensity = 8;
tracker_distance = 60;
tracker_lens = 1; % 1: 50 mm, see manual
iris_size_pix = 155;
record_for_time = 60; % recording time in seconds
extra_record_time = 10; % extra recording time for the buffer to make sure whatever
right_eye_cols = 22:23; % physical right eye is left eye on calibration screen (blue)
right_eye_color = [0,0,255];
left_eye_cols = 24:25; % physical left eye is right eye on calibration screen (red)
left_eye_color = [255,0,0];
% stim parameters
which_image = 'croc_gray.jpg';
dot_size = 14;
small_dot_size = dot_size/2;
oval_width = 5;
right_eye_color = round(right_eye_color*scr.lum_fac);
left_eye_color = round(left_eye_color*scr.lum_fac);

%% initialize datapixx and trackpixx
WaitSecs(1);
Datapixx('Open');
InitializeTPx(led_intensity, tracker_lens, tracker_distance);

expectedIrisSize = Datapixx('GetExpectedIrisSizeInPixels');


%% Setup Screen etc
thisScreen = max(Screen('Screens'));
scrGray = GrayIndex(thisScreen);
scrBlack = BlackIndex(thisScreen);
scrWhite = WhiteIndex(thisScreen);
% define the background color -----!
scrBgCol = scrBlack;
scrFgCol = scrWhite*scr.lum_fac;
% open window
[windowPtr, windowRect] = PsychImaging('OpenWindow', thisScreen, scrBgCol);
scrFR = round(Screen('FrameRate', windowPtr));
KbName('UnifyKeyNames');
Priority(MaxPriority(windowPtr));


%% Calibrate for the first time
% % do a pupil size calibration, new in firmware 16, I think
% doTPxPupilCalibration(windowPtr, 0, scr.lum_fac);
% calibration procedure here.
first_calib_res = doTPxCalibration(windowPtr, 0, scrBgCol, scr.ppd, scr.lum_fac);
Screen('Flip', windowPtr);
KbReleaseWait;
WaitSecs(1);


%% prepare the Trackpixx recording here
max_buffer_time = record_for_time+extra_record_time;
% pre-allocate
flip_times = NaN(2,max_buffer_time*scrFR); % do we drop frames?
loop_durations = NaN(1,max_buffer_time*scrFR); % how long do we need to run all the TPx commands?
samples_drawn_buffer = NaN(max_buffer_time, 6); % save position retrieved via ReadTPxData + GetTPxLatestSample
samples_drawn_position = NaN(max_buffer_time, 6); % save position retrieved via GetTPxEyePosition
flip_i = 0;
pos_1 = [];
buf_1 = [];
% load the picture and make the texture
im = imread(which_image);
im = round(im * scr.lum_fac);
im_texture = Screen('MakeTexture', windowPtr, im);
% start TrackPixx recording here
[rec_start_time_pc, rec_start_time, ...
    bufferData, sample_i] = StartTPxRecording(max_buffer_time); 
if simple_version
    bufferData = [];
end
% first flip here, then we record
Screen('DrawTexture', windowPtr, im_texture, [], windowRect);
Datapixx('RegWrRdVideoSync');
presentation_on_pc = Screen('Flip', windowPtr);
last_flip_time_pc = presentation_on_pc;
presentation_on = Datapixx('GetTime');
last_flip_time = presentation_on;


%% Presentation and Gaze-contingent display here
recording = 1;
while ((GetSecs-presentation_on_pc) < record_for_time) && recording
    
    work_starts = GetSecs;
    
    %% buffer-based online retrieval
    % Retrieve data buffer-based via ReadTPxData and GetTPxLatestSample
    if simple_version
        [sample_i, lastRetrieval] = ReadTPxDataSimple(sample_i);
        bufferData = [bufferData; lastRetrieval];
    else
        [sample_i, bufferData, lastRetrieval] = ReadTPxData(sample_i, bufferData);
    end
    % read out the latest sample from the buffer
    if simple_version
        [buf_1, buf_1_SE] = ...
            GetTPxLatestSampleSimple(bufferData(:,right_eye_cols), average_across_n_samples);
        [buf_2, buf_2_SE] = ...
            GetTPxLatestSampleSimple(bufferData(:,left_eye_cols), average_across_n_samples);
        t_buf_pc = lastRetrieval(end, 15);
        t_buf = lastRetrieval(end, 1);
    else
        [buf_1, buf_2, ~, ~, t_buf_pc, t_buf, buf_1_SE, buf_2_SE] = ...
            GetTPxLatestSample(sample_i, bufferData, average_across_n_samples);
    end
    % save those
    samples_drawn_buffer(flip_i+1, :) = [buf_1, buf_2, t_buf_pc, t_buf];
    
    %% getPosition-based online retrieval
    % Retrieve current eye position via GetTPxEyePosition
    [pos_1, pos_2, ~, ~, ~, ~, t_pos_pc, t_pos] = ...
        GetTPxEyePosition(0); % set to 1 to get datapixx timestamp
    % save those
    samples_drawn_position(flip_i+1, :) = [pos_1, pos_2, t_pos_pc, t_pos];
    
    %% Draw the positions on the screen and flip
    % draw texture
    Screen('DrawTexture', windowPtr, im_texture, [], windowRect);
    % draw instructions
    Screen('DrawText', windowPtr, ...
        ['Showing Gaze Positions of physical right eye [', num2str(right_eye_color), ...
        '] and physical left eye [', num2str(left_eye_color),']. Press ESC to end the demo.'],...
        100, 100, scrFgCol);
    % draw positions
    if ~isempty(buf_1) && ~isempty(pos_1)
        % draw positions: eye position as dot
        Screen('DrawDots', windowPtr, pos_1', ...
            dot_size, right_eye_color', [], 1); % eye 1
        Screen('DrawDots', windowPtr, pos_2', ...
            dot_size, left_eye_color', [], 1); % eye 2
        % draw positions: buffer as little dots
        if ~isempty(lastRetrieval)
            Screen('DrawDots', windowPtr, lastRetrieval(:,right_eye_cols)', ...
                small_dot_size, right_eye_color', [], 1);
            Screen('DrawDots', windowPtr, lastRetrieval(:,left_eye_cols)', ...
                small_dot_size, left_eye_color', [], 1);
        end
        % draw positions: circles as output from GetLatestSample
        if se_version % oval will change with SE
            Screen('FrameOval', windowPtr, right_eye_color', ...
                [buf_1(1), buf_1(2), buf_1(1), buf_1(2)]+...
                [-dot_size*(1+buf_1_SE(1)), -dot_size*(1+buf_1_SE(2)), dot_size*(1+buf_1_SE(1)), dot_size*(1+buf_1_SE(2))], ...
                oval_width);
            Screen('FrameOval', windowPtr, left_eye_color', ...
                [buf_2(1), buf_2(2), buf_2(1), buf_2(2)]+...
                [-dot_size*(1+buf_2_SE(1)), -dot_size*(1+buf_2_SE(2)), dot_size*(1+buf_2_SE(1)), dot_size*(1+buf_2_SE(2))], ...
                oval_width);
        else % oval will have a fixed width
            Screen('FrameOval', windowPtr, right_eye_color', ...
                [buf_1(1), buf_1(2), buf_1(1), buf_1(2)]+...
                2*[-dot_size, -dot_size, dot_size, dot_size], ...
                oval_width);
            Screen('FrameOval', windowPtr, left_eye_color', ...
                [buf_2(1), buf_2(2), buf_2(1), buf_2(2)]+...
                2*[-dot_size, -dot_size, dot_size, dot_size], ...
                oval_width);
        end
    end
    % flip
    work_ends = GetSecs;
%     Datapixx('RegWrRdVideoSync');
    this_flip_time_pc = Screen('Flip', windowPtr);
    this_flip_time = Datapixx('GetTime');
    % save these timestamps
    flip_i = flip_i + 1;
    loop_durations(flip_i) = work_ends - work_starts;
    flip_times(2, flip_i) = this_flip_time - last_flip_time;
    flip_times(1, flip_i) = this_flip_time_pc - last_flip_time_pc;
    last_flip_time_pc = this_flip_time_pc; % update last flip time
    last_flip_time = this_flip_time;
    % Check Keyboard
    [pressed, ~, keycode] = KbCheck;
    if pressed
        if keycode(KbName('escape'))
            recording = 0; % stop the recording, please
        else
            % TO DO: any other options?
            
        end
    end
end % of while recording

%% Stop the Recording here
[rec_end_time_pc, rec_end_time] = StopTPxRecording;
    
%% Last flip
Screen('DrawText', windowPtr, 'Demo done.',...
    100, 100, scrFgCol);
Datapixx('RegWrRdVideoSync');
presentation_off_pc = Screen('Flip', windowPtr);
presentation_off = Datapixx('GetTime');
% save this timestamp
flip_i = flip_i + 1;
flip_times(1, flip_i) = presentation_off - last_flip_time;
flip_times(2, flip_i) = presentation_off_pc - last_flip_time_pc;
WaitSecs(0.1);
    
%% Post-processing and shutdown
% last buffer retrieval
if simple_version
    [sample_i, lastRetrieval] = ReadTPxDataSimple(sample_i);
    bufferData = [bufferData; lastRetrieval];
else
    [sample_i, bufferData, lastRetrieval] = ReadTPxData(sample_i, bufferData);
end
% remap timing with precise method (online we use the less precise method)
bufferData = DatapixxToGetSecs(bufferData);
% remove NaNs
if ~simple_version
    [buffer_trimmed, bufferData] = RemoveNaNsFromBuffer(bufferData);
end
samples_drawn_position = samples_drawn_position(~isnan(samples_drawn_position(:,1)),:);
samples_drawn_buffer = samples_drawn_buffer(~isnan(samples_drawn_buffer(:,1)),:);
loop_durations = loop_durations(~isnan(loop_durations));
flip_times = flip_times(:,~isnan(flip_times(1,:)));
% turn off TrackPixx
UninitializeTPx;
% close screen
Priority(0);
sca;
Datapixx('Close');
disp('Demo done!');

%% save everything
if ~simple_version
    assert(buffer_trimmed==1)
end
save TrackpixxToolboxDemo;

%% make a few plots: TO DO

real_TPx_sampling_freq = size(bufferData,1) / (rec_end_time-rec_start_time);
real_TPx_sampling_freq
real_frame_rate = flip_i / (presentation_off-presentation_on);
real_frame_rate

% figure on eye movements in space
figure(1);
subplot(1,2,1);
plot(bufferData(:,16), bufferData(:,17), '.', ...
     samples_drawn_position(:,1), samples_drawn_position(:,2), 'o', ...
     samples_drawn_buffer(:,1), samples_drawn_buffer(:,2), 's');
subplot(1,2,2);
plot(bufferData(:,18), bufferData(:,19), '.', ...
     samples_drawn_position(:,3), samples_drawn_position(:,4), 'o', ...
     samples_drawn_buffer(:,3), samples_drawn_buffer(:,4), 's');
 
% histograms
figure(2);
subplot(1,2,1);
histogram(loop_durations, 'BinWidth', 0.001);
title('Loop durations');
subplot(1,2,2);
histogram(flip_times(1,:), 'BinWidth', 0.001);
title('Inter-flip durations');
