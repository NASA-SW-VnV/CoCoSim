function GraphvizLayout(address)
% GRAPHVIZLAYOUT Perform the layout analysis on the system with Graphviz.
%
%   Inputs:
%       address     System address in which to perform the analysis.
%
%   Outputs:
%       N/A

    %   Implementation Approach:
    %   1) Create the dotfile from the system or subsystem using dotfile_creator.
    %   2) Use autoLayout.bat/.sh to automatically create the graphviz output files.
    %   3) Use Tplainparser class to use Graphviz output to reposition Simulink (sub)system.

    % Get current directory
    if ~isunix
        oldDir = pwd;
        batchDir = mfilename('fullpath');
        numChars = strfind(batchDir, '\');
        if ~isempty(numChars)
            numChars = numChars(end);
            batchDir = batchDir(1:numChars-1);
        end
    else
        oldDir = pwd;
        batchDir = mfilename('fullpath');
        numChars = strfind(batchDir, '/');
        if ~isempty(numChars)
            numChars = numChars(end);
            batchDir = batchDir(1:numChars-1);
        end
    end

    % Change directory to predetermined batch location
    cd(batchDir);

    % 1) Create the dotfile from the system or subsystem using dotfile_creator.
    [filename, map] = dotfile_creator(address);

    % 2) Use autoLayout.bat/.sh to automatically create the graphviz output files.
    if ~isunix
        [~, ~] = system('autoLayout.bat'); % Suppressed output with "[~, ~] ="
    else
        [~, ~] = system('sh autoLayout.sh'); % Suppressed output with "[~, ~] ="
    end

    % 3) Use Tplainparser class to use Graphviz output to reposition Simulink (sub)system.
    % Do the initial layout
    g = TplainParser(address, filename, containers.Map());
    g.plain_wrappers;

    % Delete unneeded files
    dotfilename = [filename '.dot'];
    delete(dotfilename);
    plainfilename = [filename '-plain.txt'];
    pdffilename = [filename '.pdf'];
    delete(plainfilename);
    delete(pdffilename);

    % Change directory back
    cd(oldDir);
end