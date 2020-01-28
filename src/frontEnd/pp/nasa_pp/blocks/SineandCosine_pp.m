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
function [status, errors_msg] = SineandCosine_pp(model)
% SineandCosine_pp Searches for Sine and Cosine blocks and inline thier
% contents to avoid algebraic loops.
%   model is a string containing the name of the model to search in
% Processing SineandCosine blocks
status = 0;
errors_msg = {};

SineandCosine_list = find_system(model, ...
    'LookUnderMasks', 'all', 'MaskType','Sine and Cosine');
if not(isempty(SineandCosine_list))
    display_msg('Replacing SineandCosine blocks...', MsgType.INFO,...
        'SineandCosine_pp', '');
    for i=1:length(SineandCosine_list)
        try
            display_msg(SineandCosine_list{i}, MsgType.INFO, ...
                'SineandCosine_pp', '');
            quarter_blocks = find_system(SineandCosine_list{i}, ...
                'FollowLinks', 'on', 'LookUnderMasks', 'all',...
                'MaskType', 'Fixed-Point-Private Quandrant Processing Sine');
            if isempty(quarter_blocks)
                continue;
            end
            quarter_block = quarter_blocks{1};
            % disable link for Sine and Cosine
            [status, errors_msg_i] = LinkStatus_pp( SineandCosine_list{i} );
            errors_msg = MatlabUtils.concat(errors_msg, errors_msg_i);
            if status
                continue;
            end
            % remove mask and atomic
            p = Simulink.Mask.get(quarter_block);
            if ~isempty(p), p.delete; end
            set_param(quarter_block,'TreatAsAtomicUnit', 'off');
            Simulink.BlockDiagram.expandSubsystem(quarter_block);
        catch me
            display_msg(me.getReport(), MsgType.DEBUG, 'SineandCosine_pp', '');
            status = 1;
            errors_msg{end + 1} = sprintf('SineandCosine pre-process has failed for block %s', SineandCosine_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', MsgType.INFO, 'SineandCosine_pp', '');
end

end

