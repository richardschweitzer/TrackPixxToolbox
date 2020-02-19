function [finish_time_pc, finish_time, is_recording] = ...
    StopTPxRecording
% Stop a TrackPixx Recording, given that we are recording.
% Richard Schweitzer, 10/2018

% check whether we're recording
if Datapixx('IsReady')
    Datapixx('RegWrRd');
    status = Datapixx('GetTPxStatus');
    is_recording = status.IsRecording;
else
    is_recording = NaN;
    warning('Datapixx has not been successfully opened for use!')
end

% if so, stop recording
if ~isnan(is_recording) && is_recording
    Datapixx('StopTPxSchedule'); % Stop recording
    Datapixx('RegWrRd');
    finish_time = Datapixx('GetTime');
    finish_time_pc = PsychDataPixx('FastBoxsecsToGetsecs', finish_time);
else
    if ~isnan(is_recording)
        warnings('You called StopTPxRecording although the TrackPixx is not recording.');
    end
    finish_time = NaN;
    finish_time_pc = GetSecs;
end