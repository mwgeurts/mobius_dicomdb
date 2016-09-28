function varargout = ImportData(varargin)
%IMPORT Summary of this function goes here
%   Detailed explanation goes here

% Start timer and initialize counter
t = tic;
count = 0;

% Loop through input arguments
for i = 1:2:nargin
    
    % Store server variables
    if strcmpi(varargin{i}, 'session')
        session = varargin{i+1};
    elseif strcmpi(varargin{i}, 'server')
        server = varargin{i+1};
    elseif strcmpi(varargin{i}, 'database')
        database = varargin{i+1};
    elseif strcmpi(varargin{i}, 'table')
        table = varargin{i+1};
    elseif strcmpi(varargin{i}, 'directory')
        directory = varargin{i+1};
    end
end

% If input variables are empty, throw an error
if exist('session', 'var') == 0 || isempty(session) || ...
        exist('server', 'var') == 0 || isempty(server) || ...
        exist('database', 'var') == 0 || isempty(database)

    % Log error
    Event('The required inputs to ImportData are missing', 'ERROR');
end

% Open waitbar
h = waitbar(0.05, 'Querying current database entries');

% If table variable is empty, run QueryDatabase
if exist('table', 'var') == 0 || isempty(table) 
    
    % Log event
    Event('Querying current database entries');
    
    % Query plan names, patient name, and 
    [database, table] = QueryDatabase(database, ...
        'SELECT sopinst FROM patients');
end

% Update waitbar
waitbar(0.1, h, 'Retrieving DICOM list from Mobius3D server');

% Retrieve DICOM list
[session, list] = QueryDICOMList('server', server, 'session', session);
l = length(list);

