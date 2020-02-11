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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TriggerinputExp = getTriggerValue(Cond, triggerInput, TriggerType, TriggerBlockDt, IncomingSignalDT)
    %% trigger value

    
    
    if strcmp(TriggerBlockDt, 'real')
        %suffix = '.0';
        zero = nasa_toLustre.lustreAst.RealExpr('0.0');
        one = nasa_toLustre.lustreAst.RealExpr('1.0');
        two = nasa_toLustre.lustreAst.RealExpr('2.0');
    else
        %suffix = '';
        zero = nasa_toLustre.lustreAst.IntExpr(0);
        one = nasa_toLustre.lustreAst.IntExpr(1);
        two = nasa_toLustre.lustreAst.IntExpr(2);
    end
    if strcmp(IncomingSignalDT, 'real')
        IncomingSignalzero = nasa_toLustre.lustreAst.RealExpr('0.0');
    else
        IncomingSignalzero = nasa_toLustre.lustreAst.IntExpr(0);
    end
    if strcmp(TriggerType, 'rising')
%                 sprintf(...
%                     '0%s -> if %s then 1%s else 0%s'...
%                     ,suffix, Cond, suffix, suffix );
        TriggerinputExp = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            zero, ...
            nasa_toLustre.lustreAst.IteExpr(Cond, one, zero)) ;
    elseif strcmp(TriggerType, 'falling')
%                 TriggerinputExp = sprintf(...
%                     '0%s -> if %s then -1%s else 0%s'...
%                     ,suffix, Cond, suffix, suffix );
        TriggerinputExp = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            zero, ...
            nasa_toLustre.lustreAst.IteExpr(Cond, ...
                    nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, one),...
                    zero)) ;
    elseif strcmp(TriggerType, 'function-call')
%                 TriggerinputExp = sprintf(...
%                     '0%s -> if %s then 2%s else 0%s'...
%                     ,suffix, Cond, suffix, suffix );
        TriggerinputExp = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            zero, ...
            nasa_toLustre.lustreAst.IteExpr(Cond, ...
                    two,...
                    zero)) ;
    else
        risingCond =nasa_toLustre.utils.SLX2LusUtils.getResetCode(...
            'rising', IncomingSignalDT, triggerInput, IncomingSignalzero );
%                 TriggerinputExp = sprintf(...
%                     '%s -> if %s then (if (%s) then 1%s else -1%s) else 0%s'...
%                     ,zero,  Cond, risingCond, suffix, suffix, suffix);
        TriggerinputExp = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
            zero, ...
            nasa_toLustre.lustreAst.IteExpr(Cond, ...
                    nasa_toLustre.lustreAst.IteExpr(risingCond, one, nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG, one)),...
                    zero)) ;
    end
end
