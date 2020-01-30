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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [main_node, external_nodes, external_libraries] = ...
        stateflowCode(ss_ir, xml_trace)
    %% Statflow support: use old compiler from github

       
    %
    %
    external_nodes = {};
    external_libraries = {};
    rt = sfroot;
    m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name',bdroot(ss_ir.Origin_path));
    chart = m.find('-isa','Stateflow.Chart', 'Path', ss_ir.Origin_path);
    [ char_node, extern_Stateflow_nodes_fun] = write_Chart( chart, 0, xml_trace,'' );
    node_name = get_full_name( chart, true );
    main_node = nasa_toLustre.lustreAst.RawLustreCode(sprintf(char_node), node_name);
    if isempty(extern_Stateflow_nodes_fun)
        return;
    end
    [~, I] = unique({extern_Stateflow_nodes_fun.Name});
    extern_Stateflow_nodes_fun = extern_Stateflow_nodes_fun(I);
    for i=1:numel(extern_Stateflow_nodes_fun)
        fun = extern_Stateflow_nodes_fun(i);
        if strcmp(fun.Name,'trigo')
            external_libraries{end + 1} = 'LustMathLib_lustrec_math';
        elseif strcmp(fun.Name,'lustre_math_fun')
            external_libraries{end + 1} = 'LustMathLib_lustrec_math';
        elseif strcmp(fun.Name,'lustre_conv_fun')
            external_libraries{end + 1} = 'LustDTLib_conv';
        elseif strcmp(fun.Name,'after')
            external_nodes{end + 1} = nasa_toLustre.lustreAst.RawLustreCode(sprintf(temporal_operators(fun)), 'after');
        elseif strcmp(fun.Name, 'min') && strcmp(fun.Type, 'int*int')
            external_libraries{end + 1} = 'LustMathLib_min_int';
        elseif strcmp(fun.Name, 'min') && strcmp(fun.Type, 'real*real')
            external_libraries{end + 1} = 'LustMathLib_min_real';
        elseif strcmp(fun.Name, 'max') && strcmp(fun.Type, 'int*int')
            external_libraries{end + 1} = 'LustMathLib_max_int';
        elseif strcmp(fun.Name, 'max') && strcmp(fun.Type, 'real*real')
            external_libraries{end + 1} = 'LustMathLib_max_real';
        end
    end
end


