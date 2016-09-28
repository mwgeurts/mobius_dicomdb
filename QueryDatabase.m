function varargout = QueryDatabase(varargin)
%QUERYDATABASE Summary of this function goes here
%   Detailed explanation goes here

% Start timer
tic;

% Persistently store the database handle
persistent database

% If only one input was provided
if nargin == 1
    
    % Set query to first input argument
    sql = varargin{1};
    
% If two inputs were provided
elseif nargin == 2
    
    % Set database handle with first argument
    database = varargin{1};
    
    % Set query with second argument
    sql = varargin{2};

% Otherwise, an incorrect number of arguments exist
else

    % Throw an error
    if exist('Event', 'file') == 2
        Event(['An incorrect number of arguments were passed to ', ...
            'QueryDatabase'], 'ERROR');
    else
        error(['An incorrect number of arguments were passed to ', ...
            'QueryDatabase']);
    end
end

% Verify the database is defined
if exist('database', 'var') == 0
    if exist('Event', 'file') == 2
        Event('QueryDatabase must first be called with a database handle', ...
            'ERROR');
    else
        error('QueryDatabase must first be called with a database handle');
    end
end

% Execute query
cursor = exec(database, sql);

% Retrieve the result
cursor = fetch(cursor);

% Check return
if strfind(cursor.Message, '[SQLITE_ERROR]') > 0
    if exist('Event', 'file') == 2
        Event(cursor.Message, 'ERROR');
    else
        error(cursor.Message);
    end
end

% If this is a query
if strcmp(sql(1:6), 'SELECT')

    % Identify the table rows
    cols = regexprep(strsplit(sql(8:strfind(sql, 'FROM')-2), ', '), ...
        '[^\w]', '');
    
    % Initialize return argument
    for i = 1:length(cols)
        
        % Set empty cell array
        data.(cols{i}) = cell(0);
    end

    % Loop through results
    for i = 1:length(cols)
        
        % Store data
        if ~strcmp(cursor.Data{1}, 'No Data')
            data.(cols{i}) = cursor.Data(:,i);
        else
            data.(cols{i}) = [];
        end
    end
    
    % Log conclusion
    if exist('Event', 'file') == 2 && iscell(data.(cols{1}))
        Event(sprintf('%i record(s) returned in %0.3f seconds', ...
            length(data.(cols{1})), toc));
    else
        Event(sprintf('0 record(s) returned in %0.3f seconds', toc));
    end
else
    
    % Log conclusion
    if exist('Event', 'file') == 2
        Event(sprintf('Query completed in %0.3f seconds', toc));
    end
end

% Close the query
close(cursor);

% If an output variable is requested
if nargout == 1
    
    % If this was a query
    if strcmp(sql(1:6), 'SELECT')
        
        % Return the data
        varargout{1} = data;
        
    else
        
        % Return the database handle
        varargout{1} = database;
    end
    
% Otherwise, two outputs are requested
elseif nargout == 2 && strcmp(sql(1:6), 'SELECT')
    
    % Return the handle and data
    varargout{1} = database;
    varargout{2} = data;
end
    
% Clear temporary variables
clear sql cursor data tokens cols i;