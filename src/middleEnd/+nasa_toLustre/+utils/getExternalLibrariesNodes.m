%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
function [ lustre_nodes , open_list, abstractedNodes] = getExternalLibrariesNodes( external_libraries , lus_backend )
    [ lustre_nodes, open_list, abstractedNodes ] = recursive_call( external_libraries, {} ,lus_backend);
    if ~isempty(open_list)
        open_list = unique(open_list);
    end
    if ~isempty(abstractedNodes)
        abstractedNodes = unique(abstractedNodes);
    end
end

function [ lustre_nodes, open_list, abstractedNodes ] = recursive_call( external_libraries, already_handled, lus_backend )
    %GETEXTERNALLIBRARIESNODES returns the lustre nodes and libraries to be add
    %to the head of lustre code.
        
    lustre_nodes = {};
    open_list = {};
    abstractedNodes = {};
    if isempty(external_libraries)
        return;
    end
    
    external_libraries = unique(external_libraries);
    additional_nodes = {};
    for i=1:numel(external_libraries)
        lib = external_libraries{i};
        %if strncmp(lib, 'KIND2MathLib', 12)
        %    lib = strrep(lib, 'KIND2MathLib_', '');
        %    fun_name = sprintf('nasa_toLustre.utils.KIND2MathLib.get_%s',lib);
        %else
        if strncmp(lib, 'LustMathLib', 11)
            lib = strrep(lib, 'LustMathLib_', '');
            fun_name = sprintf('nasa_toLustre.utils.LustMathLib.get_%s',lib);
        elseif strncmp(lib, 'LustDTLib', 9)
            lib = strrep(lib, 'LustDTLib_', '');
            fun_name = sprintf('nasa_toLustre.utils.LustDTLib.get_%s',lib);
        elseif strncmp(lib, 'BlocksLib', 9)
            lib = strrep(lib, 'BlocksLib_', '');
            fun_name = sprintf('nasa_toLustre.utils.BlocksLib.get_%s',lib);
        else
            fun_name = sprintf('nasa_toLustre.utils.ExtLib.get_%s',lib);
        end
        try
            fun_handle = str2func(fun_name);
            [node, external_nodes_i, opens, abstracts] = fun_handle(lus_backend);
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'getExternalLibrariesNodes', '');
            display_msg(sprintf('Library %s not supported', lib),...
                MsgType.ERROR, 'getExternalLibrariesNodes','');
            continue;
        end
        if ischar(node)
            lustre_nodes{end + 1} = nasa_toLustre.lustreAst.RawLustreCode(node, lib);
        else
            lustre_nodes{end + 1} = node;
        end
        open_list = [open_list, opens];
        abstractedNodes = [abstractedNodes, abstracts];
        additional_nodes = [additional_nodes, external_nodes_i];
    end
    
    already_handled = unique([already_handled, external_libraries]);
    additional_nodes = unique(additional_nodes);
    additional_nodes = additional_nodes(~ismember(additional_nodes, already_handled));
    [ additional_code, additional_open_list, additional_abstractedNodes ] = recursive_call( additional_nodes, already_handled,lus_backend );
    lustre_nodes = [additional_code, lustre_nodes];
    open_list = [open_list, additional_open_list];
    abstractedNodes = [abstractedNodes, additional_abstractedNodes];
    
end

