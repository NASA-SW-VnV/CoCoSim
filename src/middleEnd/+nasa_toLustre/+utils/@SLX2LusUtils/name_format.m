
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
%% adapt blocks names to be a valid lustre names.
function str_out = name_format(str)
    str_out = strrep(str, newline, '_newline_'); % removing newline can cause a problem of similar names.
    str_out = regexprep(str_out, '^\s', '_');
    str_out = regexprep(str_out, '\s$', '_');
    str_out = strrep(str_out, ' ', '');
    str_out = strrep(str_out, '-', '_minus_');
    str_out = strrep(str_out, '+', '_plus_');
    str_out = strrep(str_out, '*', '_mult_');
    str_out = strrep(str_out, '>', '_gt_');
    str_out = strrep(str_out, '>=', '_gte_');
    str_out = strrep(str_out, '<', '_lt_');
    str_out = strrep(str_out, '<=', '_lte_');
    str_out = strrep(str_out, '.', '_dot_');
    str_out = strrep(str_out, '#', '_sharp_');
    str_out = strrep(str_out, '(', '_lpar_');
    str_out = strrep(str_out, ')', '_rpar_');
    str_out = strrep(str_out, '[', '_lsbrak_');
    str_out = strrep(str_out, ']', '_rsbrak_');
    str_out = strrep(str_out, '{', '_lbrak_');
    str_out = strrep(str_out, '}', '_rbrak_');
    str_out = strrep(str_out, ',', '_comma_');
    %             str_out = strrep(str_out, '/', '_slash_');
    str_out = strrep(str_out, '=', '_equal_');
    % for blocks starting with a digit.
    str_out = regexprep(str_out, '^(\d+)', 'x$1');
    str_out = regexprep(str_out, '/(\d+)', '/_$1');
    % for anything missing from previous cases.
    str_out = regexprep(str_out, '[^a-zA-Z0-9_/]', '_');
end

