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

function [x2, y2] = instrs_process(nodes, new_model_name, node_block_path, ...
    blk_exprs, node_name,  x2, y2, xml_trace)
    for var = fieldnames(blk_exprs)'
        try
            switch blk_exprs.(var{1}).kind
                case 'arrow' % lhs = True -> False;
                    [x2, y2] = Lus2SLXUtils.process_arrow(node_block_path, ...
                        blk_exprs, var, node_name,  x2, y2);

                case 'pre' % lhs = pre rhs;
                    [x2, y2] = Lus2SLXUtils.process_pre(node_block_path, ...
                        blk_exprs, var, node_name, x2, y2);

                case 'local_assign' % lhs = rhs;
                    [x2, y2] = Lus2SLXUtils.process_local_assign(node_block_path, ...
                        blk_exprs, var, node_name,  x2, y2);

                case 'reset' % lhs = rhs;
                    [x2, y2] = Lus2SLXUtils.process_reset(node_block_path, ...
                        blk_exprs, var, node_name,  x2, y2);

                case 'operator'
                    [x2, y2] = Lus2SLXUtils.process_operator(node_block_path, ...
                        blk_exprs, var, node_name, x2, y2);

                case {'statelesscall', 'statefulcall'}
                    [x2, y2] = Lus2SLXUtils.process_node_call(nodes, ...
                        new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);

                case 'functioncall'
                    [x2, y2] = Lus2SLXUtils.process_functioncall( ...
                        node_block_path, blk_exprs, var, node_name, x2, y2);
                case 'branch'
                    [x2, y2] = Lus2SLXUtils.process_branch(nodes, ...
                        new_model_name, node_block_path, blk_exprs, var, node_name, x2, y2, xml_trace);
                otherwise
                    display_msg(['couldn''t translate expression ' ...
                        var{1} ' to Simulink'], MsgType.ERROR, 'LUS2SLX', '');
                    ME = MException('MyComponent:noSuchVariable', ...
                        'Translation of node %s failed', node_name);
                    throw(ME);
            end
        catch ME
            display_msg(['couldn''t translate expression ' var{1} ' to Simulink'], ...
                MsgType.ERROR, 'LUS2SLX', '');
            display_msg(ME.getReport(), MsgType.DEBUG, 'LUS2SLX', '');
            %         continue;
            rethrow(ME)
        end
    end
end
