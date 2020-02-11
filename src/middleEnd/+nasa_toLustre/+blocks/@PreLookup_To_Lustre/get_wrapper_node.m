%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function extNode =  get_wrapper_node(...
    ~,blk, inputs, outputs,preLookUpExtNode,blkParams)

%    % PreLookup
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
              
    % wrapper header
    wrapper_header.NodeName = sprintf('%s_PreLookup_wrapper_ext_node',blk_name);
    % wrapper inputs
    wrapper_header_input_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('coord_input');
    wrapper_header.Inputs{1} = nasa_toLustre.lustreAst.LustreVar(...
        wrapper_header_input_name{1}, 'real');
    
    if blkParams.bpIsInputPort
        wrapper_header_input_name = [wrapper_header_input_name, inputs{2}];
        inputs2_dt = cellfun(@(x) nasa_toLustre.lustreAst.LustreVar(x.getId(), 'real'), inputs{2}, 'UniformOutput', false); 
        wrapper_header.Inputs = [wrapper_header.Inputs, inputs2_dt];
    end
    % wrapper outputs
    wrapper_output_names{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr(outputs{1}.id);
    wrapper_output_vars{1} = nasa_toLustre.lustreAst.LustreVar(...
        wrapper_output_names{1}, 'int');

    % preLookupOut
    prelookup_out{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('inline_index_bound_node_1');
    local_vars{1} = nasa_toLustre.lustreAst.LustreVar(...
        prelookup_out{1}, 'int');
    
    if ~blkParams.OutputIndexOnly
        wrapper_output_names{2} = ...
            nasa_toLustre.lustreAst.VarIdExpr(outputs{2}.id);
        wrapper_output_vars{2} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            wrapper_output_names{2}, 'real');
        
        % prelookup out puts
        prelookup_out{2} = ...
            nasa_toLustre.lustreAst.VarIdExpr('shape_bound_node_1');
        prelookup_out{3} = ...
            nasa_toLustre.lustreAst.VarIdExpr('inline_index_bound_node_2');
        prelookup_out{4} = ...
            nasa_toLustre.lustreAst.VarIdExpr('shape_bound_node_2');
        local_vars{2} = nasa_toLustre.lustreAst.LustreVar(...
            prelookup_out{2}, 'real');
        local_vars{3} = nasa_toLustre.lustreAst.LustreVar(...
            prelookup_out{3}, 'int');
        local_vars{4} = nasa_toLustre.lustreAst.LustreVar(...
            prelookup_out{4}, 'real');                
    end
    wrapper_header.Outputs = wrapper_output_vars;       
    % call prelookup
    body{1} = ...
        nasa_toLustre.lustreAst.LustreEq(prelookup_out, ...
        nasa_toLustre.lustreAst.NodeCallExpr(...
        preLookUpExtNode.name, wrapper_header_input_name));
    % defining k, which is index at node 1 - 1 (0 base)
    % if UseLastBreakpoint, and x_in beyond last breakpoint, then
    % use last breakpoint
    
    %TODO : When "~blkParams.OutputIndexOnly" is false, prelookup_out{2}, {3}
    %and {4} are not defined. But you use them in the following code when "strcmp(blkParams.UseLastBreakpoint, 'on') " is true.
    % See test "preLookupTestGen11.slx"
    
    % correct blkParams.UseLastBreakpoint
%    if strcmp(blkParams., 'on')
    
    
    
    if strcmp(blkParams.UseLastBreakpoint, 'on') && ~blkParams.OutputIndexOnly 
        
        epsilon = ...
            nasa_toLustre.blocks.Lookup_nD_To_Lustre.calculate_eps(...
            blkParams.BreakpointsForDimension{1}, 1);
        cond_w2_eq_1 =  ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.LT, ...
            prelookup_out{4},nasa_toLustre.lustreAst.RealExpr(1.), [], ...
            LusBackendType.isLUSTREC(blkParams.lus_backend), epsilon);
        then_low_index = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
            prelookup_out{1},...
            nasa_toLustre.lustreAst.IntExpr(1));
        else_high_index = nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
            prelookup_out{3},...
            nasa_toLustre.lustreAst.IntExpr(1));      
        
        rhs = nasa_toLustre.lustreAst.IteExpr(cond_w2_eq_1,...
            then_low_index,else_high_index);
        
        body{2} = nasa_toLustre.lustreAst.LustreEq(...
            wrapper_output_names{1}, rhs);        
    else 
        body{2} = nasa_toLustre.lustreAst.LustreEq(...
            wrapper_output_names{1}, ...
            nasa_toLustre.lustreAst.BinaryExpr(...
            nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
            prelookup_out{1},...
            nasa_toLustre.lustreAst.IntExpr(1)));
    end
    if ~blkParams.OutputIndexOnly
        if strcmp(blkParams.UseLastBreakpoint, 'on')  
            body{3} = ...
                nasa_toLustre.lustreAst.LustreEq(wrapper_output_names{2}, ...
                nasa_toLustre.lustreAst.IteExpr(cond_w2_eq_1,...
                prelookup_out{4},prelookup_out{2}));
        else
            % defining fraction, which is shape value at node 2
            body{3} = ...
                nasa_toLustre.lustreAst.LustreEq(wrapper_output_names{2}, ...
                prelookup_out{4});
        end
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(wrapper_header.NodeName)
    extNode.setInputs(wrapper_header.Inputs);
    extNode.setOutputs( wrapper_header.Outputs);
    extNode.setLocalVars(local_vars);
    extNode.setBodyEqs(body);
    extNode.setMetaInfo('external node code wrapper for doing PreLookup');

end

