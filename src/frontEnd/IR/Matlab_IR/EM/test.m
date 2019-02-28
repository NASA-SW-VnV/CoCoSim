
function [mean,stdev] = stats(vals)
% #codegen

% calculates a statistical mean and a standard
% deviation for the values in vals.

%len = length(vals);
%mean = avg(vals,len);
%stdev = sqrt(sum(((vals-avg(vals,len)).^2))/len);
coder.extrinsic('plot');
%plot(vals,'-+');

%function mean = avg(array,size)
%mean = sum(array)/size;
%end