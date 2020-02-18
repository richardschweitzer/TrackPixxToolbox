function [buffer_trimmed, bufferData] = RemoveNaNsFromBuffer(bufferData)
% Remove NaNs from the bufferData. 
% conditions: (1) bufferData supplied, (2) sufficiently large bufferData supplied,
% (3) TPx not recording, (4) all samples from TPx retrieved.
% Richard 10/2018

% was bufferData supplied?
if nargin==1 && ~isempty(bufferData)
    do_remove_nans = 1;
    bufferData_length = size(bufferData, 1);
else
    do_remove_nans = 0;
    bufferData = [];
    bufferData_length = 0;
end

if Datapixx('IsReady')
    % are we still recording and are there still samples in the buffer that
    % should be retrieved?
    Datapixx('RegWrRd');
    status = Datapixx('GetTPxStatus');
    is_recording = status.IsRecording;
    newBufferFrames = status.newBufferFrames;
    
    % if we're not recording and have retrieved all samples,
    % then we can safely remove NaNs from the bufferData matrix
    if is_recording == 0 && newBufferFrames == 0
        n_samples_read = status.currentWriteFrame; % how many samples in the buffer?
        if bufferData_length == 0 || do_remove_nans == 0 % no bufferData supplied
            warning('RemoveNaNsFromBuffer was called, but no bufferData was supplied');
        elseif do_remove_nans == 1 && bufferData_length > 0 && ...
                bufferData_length < n_samples_read % bufferData too small to be trimmed?
            warning(['Size of bufferData (', num2str(bufferData_length),...
                ') is smaller than the number of samples in the buffer (', ...
                num2str(n_samples_read), ') !!!']);
            buffer_trimmed = 0;
        else % this is the ideal scenario:
            bufferData = bufferData(1:n_samples_read, :);
            buffer_trimmed = 1;
        end
    else % supply warnings, if conditions above were not met
        if do_remove_nans == 1 % recording still ongoing or still samples to be retrieved
            warning(['RemoveNaNsFromBuffer was called, but there are still ', ...
                num2str(newBufferFrames), ' samples to be retrieved!']);
        else % there was no bufferData supplied
            warning('RemoveNaNsFromBuffer was called, but no bufferData was supplied');
        end
        buffer_trimmed = 0;
    end
else
    buffer_trimmed = 0;
    warning('Datapixx has not been successfully opened for use!');
end

