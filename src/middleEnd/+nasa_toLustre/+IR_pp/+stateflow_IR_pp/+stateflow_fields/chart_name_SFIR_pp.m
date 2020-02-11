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
function [new_ir, status] = chart_name_SFIR_pp(new_ir, isSF)
    %chart_name_SFIR_pp change the chart path to one name to be adapted to lustre
    %compiler that only accept chart name to be the root name of all paths.
    %file_name/subsystem_A/chart1 -> file_name_subsystem_A_chart1
    

    
    
    status = 0;
    if nargin < 2
        isSF = 0;
    end
    if isSF
        new_name = regexp(new_ir.Path, filesep, 'split');
        new_name = new_name{end};
    else
        new_name = nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.adapt_root_name(new_ir.Path);
    end
    origin_name_pattern = strcat('^', new_ir.Path);
    
    if isfield(new_ir, 'States')
        new_ir.States = adapt_states_name(new_ir.States, origin_name_pattern, new_name);
    end
    if isfield(new_ir, 'Junctions')
        new_ir.Junctions = adapt_junctions_name(new_ir.Junctions, origin_name_pattern, new_name);
    end
    new_ir.Origin_path = new_ir.Path;
    new_ir.Path = new_name;
    
    if isfield(new_ir, 'GraphicalFunctions')
        for i=1:numel(new_ir.GraphicalFunctions)
            new_ir.GraphicalFunctions{i}.Composition = adapt_composition_name(...
                new_ir.GraphicalFunctions{i}.Composition, origin_name_pattern, new_name);
            new_ir.GraphicalFunctions{i} = nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_fields.chart_name_SFIR_pp( new_ir.GraphicalFunctions{i}, 1 );
        end
    end
    
    if isfield(new_ir, 'TruthTables')
        for i=1:numel(new_ir.TruthTables)
            new_ir.TruthTables{i} = nasa_toLustre.IR_pp.stateflow_IR_pp.stateflow_fields.chart_name_SFIR_pp( new_ir.TruthTables{i}, 1 );
        end
    end
end

%% adapt root name
function states = adapt_states_name(states, origin_name_pattern, new_name)
    for i=1:numel(states)
        states{i}.Origin_path = states{i}.Path;
        states{i}.Path = regexprep(states{i}.Path, origin_name_pattern, new_name);
        
        states{i}.OuterTransitions = adapt_transitions_name(...
            states{i}.OuterTransitions, origin_name_pattern, new_name);
        
        states{i}.InnerTransitions = adapt_transitions_name(...
            states{i}.InnerTransitions, origin_name_pattern, new_name);
        
        states{i}.Composition = adapt_composition_name(...
            states{i}.Composition, origin_name_pattern, new_name);
        
    end
end

%% adapt junctions root name
function junctions = adapt_junctions_name(junctions, origin_name_pattern, new_name)
    for i=1:numel(junctions)
        junctions{i}.Origin_path = junctions{i}.Path;
        junctions{i}.Path = regexprep(junctions{i}.Path, origin_name_pattern, new_name);
        
        junctions{i}.OuterTransitions = adapt_transitions_name(...
            junctions{i}.OuterTransitions, origin_name_pattern, new_name);
        
    end
end

%% adapt root name for transitions
function trans = adapt_transitions_name(trans, origin_name_pattern, new_name)
    for j=1:numel(trans)
        trans{j}.Destination.Origin_path = trans{j}.Destination.Name;
        trans{j}.Source =  ...
            regexprep(...
            trans{j}.Source,...
            origin_name_pattern, new_name);
        trans{j}.Destination.Name =  ...
            regexprep(...
            trans{j}.Destination.Name,...
            origin_name_pattern, new_name);
        
    end
end
%% adapt root name for internal composition

function internal_composition = adapt_composition_name(...
        internal_composition, origin_name_pattern, new_name)
    
    internal_composition.DefaultTransitions = adapt_transitions_name(...
        internal_composition.DefaultTransitions, origin_name_pattern, new_name);
end
