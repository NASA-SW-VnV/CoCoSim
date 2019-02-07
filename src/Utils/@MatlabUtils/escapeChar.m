
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
        
