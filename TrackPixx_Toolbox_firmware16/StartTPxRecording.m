function [start_time_pc, start_time, newBufferData, sample_i] = ...
    StartTPxRecording(duration, bufferAddress, bufferColumns, TPx_sampling_freq)
% starts the TrackPixx recording
% Richard Schweitzer, 10/2018

if nargin == 0
    bufferAddress = 12e6;
    duration = 10*60; % in seconds, default here is 10 minutes
    bufferColumns = 25; % 20 columns from ReadTPxData + 1 for pc_time + 4 for screen coordinates
    TPx_sampling_freq = 2000;
elseif nargin == 1
    bufferAddress = 12e6;
    bufferColumns = 25;
    TPx_sampling_freq = 2000;
elseif nargin == 2
    bufferColumns = 25;
    TPx_sampling_freq = 2000;
elseif nargin == 3
    TPx_sampling_freq = 2000;
end

if bufferColumns < 19
    warning('There must be at least 19 buffer columns! This will most likely lead to an error when ReadTPxData is called.')
end

% check whether we're already recording
if Datapixx('IsReady')
    % sync clocks, see: http://psychtoolbox.org/docs/PsychDataPixx
    PsychDataPixx('GetPreciseTime'); 
    % get status from trackpixx
    Datapixx('RegWrRd');
    status = Datapixx('GetTPxStatus');
    is_recording = status.IsRecording;
else
    is_recording = NaN;
    warning('Datapixx has not been successfully opened for use!');
end

% if not, start a recording
if ~isnan(is_recording) && ~is_recording
    bufferSize = duration * TPx_sampling_freq;
    % pre-allocate a buffer that will be filled with data
    newBufferData = NaN(bufferSize, bufferColumns);
    % reset sample_i
    sample_i = 1;
    % setup schedule
    Datapixx('SetupTPxSchedule', bufferAddress, bufferSize); % Set up recording
    Datapixx('RegWrRd');
    % start recording right away
    Datapixx('StartTPxSchedule'); % Start recording
    Datapixx('RegWrRd');
    % started?
    start_time = Datapixx('GetTime');
    start_time_pc = PsychDataPixx('FastBoxsecsToGetsecs', start_time);
else
    if ~isnan(is_recording)
        warning('StartTPxRecording was called, although the TPx is already recording. You might have overwritten some important variables.');
    end
    newBufferData = [];
    sample_i = 0;
    start_time = NaN;
    start_time_pc = GetSecs;
end