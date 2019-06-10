%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function xRoot = getxRoot(xml_trace_var)
    if ischar(xml_trace_var) && exist(xml_trace_var, 'file')
        try
            DOMNODE = xmlread(xml_trace_var);
            xRoot = DOMNODE.getDocumentElement;
        catch
            xRoot = [];
        end
    elseif isa(xml_trace_var, 'nasa_toLustre.utils.SLX2Lus_Trace')
        xRoot = xml_trace_var.traceRootNode;
    elseif isa(xml_trace_var, 'org.apache.xerces.dom.ElementNSImpl')
        xRoot = xml_trace_var;
    else
        xRoot = [];
    end
end
