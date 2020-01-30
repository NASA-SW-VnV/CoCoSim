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
function blkParams = readBlkParams(~,blk,inputs,blkParams)

%    % LookupTableDynamic_To_Lustre
    
    blkParams.lookupTableType = nasa_toLustre.utils.LookupType.LookupDynamic;
    blkParams.tableIsInputPort = true;
    % read blk
    blkParams.NumberOfTableDimensions = 1;
    blkParams.NumberOfTableDimensions = blkParams.NumberOfTableDimensions;
    blkParams.BreakpointsForDimension{1} = inputs{2};
    % table
    blkParams.Table = inputs{3};
    blkParams.numberTableData=numel(blkParams.Table);  
    % look up method
    if strcmp(blk.LookUpMeth, 'Interpolation-Extrapolation')
        blkParams.InterpMethod = 'Linear';
        blkParams.ExtrapMethod = 'Linear';
    elseif strcmp(blk.LookUpMeth, 'Interpolation-Use End Values')
        blkParams.InterpMethod = 'Linear';
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.LookUpMeth, 'Use Input Nearest')
        blkParams.InterpMethod = 'Nearest';
        blkParams.directLookup = 1;
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.LookUpMeth, 'Use Input Below')
        blkParams.InterpMethod = 'Flat';
        blkParams.directLookup = 1;
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.LookUpMeth, 'Use Input Above')
        blkParams.InterpMethod = 'Above';
        blkParams.directLookup = 1;
        blkParams.ExtrapMethod  = 'Clip';
        blkParams.yIsBounded = 1;
    elseif strcmp(blk.InterpMethod, 'Cubic spline')
        display_msg(sprintf('Cubic spline interpolation in block %s is not supported',...
            HtmlItem.addOpenCmd(blk.Origin_path)), ...
            MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
    else
        blkParams.InterpMethod = 'Linear';
        blkParams.ExtrapMethod = 'Linear';
    end
    
    blkParams.RndMeth = blk.RndMeth;
    blkParams.SaturateOnIntegerOverflow = blk.DoSatur;
    
    % calculate dimJump and boundNodeOrder
    blkParams = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.addCommonData2BlkParams(...
        blkParams);    
end

