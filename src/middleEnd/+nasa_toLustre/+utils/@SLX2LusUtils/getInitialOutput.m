
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
%% Get the initial ouput of Outport depending on the dimension.
% the function returns a list of LustreExp objects: IntExpr,
% RealExpr or BooleanExpr
function InitialOutput_cell = getInitialOutput(parent, blk, InitialOutput, slx_dt, max_width)
    
    [lus_outputDataType] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slx_dt);
    if strcmp(InitialOutput, '[]')
        InitialOutput = '0';
    end
    [InitialOutputValue, InitialOutputType, status] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, InitialOutput);
    if status
        display_msg(sprintf('InitialOutput %s in block %s not found neither in Matlab workspace or in Model workspace',...
            InitialOutput, blk.Origin_path), ...
            MsgType.ERROR, 'Outport_To_Lustre', '');
        return;
    end
    if iscell(lus_outputDataType)...
            && numel(InitialOutputValue) < numel(lus_outputDataType)
        % in the case of bus type, lus_outputDataType is inlined to
        % the basic types of the bus. We need to inline
        % InitialOutputValue as well
        InitialOutputValue = arrayfun(@(x) InitialOutputValue(1), (1:numel(lus_outputDataType)*max_width));
        base_lus_outputDataType = lus_outputDataType;
        for i=2:max_width
            lus_outputDataType = [lus_outputDataType, base_lus_outputDataType];
        end
    else
        lus_outputDataType = arrayfun(@(x) {lus_outputDataType}, (1:numel(InitialOutputValue)));
    end
    %
    InitialOutput_cell = cell(1, numel(InitialOutputValue));
    for i=1:numel(InitialOutputValue)
        InitialOutput_cell{i} = nasa_toLustre.utils.SLX2LusUtils.num2LusExp(...
            InitialOutputValue(i), lus_outputDataType{i}, InitialOutputType);
    end

    if numel(InitialOutput_cell) < max_width
        InitialOutput_cell = arrayfun(@(x) InitialOutput_cell(1), (1:max_width));
    end

end
