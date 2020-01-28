%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright © 2020 United States Government as represented by the 
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
function [status, errors_msg] = DiscreteZeroPole_pp(model)
% DiscreteZeroPole_pp searches for DiscreteZeroPole blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
% Processing Gain blocks
status = 0;
errors_msg = {};

dzp_list = find_system(model,...
    'LookUnderMasks', 'all', 'BlockType','DiscreteZeroPole');
dzp_list = [dzp_list; find_system(model,'BlockType','ZeroPole')];
if not(isempty(dzp_list))
    display_msg('Replacing DiscreteTransferFcn blocks...', MsgType.INFO,...
        'DiscreteZeroPole_pp', '');
    
    
    
    %% pre-processing blocks
    for i=1:length(dzp_list)
        display_msg(dzp_list{i}, MsgType.INFO, ...
            'DiscreteZeroPole_pp', '');
        
        try
        
        % Obtaining z-expression parameters
        Zeros_str = get_param(dzp_list{i}, 'Zeros');
        [Zeros, ~, status] = SLXUtils.evalParam(...
            model, ...
            get_param(dzp_list{i}, 'Parent'), ...
            dzp_list{i}, ...
            Zeros_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                Zeros_str, dzp_list{i}), ...
                MsgType.ERROR, 'DiscreteZeroPole_pp', '');
            continue;
        end
        
        Poles_str = get_param(dzp_list{i}, 'Poles');
        [Poles, ~, status] = SLXUtils.evalParam(...
            model, ...
            get_param(dzp_list{i}, 'Parent'), ...
            dzp_list{i}, ...
            Poles_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                Poles_str, dzp_list{i}), ...
                MsgType.ERROR, 'DiscreteZeroPole_pp', '');
            continue;
        end
        
        Gain_str = get_param(dzp_list{i}, 'Gain');
        [Gain, ~, status] = SLXUtils.evalParam(...
            model, ...
            get_param(dzp_list{i}, 'Parent'), ...
            dzp_list{i}, ...
            Gain_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                Gain_str, dzp_list{i}), ...
                MsgType.ERROR, 'DiscreteZeroPole_pp', '');
            continue;
        end
        
        [n,m] = size(Zeros);
        if m > 1 && n > 1
            if numel(Gain) == 1
                Gain = Gain*ones(1, m);
            end
        end
        blocktype= get_param(dzp_list{i}, 'BlockType');
        
        % Computing state space representation
        [A,B,C,D]=zp2ss(Zeros,Poles,Gain);
        if strcmp(blocktype, 'ZeroPole')
            ST = SLXUtils.getModelCompiledSampleTime(model);
            [A, B] = NASAPPUtils.c2d(A, B ,ST);
            ST = '-1';
        else
            ST = get_param(dzp_list{i},'SampleTime');
        end
        A = mat2str(A);
        B = mat2str(B);
        C = mat2str(C);
        D = mat2str(D);
        
        % replacing
        NASAPPUtils.replace_one_block(dzp_list{i},'pp_lib/DZP');
        %restoring info
        set_param(strcat(dzp_list{i},'/A'),...
            'Value',A);
        set_param(strcat(dzp_list{i},'/B'),...
            'Value',B);
        set_param(strcat(dzp_list{i},'/C'),...
            'Value',C);
        set_param(strcat(dzp_list{i},'/D'),...
            'Value',D);
        % Sample Time
        set_param(strcat(dzp_list{i},'/X0'),...
            'SampleTime',ST);
        set_param(strcat(dzp_list{i},'/U'),...
            'SampleTime',ST);
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('DiscreteZeroPole_pp pre-process has failed for block %s', dzp_list{i});
            continue;
        end        
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteZeroPole_pp', '');
end
end


