function [body,vars,table_elem] = addTableCode(blkParams,...
        node_header,blk_inputs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % This function defines the blkParams.Table values defined by users.
        
    if blkParams.NumberOfAdjustedTableDimensions < ...
        blkParams.NumberOfTableDimensions
        nasa_toLustre.blocks.Interpolation_nD_To_Lustre.get_adjusted_table_node(...
            blkParams,node_header,blk_inputs);
        % TODO:  reduce blkParams.Table for Interpolaton_n-D with  positive number 
        % of sub-blkParams.Table selection dimension 

        %     dims = size(blkParams.Table);
        %     if blkParams.NumberOfAdjustedTableDimensions==1
        %         blkParams.Table = zeros(dims(1));
        %     elseif blkParams.NumberOfAdjustedTableDimensions==2
        %         blkParams.Table = zeros(dims(1),dims(2));
        %     elseif blkParams.NumberOfAdjustedTableDimensions==3
        %         blkParams.Table = zeros(dims(1),dims(2),dims(3));
        %     elseif blkParams.NumberOfAdjustedTableDimensions==4
        %         blkParams.Table = zeros(dims(1),dims(2),dims(3),dims(4));
        %     elseif blkParams.NumberOfAdjustedTableDimensions==5
        %         blkParams.Table = zeros(dims(1),dims(2),dims(3),dims(4),dims(5));
        %     elseif blkParams.NumberOfAdjustedTableDimensions==6
        %         blkParams.Table = zeros(dims(1),dims(2),dims(3),dims(4),dims(5),dims(6));
        %     elseif blkParams.NumberOfAdjustedTableDimensions==7
        %         blkParams.Table = zeros(dims(1),dims(2),dims(3),dims(4),dims(5),dims(6),dims(7));
        %     else
        %         % error:  we don't support more than 7
        %     end
    else
        table_elem = cell(1, numel(blkParams.Table));
        body = cell(1, numel(blkParams.Table));
        vars = cell(1, numel(blkParams.Table));
        for i=1:numel(blkParams.Table)
            table_elem{i} = nasa_toLustre.lustreAst.VarIdExpr(...
                sprintf('table_elem_%d',i));
            vars{i} = nasa_toLustre.lustreAst.LustreVar(...
                table_elem{i},'real');
            if ~(LookupType.isLookupDynamic(blkParams.lookupTableType))
                body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, ...
                    nasa_toLustre.lustreAst.RealExpr(blkParams.Table(i)));
            else
                body{i} = nasa_toLustre.lustreAst.LustreEq(table_elem{i}, ...
                    node_header.inputs_name{3}{i});
            end


        end
    end
end
