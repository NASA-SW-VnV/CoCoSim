%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% Concat cell array with a specific delimator
function joinedStr = strjoin(str, delimiter)
    if nargin < 1 || nargin > 2
        narginchk(1, 2);
    end

    strIsCellstr = iscellstr(str);

    % Check input arguments.
    if ~strIsCellstr
        error(message('MATLAB:strjoin:InvalidCellType'));
    end

    numStrs = numel(str);

    if nargin < 2
        delimiter = {' '};
    elseif ischar(delimiter)
        delimiter = {strescape(delimiter)};
    elseif iscellstr(delimiter) || isstring(delimiter)
        numDelims = numel(delimiter);
        if numDelims ~= 1 && numDelims ~= numStrs-1
            error(message('MATLAB:strjoin:WrongNumberOfDelimiterElements'));
        elseif strIsCellstr && isstring(delimiter)
            delimiter = cellstr(delimiter);
        end
        delimiter = reshape(delimiter, numDelims, 1);
    else
        error(message('MATLAB:strjoin:InvalidDelimiterType'));
    end

    str = reshape(str, numStrs, 1);

    if numStrs == 0
        joinedStr = '';
    else
        joinedCell = cell(2, numStrs);
        joinedCell(1, :) = str;
        joinedCell(2, 1:numStrs-1) = delimiter;

        joinedStr = [joinedCell{:}];
    end
end
function str = strescape(str)
    %STRESCAPE  Escape control character sequences in a string.
    %   STRESCAPE(STR) converts the escape sequences in a string to the values
    %   they represent.
    %
    %   Example:
    %
    %       strescape('Hello World\n')
    %
    %   See also SPRINTF.

    %   Copyright 2012-2015 The MathWorks, Inc.

    if iscell(str)
        str = cellfun(@(c) strescape(c), str, 'UniformOutput', false);
    else
        idx = 1;
        % Note that only [1:end-1] of the string is checked,
        % since unescaped trailing backslashes are ignored.
        while idx < length(str)
            if str(idx) == '\'
                str(idx) = [];  % Remove the '\' escape character itself.
                str(idx) = escapeChar(str(idx));
            end
            idx = idx + 1;
        end
    end

end

function c = escapeChar(c)
    switch c
        case '0'  % Null.
            c = char(0);
        case 'a'  % Alarm.
            c = char(7);
        case 'b'  % Backspace.
            c = char(8);
        case 'f'  % Form feed.
            c = char(12);
        case 'n'  % New line.
            c = char(10);
        case 'r'  % Carriage return.
            c = char(13);
        case 't'  % Horizontal tab.
            c = char(9);
        case 'v'  % Vertical tab.
            c = char(11);
        case '\'  % Backslash.
            c = '\';
        otherwise
            warning(message('MATLAB:strescape:InvalidEscapeSequence', c, c));
    end
end
        
