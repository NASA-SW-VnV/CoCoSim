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

function  [x2, y2] = process_local_assign(node_block_path, blk_exprs, var, node_name, x2, y2)
    if y2 < 30000; y2 = y2 + 150; else, x2 = x2 + 500; y2 = 100; end;
    
    ID = BUtils.adapt_block_name(var{1});
    lhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).lhs, node_name);
    
    lhs_path = BUtils.get_unique_block_name(strcat(node_block_path,'/',ID, '_lhs'));
    rhs_path = BUtils.get_unique_block_name(strcat(node_block_path,'/',ID,'_rhs'));
    
    rhs_type = blk_exprs.(var{1}).rhs.type;
    if strcmp(rhs_type, 'constant')
        rhs_name = blk_exprs.(var{1}).rhs.value;
        add_block('simulink/Commonly Used Blocks/Constant',...
            rhs_path,...
            'Value',rhs_name,...
            'Position',[x2 y2 (x2+50) (y2+50)]);
        dt = Lus2SLXUtils.getArgDataType(blk_exprs.(var{1}).rhs);
        
        if strcmp(dt, 'bool')
            set_param(rhs_path, 'OutDataTypeStr', 'boolean');
        elseif strcmp(dt, 'int')
            % keep it as inherit for MCDC importation
            %TODO: pass type information from Simulink if we have it.
            set_param(rhs_path, 'OutDataTypeStr', 'Inherit: Inherit via back propagation');
        elseif strcmp(dt, 'real')
            set_param(rhs_path, 'OutDataTypeStr', 'double');
        end
        
    elseif strcmp(rhs_type, 'array access')
        IndexParamArray = {};
        IndexOptionsCell = {};
        array = blk_exprs.(var{1}).rhs;
        idx_port_handles = [];
        nb_port_idx = 0;
        while(isfield(array, 'array'))
            if isfield(array, 'idx')
                if strcmp(array.idx.type, 'constant')
                    IndexParamArray{end+1} = array.idx.value;
                    IndexOptionsCell{end+1} = 'Index vector (dialog)';
                elseif strcmp(array.idx.type, 'variable')
                    IndexParamArray{end+1} = '';
                    IndexOptionsCell{end+1} = 'Index vector (port)';
                    idx_name = BUtils.adapt_block_name(array.idx.value, node_name);
                    nb_port_idx = nb_port_idx + 1;
                    idx_path = BUtils.get_unique_block_name(strcat(node_block_path,'/',ID,'_selector_idx_', num2str(nb_port_idx)));
                    h = add_block('simulink/Signal Routing/From',...
                        idx_path,...
                        'GotoTag',idx_name,...
                        'TagVisibility', 'local');
                   idx_port_handles(nb_port_idx) = h; 
                else
                    ME = MException('MyComponent:ArrayAccess', ...
                        'Node %s has an array access with non-constant index. Not Supported.', ...
                        node_name);
                    throw(ME);
                end
            end
            array = array.array;
        end
        
        % dimensions should be fipped
        IndexParamArray = flip(IndexParamArray);
        IndexOptionsCell = flip(IndexOptionsCell);
        idx_port_handles = flip(idx_port_handles);
        IndexOptions = MatlabUtils.strjoin(IndexOptionsCell, ',');
        NumberOfDimensions = length(IndexParamArray);
        selector_path = BUtils.get_unique_block_name(strcat(node_block_path,'/',ID,'_rhs_selector'));
        add_block('simulink/Signal Routing/Selector',...
            selector_path,...
            'MakeNameUnique', 'on', ...
            'IndexMode', 'Zero-based',...
            'IndexParamArray', IndexParamArray, ...
            'NumberOfDimensions', num2str(NumberOfDimensions),...
            'IndexOptions',IndexOptions, ...
            'InputPortWidth', '-1');
        
        rhs_name = BUtils.adapt_block_name(array.value, node_name);
        add_block('simulink/Signal Routing/From',...
            rhs_path,...
            'GotoTag',rhs_name,...
            'TagVisibility', 'local');
        
        SrcBlkH = get_param(rhs_path,'PortHandles');
        DstBlkH = get_param(selector_path, 'PortHandles');
        add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        % add port indexes: e.g., x[i][j]
        for i=1:nb_port_idx
            SrcBlkH = get_param(idx_port_handles(i),'PortHandles');
            add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(i+1), 'autorouting', 'on');
        end
        % change src block to Selector block
        rhs_path = selector_path;
    else
        rhs_name = BUtils.adapt_block_name(blk_exprs.(var{1}).rhs.value, node_name);
        add_block('simulink/Signal Routing/From',...
            rhs_path,...
            'GotoTag',rhs_name,...
            'TagVisibility', 'local', ...
            'Position',[x2 y2 (x2+50) (y2+50)]);
    end
    add_block('simulink/Signal Routing/Goto',...
        lhs_path,...
        'GotoTag',lhs_name,...
        'TagVisibility', 'local', ...
        'Position',[(x2+100) y2 (x2+150) (y2+50)]);
    
    SrcBlkH = get_param(rhs_path,'PortHandles');
    DstBlkH = get_param(lhs_path, 'PortHandles');
    add_line(node_block_path, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
end

