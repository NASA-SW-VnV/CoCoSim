%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
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
%function [status, errors_msg] = ModelReference_pp(topLevelModel)
    %ModelReference_pp will replace all model reference blocks at all levels
    % within the top level model with SubSystems having the same contents as
    % the referenced model.
    % Find Model Reference Blocks in the top level model:
    status = 0;
    errors_msg = {};

    topLevelModelHandle = get_param( topLevelModel , 'Handle' );
    mdlRefsHandles = find_system( topLevelModelHandle , 'LookUnderMasks','all', ...
        'findall' , 'on' , 'blocktype' , 'ModelReference' );
    failed = 0;
    %mdlRefIgnored = 0;
    if( ~isempty( mdlRefsHandles ) )
        for k = 1 : length( mdlRefsHandles )
            try
                mdlRefName = get_param( mdlRefsHandles(k) , 'ModelName' );
                mdlName =  get_param( mdlRefsHandles(k) , 'Name' );
                %[CompiledPortDataTypes] = SLXUtils.getCompiledParam(mdlRefsHandles(k), 'CompiledPortDataTypes');
                % if HasBusPort(CompiledPortDataTypes)
                %     display_msg([mdlRefName ' will be handled directly in the compiler ToLustre as it has Bus Ports.'], MsgType.INFO, 'ModelReference_pp', '');
                %     mdlRefIgnored = 1;
                %     continue;
                % end
                % Create a blank subsystem, fill it with the modelref's contents:
                display_msg(mdlName, MsgType.INFO, 'ModelReference_pp', '');
                try
                    ref_block_path = getfullname(mdlRefsHandles(k));
                    ssName = [ ref_block_path '_SS_' num2str(k) ];
                    ssHandle = add_block( 'built-in/SubSystem' , ssName,...
                        'MakeNameUnique', 'on');  % Create empty SubSystem
                    display_msg(ref_block_path, MsgType.INFO, 'ModelReference_pp', '');
                    slcopy_mdl2subsys( mdlRefName , ssName );   % This function copies contents of the referenced model into the SubSystem

                    Orient=get_param(ssHandle,'orientation');
                    blockPosition = get_param( mdlRefsHandles(k) , 'Position' );
                    delete_block( mdlRefsHandles(k) );
                    set_param( ssHandle , ...
                        'Name', mdlName, ...
                        'Orientation',Orient, ...
                        'Position' , blockPosition );

                    % Assigning Model Reference Callbacks to the new subsystem:
                    Replace_Callbacks( mdlRefName , ssHandle );
                catch me
                    failed = 1;
                    display_msg(me.getReport(), MsgType.DEBUG, 'ModelReference_pp', '');
                end
            catch
                status = 1;
                errors_msg{end + 1} = sprintf('ModelReference pre-process has failed for block %s', mdlRefsHandles{k});
                continue;
            end
            %check for libraries too if they were inside referenced Models
            if ~failed, LinkStatus_pp(ref_block_path); end
            if ~failed %&& ~mdlRefIgnored
                % Recursive searching of nested model references:
                ModelReference_pp(ref_block_path);
            end
        end


    end
end


function isBus = HasBusPort(CompiledPortDataTypes)
    isBus = false;
    for i=1:numel(CompiledPortDataTypes.Outport)
        try
            isBus_i = strcmp(CompiledPortDataTypes.Outport{i}, 'auto') ...
                || evalin('base', sprintf('isa(%s, ''Simulink.Bus'')',...
                CompiledPortDataTypes.Outport{i}));
        catch
            isBus_i = false;
        end
        isBus = isBus || isBus_i;
    end
    for i=1:numel(CompiledPortDataTypes.Inport)
        try
            isBus_i = strcmp(CompiledPortDataTypes.Inport{i}, 'auto') ...
                || evalin('base', sprintf('isa(%s, ''Simulink.Bus'')',...
                CompiledPortDataTypes.Inport{i}));
        catch
            isBus_i = false;
        end
        isBus = isBus || isBus_i;
    end
end
    %%
function Replace_Callbacks( mdlRefName , ssHandle )
    %Replace_Callbacks Copies the callbacks of the referenced model to the
    % callbacks of the Subsystem:

    preLoadFcn = get_param( mdlRefName , 'PreLoadFcn' );
    postLoadFcn = get_param( mdlRefName , 'PostLoadFcn' );
    loadFcn = sprintf( [ preLoadFcn '\n' postLoadFcn ] );

    initFcn = get_param( mdlRefName , 'InitFcn' );
    startFcn = get_param( mdlRefName , 'StartFcn' );
    pauseFcn = get_param( mdlRefName , 'PauseFcn' );
    continueFcn = get_param( mdlRefName , 'ContinueFcn' );
    stopFcn = get_param( mdlRefName , 'StopFcn' );
    preSaveFcn = get_param( mdlRefName , 'PreSaveFcn' );
    postSaveFcn = get_param( mdlRefName , 'PostSaveFcn' );
    closeFcn = get_param( mdlRefName , 'CloseFcn' );


    set_param( ssHandle , 'LoadFcn' , loadFcn );
    set_param( ssHandle , 'InitFcn' , initFcn );
    set_param( ssHandle , 'StartFcn' , startFcn );
    set_param( ssHandle , 'PauseFcn' , pauseFcn );
    set_param( ssHandle , 'ContinueFcn' , continueFcn );
    set_param( ssHandle , 'StopFcn' , stopFcn );
    set_param( ssHandle , 'PreSaveFcn' , preSaveFcn );
    set_param( ssHandle , 'PostSaveFcn' , postSaveFcn );
    set_param( ssHandle , 'ModelCloseFcn' , closeFcn );
end
    %%
function slcopy_mdl2subsys(model, subsysBlk)
    %  SLCOPY_MDL2SUBSYS Copy contents of a model to a Subsystem
    %
    try
        % load the model if it is not loaded
        load_system(model);

        modelName = get_param(model, 'name');

        obj = get_param(subsysBlk,'object');
        %obj.deleteContent;
        Simulink.SubSystem.deleteContents(subsysBlk)
        obj.copyContent(modelName);
    catch me
        rethrow(me);
    end
end
%endfunction
