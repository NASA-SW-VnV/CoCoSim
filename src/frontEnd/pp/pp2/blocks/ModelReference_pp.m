function ModelReference_pp(topLevelModel)
%ModelReference_pp will replace all model reference blocks at all levels
% within the top level model with SubSystems having the same contents as
% the referenced model.

% Find Model Reference Blocks in the top level model:
topLevelModelHandle = get_param( topLevelModel , 'Handle' );
mdlRefsHandles = find_system( topLevelModelHandle , 'LookUnderMasks','all', ...
    'findall' , 'on' , 'blocktype' , 'ModelReference' );

if( ~isempty( mdlRefsHandles ) )
    for k = 1 : length( mdlRefsHandles )
        mdlRefName = get_param( mdlRefsHandles(k) , 'ModelName' );
        mdlName =  get_param( mdlRefsHandles(k) , 'Name' );
        % Create a blank subsystem, fill it with the modelref's contents:
        
        try
            ref_block_path = getfullname(mdlRefsHandles);
            ssName = [ ref_block_path '_SS_' num2str(k) ];
            ssHandle = add_block( 'built-in/SubSystem' , ssName,...
                'MakeNameUnique', 'on');  % Create empty SubSystem
            
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
            display_msg(me.getReport(), MsgType.DEBUG, 'KindContract_pp', '');
        end
    end
    % Recursive searching of nested model references:
    ModelReference_pp(topLevelModel)
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
