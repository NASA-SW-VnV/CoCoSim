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
%% verification file
function verif_lus_path = create_mutant_verif_file(...
        lus_file_path,...
        mutant_lus_fpath, ...
        node_struct, ...
        node_name, ...
        new_node_name, ...
        model_checker)
    % create verification file
    [file_parent, mutant_lus_file_name, ~] = fileparts(mutant_lus_fpath);
    output_dir = fullfile(...
        file_parent, strcat(mutant_lus_file_name, '_build'));
    if ~exist(output_dir, 'dir'); mkdir(output_dir); end
    verif_lus_path = fullfile(...
        output_dir, strcat(mutant_lus_file_name, '_verif.lus'));

    if coco_nasa_utils.MatlabUtils.isLastModified(mutant_lus_fpath, verif_lus_path)...
            && coco_nasa_utils.MatlabUtils.isLastModified(lus_file_path, verif_lus_path)
        display_msg(...
            ['file ' verif_lus_path ' has been already generated'],...
            MsgType.DEBUG,...
            'Validation', '');
        return;
    end
    filetext1 = ...
        coco_nasa_utils.LustrecUtils.adapt_lustre_text(fileread(lus_file_path), model_checker, output_dir);
    sep_line =...
        '--******************** second file ********************';
    filetext2 = ...
        coco_nasa_utils.LustrecUtils.adapt_lustre_text(fileread(mutant_lus_fpath), model_checker, output_dir);
    filetext2 = regexprep(filetext2, '#open\s*<\w+>','');
    verif_line = ...
        '--******************** sVerification node *************';
    verif_node = coco_nasa_utils.LustrecUtils.construct_verif_node(...
        node_struct, node_name, new_node_name);

    verif_lus_text = sprintf('%s\n%s\n%s\n%s\n%s', ...
        filetext1, sep_line, filetext2, verif_line, verif_node);


    fid = fopen(verif_lus_path, 'w');
    fprintf(fid, verif_lus_text);
    fclose(fid);
end
