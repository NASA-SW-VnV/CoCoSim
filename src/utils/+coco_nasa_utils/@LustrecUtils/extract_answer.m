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
function [answer, CEX_XML] = extract_answer(...
        solver_output,solver, ...
        file_name, ...
        node_name, ...
        output_dir)
    answer = '';
    CEX_XML = [];
    if isempty(solver_output)
        return
    end
    tmp_file = fullfile(...
        output_dir, ...
        strcat(file_name, '_', node_name, '.xml'));
    fid = fopen(tmp_file, 'w');
    if fid == -1
        display_msg(['Couldn''t create file ' tmp_file],...
            MsgType.ERROR, 'coco_nasa_utils.LustrecUtils.extract_answer', '');
        return;
    end
    fprintf(fid, solver_output);
    fclose(fid);
    xDoc = xmlread(tmp_file);
    xProperties = xDoc.getElementsByTagName('Property');
    property = xProperties.item(0);
    try
        answer = ...
            property.getElementsByTagName('Answer').item(0).getTextContent;
    catch
        answer = 'ERROR';
    end

    if strcmp(solver, 'KIND2') || strcmp(solver, 'JKIND') ...
            || strcmp(solver, 'K') || strcmp(solver, 'J')
        if strcmp(answer, 'valid')
            answer = 'SAFE';
        elseif strcmp(answer, 'falsifiable')
            answer = 'CEX';
        end
    end
    if strcmp(answer, 'CEX')
        answer = 'UNSAFE';
    end
    if strcmp(answer, 'UNSAFE')
        if strcmp(solver, 'JKIND') || strcmp(solver, 'J')
            xml_cex = xDoc.getElementsByTagName('Counterexample');
        else
            xml_cex = xDoc.getElementsByTagName('CounterExample');
        end
        if xml_cex.getLength > 0
            CEX_XML = xml_cex;
        else
            msg = sprintf('Could not parse counter example from %s', ...
                solver_output);
            display_msg(msg, MsgType.ERROR, 'Property Checking', '');
        end
    end
    msg = sprintf('Solver Result for file %s of property %s is %s', ...
        file_name, node_name, answer);
    display_msg(msg, MsgType.INFO, 'coco_nasa_utils.LustrecUtils.extract_answer', '');
end