% Loop through DICOM list
for i = 1:l

    % If name starts/ends with 'ZZ' or 'UWQA' (QA patient)
    if ~isempty(strfind(lower(list{i}.patient_name), 'zz')) || ...
            ~isempty(strfind(lower(list{i}.patient_name), 'uwqa'))
        
        % Log event
        Event(['Skipping QA patient ', list{i}.patient_name]);
        
        % Skip this patient
        break;
    end
    
    % Update waitbar
    waitbar(0.1+0.9*i/l, h, ['Downloading DICOM data for ', ...
        list{i}.patient_name]);
    Event(['Reviewing patient records for ', list{i}.patient_name]);
    
    % Reset download RT plan cell array
    json = cell(0);
    
    % Get RTPLAN SOP instance UIDs
    [session, ~, ~, ~, list{i}.rtplan] = GetPlanSOPs('server', server, ...
        'session', session, 'patient_id', list{i}.patient_id);
    
    % Loop through RT PLANS
    for j = 1:length(list{i}.rtplan)
        
        % Search for SOP in table
        [~, c, ~] = intersect(table.sopinst, list{i}.rtplan{j}{3}{1});
        
        % If one of the plans is not already in the database, mark this
        % patient for download
        if isempty(c)
            
            % Log event
            Event(['Patient ', list{i}.patient_name, ' plan SOP ', ...
                list{i}.rtplan{j}{3}{1}{1}, ' not in database and will be ', ...
                'downloaded']);
            
            % Add RT plan object 
            [session, r] = GetRTPlan('server', server, 'session', ...
                session, 'sopinst', list{i}.rtplan{j}{3}{1}{1});
            json{length(json)+1} = LoadJSONPlan(r);
            
            % Add original SOP instance UID
            json{length(json)}.uid = list{i}.rtplan{j}{3}{1}{1};
        else
            
            % Log event
            Event(['Patient ', list{i}.patient_name, ' plan SOP ', ...
                list{i}.rtplan{j}{3}{1}{1}, ' matched database entry SOP ', ...
                table.sopinst{c}]);
        end
    end
    
    % If all DICOM plans matched datbase entries, this plan was already
    % processed
    if isempty(json)
        continue;
    end
                
    % Set GetAnonymizedDICOM input variable
    var{1}.patient_id = list{i}.patient_id;
    var{1}.patient_name = list{i}.patient_name;

    % Execute GetAnonymizedDICOM, storing the files to the temp dir
    [session, dicom] = GetAnonymizedDICOM('server', server, 'session', ...
        session, 'list', var, 'folder', tempdir);

    % Log event
    Event('Importing RTPLAN files');

    % Preallocate rtplans and rtstructs object
    rtplans = cell(length(json), 1);
    rtstructs = cell(length(json), 1);
    
    % Loop through the DICOM files searching for RT plan objects
    for j = 1:length(dicom{1}.files)
        
        % If the file is an RT Plan
        if ~isempty(regexpi(dicom{1}.files{j}, 'RTPLAN'))

            % Log event
            Event(['Loading RTPLAN file ', dicom{1}.files{j}]);

            % Load DICOM file
            d = dicominfo(dicom{1}.files{j});

            % Loop through RT plans
            for k = 1:length(json)

                % If plan name matches DICOM file
                if strcmp(json{k}.RTPlanName, d.RTPlanName);
                    
                    % Log plan name
                    Event(['Patient plan ', json{k}.RTPlanName, ...
                        ' matches RTPLAN file']);
                    count = count + 1;

                    % Make subdirectory in folder
                    Event(['Creating DICOM subdirectory ', json{k}.uid]);
                    mkdir(directory, json{k}.uid);

                    % Copy RT plan to subdirectory
                    [~, b, c] = fileparts(dicom{1}.files{j});
                    copyfile(dicom{1}.files{j}, fullfile(directory, ...
                        json{k}.uid, [b, c]));

                    % Store anonymized rtplan object
                    rtplans{k} = d;
                    
                    % Compute Rx dose, dose per fx
                    dose = 0;
                    doseperfx = 0;
                    if isfield(json{k}.FractionGroupSequence.Item_1, ...
                            'ReferencedDoseReferenceSequence')
                        dose = json{k}.FractionGroupSequence.Item_1...
                            .ReferencedDoseReferenceSequence.Item_1...
                            .TargetPrescriptionDose;
                        doseperfx = dose/json{k}.FractionGroupSequence...
                            .Item_1.NumberOfFractionsPlanned;
                    end
                    
                    % If SW version is multiple entries, reduce to a single
                    % value
                    if iscell(json{k}.SoftwareVersion)
                        json{k}.SoftwareVersion = ...
                            strtrim(json{k}.SoftwareVersion{1});
                    end
                    
                    % Insert plan into database within try/catch statement
                    try
                    database = QueryDatabase(database, sprintf(['INSERT INTO ', ...
                        'patients(sopinst, importdate, id, name, birthdate, ', ...
                        'sex, plan, plandate, machine, tps, version, type, ', ...
                        'mode, rxdose, fractions, doseperfx, position) ', ...
                        'VALUES(''%s'', %f, ''%s'', ''%s'', %f, ''%s'', ', ...
                        '''%s'', %f, ''%s'', ''%s'', ''%s'', ''%s'', ', ...
                        '''%s'', %f, %i, %f, ''%s'')'], json{k}.uid, ...
                        now, json{k}.PatientID, json{k}.PatientName, ...
                        datenum(json{k}.PatientBirthDate, 'yyyymmdd'), ...
                        json{k}.PatientSex, json{k}.RTPlanName, ...
                        datenum([json{k}.RTPlanDate, json{k}.RTPlanTime], ...
                        'yyyymmddHHMMSS'), json{k}.BeamSequence.Item_1...
                        .TreatmentMachineName, json{k}.ManufacturerModelName, ...
                        json{k}.SoftwareVersion, json{k}.BeamSequence...
                        .Item_1.BeamType, json{k}.BeamSequence.Item_1...
                        .RadiationType, dose, json{k}.FractionGroupSequence...
                        .Item_1.NumberOfFractionsPlanned, doseperfx, ...
                        json{k}.PatientSetupSequence.Item_1.PatientSetupNumber));
                    
                    % Catch and display SQL errors
                    catch err
                        Event(['Error adding patient to databse: ', ...
                            err.message], 'WARN');
                    end
                    
                    % Append plan SOP to table
                    table.sopinst{length(table.sopinst)+1} = json{k}.uid;
                    
                    % Stop searching, as plan was found
                    break;
                end
            end
        end
    end
    
    % Log event
    Event('Importing RTDOSE objects');

    % Loop through the DICOM files searching for RT dose objects
    for j = 1:length(dicom{1}.files)
        
        % If the file is an RT Dose
        if ~isempty(regexpi(dicom{1}.files{j}, 'RTDOSE'))

            % Log event
            Event(['Loading RTDOSE file ', dicom{1}.files{j}]);

            % Load DICOM file
            d = dicominfo(dicom{1}.files{j});

            % Loop through matched RT plans
            for k = 1:length(rtplans)
                
                % If RT Dose references this plan
                if isfield(d, 'ReferencedRTPlanSequence') && ...
                        isfield(d.ReferencedRTPlanSequence.Item_1, ...
                        'ReferencedSOPInstanceUID') && ...
                        strcmp(rtplans{k}.SOPInstanceUID, ...
                        d.ReferencedRTPlanSequence.Item_1...
                        .ReferencedSOPInstanceUID)

                    % Copy dose into plan folder
                    [~, b, c] = fileparts(dicom{1}.files{j});
                    copyfile(dicom{1}.files{j}, fullfile(directory, ...
                        json{k}.uid, [b, c]));
                end
            end
        end
    end
    
    % Log event
    Event('Importing RTSTRUCT objects');

    % Loop through the DICOM files searching for RT struct objects
    for j = 1:length(dicom{1}.files)
        
        % If the file is an RT struct
        if ~isempty(regexpi(dicom{1}.files{j}, 'RTSTRUCT'))

            % Log event
            Event(['Loading RTSTRUCT file ', dicom{1}.files{j}]);

            % Load DICOM file
            d = dicominfo(dicom{1}.files{j});

            % Loop through matched RT plans
            for k = 1:length(rtplans)
                
                % If RT plan references this structure set
                if isfield(rtplans{k}, 'ReferencedStructureSetSequence') && ...
                        isfield(rtplans{k}.ReferencedStructureSetSequence.Item_1...
                        , 'ReferencedSOPInstanceUID') && ...
                        strcmp(rtplans{k}.ReferencedStructureSetSequence.Item_1...
                        .ReferencedSOPInstanceUID, d.SOPInstanceUID)
                    
                    % Copy structure set into plan folder
                    [~, b, c] = fileparts(dicom{1}.files{j});
                    copyfile(dicom{1}.files{j}, fullfile(directory, ...
                        json{k}.uid, [b, c]));
                    
                    % Store anonymized RT struct object
                    rtstructs{k} = d;
                end
            end
        end
    end
    
    % Log event
    Event('Importing CT objects');

    % Loop through the DICOM files searching for CT images
    for j = 1:length(dicom{1}.files)
        
        % If the file is a CT
        if ~isempty(regexpi(dicom{1}.files{j}, '^CT'))

            % Log event
            Event(['Loading CT image ', dicom{1}.files{j}]);

            % Load DICOM file
            d = dicominfo(dicom{1}.files{j});

            % Loop through matched RT structure sets
            for k = 1:length(rtstructs)
                
                % If RT structure references this image using the
                % referencedstudysequence tag
                if isfield(rtstructs{k}, 'ReferencedStudySequence') && ...
                        strcmp(rtstructs{k}.ReferencedStudySequence.Item_1...
                        .ReferencedSOPInstanceUID, d.StudyInstanceUID)
                    
                    % Copy CT into plan folder
                    [~, b, c] = fileparts(dicom{1}.files{j});
                    copyfile(dicom{1}.files{j}, fullfile(directory, ...
                        json{k}.uid, [b, c]));
                    
                % Otherwise, if RT structure references this image using 
                % the referencedstudysequence tag
                elseif isfield(rtstructs{k}, ...
                        'ReferencedFrameOfReferenceSequence') && isfield(...
                        rtstructs{k}.ReferencedFrameOfReferenceSequence...
                        .Item_1, 'RTReferencedStudySequence') && strcmp(...
                        rtstructs{k}.ReferencedFrameOfReferenceSequence...
                        .Item_1.RTReferencedStudySequence.Item_1...
                        .ReferencedSOPInstanceUID, d.StudyInstanceUID)
                    
                    % Copy CT into plan folder
                    [~, b, c] = fileparts(dicom{1}.files{j});
                    copyfile(dicom{1}.files{j}, fullfile(directory, ...
                        json{k}.uid, [b, c]));
                end
            end
        end
    end
end

% Log completion
Event(sprintf('Import completed in %0.3f seconds, adding %i plans', ...
    toc(t), count));

% Close waitbar
close(h);

% Clear temporary variables
clear i j k h l a b c f r s t x var session server database table directory ...
    anonplan dicom json rtplans rtstructs;

% Return output variables
if nargout == 1
    varargout{1} = session;
elseif nargout == 2
    varargout{1} = session;
    varargout{2} = database;
end
