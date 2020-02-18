function [xy_res, xy_res_SE] = ...
    GetTPxLatestSampleSimple(xy, n_samples)
% gets the latest sample based on the XY-data passed to this function.
% if n_samples is larger than 1, then an aggregate is possible.
% by Richard Schweitzer, 10/2018

if nargin == 0
    error('XY must be supplied.')
elseif nargin == 1
    n_samples = 2; % corresponds to 1000 Hz
end

% make sure n_samples is positive...
if n_samples < 1
    n_samples = 1;
end

% get xy length
xy_length = size(xy, 1);
xy_columns = size(xy, 2);

% do we have enough samples?
if xy_length == 0 || xy_columns < 1 % empty or insufficiently small xy
    warning('xy data is empty!');
    xy_res = [NaN, NaN];
    xy_res_SE = [NaN, NaN];
else % xy data is okay
    if n_samples > xy_length % we want more samples than there are in the buffer?
        n_samples = xy_length; % we only get what's in the buffer!
    end
    % is it one sample?
    if n_samples > 1 % last n_samples values retrieved -> mean
        xy_res = median(xy((end-(n_samples-1)):end,:),'omitnan');
        xy_res_SE = std(xy((end-(n_samples-1)):end,:),'omitnan')./sqrt(n_samples);
    else % last value retrieved
        xy_res = xy(end,:);
        xy_res_SE = 0;
    end
end