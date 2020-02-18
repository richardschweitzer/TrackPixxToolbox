function [firstEyeScreen, secondEyeScreen,...
    firstEyeCartesian, secondEyeCartesian,...
    firstEyeRaw, secondEyeRaw,...
    t_pc, t] = GetTPxEyePosition(get_timestamp, remote_mode)
% Gets you the current gaze position (in screen coord, cartesian coord, and raw)
% from the TrackPixx. 
% It does not provide a reliable timestamp though. Timestamp retrieval is
% also gonna be more computationally expensive.
% by Richard Schweitzer 10/2018, based on Danny M.'s function

if nargin==1
    remote_mode = 0; % 0: chin-rest, 1: remote
elseif nargin==0
    remote_mode = 0;
    get_timestamp = 0; % 0: GetSecs timestamp, 1: Datapixx timestamp
end

% this command takes time, as well
if get_timestamp == 1
    DP_open = Datapixx('IsReady');
    if DP_open == 1
        Datapixx('RegWrRd');
    else
        warning('Datapixx has not been successfully opened for use!');
    end
end

% get current eye position
% Usage:
% [xScreenRight yScreenRight xScreenLeft yScreenLeft xRawRight yRawRight xRawLeft yRawLeft] = Datapixx('GetEyePosition');
% Returns calibrated eye position and raw data
%    Optional parameter used to select either remote or chin-rest calibration   0: Chin-Rest   1: Remote
[xScreenCartesian_2, yScreenCartesian_2, xScreenCartesian_1, yScreenCartesian_1,...
    xRaw_2, yRaw_2, xRaw_1, yRaw_1] = ...
    Datapixx('GetEyePosition', remote_mode);

% get current time
if get_timestamp == 1 && DP_open == 1 % time based on Datapixx timestamp (approximate)
    t = Datapixx('GetTime');
    t_pc = PsychDataPixx('FastBoxsecsToGetsecs', t);
else % based on pc timestamp
    t = NaN;
    t_pc = GetSecs;
end

% cartesian
firstEyeCartesian = [xScreenCartesian_1, yScreenCartesian_1];
secondEyeCartesian = [xScreenCartesian_2, yScreenCartesian_2];
% raw
firstEyeRaw = [xRaw_1, yRaw_1];
secondEyeRaw = [xRaw_2, yRaw_2];
% convert to screen coord
firstEyeScreen = Datapixx('ConvertCoordSysToCustom', firstEyeCartesian);
secondEyeScreen = Datapixx('ConvertCoordSysToCustom', secondEyeCartesian);
