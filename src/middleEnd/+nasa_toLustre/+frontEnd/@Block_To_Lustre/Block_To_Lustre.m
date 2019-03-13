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
        
        % the code of the block, e.g. a list of nasa_toLustre.lustreAst.LustreEq;
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
        isAbstracted(obj, parent, blk, lus_backend, coco_backend, main_sampleTime, varargin)
    end
    methods
        addVariable(obj, varname, ...
                xml_trace, originPath, port, width, index, isInsideContract, IsNotInSimulink)

        function setVariables(obj, vars)
            obj.variables = vars;
        end

        addUnsupported_options(obj, option)

        addExternal_libraries(obj, lib)

        function setExternal_libraries(obj, lib)
            obj.external_libraries = lib;
        end

        addExtenal_node(obj, nodeAst)
     
        function setCode(obj, code)
            obj.lustre_code = code;
        end

        addCode(obj, code)

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
        
        res = isContentNeedToBeTranslated(obj)

    end
    methods(Static)
        
        % Adapt BlockType to the name of the class that will handle its
        %translation.
        name = blkTypeFormat(name)
        
        % Return if the block has not a class that handle its translation.
        % e.g Inport block is trivial and does not need a code, its name is given
        % in the node signature.
        b = ignored(blk)

        
        %% find_system: look for blocks inside a struct using parameters such as BlcokType, MaskType.
        % e.g blks = Block_To_Lustre.find_blocks(ss, 'BlockType', 'UnitDelay', 'StateName', 'X')
        blks = find_blocks(ss, varargin)
        
    end
    
end

