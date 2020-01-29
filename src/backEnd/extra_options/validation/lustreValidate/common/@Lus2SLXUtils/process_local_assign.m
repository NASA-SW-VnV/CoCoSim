%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

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

