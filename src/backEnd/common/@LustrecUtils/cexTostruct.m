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
% 

function [ds, time_max] = cexTostruct(...
        cex_xml, ...
        node_name,...
        inports)
    IN_struct = [];

    nodes = cex_xml.item(0).getElementsByTagName('Node');
    node = [];
    for idx=0:(nodes.getLength-1)
        if strcmp(nodes.item(idx).getAttribute('name'), node_name)
            node = nodes.item(idx);
            break;
        end
    end
    if isempty(node)
        return;
    end
    streams = node.getElementsByTagName('Stream');
    stream_names = {};
    for i=0:(streams.getLength-1)
        s = streams.item(i).getAttribute('name');
        stream_names{i+1} = char(s);
    end
    time_max = 0;
    for i=1:numel(inports)
        IN_struct.signals(i).name = inports(i).name;
        IN_struct.signals(i).datatype = ...
            LusValidateUtils.get_slx_dt(inports(i).datatype);
        if isfield(inports(i), 'dimensions')
            IN_struct.signals(i).dimensions = inports(i).dimensions;
        else
            IN_struct.signals(i).dimensions =  1;
        end

        stream_name = inports(i).name;
        stream_index = find(strcmp(stream_names, stream_name), 1);
        if isempty(stream_index)
            IN_struct.signals(i).values = [];
        else
            [values, time_step] =...
                LustrecUtils.extract_values(...
                streams.item(stream_index-1), inports(i).datatype);
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
                    MatlabUtils.construct_random_booleans(...
                    nb_steps, min, max_v, dim);
            elseif strcmp(...
                   nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                    'int')
                values = ...
                    MatlabUtils.construct_random_integers(...
                    nb_steps, min, max_v, IN_struct.signals(i).datatype, dim);
            elseif strcmp(...
                    IN_struct.signals(i).datatype,...
                    'single')
                values = ...
                    single(...
                    MatlabUtils.construct_random_doubles(...
                    nb_steps, min, max_v, dim));
            else
                values = ...
                    MatlabUtils.construct_random_doubles(...
                    nb_steps, min, max_v, dim);
            end
            IN_struct.signals(i).values =...
                [IN_struct.signals(i).values, values];
        end
    end
    IN_struct.time = (0:1:time_max)';
    ds = Simulink.SimulationData.Dataset(IN_struct);
end

