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
%function [status, errors_msg] = LookupNDDirect_pp(model)
% LookupNDDirect_pp Searches for LookupNDDirect blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
% Processing LookupNDDirect blocks
status = 0;
errors_msg = {};

LookupNDDirect_list = find_system(model, ...
    'LookUnderMasks', 'all', 'BlockType','LookupNDDirect');
if not(isempty(LookupNDDirect_list))
    display_msg('Replacing LookupNDDirect blocks...', MsgType.INFO,...
        'LookupNDDirect_pp', '');
    for i=1:length(LookupNDDirect_list)
        try
            display_msg(LookupNDDirect_list{i}, MsgType.INFO, ...
                'LookupNDDirect_pp', '');
            % get all parameters
            NumberOfTableDimensions = get_param(LookupNDDirect_list{i},'NumberOfTableDimensions');
            InputsSelectThisObjectFromTable = get_param(LookupNDDirect_list{i},'InputsSelectThisObjectFromTable');
            TableIsInput = get_param(LookupNDDirect_list{i},'TableIsInput');
            TableMin = get_param(LookupNDDirect_list{i},'TableMin');
            TableMax = get_param(LookupNDDirect_list{i},'TableMax');
            TableDataTypeStr = get_param(LookupNDDirect_list{i},'TableDataTypeStr');
            Table = get_param(LookupNDDirect_list{i},'Table');
            
            % add pp subsystem
            tmp_block_path = strcat(LookupNDDirect_list{i}, '__tmp');
            if strcmp(TableIsInput, 'on')
                pp_name = 'DirectLookupTableAsInput';
            else
                pp_name = 'DirectLookup';
            end
            h = add_block(fullfile('pp_lib',pp_name), tmp_block_path, ...
                'MakeNameUnique', 'on');
            tmp_block_path = fullfile(get_param(h, 'Parent'), get_param(h, 'Name'));
            set_param(tmp_block_path, 'LinkStatus', 'inactive');
            
            % transfer parameters from Direct lookup table to Selector
            selector_path = fullfile(tmp_block_path, 'Selector');
            IndexOptionArray = arrayfun(@(x) 'Index vector (port)', ...
                (1:str2double(NumberOfTableDimensions)), 'UniformOutput', 0);
            if strcmp(InputsSelectThisObjectFromTable, 'Vector') ||...
                strcmp(InputsSelectThisObjectFromTable, 'Column')
                IndexOptionArray{1} = 'Select all';
            elseif strcmp(InputsSelectThisObjectFromTable, '2-D Matrix')
                IndexOptionArray{1} = 'Select all';
                IndexOptionArray{2} = 'Select all';
            elseif ~strcmp(InputsSelectThisObjectFromTable, 'Element')
                % New name
                table_ports = get_param(LookupNDDirect_list{i},'PortHandles');
                nb_inputs = length(table_ports.Inport);
                if strcmp(TableIsInput, 'on')
                    nb_inputs = nb_inputs - 1;
                end
                nb_dimensionSelectAll = ...
                    str2double(NumberOfTableDimensions) - nb_inputs;
                IndexOptionArray(1:nb_dimensionSelectAll) = {'Select all'};
            end
            set_param(selector_path, ...
                'NumberOfDimensions', NumberOfTableDimensions,...
                'IndexOptionArray', IndexOptionArray, ...
                'IndexMode', 'Zero-based');
            

            % add Inports to selector SS
            selector_ports = get_param(selector_path,'PortHandles');
            for portIdx=2:length(selector_ports.Inport)
                portName = fullfile(tmp_block_path,sprintf('Idx%d', portIdx));
                h = add_block('simulink/Sources/In1', portName,...
                    'Port', num2str(portIdx-1));
                ports = get_param(h,'PortHandles');
                add_line(tmp_block_path, ports.Outport, selector_ports.Inport(portIdx),'autorouting','on');
            end
            
            % set table parameters
            U_path = fullfile(tmp_block_path, 'U');
            set_param(U_path, 'OutMin', TableMin);
            set_param(U_path, 'OutMax', TableMax);
            if strcmp(TableDataTypeStr, 'Inherit: Inherit from ''Table data''')
                if strcmp(TableIsInput, 'off')
                    TableDataTypeStr = 'Inherit: Inherit from ''Constant value''';
                else
                    TableDataTypeStr = 'Inherit: auto';
                end
            end
            set_param(U_path, 'OutDataTypeStr', TableDataTypeStr);
            if strcmp(TableIsInput, 'off')
                % U is constant
                set_param(U_path, 'Value', Table);
            end
            
            % organize blocks
            try BlocksPosition_pp(tmp_block_path); catch, end
            
            NASAPPUtils.replace_one_block(LookupNDDirect_list{i},tmp_block_path);
            delete_block(tmp_block_path);
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'LookupNDDirect_pp', '');
            status = 1;
            errors_msg{end + 1} = sprintf('LookupNDDirect pre-process has failed for block %s', LookupNDDirect_list{i});
            % remove tmp SS, if exist
            try delete_block(tmp_block_path); catch, end
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'LookupNDDirect_pp', '');
end

end

