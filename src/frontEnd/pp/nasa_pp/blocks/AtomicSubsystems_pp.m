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
function [status, errors_msg] = AtomicSubsystems_pp( new_model_base )
    %ATOMIC_PROCESS change all blocks to be atomic
    % Configure any subsystem to be treated as Atomic
    status = 0;
    errors_msg = {};
    
    ssys_list = find_system(new_model_base,'LookUnderMasks', 'all',...
        'BlockType','SubSystem');
    if not(isempty(ssys_list))
        display_msg('Processing Subsystem blocks', MsgType.INFO, 'PP', '');
        for i=1:length(ssys_list)
            %disp(ssys_list{i})
            try
                set_param(ssys_list{i},'TreatAsAtomicUnit','on');
                set_param(ssys_list{i},'MinAlgLoopOccurrences','off');
                
            catch me
                display_msg(me.message, MsgType.DEBUG, 'AtomicSubsystems_pp', '');
                status = 1;
                errors_msg{end + 1} = sprintf('AtomicSubsystems pre-process has failed for block %s', ssys_list{i});
                continue;
            end
        end
        display_msg('Done\n\n', MsgType.INFO, 'PP', '');
    end
    configSet = getActiveConfigSet(new_model_base);
    set_param(configSet, 'AlgebraicLoopMsg', 'error');
    set_param(configSet, 'ArtificialAlgebraicLoopMsg', 'error');
    solveAlgebraicLoops(new_model_base);
end

function solveAlgebraicLoops(new_model_base)
    % set off atomic for subsystems that cause algebraic loops
    % this function is rucursive, because after solving each block we should
    % rerun the process in order to check if the solved block has broken the
    % algebraic loop. That increase the number of atomic blocks instead of
    % turning off all blocks detected in algebraic loop.
    code_on=sprintf('%s([], [], [], ''compile'')', new_model_base);
    matlabOpenFormat = 'matlab:open\w+\s*\(''([^''])+''';
    try
        warning off;
        evalin('base',code_on);
    catch ME
        causes = ME.cause;
        if isempty(causes) ...
                && strcmp(ME.identifier, 'Simulink:Engine:NoNonvirtSubsysSelfLoops')
            causes{1} = ME;
        end
        for c=causes'
            subsys = '';
            switch c{1}.identifier
                case {'Simulink:Engine:BlkInAlgLoopErr', ...
                        'Simulink:Engine:BlkInAlgLoopErrWithInfo', ...
                        'Simulink:Engine:NoNonvirtSubsysSelfLoops'}
                    display_msg('Algebraic Loop detected', MsgType.INFO, 'PP', '');
                    msg = c{1}.message;
                    tokens = regexp(msg, matlabOpenFormat, 'tokens', 'once');
                    if isempty(tokens)
                        continue;
                    end
                    subsys = tokens{1};
                case 'Simulink:DataType:InputPortCannotAcceptMixedDataTypeWithHint'
                    msg = c{1}.message;
                    tokens = regexp(msg, 'The inport block\s*''([^''])+''', 'tokens', 'once');
                    if isempty(tokens)
                        continue;
                    end
                    subsys = fileparts(tokens{1});
            end
            if ~isempty(subsys)
                try
                    display_msg(['Turn off atomic in block' subsys], MsgType.INFO, 'PP', '');
                    set_param(subsys,'TreatAsAtomicUnit','off');
                    try Simulink.BlockDiagram.expandSubsystem(subsys); catch, end
                    solveAlgebraicLoops(new_model_base);
                catch
                end
            end
        end
        
        return;
    end
    code_off=sprintf('%s([], [], [], ''term'')', new_model_base);
    evalin('base',code_off);
    
end