function [status, stdout, stderr] = system_timeout(varargin)
    % system_timeout - Execute a command on the host operating system
    %
    %   This function is very similar to Matlab's builtin SYSTEM function
    %   with the exception that it provides a way for the user to specify a
    %   timeout time (in seconds) after which the function will error out.
    %
    %
    % USAGE:
    %   [status, stdout, stderr] = cmd(command, *timeout)
    %
    % INPUTS:
    %   command:    String, Command to be evaluated by the host OS
    %
    %   timeout:    Integer, (Optional) Number of seconds to wait for the
    %               process to complete. A value of either 0 or Inf
    %               indicates that there is no timeout (Default = 0)
    %
    % OUTPUTS;
    %   status:     Integer, Exit code returned by the process. Typically a
    %               value of 0 indicates that the process completed without
    %               error while a non-zero value indicates some sort of
    %               error.
    %
    %   stdout:     String, Output from the process that was printed to
    %               standard output.
    %
    %   stderr:     String, Output from the process that was printed to
    %               standard error buffer. Can be used in case of a
    %               non-zero return code to determine what type of error
    %               occurred.
    %
    % See also SYSTEM, UNIX, DOS
    %
    % Last Modified: 08-15-2014
    % Modified By: Jonathan Suever (suever@gmail.com)

    % Copyright (c) 2014, Jonathan Suever
    % All rights reserved.
    %
    % This software may be modified and distributed under the terms of the
    % BSD license. See the LICENSE file for details.

    % Check that java is running since we rely upon it
    if ~usejava('jvm')
        error(sprintf('%s:JavaUnavailable', mfilename), ...
            'Java is not currently running');
    end

    ip = inputParser();
    ip.addRequired('Command', @ischar);
    ip.addOptional('Timeout', Inf, @(x)isscalar(x) && isnumeric(x))
    ip.parse(varargin{:});

    % Convert to milliseconds
    timeout = ip.Results.Timeout * 1000;

    % Setup the java runtime so that we can control the process
    runtime = java.lang.Runtime.getRuntime();
    process = runtime.exec(ip.Results.Command);

    if timeout <= 0 || isinf(timeout)
        % If no timeout was specified then just wait for it to complete
        status = process.waitFor();
    else
        % Figure out what time this process should be done
        curtime = @java.lang.System.currentTimeMillis;
        endtime = curtime() + timeout;

        % Loop until it is completed (check 100 times a second)
        while (isRunning(process) && (curtime() < endtime))
            pause(1e-2);
        end

        % If the process is still alive then we need to terminate it
        if isRunning(process)
            % Store the output so the user can see the progress
            stdout = getOutput(process);
            process.destroy()

            % Print an error message indicating a timeout event
            msg = sprintf('Process timeout after %d seconds.',timeout/1000);

            % Append stdout to the error message
            if ~isempty(stdout)
                msg = strcat(msg, '\n\n', 'OUTPUT:\n', stdout);
            end

            error(sprintf('%s:OperationTimedOut', mfilename), msg)
        end

        % Return the status code upon successful completion
        status = process.exitValue();
    end

    % Grab the stdout and stderr buffers
    [stdout, stderr] = getOutput(process);

    % Make sure it's good and dead
    process.destroy();
end

function [stdout, stderr] = getOutput(process)
    % getOutput - Get stdout and stderr as character arrays
    %
    % USAGE:
    %   [stdout, stderr] = getOutput(process)

    stdout = stream2char(process.getInputStream);
    stderr = stream2char(process.getErrorStream);
end

function out = stream2char(stream)
    % stream2char - Convert InputStream and ErrorStream to character array
    %
    % USAGE:
    %   str = stream2char(stream)

    out = char(arrayfun(@(x)char(stream.read), 1:stream.available));
end

function bool = isRunning(process)
    % isRunning - Quick and dirty way to check if the process is running
    %
    % USAGE:
    %   bool = isRunning(process)

    % Operates under the assumption that process.exitValue() will result in
    % an IllegalThreadStateException if the process is still running
    try
        process.exitValue();
        bool = false;
    catch
        bool = true;
    end
end
