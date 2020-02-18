function [sample_i, tempBufferData] = ReadTPxDataSimple(sample_i)
% This function retrieves all not yet read samples in buffer. 
% Then, (fast) pc timestamps and gaze positions relative to the screen
% will be computed. Finally, everything is written into bufferData.
% bufferData must have at least 19 columns, since ReadTPxData returns 14
% columns and we need five more (i.e., t_pc, 1st_eye_x, 1st_eye_y,
% 2nd_eye_x, 2nd_eye_y).
% THIS is the simple version without any input arguments.
% by Richard, 10/2018

if nargin==0
    error('You have to supply sample_i at least!')
else
    if Datapixx('IsReady') % check whether Datapixx is ready
        % what's the status? Have we got any samples to retrieve?
        Datapixx('RegWrRd');
        status = Datapixx('GetTPxStatus');
        toRead = status.newBufferFrames;
        % if so, retrieve them
        if toRead > 0
            % this is the data collected since the last retrieval:
            % timetag : tempBufferData(:,1) IN SECONDS
            % left_raw_x : tempBufferData(:,2)
            % left_raw_y : tempBufferData(:,3)
            % leftPP_hori : tempBufferData(:,4)
            % leftPP_vert : tempBufferData(:,5)
            % left_angle : tempBufferData(:,6)
            % right_raw_x : tempBufferData(:,7)
            % right_raw_y : tempBufferData(:,8)
            % rightPP_hori : tempBufferData(:,9)
            % rightPP_vert : tempBufferData(:,10)
            % right_angle : tempBufferData(:,11)
            % Digital Input values : tempBufferData(:,12)
            % blink_left : tempBufferData(:,13)
            % blink_right : tempBufferData(:,14)
            [tempBufferData, underflow, overflow] = Datapixx('ReadTPxData', toRead);
            tempBufferData_columns = size(tempBufferData, 2);
            tempBufferData_length = size(tempBufferData, 1);
            % output from ReadTPxData must have 14 columns!
            if tempBufferData_columns ~= 14
                warning(['tempBufferData_columns is not 14, but ', num2str(tempBufferData_columns), '!']);
            end
            % TO DO: deal under- and overflows:
            if underflow > 0 || overflow > 0
                warning(['ReadTPxData resulted in underflow=', num2str(underflow), ...
                    ', overflow=', num2str(overflow)]);
            end
            % convert datapixx timestamps to pc timestamps (fast mode)
            t_pc = PsychDataPixx('FastBoxsecsToGetsecs', tempBufferData(:,1));
            % convert to screen coordinates
            firstEyeScreen = Datapixx('ConvertCoordSysToCustom', tempBufferData(:,2:3));
            secondEyeScreen = Datapixx('ConvertCoordSysToCustom', tempBufferData(:,7:8));
            % save to temporary buffer
            tempBufferData = [tempBufferData, t_pc, firstEyeScreen, secondEyeScreen];
            % update sample_i
            sample_i = sample_i + tempBufferData_length;
        end
    else
        warning('Datapixx has not been successfully opened for use!');
    end
end