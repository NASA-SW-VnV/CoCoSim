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

function [IN_struct, time_max] = Kind2CEXTostruct(...
    node_struct, ...
    cex_xml, ...
    node_name)
    IN_struct = [];
    time_max = 0;
    nodes = cex_xml.item(0).getElementsByTagName('Node');
    if nodes.getLength == 0
        nodes = cex_xml.item(0).getElementsByTagName('Function');
    end
    node = [];
    for idx=0:(nodes.getLength-1)
        if strcmp(nodes.item(idx).getAttribute('name'), node_name)
            node = nodes.item(idx);
            break;
        end
    end
    if isempty(node)
        display_msg('Failed to parse CounterExample',...
            MsgType.ERROR, 'coco_nasa_utils.Kind2Utils.Kind2CEXTostruct', '');
        return;
    end
    IN_struct.node_name = node_name;
    streams = node.getElementsByTagName('Stream');
    node_streams = {};
    node_streams_name = {};
    for i=0:(streams.getLength-1)
        if strcmp(streams.item(i).getParentNode.getAttribute('name'),...
                node_name) && ...
                strcmp(streams.item(i).getAttribute('class'),...
                'input')
            node_streams_name{numel(node_streams_name) + 1} = ...
                char(streams.item(i).getAttribute('name'));
            node_streams{numel(node_streams) + 1} = streams.item(i);
        end
    end
    if isfield(node_struct, 'inputs')
        node_inputs = node_struct.inputs;
        nb_in = numel(node_inputs);
        for i=1:nb_in
            input_name = node_inputs(i).name;
            id_stream = find(strcmp(input_name, node_streams_name));
            if isempty(id_stream)
                IN_struct.signals(i).name = input_name;
                IN_struct.signals(i).datatype = LusValidateUtils.get_slx_dt(node_inputs(i).datatype);
                %TODO dimension > 1 case
                IN_struct.signals(i).dimensions =  1;
                IN_struct.signals(i).values = [];
            else
                s_name = char(node_streams{id_stream}.getAttribute('name'));
                s_dt =  char(LusValidateUtils.get_slx_dt(node_streams{id_stream}.getAttribute('type')));

                IN_struct.signals(i).name = s_name;
                IN_struct.signals(i).datatype = s_dt;

                %TODO parse the type and extract dimension
                IN_struct.signals(i).dimensions =  1;

                [values, time_step] =...
                    coco_nasa_utils.LustrecUtils.extract_values(...
                    node_streams{id_stream}, s_dt);
                IN_struct.signals(i).values = values';
                time_max = max(time_max, time_step);
            end
        end
    else
        for i=1:numel(node_streams)
            s_name = char(node_streams{i}.getAttribute('name'));
            s_dt =  char(LusValidateUtils.get_slx_dt(node_streams{i}.getAttribute('type')));

            IN_struct.signals(i).name = s_name;
            IN_struct.signals(i).datatype = s_dt;

            %TODO parse the type and extract dimension
            IN_struct.signals(i).dimensions =  1;

            [values, time_step] =...
                coco_nasa_utils.LustrecUtils.extract_values(...
                node_streams{i}, s_dt);
            IN_struct.signals(i).values = values';
            time_max = max(time_max, time_step);
        end
    end
    min = -100; max_v = 100;
    for i=1:numel(IN_struct.signals)
        if numel(IN_struct.signals(i).values) < time_max + 1
            nb_steps = time_max +1 - numel(IN_struct.signals(i).values);
            dim = IN_struct.signals(i).dimensions;
            if strcmp(...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                    'bool')
                values = ...
                    coco_nasa_utils.MatlabUtils.construct_random_booleans(...
                    nb_steps, min, max_v, dim);
            elseif strcmp(...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                    'int')
                values = ...
                    coco_nasa_utils.MatlabUtils.construct_random_integers(...
                    nb_steps, min, max_v, IN_struct.signals(i).datatype, dim);
            elseif strcmp(...
                    IN_struct.signals(i).datatype,...
                    'single')
                values = ...
                    single(...
                    coco_nasa_utils.MatlabUtils.construct_random_doubles(...
                    nb_steps, min, max_v, dim));
            else
                values = ...
                    coco_nasa_utils.MatlabUtils.construct_random_doubles(...
                    nb_steps, min, max_v, dim);
            end
            IN_struct.signals(i).values =...
                [IN_struct.signals(i).values, values];
        end
    end
    IN_struct.time = (0:1:time_max)';
end

    


