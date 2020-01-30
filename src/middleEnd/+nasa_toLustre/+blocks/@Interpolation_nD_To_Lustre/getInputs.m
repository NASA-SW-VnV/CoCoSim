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
function [inputs] = getInputs(obj, parent, blk, blkParams)
    %GETINPUTS gets and pre-process inputs to k, f format.
    % if the input is using bus, it divide it into two seperated inputs (index
    % and fraction) .
    % In the case of input is a dimension selection, it transform it as an index
    % and extend inputs by a fraction equal to zero.
    RndMeth = 'Simplest'; %blk.RndMeth; % RndMeth of the block is only for fixed type computations.
    SaturateOnIntegerOverflow = blk.SaturateOnIntegerOverflow;
    
    widths = blk.CompiledPortWidths.Inport;
    nbInpots = numel(widths);
    
    % start from the last input. It can be Table values "input port" or
    % selection index "s" or fraction.
    inputs = {};
    
    % If Table source is "Input port"
    tableIsInputPort = strcmp(blk.TableSpecification, 'Explicit values') && ...
        strcmp(blk.TableSource, 'Input port');
    if tableIsInputPort
        inputs{end + 1} = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(...
            parent, blk, nbInpots);
        slxinport_dt = blk.CompiledPortDataTypes.Inport{end};
        Lusinport_dt = ...
            nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slxinport_dt);
        if ~strcmp(Lusinport_dt, 'real')
            [external_lib, conv_format] = ...
                nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                slxinport_dt, 'real');
            if ~isempty(conv_format)
                obj.addExternal_libraries(external_lib);
                inputs{end} = cellfun(@(x) ...
                    nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                    conv_format,x),inputs{end}, 'un', 0);
            end
        end
        nbInpots = nbInpots - 1;
    end
    
    % Number of sub-table selection dimension is not zero
    max_width = 1;
    if ~strcmp(blk.NumSelectionDims, '0')
        %
        numSelectionDims = str2num(blk.NumSelectionDims);
        tableDim = blkParams.TableDim;
        lusOne = nasa_toLustre.lustreAst.RealExpr('1.0');
        lusZero = nasa_toLustre.lustreAst.RealExpr('0.0');
        for selDim = 1:numSelectionDims
            selctNames = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(...
                parent, blk, nbInpots);
            slxinport_dt = blk.CompiledPortDataTypes.Inport{nbInpots};
            Lusinport_dt = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(slxinport_dt);
            if ~strcmp(Lusinport_dt, 'int')
                [external_lib, conv_format] = ...
                    nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                    slxinport_dt, 'int', RndMeth, ...
                    SaturateOnIntegerOverflow);
                if ~isempty(conv_format)
                    obj.addExternal_libraries(external_lib);
                    selctNames = cellfun(@(x) ...
                        nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                        conv_format,x),selctNames, 'un', 0);
                end
            end
            selFraction = cell(1, length(selctNames));
            %dim = nasa_toLustre.lustreAst.IntExpr(tableDim(end - selDim + 1));
            dim_minus_1 = nasa_toLustre.lustreAst.IntExpr(tableDim(end - selDim + 1) - 1);
            dim_minus_2 = nasa_toLustre.lustreAst.IntExpr(tableDim(end - selDim + 1) - 2);
            for selIdx = 1: length(selctNames)
                if strcmp(blk.ValidIndexMayReachLast, 'off')
                    cond = nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                        selctNames{selIdx}, dim_minus_1);
                    
                    selFraction{selIdx} = nasa_toLustre.lustreAst.IteExpr(...
                        cond, lusOne, lusZero, true);
                else
                    % this is the same code as the then branch.. seems they
                    %  needed to be different! TODO: go through logic again
                    cond = nasa_toLustre.lustreAst.BinaryExpr(...
                        nasa_toLustre.lustreAst.BinaryExpr.GTE, ...
                        selctNames{selIdx}, dim_minus_1);                    
                    selFraction{selIdx} = nasa_toLustre.lustreAst.IteExpr(...
                        cond, lusOne, lusZero, true);
                end
            end
            inputs{end + 1} = selFraction;
            inputs{end + 1} = selctNames;
            max_width = max(max_width, length(inputs{end}));
            nbInpots = nbInpots - 1;
        end
    end
    
    if nbInpots > 0
        if strcmp(blk.RequireIndexFractionAsBus, 'on')
            for i=nbInpots:-1:1
                tmp_inputs = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(...
                    parent, blk, i);
                Lusinport_dt = ...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                    blk.CompiledPortDataTypes.Inport{i});
                
                % add fraction
                inputs{end + 1} = tmp_inputs(2:2:end);
                if ~strcmp(Lusinport_dt{2}, 'real')
                    [external_lib, conv_format] = ...
                        nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                        Lusinport_dt{2}, 'real');
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{end} = cellfun(@(x) ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                            conv_format,x),inputs{end}, 'un', 0);
                    end
                end
                % add indexes
                inputs{end + 1} = tmp_inputs(1:2:end);
                % cast indexes to int
                if ~strcmp(Lusinport_dt{1}, 'int')
                    [external_lib, conv_format] = ...
                        nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                        Lusinport_dt{1}, 'int', RndMeth, ...
                        SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{end} = cellfun(@(x) ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                            conv_format,x),inputs{end}, 'un', 0);
                    end
                end
                
                max_width = max(max_width, length(inputs{end}));
            end
        else
            isfraction = true;
            for i=nbInpots:-1:1
                inputs{end + 1} = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(...
                    parent, blk, i);
                
                Lusinport_dt = ...
                    nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                    blk.CompiledPortDataTypes.Inport{i});
                if isfraction
                    dt = 'real';
                else
                    dt = 'int';
                end
                % cast to real for fraction and to int for indexes
                if ~strcmp(Lusinport_dt, dt)
                    [external_lib, conv_format] = ...
                        nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                        Lusinport_dt, dt, RndMeth, ...
                        SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{end} = cellfun(@(x) ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                            conv_format,x),inputs{end}, 'un', 0);
                    end
                end
                isfraction = ~isfraction;
                
                max_width = max(max_width, length(inputs{end}));
            end
        end
    end
    % flip inputs
    inputs = inputs(end:-1:1);
    
    % inline inputs
    nbInpots = length(inputs);
    if tableIsInputPort
        nbInpots = nbInpots - 1;
    end
    for i=1:nbInpots
        if length(inputs{i}) < max_width && length(inputs{i}) == 1
            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
        end
    end
    
end

