function [firstEyeScreen, secondEyeScreen, firstEyeCartesian, secondEyeCartesian, ...
    t_pc, t, ...
    firstEyeScreen_SE, secondEyeScreen_SE] = ...
    GetTPxLatestSample(sample_i, bufferData, n_samples)
% gets the latest sample based on the data retrieved from the buffer.
% if n_samples is larger than 1, then an aggregate is possible.
% by Richard Schweitzer, 10/2018

right_eye_cols_cartesian = 2:3; % prev. 2:3
left_eye_cols_cartesian = 5:6; % prev. 7:8
right_eye_cols = 22:23; % prev. 16:17
left_eye_cols = 24:25; % prev. 18:19
expected_ncol = 20;

if nargin == 0
    error('bufferData must be supplied.')
elseif nargin == 1
    n_samples = 2; % corresponds to 1000 Hz
end

% make sure n_samples is positive...
if n_samples < 1
    n_samples = 1;
end

% get buffer length
bufferData_length = size(bufferData, 1);
bufferData_columns = size(bufferData, 2);

% do we have enough samples?
if bufferData_length == 0 || bufferData_columns < expected_ncol % empty or insufficiently small buffer
    warning(['bufferData either is empty or has less than', num2str(expected_ncol), ' columns!']);
    firstEyeScreen = [NaN, NaN];
    secondEyeScreen = [NaN, NaN];
    firstEyeCartesian = [NaN, NaN];
    secondEyeCartesian = [NaN, NaN];
    t_pc = NaN;
    t = NaN;   
    firstEyeScreen_SE = [NaN, NaN];
    secondEyeScreen_SE = [NaN, NaN];
else % bufferData is okay
    if n_samples > bufferData_length-1 % we want more samples than there are in the buffer?
        n_samples = bufferData_length-1; % we only get what's in the buffer!
    end
    % is it one sample?
    if n_samples > 1 % last n_samples values retrieved -> mean
        firstEyeCartesian = mean(bufferData((sample_i-1-(n_samples-1)):(sample_i-1),right_eye_cols_cartesian),'omitnan');
        secondEyeCartesian = mean(bufferData((sample_i-1-(n_samples-1)):(sample_i-1),left_eye_cols_cartesian),'omitnan');
    else % last value retrieved
        firstEyeCartesian = bufferData(sample_i,right_eye_cols_cartesian);
        secondEyeCartesian = bufferData(sample_i,left_eye_cols_cartesian);
    end
    t = bufferData((sample_i-1),1); % latest timestamp
    if bufferData_columns >= 19 % Screen coordinates available, as well.
        if n_samples > 1 % last n_samples values
            firstEyeScreen = mean(bufferData((sample_i-1-(n_samples-1)):(sample_i-1),right_eye_cols),'omitnan');
            firstEyeScreen_SE = std(bufferData((sample_i-1-(n_samples-1)):(sample_i-1),right_eye_cols),'omitnan')./sqrt(n_samples);
            secondEyeScreen = mean(bufferData((sample_i-1-(n_samples-1)):(sample_i-1),left_eye_cols),'omitnan');
            secondEyeScreen_SE = std(bufferData((sample_i-1-(n_samples-1)):(sample_i-1),left_eye_cols),'omitnan')./sqrt(n_samples);
        else % latest sample
            firstEyeScreen = bufferData(sample_i-1,right_eye_cols);
            firstEyeScreen_SE = 0;
            secondEyeScreen = bufferData(sample_i-1,left_eye_cols);
            secondEyeScreen_SE = 0;
        end
        t_pc = bufferData((sample_i-1),15); % latest timestamp
    else % if no screen coordinates available, just return none.
        firstEyeScreen = [NaN, NaN];
        firstEyeScreen_SE = [NaN, NaN];
        secondEyeScreen = [NaN, NaN];
        secondEyeScreen_SE = [NaN, NaN];
        t_pc = NaN;
    end
end