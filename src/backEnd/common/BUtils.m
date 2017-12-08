classdef BUtils
    %BUTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static = true)
        
        function [obs_pos] = get_obs_position(parent_subsystem)
            blocks = find_system(parent_subsystem, 'SearchDepth', '1', 'FindAll', 'on', 'Type', 'Block');
            positions = get_param(blocks, 'Position');
            max_x = 0;
            min_x = 0;
            max_y = 0;
            min_y = 0;
            for idx_pos=1:numel(positions)
                max_x = max(max_x, positions{idx_pos}(1));
                if idx_pos == 1
                    min_x = positions{idx_pos}(1);
                    min_y = positions{idx_pos}(2);
                else
                    min_x = min(min_x, positions{idx_pos}(1));
                    min_y = min(min_y, positions{idx_pos}(2));
                end
            end
            obs_pos = [max_x max_y (max_x + 150) (max_y + 60)];
        end
        
        %%
        function new_name = adapt_block_name(var_name, ID)
            %     new_name = regexprep(var_name,'^__(\w)','$1');
            var_name = matlab.lang.makeValidName(char(var_name));
            prefix = '';
            if nargin >= 2
                ID = char(ID);
                %                 display(ID)
                prefix = strcat(ID, '_');
            end
            if numel(prefix)>30
                prefix = strcat('a_', prefix(numel(prefix) - 20 : end));
            end
            if numel(var_name) > 40
                new_name = strcat(prefix,'a_', var_name(numel(var_name) - 30 : end));
            else
                new_name = strcat(prefix, var_name);
            end
            if numel(char(new_name)) > 43
                new_name = BUtils.adapt_block_name(new_name);
            end
            new_name = char(new_name);
        end
        
        
        
        %%
        function block_path  = get_unique_name(block_path)
            n= 1;
            while getSimulinkBlockHandle(block_path) ~= -1
                block_path = strcat(block_path, num2str(n));
            end
        end
        
        %% Get the block name from path
        function out = naming_alone(nomsim)
            [a,~]=regexp (nomsim, filesep, 'split');
            out = a{end};
        end
        %%
        function data = read_EMF(contract_path)
            % read json file
            try
                filetext = fileread(contract_path);
            catch ME
                display_msg('No Contract file', Constants.ERROR, 'Zustre ', '');
                rethrow(ME);
            end
            
            % encode json file
            filetext = regexprep(filetext,'"__','"xx');
            
            %parse the data
            if strcmp(filetext, '')
                warndlg('No cocospec contracts were generated','CoCoSim: Warning');
                return;
            end
            data = json_decode(filetext);
        end
        
        %%
        function  force_inports_DT(block_name)
            inport_list = find_system(block_name,'BlockType','Inport');
            model = regexp(block_name,'/','split');
            model = model{1};
            if ~isempty(inport_list)
                warning off;
                code_on=sprintf('%s([], [], [], ''compile'')', model);
                eval(code_on);
                port_map = containers.Map();
                for i=1:length(inport_list)
                    port_dt = get_param(inport_list{i}, 'CompiledPortDataTypes');
                    port_map(inport_list{i}) = port_dt.Outport;
                end
                code_off = sprintf('%s([], [], [], ''term'')', model);
                eval(code_off);
                warning on;
                for i=1:length(inport_list)
                    dt = port_map(inport_list{i});
                    set_param(inport_list{i}, 'OutDataTypeStr', dt{1})
                end
            end
        end
        
        function res = isLastModified(file1, file2)
            % This function return true if file2 is new comparing to file1
            % This means file2 has been modified or created after file1
            if ~exist(file2, 'file') || ~exist(file1, 'file')
                res = false;
                return;
            end
            f1_info = dir(file1);
            f2_info = dir(file2);
            if isempty(f1_info) || isempty(f2_info)
                res = false;
                return;
            end
            res = f1_info.datenum < f2_info.datenum;
        end
        
        function status = check_files_exist(varargin)
            status = 0;
            for i=1:numel(varargin)
                if ~exist(varargin{i}, 'file')
                    msg = sprintf('FILE NOT FOUND: %s', varargin{i});
                    display_msg(msg, Constants.ERROR, 'Zustre ', '');
                    status = 1;
                    break;
                end
            end
        end
    end
    
end

