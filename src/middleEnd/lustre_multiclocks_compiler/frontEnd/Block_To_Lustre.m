classdef Block_To_Lustre < handle
    %Block_To_Lustre an interface for all write blocks classes. Any BlockType_write
    %class inherit from this class.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        
        % the code of the block, e.g. a list of LustreEq;
        lustre_code = {};
        
        %The list of variables to be added to node variables list.
        variables = {};% list of LustreVar
        
        %external_libraries defines the list of used nodes, as int_to_int16
        %..., this nodes will be added in the head of the lustre file
        external_libraries = {};
        
        %external_nodes is nodes specific to this block and they are not
        %libraries used by more than one block. Use external_libraries
        %in case the node name is not unique.
        % Example: some block can be coded in many nodes, a main node and
        % some useful nodes. Make sure those useful nodes have unique name.
        external_nodes = {}; %List of LustreNode
        
        %unsupported_options are the options in the corresponding block
        %that are not supported in the translation. This options are the
        %Dialogue parameters specified by the user. Like DataType
        %conversion ...
        unsupported_options = {};%List of String
        
        %For masked Subsystems, they will be treated as normal Subsystem
        %(so they will be defined as external node). To disable this
        %behavior set this attribute to False. So you can define the
        %definition of the Masked SS in MaskType_To_Lustre.
        ContentNeedToBeTranslated = 1;
        
        
        
    end
    
    methods (Abstract)
        %these functions should be implemented by all classes inherit from
        %this class
        write_code(obj, parent, blk, xml_trace,...
            lus_backend, coco_backend, main_sampleTime, varargin)
        getUnsupportedOptions(obj, parent, blk, ...
            lus_backend, coco_backend, main_sampleTime, varargin)
        isAbstracted(obj, lus_backend, parent, blk, main_sampleTime, varargin)
    end
    methods
        function addVariable(obj, varname, ...
                xml_trace, originPath, port, width, index, isInsideContract, IsNotInSimulink)
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
        function setVariables(obj, vars)
            obj.variables = vars;
        end
        function addUnsupported_options(obj, option)
            if iscell(option)
                obj.unsupported_options = [obj.unsupported_options, option];
            else
                obj.unsupported_options{numel(obj.unsupported_options) +1} = option;
            end
        end
        function addExternal_libraries(obj, lib)
            if iscell(lib)
                obj.external_libraries = [obj.external_libraries, lib];
            elseif ~ischar(lib) && numel(lib) > 1
                for i=1:numel(lib)
                    obj.external_libraries{end +1} = lib(i);
                end
            else
                obj.external_libraries{end +1} = lib;
            end
        end
        function setExternal_libraries(obj, lib)
            obj.external_libraries = lib;
        end
        function addExtenal_node(obj, nodeAst)
            if iscell(nodeAst)
                obj.external_nodes = [obj.external_nodes, nodeAst];
            elseif ~ischar(nodeAst) && numel(nodeAst) > 1
                for i=1:numel(nodeAst)
                    obj.external_nodes{end +1} = nodeAst(i);
                end
            else
                obj.external_nodes{end +1} = nodeAst;
            end
        end
        
        function setCode(obj, code)
            obj.lustre_code = code;
        end
        function addCode(obj, code)
            if iscell(code)
                obj.lustre_code = [obj.lustre_code, code];
            elseif ~ischar(code) && numel(code) > 1
                for i=1:numel(code)
                    obj.lustre_code{end +1} = code(i);
                end
            else
                obj.lustre_code{end +1} = code;
            end
        end
        % Getters
        function code = getCode(obj)
            code = obj.lustre_code;
        end
        function variables = getVariables(obj)
            variables = obj.variables;
        end
        function res = getExternalLibraries(obj)
            res = obj.external_libraries;
        end
        function res = getExternalNodes(obj)
            res = obj.external_nodes;
        end
        function res = isContentNeedToBeTranslated(obj)
            res = obj.ContentNeedToBeTranslated;
        end
    end
    methods(Static)
        
        % Adapt BlockType to the name of the class that will handle its
        %translation.
        function name = blkTypeFormat(name)
            name = strrep(name, ' ', '');
            name = strrep(name, '-', '');
        end
        
        % Return if the block has not a class that handle its translation.
        % e.g Inport block is trivial and does not need a code, its name is given
        % in the node signature.
        function b = ignored(blk)
            % add blocks that will be ignored because they are supported
            % somehow implicitly or not important for Code generation and Verification.
            blksIgnored = {'Inport', 'Terminator', 'Scope', 'Display', ...
                'EnablePort','ActionPort', 'ResetPort', 'TriggerPort', ...
                'ToWorkspace', 'DataTypeDuplicate', ...
                'Data Type Propagation'};
            % the list of block without outputs but should be translated to
            % Lustre.
            blksWithNoOutputsButNotIgnored = {...
                'Outport',...
                'Design Verifier Assumption', ...
                'Design Verifier Proof Objective', ...
                'Assertion', ...
                'VerificationSubsystem'};
            type = blk.BlockType;
            try
                masktype = blk.MaskType;
            catch
                masktype = '';
            end
            hasNoOutpot = ...
                isfield(blk, 'CompiledPortWidths') && isempty(blk.CompiledPortWidths.Outport);
            b = ismember(type, blksIgnored) ...
                || ismember(masktype, blksIgnored)...
                || ...
                (~ismember(type, blksWithNoOutputsButNotIgnored) ...
                && ~ismember(masktype, blksWithNoOutputsButNotIgnored) ...
                && hasNoOutpot);
        end
        
        %% find_system: look for blocks inside a struct using parameters such as BlcokType, MaskType.
        % e.g blks = Block_To_Lustre.find_blocks(ss, 'BlockType', 'UnitDelay', 'StateName', 'X')
        function blks = find_blocks(ss, varargin)
            blks = {};
            doesMatch = true;
            for i=1:2:numel(varargin)
                if ~(isfield(ss, varargin{i}) && isequal(ss.BlockType, varargin{i+1}))
                    doesMatch = false;
                    break;
                end
            end
            if doesMatch
                blks{1} = ss;
            end
            if isfield(ss, 'Content') && ~isempty(ss.Content)
                field_names = fieldnames(ss.Content);
                for i=1:numel(field_names)
                    blks_i = Block_To_Lustre.find_blocks(ss.Content.(field_names{i}), varargin{:});
                    blks = [blks, blks_i];
                end
            end
            
        end
        
    end
    
end

