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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = TestCaseGenMenu(varargin)
    schema = sl_container_schema;
    schema.label = 'Test-case generation using ...';
    schema.statustip = 'Generate Lustre code';
    schema.autoDisableWhen = 'Busy';

    schema.childrenFcns = {@MCDC,@Mutation , @Random};
end

%%
function schema = Random(varargin)
    schema = sl_action_schema;
    schema.label = 'Random testing';
    schema.callback = @RandomCallback;
end

function RandomCallback(varargin)
    try
        model_full_path = coco_nasa_utils.MenuUtils.get_file_name(gcs);
        coco_nasa_utils.MenuUtils.add_pp_warning(model_full_path);
        randomTestGui('model_full_path',model_full_path);
    catch ME
        coco_nasa_utils.MenuUtils.handleExceptionMessage(ME, 'Test-case generation');
    end
end

%%
function schema = Mutation(varargin)
    schema = sl_action_schema;
    schema.label = 'Mutation based testing (Work in progress!)';
    schema.state = 'Disabled';
    schema.callback = @MutationCallback;
end

function MutationCallback(varargin)
    try
        model_full_path = coco_nasa_utils.MenuUtils.get_file_name(gcs);
        coco_nasa_utils.MenuUtils.add_pp_warning(model_full_path);
        mutation_test_gui('model_full_path',model_full_path);
    catch ME
        coco_nasa_utils.MenuUtils.handleExceptionMessage(ME, 'Test-case generation');
    end
end

%%
function schema = MCDC(varargin)
    schema = sl_action_schema;
    schema.label = 'MC-DC coverage (Work in progress!)';
    % schema.state = 'Disabled';
    schema.callback = @MCDCCallback;
end

function MCDCCallback(varargin)
    try
        model_full_path = coco_nasa_utils.MenuUtils.get_file_name(gcs);
        coco_nasa_utils.MenuUtils.add_pp_warning(model_full_path);
        mcdc_test_gui('model_full_path',model_full_path);
    catch ME
        coco_nasa_utils.MenuUtils.handleExceptionMessage(ME, 'Test-case generation');
    end
end
