function [return_time, return_time_pc] = InitializeTPx(led_intensity, which_lens, distance_cm, iris_size_pix)
% wakes the TPx up and sets LED intensity and iris size in pixels
% Richard Schweitzer, 10/2018

% default values
if nargin == 3
    iris_size_pix = 140;
elseif nargin == 2
    distance_cm = 60;
    iris_size_pix = 140;
elseif nargin == 1
    which_lens = 1;
    distance_cm = 60;
    iris_size_pix = 140;
elseif nargin == 0
    led_intensity = 8;
    which_lens = 1;
    distance_cm = 60;
    iris_size_pix = 140;
end
% was iris size specified?
if nargin < 4
    iris_size_set = 0;
else
    iris_size_set = 1;
end

if Datapixx('IsReady')
    % sync clocks, see: http://psychtoolbox.org/docs/PsychDataPixx
    PsychDataPixx('GetPreciseTime'); 
    % setup the TrackPixx
    Datapixx('RegWrRd');
    Datapixx('SetTPxAwake');
    Datapixx('RegWrRd');
    Datapixx('SetLedIntensity', led_intensity);
    Datapixx('SetLens', which_lens); % 0 (25 mm), 1 (50 mm), 2 (75 mm)
    Datapixx('SetDistance', distance_cm+1); % Tracking distance is defined as the direct line from lens tip to subject's eyes + 1 cm.
    if iris_size_set && ~isnan(iris_size_pix) && iris_size_pix > 10
        % Usual values: 70 @ 60cm with 25mm lens, 140 @ 60cm with 50mm and 150 for MRI.
        Datapixx('SetExpectedIrisSizeInPixels', iris_size_pix) 
    end
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