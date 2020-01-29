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
function new_model_path = importLusReq(current_openedSS, lusFilePath, mappingPath, createNewFile)
    %IMPORTLUSREQ takes a Simulink model and Lustre file to import it as
    %requirement attached to the simulink model
    global LUSTREC;
    model_full_path = get_param(bdroot(current_openedSS), 'FileName');
    if nargin < 2
        errordlg('Lustre file path is required');
        return;
    end
    if  ~exist(lusFilePath, 'file')
        errordlg(sprintf('Lustre file %s can not be Found', lusFilePath));
        return;
    end
    if ~(MatlabUtils.endsWith(lusFilePath, '.lus') || MatlabUtils.endsWith(lusFilePath, '.lusi'))
        errordlg('Lustre file extension should be ".lus"');
        return;
    end
    
    if  nargin >= 3 && ~isempty(mappingPath) && ~exist(mappingPath, 'file')
        errordlg(sprintf('Mapping file %s between contract variables and Simulink can not be found', mappingPath));
        mappingPath = '';
    elseif nargin < 3
        mappingPath = '';
    end
    
    if nargin < 4 
        createNewFile = true;
    end
    
    
    %[lus_dir, ~, ~] = fileparts(lusFilePath);
    
    [model_dir, file_name, ~] = fileparts(model_full_path);
    output_dir = fullfile(model_dir, 'cocosim_output', file_name);
    if ~exist(output_dir, 'dir'); MatlabUtils.mkdir(output_dir); end
    
    
    % check syntax
    [~, syntax_status, output] = LustrecUtils.generate_lusi(lusFilePath, LUSTREC );
    if syntax_status && ~isempty(output)
        display_msg('Lustre Syntax check has failed for contract code. The parsing error is the following:', MsgType.ERROR, 'TOLUSTRE', '');
        [~, lustre_file_base, ~] = fileparts(lusFilePath);
        output = regexprep(output, lusFilePath, HtmlItem.addOpenFileCmd(lusFilePath, lustre_file_base));
        display_msg(output, MsgType.ERROR, 'TOLUSTRE', '');
        return;
    end
    % generate json file of lustre
    [lus_IR_path, status] = LustrecUtils.generate_emf(lusFilePath, output_dir);
    if status
        display_msg('Could not export Lustre AST.', MsgType.ERROR, 'importLusReq', '');
        return;
    end
    [new_model_path, status] = ImportLusUtils.importLustreSpec(...
        current_openedSS,...
        lus_IR_path,...
        mappingPath, ...
        createNewFile);
    if status
        return;
    end
    display_msg('Generating Req Completed', MsgType.RESULT, 'importLusReq', '');
end

