function addVariable(obj, varname, ...
        xml_trace, originPath, port, width, index, isInsideContract, IsNotInSimulink)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    if iscell(varname)
        obj.variables = [obj.variables, varname];
    else
        obj.variables{end +1} = varname;
    end
    if nargin >= 3
        if iscell(varname)
            for i=1:numel(varname)
                xml_trace.add_InputOutputVar('Variable', varname{i}.getId(), originPath, port, width, i, isInsideContract, IsNotInSimulink);
            end
        else
            xml_trace.add_InputOutputVar('Variable', varname.getId(), originPath, port, width, index, isInsideContract, IsNotInSimulink);
        end
    end
end
