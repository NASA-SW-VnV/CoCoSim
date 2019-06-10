function [display] = get_observer_display()
    %% Returns the Display parameter value for the Observer block
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    display = sprintf('color(''red'')\n');
    display = [display sprintf('text(0.5, 0.5, [''CoCoSpec: '''''' get_param(gcb,''name'') ''''''''], ''horizontalAlignment'', ''center'');\n')];
    display = [display 'text(0.99, 0.03, ''{\bf\fontsize{12}'];
    display = [display char('INVARIANT')];
    display = [display '}'', ''hor'', ''right'', ''ver'', ''bottom'', ''texmode'', ''on'');'];
end
