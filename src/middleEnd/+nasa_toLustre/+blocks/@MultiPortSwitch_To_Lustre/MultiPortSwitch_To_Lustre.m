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
classdef MultiPortSwitch_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %FromWorkspace_To_Lustre 

%    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, coco_backend, main_sampleTime, varargin)
            global  CoCoSimPreferences;
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk);
            
            [numInputs, ~, ~] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Inputs);
            blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            
            portIndex = nasa_toLustre.lustreAst.VarIdExpr(sprintf('%s_portIndex',blk_name));
            obj.addVariable(nasa_toLustre.lustreAst.LustreVar(portIndex, 'int'));
            
            indexShift = 0;    % portIndex = readin index + indexShift.  
            %                    indexShift = 0 for 1-based contiguous (1st port is control port)
            %                    indexShift = 2 for 0-based contigous        
               
            if strcmp(blk.DataPortOrder, 'Zero-based contiguous')
                indexShift = indexShift + 1;
            elseif strcmp(blk.DataPortOrder, 'Specify indices')
                display_msg(sprintf('Specify indices is not supported  in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'MultiportSwitch_To_Lustre', '');
            end
            
            codes = cell(1, numel(outputs) + 1); 
            codes{1} = nasa_toLustre.lustreAst.LustreEq(portIndex, ...
                nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, ...
                            inputs{1}{1},...
                            nasa_toLustre.lustreAst.IntExpr(indexShift)));
            %sprintf('%s = %s + %d; \n\t', portIndex, inputs{1}{1},indexShift);
                        
            for i=1:numel(outputs)
                %code = sprintf('%s = \n\t', outputs{i});
                conds = cell(1, numInputs);
                thens = cell(1, numInputs + 1);
                for j=1:numInputs
                    conds{j} = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, portIndex, nasa_toLustre.lustreAst.IntExpr(j));
                    thens{j} = inputs{j+1}{i};
                    %code = sprintf('%s  if(%s = %d) then %s\n\t', code, portIndex,j,inputs{j+1}{i});   % 1st port is control port
                end
                thens{numInputs + 1} = inputs{numel(inputs)}{i};
                %codes{i + 1} = sprintf('%s  else %s ;\n\t', code,inputs{numel(inputs)}{i});   % default port is always last port whether there is additional port or not
                codes{i + 1} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
                    nasa_toLustre.lustreAst.IteExpr.nestedIteExpr(conds, thens));
            end
            
            obj.addCode( codes );
            
            %% Design Error Detection Backend code:
            if CoCoBackendType.isDED(coco_backend)
                if ismember(CoCoBackendType.DED_OUTMINMAX, ...
                        CoCoSimPreferences.dedChecks)
                    outputDataType = blk.CompiledPortDataTypes.Outport{1};
                    lusOutDT =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(outputDataType);
                    DEDUtils.OutMinMaxCheckCode(obj, parent, blk, outputs, lusOutDT, xml_trace);
                end
            end
            
        end
        
        [inputs] = getBlockInputsNames_convInType2AccType(obj, parent, blk)        
        
        function options = getUnsupportedOptions(obj, ~, blk, varargin)
            if strcmp(blk.DataPortOrder, 'Specify indices')
                obj.addUnsupported_options(...
                    sprintf('Specify indices is not supported  in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end    
            if strcmp(blk.AllowDiffInputSizes, 'on')
                obj.addUnsupported_options(...
                    sprintf('Allow different data input sizes is not supported  in block %s',...
                    HtmlItem.addOpenCmd(blk.Origin_path)));
            end             
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

