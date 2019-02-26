function bool = AinB(A,B)
% AINB Determine if string A is an element in cell array B.
%
%   Inputs:
%       A       Character vector.
%       B       Cell array.
%
%   Outputs:
%       bool    Whether A is in B (1), or not(0).
%
%   Examples:
%       AinB('a',{'a','b','c'}) -> true
%       AinB('a',{'abc'})       -> false
%       AinB({'a'},{{'a'}})     -> bad input results not guaranteed
%       AinB('a',{{'a'}})       -> false
%
%   Another method to do this using built-in functions:
%       isempty(find(strcmp(A,B)))

    bool = false;
    if ischar(A) && iscell(B)
        for i = 1:length(B)
            if ischar(B{i}) && strcmp(A,B{i})
                bool = true;
                return
            end
        end
    end
end