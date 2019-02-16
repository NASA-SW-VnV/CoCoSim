%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function U_dims = tf_get_U_dims(model, pp_name, blkList)
    % geting dimensions of U
    warning off;
    code_on=sprintf('%s([], [], [], ''compile'')', model);
    eval(code_on);
    try
        U_dims = cell(1, length(blkList));
        for i=1:length(blkList)
            try
                NumeratorSource = get_param(blkList{i}, 'NumeratorSource');
                DenominatorSource = get_param(blkList{i}, 'DenominatorSource');
            catch
                NumeratorSource = '';
                DenominatorSource = '';
            end

            if isequal(NumeratorSource, 'Input port') ...
                    || isequal(DenominatorSource, 'Input port')
                display_msg(sprintf('block %s has external numerator/denominator not supported',...
                    blkList{i}), ...
                    MsgType.ERROR, pp_name, '');
                U_dims{i} = [];
                continue;
            end
            CompiledPortDimensions = get_param(blkList{i}, 'CompiledPortDimensions');
            in_matrix_dimension = Assignment_To_Lustre.getInputMatrixDimensions(CompiledPortDimensions.Inport);
            if numel(in_matrix_dimension) > 1
                display_msg(sprintf('block %s has external reset signal not supported',...
                    blkList{i}), ...
                    MsgType.ERROR, pp_name, '');
                U_dims{i} = [];
                continue;
            else
                U_dims{i} = in_matrix_dimension{1}.dims;
            end
        end
    catch me
        display_msg(me.getReport(), ...
            MsgType.DEBUG, pp_name, '');
        code_off = sprintf('%s([], [], [], ''term'')', model);
        eval(code_off);
        %warning on;
        return;
    end
    code_off = sprintf('%s([], [], [], ''term'')', model);
    eval(code_off);
    %warning on;

end

