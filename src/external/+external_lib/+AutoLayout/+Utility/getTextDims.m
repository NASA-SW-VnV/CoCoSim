function dims = getTextDims(string, fontName, fontSize, varargin)
% GETTEXTDIMS Get dimensions of string ([width, height]).
%
%   Inputs:
%       string      A character array.
%       fontName    The name of the font that string is written in.
%       fontSize    The size of the font that string is written in.
%       varargin    Indicates what system to create the annotation in. If
%                   not set, a system will be created and later deleted
%                   (this is slow). Otherwise varargin should be a char
%                   array of a system path that is open.
%
%   Outputs:
%       dims        Dimensions of the string given as [width, height].

    % Check number of arguments
    try
        assert(nargin == 3 || nargin == 4)
    catch
        error(['Error using ' mfilename ':' char(10) ...
            ' Wrong number of arguments.' char(10)])
    end

    % Check fontSize argument
    try
        assert(fontSize > 0);
    catch
        error(['Error using ' mfilename ':' char(10) ...
            ' Invalid argument: fontSize. Value must be greater than 0.' char(10)])
    end

    % Create annotation for the text, get its bounds, then undo
    if nargin == 4
        % Create annotation in given system
        name = varargin{1};
        [handle, bounds] = createNoteGetDims();
        delete(handle)
    else
        % Create dummy model for the system and create annotation
        name = new_system_makenameunique('TempToFindTextSize');
        open_system(name)
        [~, bounds] = createNoteGetDims();
        close_system(name, 0)
    end

    dims = bounds(3:4) - bounds(1:2);

    function [hdl, bnds] = createNoteGetDims()
        % Create note, then get dimensions
        hdl = add_block('built-in/Note', [name '/annotation'], ...
            'Text', string, 'FontName', fontName, 'FontSize', fontSize);
        ob = get_param(hdl, 'Object');
        bnds = ob.getBounds;
    end
end

%% Old method - did not always get correct values for unknown reasons
% % Create the text in a figure and check the size of that
% testFig = figure;
% uicontrol(testFig)
% x = uicontrol('Style', 'text', 'FontName', fontName, 'FontSize', fontSize);
% set(x, 'String', string);
% size = get(x, 'extent');
% height = size(4)-size(2);
% width = size(3)-size(1);
% close(testFig);