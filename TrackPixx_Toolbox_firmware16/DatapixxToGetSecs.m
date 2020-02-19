function bufferData = DatapixxToGetSecs(bufferData)
% converts TrackPixx Databuffer time (first column) to GetSecs Time.
% This is the precise function to remap Datapixx time to pc time: Since it
% takes more time, it should only be run, once dataBuffer collection was
% finished.
% by Richard 10/2018

expected_ncol = 25; % see ReadTPxDataSimple

if nargin==0
    bufferData = [];
    warning('At least bufferData has to be supplied!');
elseif nargin==1
    if ~isempty(bufferData) 
        bufferData_columns = size(bufferData, 2);
        if bufferData_columns < expected_ncol % proper bufferData should have 19 cols, as returned by ReadTPxData
            warning(['This bufferData has less than ', num2str(expected_ncol), ' columns, but ', ...
                num2str(bufferData_columns), '. Have you used ReadTPxData?']);
        end
        bufferData(:,bufferData_columns+1) = PsychDataPixx('BoxsecsToGetsecs', bufferData(:,1));
    else
        warning('Empty bufferData supplied!')
    end
end