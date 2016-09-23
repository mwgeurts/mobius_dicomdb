function handle = LoadDatabase(file)
%LOADDATABASE Summary of this function goes here
%   Detailed explanation goes here

% Start timer
tic;

% Add SQLite JDBC driver (current database is 3.8.5)
javaaddpath('./sqlite-jdbc-3.8.5-pre1.jar');

% Verify database file exists
if exist(file, 'file') == 2

    % Store database, username, and password
    handle = database(file, '', '', 'org.sqlite.JDBC', ...
        ['jdbc:sqlite:',file]);

    % Set the data return format to support strings
    setdbprefs('DataReturnFormat', 'cellarray');
    
    % Stop timer and log completion
    if exist('Event', 'file') == 2
        Event(sprintf(['The SQLite3 database %s loaded successfully in ', ...
            '%0.3f seconds'], file, toc));
    end
    
% Otherwise, if the database cannot be loaded
else
    
    % Log an error
    if exist('Event', 'file') == 2
        Event(['The SQLite3 database ', file, ' is missing'], 'ERROR');
    else
        error(['The SQLite3 database ', file, ' is missing']);
    end
    
    % Return empty array
    handle = [];
end
