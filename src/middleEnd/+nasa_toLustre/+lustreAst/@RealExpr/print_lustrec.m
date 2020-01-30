function code = print_lustrec(obj)

    code = sprintf('%.15f', obj.getValue());
    %3.43040000 => 3.4304 code has always "." in it
    code = regexprep(code, '0+$', '0');
end
