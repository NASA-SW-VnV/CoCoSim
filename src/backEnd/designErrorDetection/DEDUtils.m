classdef DEDUtils
    %DEDUTILS DesignErrorDetection(DED) utils functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        function prop = OutOfBoundCheck(indexPortNames, width)
            prop = {};
            % calculate Bound dimension
            widthMin = IntExpr(1);
            widthMax = IntExpr(width);
            % set the property
            lines = cell(numel(indexPortNames), 1);
            for j=1:numel(indexPortNames)
                % widthMin <= index and index <= widthMax
                lines{j} = BinaryExpr(BinaryExpr.AND, ...
                    BinaryExpr(BinaryExpr.LTE, widthMin, indexPortNames{j}), ...
                    BinaryExpr(BinaryExpr.LTE, indexPortNames{j}, widthMax));
            end
            if ~isempty(lines)
                prop = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, lines);
            end
        end
        function prop = OutMinMaxCheck(parent, blk, outputs, lus_dt)
            prop = {};
            if isequal(blk.OutMin, '[]') && isequal(blk.OutMax, '[]')
                % no need for the assertion.
                return;
            end
            if ~isequal(lus_dt, 'int') && ~isequal(lus_dt, 'real')
                % only important for 'int' and 'real' DataType
                return;
            end
            
            nb_outputs = numel(outputs);
            [outMin, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent,...
                blk, blk.OutMin);
            if status
                outMin = [];
            end
            [outMax, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent,...
                blk, blk.OutMax);
            if status
                outMax = [];
            end
            
            % adapt outMin and outMax to the dimension of output
            if ~isempty(outMin) && numel(outMin) < nb_outputs
                outMin = arrayfun(@(x) outMin(1), (1:nb_outputs));
            end
            if ~isempty(outMax) && numel(outMax) < nb_outputs
                outMax = arrayfun(@(x) outMax(1), (1:nb_outputs));
            end
            
            prop_parts = {};
            for j=1:nb_outputs
                if ~isempty(outMin)
                    lusMin = SLX2LusUtils.num2LusExp(outMin(j), lus_dt);
                end
                if ~isempty(outMax)
                    lusMax = SLX2LusUtils.num2LusExp(outMax(j), lus_dt);
                end
                if isempty(outMin)
                    prop_parts{j} = BinaryExpr(BinaryExpr.LTE, outputs{j},...
                        lusMax);
                elseif isempty(outMax)
                    prop_parts{j} = BinaryExpr(BinaryExpr.LTE, lusMin, ...
                        outputs{j});
                else
                    prop_parts{j} = BinaryExpr(BinaryExpr.AND, ...
                        BinaryExpr(BinaryExpr.LTE, lusMin, outputs{j}), ...
                        BinaryExpr(BinaryExpr.LTE, outputs{j}, lusMax));
                end
            end
            if ~isempty(prop_parts)
                prop = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, prop_parts);
            end
        end
    end
end

