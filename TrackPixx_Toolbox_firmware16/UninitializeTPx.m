function UninitializeTPx
% shuts down Trackpixx, but only if it is not recording
% Richard Schweitzer, 10/2018

% check whether we're recording
if Datapixx('IsReady')
    Datapixx('RegWrRd');
    status = Datapixx('GetTPxStatus');
    is_recording = status.IsRecording;
else
    is_recording = NaN;
end

if ~isnan(is_recording) && ~is_recording
    Datapixx('SetLedIntensity', 0); % turns off illuminator
    Datapixx('RegWrRd');
    Datapixx('SetTPxSleep');
    Datapixx('RegWrRd');
    % turn off TrackPixx console display
    Datapixx('SetVideoConsoleDisplay', 1);
    Datapixx('RegWrRd');
else
    if ~isnan(is_recording)
        warning('TrackPixx is still recording. Cannot shut it down!')
    else
        warning('Datapixx has not been successfully opened for use!')
    end
end