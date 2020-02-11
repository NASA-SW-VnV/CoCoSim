
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
function code = print(obj, backend, inPreludeFile)
    % inPreludeFile is true if the code is printed in plu file.
    % backend can be PRELUDE but printed in "lus" file for the monoperiodic
    % nodes implementation. They should respect some restriction as no starting
    % with underscore in variable/node names.
    if ~exist('inPreludeFile', 'var')
        inPreludeFile = false;
    end
    lines = {};
    %% metaInfo
    if ~isempty(obj.metaInfo)
        if ischar(obj.metaInfo)
            if LusBackendType.isPRELUDE(backend) && inPreludeFile
                lines{end + 1} = sprintf('--%s\n',...
                    strrep(obj.metaInfo, newline, '--'));
            else
                lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                    obj.metaInfo);
            end
        else
            lines{end + 1} = obj.metaInfo.print(backend);
        end
    end
    %% PRELUDE for main node
    if LusBackendType.isPRELUDE(backend) ...
            && inPreludeFile...
            && obj.isMain
        for i=1:length(obj.inputs)
            lines{end + 1} = sprintf('sensor %s wcet 1;\n', obj.inputs{i}.getId());
        end
        for i=1:length(obj.outputs)
            lines{end + 1} = sprintf('actuator %s wcet 1;\n', obj.outputs{i}.getId());
        end
    end
    %%    
    if obj.isImported
        isImported_str = 'imported';
    else
        isImported_str = '';
    end
    semicolon =';';
    if LusBackendType.isPRELUDE(backend) && inPreludeFile
        semicolon = '';
    end
    nodeName = obj.name;
    %PRELUDE does not support "_" in the begining of the word.
    if LusBackendType.isPRELUDE(backend) ...
            && MatlabUtils.startsWith(nodeName, '_')
        nodeName = sprintf('x%s', nodeName);
    end
    lines{end + 1} = sprintf('node %s %s(%s)\nreturns(%s)%s\n', ...
        isImported_str, ...
        nodeName, ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.inputs, backend, true), ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.outputs, backend, true), ...
        semicolon);
    if ~isempty(obj.localContract) && ~inPreludeFile
        lines{end + 1} = obj.localContract.print(backend);
    end

    if obj.isImported
        code = MatlabUtils.strjoin(lines, '');
        return;
    end

    if ~isempty(obj.localVars)
        lines{end + 1} = sprintf('var %s\n', ...
            nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.localVars, backend));
    end
    lines{end+1} = sprintf('let\n');
    % local Eqs
    for i=1:numel(obj.bodyEqs)
        eq = obj.bodyEqs{i};
        if isempty(eq)
            continue;
        end
        lines{end+1} = sprintf('\t%s\n', ...
            eq.print(backend));

    end
    lines{end+1} = sprintf('tel\n');
    code = MatlabUtils.strjoin(lines, '');
end
