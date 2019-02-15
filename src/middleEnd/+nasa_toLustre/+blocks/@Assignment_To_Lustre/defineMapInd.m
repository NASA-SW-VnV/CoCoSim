function [isPortIndex,ind,selectorOutputDimsArray] = ...
        defineMapInd(~,parent,blk,inputs,U_expanded_dims,isSelector)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % if isSelector then U_expanded_dims should be in_matrix_dimension{1}
    indexPortNumber = 0;
    isPortIndex = false;
    IndexMode = blk.IndexMode;
    indPortNumber = zeros(1,numel(blk.IndexOptionArray));
    [numOutDims, ~, ~] = ...
        Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
    selectorOutputDimsArray = ones(1,numOutDims);
    if isSelector
        AssignSelectAll = 'Select all';
        AssignSelectToLustre = 'Selector_To_Lustre';
        portNumberOffset = 1;
    else
        AssignSelectAll = 'Assign all';
        AssignSelectToLustre = 'Assignment_To_Lustre';
        portNumberOffset = 2;  % 1st and 2nd for Y0 and U
    end
    for i=1:numel(blk.IndexOptionArray)
        if strcmp(blk.IndexOptionArray{i}, AssignSelectAll)
            ind{i} = (1:U_expanded_dims.dims(i));
            selectorOutputDimsArray(i) = U_expanded_dims.dims(i);
        elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (dialog)')
            [Idx, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
            ind{i} = Idx;
            selectorOutputDimsArray(i) = numel(Idx);
        elseif strcmp(blk.IndexOptionArray{i}, 'Index vector (port)')
            isPortIndex = true;
            indexPortNumber = indexPortNumber + 1;
            portNumber = indexPortNumber + portNumberOffset;
            indPortNumber(i) = portNumber;
            selectorOutputDimsArray(i) = numel(inputs{portNumber});
            for j=1:numel(inputs{portNumber})
                if strcmp(IndexMode, 'Zero-based')
                    ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                        inputs{portNumber}{j},...
                        IntExpr(1));
                    %sprintf('%s + 1',inputs{portNumber}{j});
                else
                    ind{i}{j} = inputs{portNumber}{j};
                end
            end
        elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
            [selectorOutputDimsArray(i), ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});
            [Idx, ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
            if isSelector
                ind{i} = (Idx:Idx+selectorOutputDimsArray(i)-1);
            else
                % check for scalar or vector
                if U_expanded_dims.numDs == 1
                    if U_expanded_dims.dims(1) == 1   %scalar
                        ind{i} = Idx;
                    else     %vector
                        ind{i} = (Idx:Idx+U_expanded_dims.dims(1)-1);
                    end
                else      % matrix
                    ind{i} = (Idx:Idx+U_expanded_dims.dims(i)-1);
                end
            end
            
        elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (port)')
            isPortIndex = true;
            indexPortNumber = indexPortNumber + 1;
            portNumber = indexPortNumber + portNumberOffset;
            indPortNumber(i) = portNumber;
            [selectorOutputDimsArray(i), ~, ~] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});
            if isSelector
                for j=1:selectorOutputDimsArray(i)
                    
                    if strcmp(IndexMode, 'Zero-based')
                        ind{i}{j} = BinaryExpr.BinaryMultiArgs(...
                            BinaryExpr.PLUS, ...
                            {...
                            inputs{portNumber}{1}, ...
                            IntExpr(1), ...
                            IntExpr(j-1)...
                            });
                        %sprintf('%s + 1 + %d',inputs{portNumber}{1},(j-1));
                    else
                        ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                            inputs{portNumber}{1},...
                            IntExpr(j-1));
                        %sprintf('%s + %d',inputs{portNumber}{1},(j-1));
                    end
                end
            else
                if U_expanded_dims.numDs == 1
                    jend = U_expanded_dims.dims(1);
                else
                    jend = U_expanded_dims.dims(i);
                end
                for j=1:jend
                    if j==1
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                                inputs{portNumber}{1},...
                                IntExpr(1));
                            %sprintf('%s + 1',inputs{portNumber}{1});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    else
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = BinaryExpr.BinaryMultiArgs(...
                                BinaryExpr.PLUS, ...
                                {...
                                inputs{portNumber}{1}, ...
                                IntExpr(1), ...
                                IntExpr(j-1)...
                                });
                            %sprintf('%s + 1 + d',inputs{portNumber}{1},(j-1));
                        else
                            ind{i}{j} = BinaryExpr(BinaryExpr.PLUS,...
                                inputs{portNumber}{1},...
                                IntExpr(j-1));
                            %sprintf('%s + d',inputs{portNumber}{1},(j-1));
                        end
                    end
                end
            end
        elseif strcmp(blk.IndexOptionArray{i}, 'Starting and ending indices (port)')
            display_msg(sprintf('IndexOption  %s not supported in block %s',...
                blk.IndexOptionArray{i}, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, AssignSelectToLustre, '');
        else
            % should not be here
            display_msg(sprintf('IndexOption  %s not recognized in block %s',...
                blk.IndexOptionArray{i}, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                MsgType.ERROR, AssignSelectToLustre, '');
        end
        if strcmp(IndexMode, 'Zero-based') && indPortNumber(i) == 0
            if ~strcmp(blk.IndexOptionArray{i}, AssignSelectAll)
                ind{i} = ind{i} + 1;
            end
        end
    end
end
