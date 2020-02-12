%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright � 2020 United States Government as represented by the
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
function [status, errors_msg] = Gain_pp(model)
    % Gain_pp Searches for gain blocks and replaces them by a
    % PP-friendly equivalent.
    %   model is a string containing the name of the model to search in
    % Processing Gain blocks
    status = 0;
    errors_msg = {};
    
    Gain_list = find_system(model, ...
        'LookUnderMasks', 'all', 'BlockType','Gain');
    if not(isempty(Gain_list))
        display_msg('Replacing Gain blocks...', MsgType.INFO,...
            'Gain_pp', '');
        allCompiledDT = coco_nasa_utils.SLXUtils.getCompiledParam(Gain_list, 'CompiledPortDataTypes');
        %compiledInportDim = coco_nasa_utils.SLXUtils.getCompiledParam(Gain_list, 'CompiledPortDimensions');
        for i=1:length(Gain_list)
            try
                display_msg(Gain_list{i}, MsgType.INFO, ...
                    'Gain_pp', '');
                gain = get_param(Gain_list{i},'Gain');
                [gain_value, ~, status] = coco_nasa_utils.SLXUtils.evalParam(...
                    model, ...
                    get_param(Gain_list{i}, 'Parent'), ...
                    Gain_list{i}, ...
                    gain);
                if status == 0 && numel(gain_value) == 1
                    continue;
                end
                CompiledPortDataTypes = allCompiledDT{i};

                % set The Gain datatype
                ParamDataTypeStr = get_param(Gain_list{i}, 'ParamDataTypeStr');
                if strcmp(ParamDataTypeStr, 'Inherit: Inherit from ''Gain''') ...
                        || strcmp(ParamDataTypeStr, 'Inherit: Inherit via internal rule')
                    cstDataType = 'Inherit: Inherit from ''Constant value''';
                elseif strcmp(ParamDataTypeStr, 'Inherit: Same as input')
                    if coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Inport{1}, 'fix') ... % sfix, ufix
                            || coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Inport{1}, 'flt') %flts, fltu
                        cstDataType = 'Inherit: Inherit via back propagation';
                    else
                        cstDataType = CompiledPortDataTypes.Inport{1};
                    end
                else
                    cstDataType = ParamDataTypeStr;
                end
                
                if coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Outport{1}, 'fix') ... % sfix, ufix
                        || coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Outport{1}, 'flt') %flts, fltu
                    productDataType = get_param(Gain_list{i}, 'OutDataTypeStr');
                    %cstDataType = 'Inherit: Inherit from ''Constant value''';
                elseif strcmp(CompiledPortDataTypes.Inport{1}, 'boolean') ...
                        && ~coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Outport{1}, 'fix')
                    productDataType = CompiledPortDataTypes.Outport{1};
                    %cstDataType = 'Inherit: Inherit from ''Constant value''';
                else
                    productDataType = get_param(Gain_list{i}, 'OutDataTypeStr');
                    %cstDataType = 'Inherit: Inherit via back propagation';
                end
                Multiplication = get_param(Gain_list{i}, 'Multiplication');
                SaturateOnIntegerOverflow = get_param(Gain_list{i},'SaturateOnIntegerOverflow');
                
                if strcmp(Multiplication, 'Element-wise(K.*u)')
                    pp_name = 'gain_ElementWise';
                elseif strcmp(Multiplication, 'Matrix(K*u)')
                    pp_name = 'gain_K_U';
                elseif strcmp(Multiplication, 'Matrix(K*u) (u vector)')
                    pp_name = 'gain_K_U_with_reshape';
                elseif strcmp(Multiplication, 'Matrix(u*K)')
                    pp_name = 'gain_U_K';
                end
                
                OutMin = get_param(Gain_list{i}, 'OutMin');
                OutMax = get_param(Gain_list{i}, 'OutMax');
                
                % replace block
                NASAPPUtils.replace_one_block(Gain_list{i},fullfile('pp_lib',pp_name));
                
                % set parameters to constant block
                set_param(strcat(Gain_list{i},'/K'),...
                    'Value',gain);
                set_param(strcat(Gain_list{i},'/K'),...
                    'OutDataTypeStr',cstDataType);
                if strcmp(Multiplication, 'Element-wise(K.*u)')
                    set_param(strcat(Gain_list{i},'/K'),...
                        'VectorParams1D','on');
                end
                
                % set parameters to inport: if not set Simulink might give different
                % datatype for the inport than the original model.
                if ~(coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Inport{1}, 'fix') ... % sfix, ufix
                        || coco_nasa_utils.MatlabUtils.contains(CompiledPortDataTypes.Inport{1}, 'flt')) %flts, fltu
                    set_param(strcat(Gain_list{i},'/u'),...
                        'OutDataTypeStr',CompiledPortDataTypes.Inport{1});
                end
                % set parameters for u vector
                if strcmp(pp_name, 'gain_K_U_with_reshape')
                    k_dim = size(gain_value);
                    if k_dim(end) ~= 1
                        set_param(strcat(Gain_list{i},'/Reshape'),...
                            'OutputDimensionality','Column vector (2-D)');
                    else
                        set_param(strcat(Gain_list{i},'/Reshape'),...
                            'OutputDimensionality','Row vector (2-D)');
                    end
                end
                
                % set parameters to product block
                if strcmp(productDataType, 'Inherit: Same as input')
                    productDataType = 'Inherit: Same as first input';
                end
                set_param(strcat(Gain_list{i},'/Product'),...
                    'OutDataTypeStr',productDataType);
                set_param(strcat(Gain_list{i},'/Product'),...
                    'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
                
                set_param(strcat(Gain_list{i},'/Out1'), 'OutMin', OutMin);
                set_param(strcat(Gain_list{i},'/Out1'), 'OutMax', OutMax);
            catch me
                display_msg(me.getReport(), MsgType.DEBUG, 'Gain_pp', '');
                status = 1;
                errors_msg{end + 1} = sprintf('Gain pre-process has failed for block %s', Gain_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'Gain_pp', '');
    end
    
end

