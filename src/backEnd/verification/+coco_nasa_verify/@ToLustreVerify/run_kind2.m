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
function failed = run_kind2(model, nom_lustre_file, xml_trace, ...
        top_node_name, Assertions_list, contractBlocks_list, KIND2)
    
    if ~isempty(Assertions_list) && ~isempty(contractBlocks_list)
        display_msg('Having both Assertion/Proof blocks and contracts are not supported in KIND2.', MsgType.ERROR, 'toLustreVerify.run_kind2', '');
        return;
    end
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    if isfield(CoCoSimPreferences, 'verificationTimeout')
        timeout = CoCoSimPreferences.verificationTimeout;
    else
        timeout = 120;
    end
    if ~isempty(Assertions_list)
        OPTS = ' --slice_nodes false --check_subproperties true ';
        timeout_analysis = timeout / numel(Assertions_list);
    elseif ~isempty(contractBlocks_list)
        if CoCoSimPreferences.compositionalAnalysis
            OPTS = '--modular true --compositional true';
        else
            OPTS = '--modular true';
        end
        timeout_analysis = timeout / numel(contractBlocks_list);
    else
        display_msg('No Property to check.', MsgType.RESULT, 'toLustreVerify.run_kind2', '');
        return;
    end
    tkind2_start = tic;
    [failed, kind2_out] = coco_nasa_utils.Kind2Utils.runKIND2(...
        nom_lustre_file,...
        top_node_name, ...
        OPTS, KIND2, timeout, timeout_analysis);
    tkind2_finish = toc(tkind2_start);
    if failed
        return;
    end
    display_msg(sprintf('Total KIND2 running time: %f seconds', tkind2_finish), Constants.RESULT, 'Time', '');
    % sometimes kind2 give up quickly and give everything as UNKNOWN.
    % and we get better results in the second run so we run it twice.
    if tkind2_finish < 10 ...
            && coco_nasa_utils.MatlabUtils.contains(kind2_out, 'unknown</Answer>') ...
            && ~coco_nasa_utils.MatlabUtils.contains(kind2_out, 'falsifiable</Answer>') ...
            && ~coco_nasa_utils.MatlabUtils.contains(kind2_out, 'valid</Answer>')
        display_msg('Re-running Kind2', MsgType.INFO, 'toLustreVerify.run_kind2', '');
        [failed, kind2_out] = coco_nasa_utils.Kind2Utils.runKIND2(...
            nom_lustre_file,...
            top_node_name, ...
            OPTS, KIND2, timeout, timeout_analysis);
        if failed, return; end
    end
    % Sometimes the Initial state is unsat
    if coco_nasa_utils.MatlabUtils.contains(kind2_out, 'the system has no reachable states')
        display_msg('The system has no reachable states.', MsgType.ERROR, 'toLustreVerify.run_kind2', '');
    end
    mapping_file = xml_trace.json_file_path;
    try
        [failed, verificationResults] = cocoSpecKind2(nom_lustre_file, mapping_file, kind2_out);
        if failed
            return;
        end
        export_verif_results(model, verificationResults, xml_trace);
        VerificationMenu.displayHtmlVerificationResultsCallbackCode(model);
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'toLustreVerify.run_kind2', '');
        display_msg('Something went wrong in Verification.', MsgType.ERROR, 'toLustreVerify.run_kind2', '');
    end
    
end


%%
function export_verif_results(model, verificationResults, xml_trace)
    try
        % pre-process verificationResults
        % change Lustre names to Simulink names
        res = pp_verif_results(verificationResults, xml_trace);
        %% export to json
        json_fname = strcat(model,'_KIND2_verificationResults_', strrep(datestr(now), ' ', '-'),'.json');
        [output_dir, ~, ~] = fileparts(xml_trace.xml_file_path);
        [~, json_path] = coco_nasa_utils.MatlabUtils.json_export(...
            res, output_dir, json_fname);
        display_msg(sprintf('Verification results are exported to Json file: %s', json_path),...
            MsgType.RESULT, 'run_kind2', '');
    catch me
        display_msg(me.getReport(), MsgType.DEBUG, 'toLustreVerify.run_kind2', '');
    end
end

%%
function res = pp_verif_results(verificationResults, xml_trace)
    res = struct();
    res.modePath = xml_trace.model_full_path;
    Nodes = containers.Map();
    for i = 1 : length(verificationResults.analysisResults)
        s = verificationResults.analysisResults{i};
        r = struct();
        r.top = s.top;
        r.abstract = s.abstract;
        r.assumptions = lus_nodes_to_slx_path(s.assumptions, xml_trace);
        r.properties = cellfun(@(x) pp_property(x, xml_trace), s.properties,...
            'UniformOutput', 0);
        if isKey(Nodes, s.top)
            Nodes(s.top) = coco_nasa_utils.MatlabUtils.concat(Nodes(s.top), r);
        else
            Nodes(s.top) = {r};
        end
    end
    res.analysisResults = Nodes;
end

function res = pp_property(prop, xml_trace)
    res = prop;
    if isfield(prop, 'counterExample')
        res.counterExample = pp_counterExample(prop.counterExample, xml_trace);
    end
end

function res = pp_counterExample(cex, xml_trace)
    res = pp_node(cex.node, xml_trace);
    function node = pp_node(cex_node, xml_trace)
        node = struct();
        nodeName = lus_nodes_to_slx_path(cex_node.name, xml_trace);
        if length(nodeName) == 1
            node.name = nodeName{1};
        else
            node.name = cex_node.name;
        end
        node.timeSteps = cex_node.timeSteps;
        node.streams = cex_node.streams;
        node.nodes = {};
        if isfield(cex_node, 'nodes')
            for i = 1:length(cex_node.nodes)
                node.nodes{i} = pp_node(cex_node.nodes{i}, xml_trace);
            end
        end
    end
    
end


function paths = lus_nodes_to_slx_path(string, xml_trace)
    t = regexp(string, '\w+', 'match');
    paths = {};
    for i = 1 : length(t)
        if isKey(xml_trace.nodes_map, t{i})
            elt = xml_trace.nodes_map(t{i});
            paths{end+1} = char(elt.getAttribute('OriginPath'));
        end
    end
end
