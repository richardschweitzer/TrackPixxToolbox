function [sample_i, bufferData, tempBufferData] = ReadTPxData(sample_i, bufferData)
% This function retrieves all not yet read samples in buffer. 
% Then, (fast) pc timestamps and gaze positions relative to the screen
% will be computed. Finally, everything is written into bufferData.
% bufferData must have at least 19 columns, since ReadTPxData returns 14
% columns and we need five more (i.e., t_pc, 1st_eye_x, 1st_eye_y,
% 2nd_eye_x, 2nd_eye_y). 
% by Richard, 10/2018, updated 02/2020

expected_ncol = 20; % this should be the width of the returned data starting at firmware 14
expected_ncol_bufferData = 25; % this is the allocated size of bufferData, without the last column that we create with DatapixxToGetSecs
% physical right eye is left eye on screen!!!
right_eye_cols_cartesian = 2:3; % prev. 2:3
left_eye_cols_cartesian = 5:6; % prev. 7:8

if nargin==2 % check for two input arguments
    tempBufferData = [];
    bufferData_length = size(bufferData, 1);
    bufferData_columns = size(bufferData, 2);
    if bufferData_length > 0 && bufferData_columns >= expected_ncol_bufferData && ... % check for proper bufferData
            sample_i <= bufferData_length % check that our iterator does not exceed bufferData
        if Datapixx('IsReady') % check whether Datapixx is ready
            % what's the status? Have we got any samples to retrieve?
            Datapixx('RegWrRd');
            status = Datapixx('GetTPxStatus');
            toRead = status.newBufferFrames;
            % if so, retrieve them
            if toRead > 0
                % THIS LIST CHANGED AT FIRMWARE REV 14
                % timetag : tempBufferData(:,1) IN SECONDS
                % leftScrPosX : tempBufferData(:,2), prev. left_raw_x
                % leftScrPosY : tempBufferData(:,3), prev. left_raw_y
                % leftPPSize : tempBufferData(:,4), prev. leftPP_hori
                % rightScrPosX : tempBufferData(:,5), prev. leftPP_vert
                % rightScrPosY : tempBufferData(:,6), prev. left_angle
                % rightPPSize : tempBufferData(:,7), prev. right_raw_x
                % DigitalInput : tempBufferData(:,8), prev. right_raw_y
                % leftBlink : tempBufferData(:,9), prev. rightPP_hori
                % rightBlink : tempBufferData(:,10), prev. rightPP_vert
                % DigitalOutput : tempBufferData(:,11), prev. right_angle
                % leftFixation : tempBufferData(:,12), prev. Digital Input values
                % rightFixation : tempBufferData(:,13), prev. blink_left
                % leftSaccade : tempBufferData(:,14), prev. blink_right
                % rightSaccade : tempBufferData(:,15)
                % messageCode : tempBufferData(:,16)
                % leftRawX : tempBufferData(:,17)
                % leftRawY : tempBufferData(:,18)
                % rightRawX : tempBufferData(:,19)
                % rightRawY : tempBufferData(:,20)
                %%%%%%%%%%%%%%% Richards add-on
                % timetag_pc_fast : tempBufferData(:,21)
                % leftScrPosX_mapped : tempBufferData(:,22)
                % leftScrPosY_mapped : tempBufferData(:,23)
                % rightScrPosX_mapped : tempBufferData(:,24)
                % rightScrPosY_mapped : tempBufferData(:,25)
                % timetag_pc : tempBufferData(:,26) --> happens later when calling DatapixxToGetSecs
            
                % get the data collected since the last retrieval.
                [tempBufferData, underflow, overflow] = Datapixx('ReadTPxData', toRead);
                tempBufferData_columns = size(tempBufferData, 2); 
                tempBufferData_length = size(tempBufferData, 1);
                % output from ReadTPxData must have 14 columns!
                if tempBufferData_columns ~= expected_ncol
                    warning(['tempBufferData_columns is not ', num2str(expected_ncol), ...
                        ', but ', num2str(tempBufferData_columns), '!']);
                end
                % TO DO: deal under- and overflows:
                if underflow > 0 || overflow > 0
                    warning(['ReadTPxData resulted in underflow=', num2str(underflow), ...
                        ', overflow=', num2str(overflow)]);
                end
                % convert datapixx timestamps to pc timestamps (fast mode)
                t_pc = PsychDataPixx('FastBoxsecsToGetsecs', tempBufferData(:,1));
                % convert to screen coordinates
                firstEyeScreen = Datapixx('ConvertCoordSysToCustom', tempBufferData(:,right_eye_cols_cartesian)); % prev. 2:3
                secondEyeScreen = Datapixx('ConvertCoordSysToCustom', tempBufferData(:,left_eye_cols_cartesian)); % prev. 7:8
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