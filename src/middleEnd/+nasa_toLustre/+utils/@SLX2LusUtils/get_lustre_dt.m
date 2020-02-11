
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
%% Change Simulink DataTypes to Lustre DataTypes. Initial default
%value is also given as a string.
function [ Lustre_type, zero, one, isBus, isEnum, hasEnum] = ...
        get_lustre_dt( slx_dt)
    %
    %
    global TOLUSTRE_ENUMS_MAP;
    if isempty(TOLUSTRE_ENUMS_MAP)
        TOLUSTRE_ENUMS_MAP = containers.Map;
    end
    isBus = false;
    isEnum = false;
    hasEnum = false;
    if strcmp(slx_dt, 'real') || strcmp(slx_dt, 'int') || strcmp(slx_dt, 'bool')
        Lustre_type = slx_dt;
    else
        if strcmp(slx_dt, 'logical') || strcmp(slx_dt, 'boolean') ...
                || strcmp(slx_dt, 'action') || strcmp(slx_dt, 'fcn_call')
            Lustre_type = 'bool';
        elseif strncmp(slx_dt, 'int', 3) || strncmp(slx_dt, 'uint', 4) || strncmp(slx_dt, 'fixdt(1,16,', 11) || strncmp(slx_dt, 'sfix64', 6)
            Lustre_type = 'int';
        elseif strcmp(slx_dt, 'double') || strcmp(slx_dt, 'single')
            Lustre_type = 'real';
        else
            % considering enumaration as int
            if strncmp(slx_dt, 'Enum:', 4)
                slx_dt = regexprep(slx_dt, 'Enum:\s*', '');
            end
            if isKey(TOLUSTRE_ENUMS_MAP, lower(slx_dt))
                isEnum = true;
                hasEnum = true;
                Lustre_type = lower(slx_dt);
            else 
                isBus = SLXUtils.isSimulinkBus(char(slx_dt));
                if isBus
                    Lustre_type = nasa_toLustre.utils.SLX2LusUtils.getLustreTypesFromBusObject(char(slx_dt));
                else
                    Lustre_type = 'real';
                end
            end

        end
    end
    if iscell(Lustre_type)
        zero = {};
        one = {};
        for i=1:numel(Lustre_type)
            if isKey(TOLUSTRE_ENUMS_MAP, Lustre_type{i})
                members = TOLUSTRE_ENUMS_MAP(Lustre_type{i});
                % DefaultValue of Enum is the first element
                zero{i} = members{1};
                one{i} = members{1};
                hasEnum = true;
            elseif strcmp(Lustre_type{i}, 'bool')
                zero{i} = nasa_toLustre.lustreAst.BoolExpr('false');
                one{i} = nasa_toLustre.lustreAst.BoolExpr('true') ;
            elseif strcmp(Lustre_type{i}, 'int')
                zero{i} = nasa_toLustre.lustreAst.IntExpr('0');
                one{i} = nasa_toLustre.lustreAst.IntExpr('1');
            else
                zero{i} = nasa_toLustre.lustreAst.RealExpr('0.0');
                one{i} = nasa_toLustre.lustreAst.RealExpr('1.0');
            end
        end
    else
        if isKey(TOLUSTRE_ENUMS_MAP, Lustre_type)
            members = TOLUSTRE_ENUMS_MAP(Lustre_type);
            zero = members{1};
            one = members{1};
            hasEnum = true;
        elseif strcmp(Lustre_type, 'bool')
            zero = nasa_toLustre.lustreAst.BoolExpr('false');
            one = nasa_toLustre.lustreAst.BoolExpr('true');
        elseif strcmp(Lustre_type, 'int')
            zero = nasa_toLustre.lustreAst.IntExpr('0');
            one = nasa_toLustre.lustreAst.IntExpr('1');
        else
            zero = nasa_toLustre.lustreAst.RealExpr('0.0');
            one = nasa_toLustre.lustreAst.RealExpr('1.0');
        end
    end
end

