function [inputs] = getInputs(obj, parent, blk)
    %GETINPUTS gets and pre-process inputs to k, f format.
    % if the input is using bus, it divide it into two seperated inputs (index
    % and fraction) .
    % In the case of input is a dimension selection, it transform it as an index
    % and extend inputs by a fraction equal to zero.
    %RndMeth = bk.RndMeth;
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
        nbInpots = nbInpots - 1;
    end
    
    % Number of sub-table selection dimension is not zero
    max_width = 1;
    if ~strcmp(blk.NumSelectionDims, '0')
        %
        numSelectionDims = str2num(blk.NumSelectionDims);
        for selIdx = 1:numSelectionDims
            inputs{end + 1} = nasa_toLustre.lustreAst.RealExpr('0.0');
            inputs{end + 1} = nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(...
                parent, blk, nbInpots);
            max_width = max(max_width, inputs{end});
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
                if ~strcmp(Lusinport_dt, 'real')
                    [external_lib, conv_format] = ...
                        nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(...
                        Lusinport_dt, 'real');
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
                        Lusinport_dt{1}, 'int', 'Nearest', ...
                        SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{end} = cellfun(@(x) ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                            conv_format,x),inputs{end}, 'un', 0);
                    end
                end
                
                max_width = max(max_width, inputs{end});
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
                        Lusinport_dt, dt, 'Nearest', ...
                        SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{end} = cellfun(@(x) ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(...
                            conv_format,x),inputs{end}, 'un', 0);
                    end
                end
                isfraction = ~isfraction;
                
                max_width = max(max_width, inputs{end});
            end
        end
    end
    % flip inputs
    inputs = inputs(end:-1:1);
    
    % inline inputs
    nbInpots = numel(widths);
    if tableIsInputPort
        nbInpots = nbInpots - 1;
    end
    for i=1:nbInpots
        if length(inputs{i}) < max_width && length(inputs{i}) == 1
            inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
        end
    end
    
end

