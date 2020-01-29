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

function add_operator_block(op_path, operator, x, y2, dt)
    switch operator
        case {'+', '-'}
            operator = regexprep(operator,'+','++');
            operator = regexprep(operator,'-','+-');
            add_block('simulink/Math Operations/Add',...
                op_path,...
                'Inputs', operator, ...
                'OutDataTypeStr', dt, ...
                'Position',[(x+200) y2 (x+250) (y2+50)]);
        case 'uminus'
            add_block('simulink/Math Operations/Gain',...
                op_path,...
                'Gain', '-1', ...
                'OutDataTypeStr', dt, ...
                'Position',[(x+200) y2 (x+250) (y2+50)]);
        case '*'
            add_block('simulink/Math Operations/Product',...
                op_path,...
                'OutDataTypeStr', dt, ...
                'Position',[(x+200) y2 (x+250) (y2+50)]);
        case '/'
            add_block('simulink/Math Operations/Divide',...
                op_path,...
                'OutDataTypeStr', dt, ...
                'Position',[(x+200) y2 (x+250) (y2+50)]);
        case 'mod'
%             add_block('simulink/Math Operations/Math Function',...
%                 op_path,...
%                 'Operator', 'rem',...
%                 'OutDataTypeStr', dt, ...
%                 'Position',[(x+200) y2 (x+250) (y2+50)]);
            % I assume mod is mode of int_div_euclidean option enabled in lustrec
            % it's the mathematical mod and not C language mod.
            if ~bdIsLoaded('pp_lib'); load_system('pp_lib.slx'); end
            add_block('pp_lib/mode_int_div_euclidean_lustrec',...
                op_path,...
                'Position',[(x+200) y2 (x+250) (y2+50)]);
        case {'&&', '||', 'xor', 'not'}
            operator = regexprep(operator,'&&','AND');
            operator = regexprep(operator,'||','OR');
            operator = regexprep(operator,'xor','XOR');
            operator = regexprep(operator,'not','NOT');
            add_block('simulink/Logic and Bit Operations/Logical Operator',...
                op_path,...
                'Operator', operator,...
                'Position',[(x+200) y2 (x+250) (y2+50)]);


        case {'=', '!=', '<','<=', '>=', '>'}
            if strcmp(operator, '='); operator = regexprep(operator,'=','=='); end
            operator = regexprep(operator,'!=','~=');
            operator = regexprep(operator,'<>','~=');
            add_block('simulink/Logic and Bit Operations/Relational Operator',...
                op_path,...
                'Operator', operator,...
                'Position',[(x+200) y2 (x+250) (y2+50)]);

        case 'impl'
            if ~bdIsLoaded('cocosimLibs'); load_system('cocosimLibs.slx'); end
            add_block('cocosimLibs/Implies',...
                op_path,...
                'Position',[(x+200) y2 (x+250) (y2+50)]);
        otherwise
            display_msg(['Unkown operator ' operator], MsgType.ERROR, 'LUS2SLX', '');
    end

end

