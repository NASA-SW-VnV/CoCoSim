classdef MF_To_LustreNode
    %MF_To_LustreNode translates a MATLAB Function to Lustre node
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        function [main_node, external_nodes, external_libraries ] = ...
                mfunction2node(parent,  blk,  xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
            L = nasa_toLustre.ToLustreImport.L;
            import(L{:})
            external_nodes = {};
            external_libraries = {};
            % get Matlab Function parameters
            is_main_node = false;
            isEnableORAction = false;
            isEnableAndTrigger = false;
            isContractBlk = false;
            isMatlabFunction = true;
            blk = MF_To_LustreNode.creatInportsOutports(blk);
            [node_name, node_inputs, node_outputs,...
                ~, ~] = ...
                nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent, blk, is_main_node,...
                isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
                main_sampleTime, xml_trace);
            %script = blk.Script;
            comment = LustreComment(...
                sprintf('Original block name: %s', blk.Origin_path), true);
            main_node = LustreNode(...
                comment, ...
                node_name,...
                node_inputs, ...
                node_outputs, ...
                {}, ...
                {}, ...
                {}, ...
                false);
            main_node.setIsImported(true);
            
        end
        
        function blk = creatInportsOutports(blk)
            content = struct();
            Inputs = blk.Inputs;
            Outputs = blk.Outputs;
            for i=1:numel(Inputs)
                in = Inputs{i};
                port = in.Port;
                in.Port = num2str(port);%as Inport
                in.BlockType = 'Inport';
                in.Origin_path = fullfile(blk.Origin_path, in.Name);
                in.Path = fullfile(blk.Path, in.Name);
                in.CompiledPortWidths.Outport = blk.CompiledPortWidths.Inport(port);
                in.CompiledPortWidths.Inport = [];
                in.CompiledPortDataTypes.Outport = blk.CompiledPortDataTypes.Inport(port);
                in.CompiledPortDataTypes.Inport = {};
                in.BusObject = '';
                content.(in.Name) = in;
            end
            for i=1:numel(Outputs)
                out = Outputs{i};
                port = out.Port;
                out.Port = num2str(port);%as Outport
                out.BlockType = 'Outport';
                out.Origin_path = fullfile(blk.Origin_path, out.Name);
                out.Path = fullfile(blk.Path, out.Name);
                out.CompiledPortWidths.Inport = blk.CompiledPortWidths.Outport(port);
                out.CompiledPortWidths.Outport = [];
                out.CompiledPortDataTypes.Inport = blk.CompiledPortDataTypes.Outport(port);
                out.CompiledPortDataTypes.Outport = {};
                out.BusObject = '';
                content.(out.Name) = out;
            end
            blk.Content = content;
        end
    end
    
    
    
end

