function report = parseLustrecErrorMessage(message, msg_type)
    %PARSELUSTRECERRORMESSAGE tries to report why lustrec failed based on its
    %output
    report = '';
    
    if ~isempty(regexp(message, 'Raised at file "parsing.ml", line', 'match', 'once'))
        report = 'Lustrec Failed because of a syntax error.';
    end
    
    if nargin > 2
        %print report
        display_msg(report, msg_type, 'parseLustrecErrorMessage', '');
    end
end

