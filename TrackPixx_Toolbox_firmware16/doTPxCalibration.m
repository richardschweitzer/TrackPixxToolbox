function calib_result = doTPxCalibration(scr_win, dlp_mode, scr_bg, scr_ppd, scr_lum_fac)
% starts the calibration and validation procedures.
% by Richard, 10/2018

% check for arguments. 
if nargin==2
    scr_bg = 0.5;
    scr_ppd = load_default_scr_ppd;
    scr_lum_fac = 1;
elseif nargin==3
    scr_ppd = load_default_scr_ppd;
    scr_lum_fac = 1;
elseif nargin==4
    scr_lum_fac = 1;
elseif nargin==0
    error('scr_win has to be specified!');
elseif nargin==1
    dlp_mode = NaN;
    scr_bg = 0.5;
    scr_ppd = load_default_scr_ppd;
    scr_lum_fac = 1;
end

% start calibration here.
if Datapixx('IsReady') %% Datapixx is ready
    
    % go to full HD mode
    if isnan(dlp_mode) || dlp_mode ~= 0
        Datapixx('SetPropixxDlpSequenceProgram', 0);
        Datapixx('RegWr');
    end
    
    % run calibration until we're happy with the result.
    happy_yes = 0;
    while ~isnan(happy_yes) && ~happy_yes
        calib_result = TPxCalibrationValidationRichardsFunction(scr_win, scr_bg, ...
            scr_ppd, scr_lum_fac); % the rest of the arguments are default
        if isfield(calib_result, 'happy_val')
            happy_yes = calib_result.happy_val; % NaN can be returned
        else
            happy_yes = NaN;
        end
    end
    
    % compute mean error for each eye.
    if isfield(calib_result, 'error_vector_dva') && ~isempty(calib_result.error_vector_dva) && ...
            all(all(~isnan(calib_result.error_vector_dva),1))
        error_vector_dva = calib_result.error_vector_dva;
        distRight = sqrt(error_vector_dva(:,1).^2 + error_vector_dva(:,2).^2);
        distLeft = sqrt(error_vector_dva(:,3).^2 + error_vector_dva(:,4).^2);
        calib_result.mean_error = [mean(distLeft, 'omitnan'), mean(distRight, 'omitnan')];
    end
    
    % go back to the mode specified previously
    if ~isnan(dlp_mode) && dlp_mode ~= 0
        Datapixx('SetPropixxDlpSequenceProgram', dlp_mode);
        Datapixx('RegWr');
    end
    
else %% Datapixx not ready
    calib_result = [];
    warning('Datapixx has not been successfully opened for use!')
end

end % of main function


function scr_ppd = load_default_scr_ppd
% loads the ppd for our setup. 
% THESE VALUES MIGHT HAVE TO BE ADJUSTED, otherwise the computed error is
% unrealistic;
scr_resx = 1920; % horizontal resolution of the screen [pixels], default: full HD
scr_dist = 380; % distance from the observer to the screen [cm]
scr_width = 250.2; % width of the screen [cm]
scr_height = 140.7;
scr_ppd = scr_dist*tan(1*pi/180)/(scr_width/scr_resx);
scr_lum_fac = 1;
end

