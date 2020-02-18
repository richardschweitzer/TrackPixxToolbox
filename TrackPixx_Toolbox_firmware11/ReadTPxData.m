function [sample_i, bufferData, tempBufferData] = ReadTPxData(sample_i, bufferData)
% This function retrieves all not yet read samples in buffer. 
% Then, (fast) pc timestamps and gaze positions relative to the screen
% will be computed. Finally, everything is written into bufferData.
% bufferData must have at least 19 columns, since ReadTPxData returns 14
% columns and we need five more (i.e., t_pc, 1st_eye_x, 1st_eye_y,
% 2nd_eye_x, 2nd_eye_y). 
% by Richard, 10/2018

if nargin==2 % check for two input arguments
    tempBufferData = [];
    bufferData_length = size(bufferData, 1);
    bufferData_columns = size(bufferData, 2);
    if bufferData_length > 0 && bufferData_columns >= 19 && ... % check for proper bufferData
            sample_i <= bufferData_length % check that our iterator does not exceed bufferData
        if Datapixx('IsReady') % check whether Datapixx is ready
            % what's the status? Have we got any samples to retrieve?
            Datapixx('RegWrRd');
            status = Datapixx('GetTPxStatus');
            toRead = status.newBufferFrames;
            % if so, retrieve them
            if toRead > 0
                % this is the data collected since the last retrieval:
                % timetag : tempBufferData(:,1)
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
                % save to the buffer:
                % not like this, because it's really slow:
                % bufferData(save_index, tempBufferData_columns+1) = t_pc; % the pc timestamps
                % bufferData(save_index, tempBufferData_columns+(2:3)) = firstEyeScreen;
                % bufferData(save_index, tempBufferData_columns+(4:5)) = secondEyeScreen;
                % instead, see: https://de.mathworks.com/matlabcentral/answers/54522-why-is-indexing-vectors-matrices-in-matlab-very-inefficient
                save_index = sample_i:(sample_i+tempBufferData_length-1);
                bufferData(save_index, :) = tempBufferData;
                % update the sample_i:
                sample_i = sample_i + tempBufferData_length;
            end
        else
            warning('Datapixx has not been successfully opened for use!');
        end
    else
        warning('Non-empty bufferData with more rows than sample_i and 19 or more columns must be supplied');
    end
else
    error('Two arguments must be supplied: sample_i and bufferData');
end