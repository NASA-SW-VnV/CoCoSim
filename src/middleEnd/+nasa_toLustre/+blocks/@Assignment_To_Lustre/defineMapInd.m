%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
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
function [isPortIndex,ind,selectorOutputDimsArray] = ...
        defineMapInd(~,parent,blk,inputs,U_expanded_dims,isSelector)
  
    
    % if isSelector then U_expanded_dims should be in_matrix_dimension{1}
    indexPortNumber = 0;
    isPortIndex = false;
    IndexMode = blk.IndexMode;
    indPortNumber = zeros(1,numel(blk.IndexOptionArray));
    [numOutDims, ~, ~] = ...
        nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.NumberOfDimensions);
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
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
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
                    ind{i}{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                        inputs{portNumber}{j},...
                        nasa_toLustre.lustreAst.IntExpr(1));
                    %sprintf('%s + 1',inputs{portNumber}{j});
                else
                    ind{i}{j} = inputs{portNumber}{j};
                end
            end
        elseif strcmp(blk.IndexOptionArray{i}, 'Starting index (dialog)')
            [Idx, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.IndexParamArray{i});
            if isSelector
                [selectorOutputDimsArray(i), ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});                
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
            if isSelector
                [selectorOutputDimsArray(i), ~, ~] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.OutputSizeArray{i});
                for j=1:selectorOutputDimsArray(i)
                    
                    if strcmp(IndexMode, 'Zero-based')
                        ind{i}{j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                            nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                            {...
                            inputs{portNumber}{1}, ...
                            nasa_toLustre.lustreAst.IntExpr(1), ...
                            nasa_toLustre.lustreAst.IntExpr(j-1)...
                            });
                        %sprintf('%s + 1 + %d',inputs{portNumber}{1},(j-1));
                    else
                        ind{i}{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                            inputs{portNumber}{1},...
                            nasa_toLustre.lustreAst.IntExpr(j-1));
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
                            ind{i}{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                                inputs{portNumber}{1},...
                                nasa_toLustre.lustreAst.IntExpr(1));
                            %sprintf('%s + 1',inputs{portNumber}{1});
                        else
                            ind{i}{j} = inputs{portNumber}{j};
                        end
                    else
                        if strcmp(IndexMode, 'Zero-based')
                            ind{i}{j} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                                nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                                {...
                                inputs{portNumber}{1}, ...
                                nasa_toLustre.lustreAst.IntExpr(1), ...
                                nasa_toLustre.lustreAst.IntExpr(j-1)...
                                });
                            %sprintf('%s + 1 + d',inputs{portNumber}{1},(j-1));
                        else
                            ind{i}{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,...
                                inputs{portNumber}{1},...
                                nasa_toLustre.lustreAst.IntExpr(j-1));
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
