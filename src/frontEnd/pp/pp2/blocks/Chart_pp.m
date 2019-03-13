function [status, errors_msg] = Chart_pp( model )
%CHART_PROCESS change Action Language of the chart from C to Matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = 0;
errors_msg = {};

rt = sfroot;
m = rt.find('-isa','Stateflow.Machine','Name',model);
chartArr = m.find('-isa','Stateflow.Chart');
if not(isempty(chartArr))
    display_msg('Processing Charts...', Constants.INFO, 'Chart_pp', '');
    for i=1:numel(chartArr)
        try
            chart = chartArr(i);
            display_msg(chart.Name, Constants.INFO, 'Chart_pp', '');
            chart.set('ActionLanguage', 'MATLAB');
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('Chart pre-process has failed for block %s', chartArr(i).Name);
            continue;
        end
    end
    display_msg('Done\n\n', Constants.INFO, 'Chart_pp', '');
end

end

