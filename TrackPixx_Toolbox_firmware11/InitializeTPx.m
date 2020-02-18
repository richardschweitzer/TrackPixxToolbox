function [return_time, return_time_pc] = InitializeTPx(led_intensity, iris_size_pix)
% wakes the TPx up and sets LED intensity and iris size in pixels
% Richard Schweitzer, 10/2018

% default values
if nargin == 1
    iris_size_pix = 140; 
elseif nargin == 0
    led_intensity = 8;
    iris_size_pix = 140;
end

if Datapixx('IsReady')
    % sync clocks, see: http://psychtoolbox.org/docs/PsychDataPixx
    PsychDataPixx('GetPreciseTime'); 
    % setup the TrackPixx
    Datapixx('RegWrRd');
    Datapixx('SetTPxAwake');
    Datapixx('RegWrRd');
    Datapixx('SetLedIntensity', led_intensity);
    Datapixx('SetExpectedIrisSizeInPixels', iris_size_pix)
    Datapixx('RegWrRd');
    % set console mode: ON!
    Datapixx('SetVideoConsoleDisplay', 0);
    Datapixx('RegWrRd');
    % get time of TPx initialization
    return_time = Datapixx('GetTime');
    return_time_pc = PsychDataPixx('FastBoxsecsToGetsecs', return_time);
else
    warning('Datapixx has not been successfully opened for use!');
    return_time = NaN;
    return_time_pc = GetSecs;
end