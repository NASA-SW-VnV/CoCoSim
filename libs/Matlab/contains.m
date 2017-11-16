function tf = contains(s, pattern, varargin)
tf = ~isempty(strfind(s, pattern));
end