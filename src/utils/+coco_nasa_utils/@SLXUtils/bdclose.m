function bdclose(last_closed_model)
    %BDCLOSE is a wrapper of bdclose('all')
    if nargin < 1
        last_closed_model = '';
    end
    try
        bdclose('all');
    catch me
        matlabOpenFormat = 'matlab:open\w+\s*\(''([^''])+''';
        if strcmp(me.identifier, 'Simulink:Engine:InvModelClose')
            tokens = regexp(me.message, matlabOpenFormat, 'tokens', 'once');
            if isempty(tokens)
                return
            end
            SLXUtils.terminate(tokens{1});
            if ~strcmp(tokens{1}, last_closed_model)
                SLXUtils.bdclose(tokens{1});
                return
            end
        end
        rethrow(me)
    end
end

