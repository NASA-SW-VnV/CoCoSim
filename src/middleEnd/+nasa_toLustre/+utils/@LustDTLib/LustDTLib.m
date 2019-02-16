classdef LustDTLib
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
            if LusBackendType.isKIND2(lus_backend)
                abstractedNodes = {};
                import nasa_toLustre.lustreAst.*
                opens = {};
                external_nodes = {};
                % y  <= x < y + 1.0
                contractElts{1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.AND, ...
                    BinaryExpr(BinaryExpr.LTE, ...
                    VarIdExpr('y'),...
                    VarIdExpr('x')),...
                    BinaryExpr(BinaryExpr.LT, ...
                    VarIdExpr('x'),...
                    BinaryExpr(BinaryExpr.PLUS, ...
                    VarIdExpr('y'), ...
                    RealExpr('1.0'), ...
                    false)...
                    ), ...
                    false));
                contract = LustreContract();
                contract.setBodyEqs(contractElts);
                node = LustreNode();
                node.setName('_floor');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, ...
                    UnaryExpr(UnaryExpr.INT, VarIdExpr('x')))));
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
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustDTLib__Ceiling'};
                
                % y - 1.0 < x <= y
                contractElts{1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.AND, ...
                    BinaryExpr(BinaryExpr.LT, ...
                    BinaryExpr(BinaryExpr.MINUS, ...
                    VarIdExpr('y'), ...
                    RealExpr('1.0'), ...
                    false),...
                    VarIdExpr('x')), ...
                    BinaryExpr(BinaryExpr.LTE, ...
                    VarIdExpr('x'),...
                    VarIdExpr('y')),...
                    false));
                contract = LustreContract();
                contract.setBodyEqs(contractElts);
                node = LustreNode();
                node.setName('_ceil');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, ...
                    NodeCallExpr('_Ceiling', VarIdExpr('x')))));
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
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustMathLib_abs_real', 'LustDTLib_Round'};
                % abs(x - y) < 1.0
                contractElts{1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.LTE, ...
                    NodeCallExpr('abs_real', ...
                    BinaryExpr(BinaryExpr.MINUS,...
                    VarIdExpr('x'), ...
                    VarIdExpr('y'), ...
                    false)),...
                    RealExpr('1.0'), ...
                    false));
                contract = LustreContract();
                contract.setBodyEqs(contractElts);
                node = LustreNode();
                node.setName('_round');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, ...
                    NodeCallExpr('_Round', VarIdExpr('x')))));
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
            import nasa_toLustre.lustreAst.*
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
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr.nestedIteExpr(...
                {...
                BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'),RealExpr('0.5')),...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'),RealExpr('-0.5'))...
                },...
                {...
                NodeCallExpr('_floor', VarIdExpr('x')),...
                RealExpr('0.0'),...
                NodeCallExpr('_ceil', VarIdExpr('x'))...
                }));
            
            node = LustreNode();
            node.setMetaInfo('Rounds number to the nearest integer towards zero');
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'real'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
            external_nodes = {strcat('LustDTLib_', '_floor'),...
                strcat('LustDTLib_', '_ceil')};
        end
        
        
    end
    
end

