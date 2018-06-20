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
        
        % the code of the block, e.g. outputs = block_name(inputs);
        lustre_code = '';
        
        %The list of variables to be added to node variables list.
        variables = {};
        
        %external_libraries defines the list of used nodes, as int_to_int16
        %..., this nodes will be added in the head of the lustre file
        external_libraries = {};
        
        %external_nodes is nodes specific to this block and they are not
        %libraries used by more than one block. Use external_libraries
        %in case the node name is not unique.
        % Example: some block can be coded in many nodes, a main node and
        % some useful nodes. Make sure those useful nodes have unique name.
        external_nodes = '';
        
        %unsupported_options are the options in the corresponding block
        %that are not supported in the translation. This options are the
        %Dialogue parameters specified by the user. Like DataType
        %conversion ...
        unsupported_options = {};
    end
    
    methods (Abstract)
        %these functions should be implemented by all classes inherit from
        %this class
        write_code(obj, parent, blk, xml_trace, main_sampleTime, varargin)
        getUnsupportedOptions(obj, parent, blk, main_sampleTime, xml_trace, varargin)
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
                        xml_trace.add_InputOutputVar('Variable', varname{i}, originPath, port, width, i, isInsideContract, IsNotInSimulink);
                    end
                else
                    xml_trace.add_InputOutputVar('Variable', varname, originPath, port, width, index, isInsideContract, IsNotInSimulink);
                end
            end
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
            else
                obj.external_libraries{numel(obj.external_libraries) +1} = lib;
            end
        end
        function addExtenal_node(obj, node_code)
            obj.external_nodes = sprintf('%s\n%s', ...
                obj.external_nodes, node_code);
        end
        function setCode(obj, code)
            obj.lustre_code = code;
        end
        
        function code = getCode(obj)
            code = obj.lustre_code;
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
            % add blocks that will be ignored because they are supported somehow implicitly or not important for Code generation adn Verification.
            blksNames = {'Inport', 'Terminator', 'Scope', 'Display', ...
                'EnablePort','ActionPort', 'ResetPort', 'TriggerPort', 'ToWorkspace', ...
                'DataTypeDuplicate', 'Data Type Propagation'};
            type = blk.BlockType;
            try
                masktype = sub_blk.MaskType;
            catch
                masktype = '';
            end
            
            b = ismember(type, blksNames) || ismember(masktype, blksNames)...
                || (~strcmp(type, 'Outport') ...
                && isfield(blk, 'CompiledPortWidths') && isempty(blk.CompiledPortWidths.Outport));
        end
    end
    
    
    
end

