function handles = ScanFiles(handles)
% scanFiles updates number of files in the dicomfiles folder

% Log event
t = tic;
Event(['Scanning directory ', handles.config.DICOM_FOLDER, ' for files']);

% Query the database for all patients
[handles.database, n] = QueryDatabase(handles.database, ...
    'SELECT sopinst FROM patients');

% Loop through results
for i = 1:length(n.sopinst)
    
    % Scan the dicomfiles subdirectory for the number of files 
    l = length(dir([handles.config.DICOM_FOLDER, '/', n.sopinst{i}])) - 2;
    
    % Query the database for all patients
    handles.database = QueryDatabase(handles.database, ...
        sprintf('UPDATE patients SET numfiles = %i WHERE sopinst = ''%s''', ...
        l, n.sopinst{i}));
end

% Log completion
Event(sprintf('Directory scan completed successfully in %0.3f seconds', ...
    toc(t)));

% Clear temporary variables
clear i l n t;

