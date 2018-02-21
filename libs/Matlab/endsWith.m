function tf = endsWith(s, pattern)
tf = any(regexp(s, strcat(pattern, '$')));
end



