function h = new_system_makenameunique(baseName, varargin)
% NEW_SYSTEM_MAKENAMEUNIQUE new_system command except that it appends a
%   number to the name to ensure a file with the name does not exist.
%
%   For more information about new_system, type: "help new_system" at the
%   command line.

    name = baseName;
    % exist returns 4 if the file is a Simulink model or a library file
    if exist(name, 'file') == 4
        n = 1;
        while exist(strcat(name, num2str(n)), 'file') == 4
            n = n + 1;
        end
        name = strcat(name, num2str(n));
    end

    h = new_system(name,varargin{:});
end