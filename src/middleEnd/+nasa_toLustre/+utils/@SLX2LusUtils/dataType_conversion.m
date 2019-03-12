
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [external_lib, conv_format] = dataType_conversion(inport_dt, outport_dt, RndMeth, SaturateOnIntegerOverflow)
    %
    %
    [lus_in_dt, ~, ~, ~, InIsEnum] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( inport_dt);
    [lus_out_dt, ~, ~, ~, OutIsEnum] = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( outport_dt);
    if nargin < 3 || isempty(RndMeth)
        if strcmp(lus_in_dt, 'int')
            RndMeth = 'int_to_real';
        else
            RndMeth = 'real_to_int';
        end
    else
        if strcmp(lus_in_dt, 'int')
            RndMeth = 'int_to_real';

        elseif strcmp(RndMeth, 'Simplest') || strcmp(RndMeth, 'Zero')
            RndMeth = 'real_to_int';
        else
            RndMeth = strcat('_',RndMeth);
        end
    end
    if nargin < 4 || isempty(SaturateOnIntegerOverflow)
        SaturateOnIntegerOverflow = 'off';
    end
    if InIsEnum
        [external_lib, conv_format1] = nasa_toLustre.utils.SLX2LusUtils.dataType_conversion('int', outport_dt, RndMeth, SaturateOnIntegerOverflow);
        conv_format = nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format1,...
            nasa_toLustre.lustreAst.NodeCallExpr(sprintf('%s_to_int', char(lus_in_dt)), {}));
        return;
    end
    if OutIsEnum
        [external_lib, conv_format1] = nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'int', RndMeth, SaturateOnIntegerOverflow);
        conv_format = nasa_toLustre.lustreAst.NodeCallExpr(...
            sprintf('int_to_%s', char(lus_out_dt)), conv_format1);
        return;
    end
    external_lib = {};
    conv_format = {};

    switch outport_dt
        case 'boolean'
            if strcmp(lus_in_dt, 'int')
                external_lib = {'LustDTLib_int_to_bool'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('int_to_bool', {});
            elseif strcmp(lus_in_dt, 'real')
                external_lib = {'LustDTLib_real_to_bool'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('real_to_bool', {});
            end
        case {'double', 'single'}
            if strcmp(lus_in_dt, 'int')
                external_lib = {strcat('LustDTLib_', RndMeth)};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr(RndMeth, {});
            elseif strcmp(lus_in_dt, 'bool')
                external_lib = {'LustDTLib_bool_to_real'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('bool_to_real', {});
            end
        case {'int8','uint8','int16','uint16', 'int32','uint32'}
            if strcmp(SaturateOnIntegerOverflow, 'on')
                conv = strcat('int_to_', outport_dt, '_saturate');
            else
                conv = strcat('int_to_', outport_dt);
            end
            if strcmp(lus_in_dt, 'int')
                external_lib = {strcat('LustDTLib_',conv)};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr(conv, {});
            elseif strcmp(lus_in_dt, 'bool')
                external_lib = {'LustDTLib_bool_to_int'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('bool_to_int', {});
            elseif strcmp(lus_in_dt, 'real')
                external_lib = {strcat('LustDTLib_', conv),...
                    strcat('LustDTLib_', RndMeth)};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr(conv, ...
                    nasa_toLustre.lustreAst.NodeCallExpr(RndMeth, {}));
            end



            %lustre conversion
        case 'int'
            if strcmp(lus_in_dt, 'bool')
                external_lib = {'LustDTLib_bool_to_int'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('bool_to_int', {});
            elseif strcmp(lus_in_dt, 'real')
                external_lib = {strcat('LustDTLib_', RndMeth)};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr(RndMeth, {});
            end
        case 'real'
            if strcmp(lus_in_dt, 'int')
                external_lib = {strcat('LustDTLib_', RndMeth)};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr(RndMeth, {});
            elseif strcmp(lus_in_dt, 'bool')
                external_lib = {'LustDTLib_bool_to_real'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('bool_to_real', {});
            end
        case 'bool'
            if strcmp(lus_in_dt, 'int')
                external_lib = {'LustDTLib_int_to_bool'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('int_to_bool', {});
            elseif strcmp(lus_in_dt, 'real')
                external_lib = {'LustDTLib_real_to_bool'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('real_to_bool', {});
            end

        otherwise
            %fixdt 
            if strcmp(lus_in_dt, 'int')
                external_lib = {strcat('LustDTLib_', RndMeth)};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr(RndMeth, {});
            elseif strcmp(lus_in_dt, 'bool')
                external_lib = {'LustDTLib_bool_to_real'};
                conv_format = nasa_toLustre.lustreAst.NodeCallExpr('bool_to_real', {});
            end
    end
end
