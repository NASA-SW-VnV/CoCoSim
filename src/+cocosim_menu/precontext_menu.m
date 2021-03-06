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
function schema = precontext_menu(varargin)
    %cocoSim_menu Define the custom menu function.
    
    schema = sl_container_schema;
    schema.label = 'CoCoSim';
    schema.statustip = 'Automated Analysis Framework';
    schema.autoDisableWhen = 'Busy';
    
    schema.childrenFcns = {@verificationResultPrecontextMenu, ...
        @attachContract,...
        @MiscellaneousMenu.replaceInportsWithSignalBuilders, ...
        @getAutoLayoutTool};
    
end
%%
function schema = verificationResultPrecontextMenu(varargin)
    schema = sl_container_schema;
    schema.label = 'Verification Results';
    schema.statustip = 'Get the Active verification results';
    schema.autoDisableWhen = 'Busy';
    schema.childrenFcns = {...
        @VerificationMenu.displayHtmlVerificationResults,...
        @VerificationMenu.compositionalOptions...
        };
    modelWorkspace = get_param(bdroot(gcs),'modelworkspace');
    if ~isempty(modelWorkspace) && modelWorkspace.hasVariable('compositionalMap')
        schema.state = 'Enabled';
    else
        schema.state = 'Hidden';
    end
end
%%
function schema = attachContract(varargin)
    schema = sl_action_schema;
    schema.label = 'Attach Contract to selected block';
    schema.statustip = 'Attach Contract to the selected Block/Subsystem';
    schema.autoDisableWhen = 'Busy';
    MyBlocks = find_system(gcs,'Selected','on');
    schema.state = 'Enabled';
    schema.callback = @(x) attachContractCallback(x, MyBlocks);
end
function attachContractCallback(~, MyBlocks)
    if ~isempty(MyBlocks)
        if length(MyBlocks) == 1
            blk = MyBlocks{1};
        elseif ismember(gcb, MyBlocks)
            blk = gcb;
        elseif length(MyBlocks)==2 && strcmp(MyBlocks{1}, gcs)
            blk = MyBlocks{2};
        elseif length(MyBlocks) > 1
            % Too many selected block
            errordlg(sprintf('Too many selected blocks:\n%s', ...
                sprintf(coco_nasa_utils.MatlabUtils.strjoin(MyBlocks, '\n'))));
            return
        end
        if strcmp(get_param(blk, 'BlockType'), 'Inport') ...
            || strcmp(get_param(blk, 'BlockType'), 'Outport')
            errordlg('You cannot attach contracts to (In|Out)port block');
            return
        end
        root = bdroot(blk);
        try
            % save system before changes
            save_system(root,'','OverwriteIfChangedOnDisk',true)
            [blkH, status]  = coco_nasa_utils.MenuUtils.attach_contract(blk);
            if status == 0
                open_system(blkH, 'force');
            end
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'attachContractCallback', '');
            status = 1;
        end
        if status
            % restore model
            fname = get_param(root, 'fileName');
            close_system(root, 0);
            open_system(fname);
        end
    end
end
%%
function schema = getAutoLayoutTool(callbackinfo)
    schema = sl_action_schema;
    schema.label = 'Auto Layout';
    schema.userdata = 'autolayout';
    schema.callback = @AutoLayoutToolCallback;
end

function AutoLayoutToolCallback(callbackInfo)
    try
        Simulink.BlockDiagram.arrangeSystem(gcs);
    catch
        external_lib.AutoLayout.AutoLayout(gcs);
    end
end
