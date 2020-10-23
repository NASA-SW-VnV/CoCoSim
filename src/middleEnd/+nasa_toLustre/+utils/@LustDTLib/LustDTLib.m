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
classdef LustDTLib

    %LustDTLib This class is a set of Lustre dataType conversions.
    properties
    end
    methods(Static)
        % This functions are defined in the class folder
        %% To and from Bool
        [node, external_nodes, opens, abstractedNodes] = get_real_to_bool(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_bool(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_bool_to_int(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_bool_to_real(varargin)
        %% Int to Int
        [node, external_nodes, opens, abstractedNodes] = get_int_to_int8(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_uint8(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_int16(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_uint16(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_int32(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_uint32(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_int8_saturate(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_uint8_saturate(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_int16_saturate(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_uint16_saturate(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_int32_saturate(varargin)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_uint32_saturate(varargin)
        %%
        [node, external_nodes, opens, abstractedNodes] = get_conv(lus_backend)
        [node, external_nodes, opens, abstractedNodes] = get_int_to_real(lus_backend, varargin)
        [node, external_nodes, opens, abstractedNodes] = get_real_to_int(lus_backend, varargin)
        [node, external_nodes, opens, abstractedNodes] = get__Floor(lus_backend, varargin)
        [node, external_nodes, opens, abstractedNodes] = get__Ceiling(lus_backend, varargin)
        [node, external_nodes, opens, abstractedNodes] = get__Round(lus_backend, varargin)
        [node, external_nodes, opens, abstractedNodes] = get__Convergent(varargin)
        [node, external_nodes, opens, abstractedNodes] = get__Nearest(varargin)
        [node, external_nodes, opens, abstractedNodes] = get__Fix(varargin)
    end
    
    methods(Static)
        %% Methods that has the same name to other e.g. get__fix and get__Fix.
        %% we define one of them here and the other in the class folder
        
        % this one for "Rounding" Simulink block, it is different from Floor by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__floor(lus_backend, varargin)
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
                abstractedNodes = {};
                                opens = {};
                external_nodes = {};
                % y  <= x < y + 1.0
                contractElts{1} = nasa_toLustre.lustreAst.ContractGuaranteeExpr('', ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, ...
                    nasa_toLustre.lustreAst.VarIdExpr('y'),...
                    nasa_toLustre.lustreAst.VarIdExpr('x')),...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
                    nasa_toLustre.lustreAst.VarIdExpr('x'),...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                    nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                    nasa_toLustre.lustreAst.RealExpr('1.0'), ...
                    false)...
                    ), ...
                    false));
                contract = nasa_toLustre.lustreAst.LustreContract();
                contract.setBodyEqs(contractElts);
                node = nasa_toLustre.lustreAst.LustreNode();
                node.setName('_floor');
                node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
                node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'real'));
                %TODO: no need for this contract, implementation is enough.
                %node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.REAL, ...
                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.INT, nasa_toLustre.lustreAst.VarIdExpr('x')))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
        end
        
        
        
        % this one for "Rounding" block, it is different from Ceiling by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__ceil(lus_backend, varargin)
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
                                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustDTLib__Ceiling'};
                
                % y - 1.0 < x <= y
                contractElts{1} = nasa_toLustre.lustreAst.ContractGuaranteeExpr('', ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND, ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
                    nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                    nasa_toLustre.lustreAst.RealExpr('1.0'), ...
                    false),...
                    nasa_toLustre.lustreAst.VarIdExpr('x')), ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, ...
                    nasa_toLustre.lustreAst.VarIdExpr('x'),...
                    nasa_toLustre.lustreAst.VarIdExpr('y')),...
                    false));
                contract = nasa_toLustre.lustreAst.LustreContract();
                contract.setBodyEqs(contractElts);
                node = nasa_toLustre.lustreAst.LustreNode();
                node.setName('_ceil');
                node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
                node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'real'));
                %TODO: no need for this contract, implementation is enough.
                %node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.REAL, ...
                    nasa_toLustre.lustreAst.NodeCallExpr('_Ceiling', nasa_toLustre.lustreAst.VarIdExpr('x')))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
            
        end
        
        
        
        % this one for "Rounding" block, it is different from Round by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__round(lus_backend, varargin)
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend)
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustMathLib_abs_real', 'LustDTLib__Round'};
                % abs(x - y) < 1.0
                contractElts{1} = nasa_toLustre.lustreAst.ContractGuaranteeExpr('', ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, ...
                    nasa_toLustre.lustreAst.NodeCallExpr('abs_real', ...
                    nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
                    nasa_toLustre.lustreAst.VarIdExpr('x'), ...
                    nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                    false)),...
                    nasa_toLustre.lustreAst.RealExpr('1.0'), ...
                    false));
                contract = nasa_toLustre.lustreAst.LustreContract();
                contract.setBodyEqs(contractElts);
                node = nasa_toLustre.lustreAst.LustreNode();
                node.setName('_round');
                node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
                node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'real'));
                %TODO: no need for this contract, implementation is enough.
                %node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.REAL, ...
                    nasa_toLustre.lustreAst.NodeCallExpr('_Round', nasa_toLustre.lustreAst.VarIdExpr('x')))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
            
        end
        
        % this one for "Rounding" block, it is different from Fix by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__fix(varargin)
                        opens = {};
            abstractedNodes = {};
            % format = '--Rounds number to the nearest integer towards zero.\n';
            % format = [ format ,'node _fix (x: real)\nreturns(y:real);\nlet\n\t'];
            % format = [ format , 'y = if (x >= 0.5) then _floor(x)\n\t\t'];
            % format = [ format , ' else if (x > -0.5) then 0.0 \n\t\t'];
            % format = [ format , ' else _ceil(x);'];
            % format = [ format , '\ntel\n\n'];
            % node = sprintf(format);
            
            node_name = '_fix';
            bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
                nasa_toLustre.lustreAst.VarIdExpr('y'), ...
                nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(...
                {...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GTE, nasa_toLustre.lustreAst.VarIdExpr('x'),nasa_toLustre.lustreAst.RealExpr('0.5')),...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, nasa_toLustre.lustreAst.VarIdExpr('x'),nasa_toLustre.lustreAst.RealExpr('-0.5'))...
                },...
                {...
                nasa_toLustre.lustreAst.NodeCallExpr('_floor', nasa_toLustre.lustreAst.VarIdExpr('x')),...
                nasa_toLustre.lustreAst.RealExpr('0.0'),...
                nasa_toLustre.lustreAst.NodeCallExpr('_ceil', nasa_toLustre.lustreAst.VarIdExpr('x'))...
                }));
            
            node = nasa_toLustre.lustreAst.LustreNode();
            node.setMetaInfo('Rounds number to the nearest integer towards zero');
            node.setName(node_name);
            node.setInputs(nasa_toLustre.lustreAst.LustreVar('x', 'real'));
            node.setOutputs(nasa_toLustre.lustreAst.LustreVar('y', 'real'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
            external_nodes = {strcat('LustDTLib_', '_floor'),...
                strcat('LustDTLib_', '_ceil')};
        end
        
        
    end
    
end

