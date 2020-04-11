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
classdef ContractModeBlock_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % ContractModeBlock_To_Lustre is translating Mode Subsystem by a mode
    % in cocospec:
    % mode mode_name(
    %   require first_input;
    %   ensure second_input;
    % );
    

    
    properties
    end
    
    methods
        function obj = ContractModeBlock_To_Lustre()
            obj.ContentNeedToBeTranslated = 0;
        end
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, main_sampleTime, varargin)
            
            if ~nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent)
                display_msg(sprintf('Mode block "%s" should not be outside a Contract Subsystem', HtmlItem.addOpenCmd(blk.Origin_path)),...
                    MsgType.ERROR, 'ContractModeBlock_To_Lustre', '');
                return;
            end
            widths = blk.CompiledPortWidths.Inport;
            nb_inputs = numel(widths);
            inputs = cell(1, nb_inputs);
            
            for i=1:nb_inputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                
                % Get the input datatype
                inport_dt = blk.CompiledPortDataTypes.Inport(i);
                
                if ~strcmp(inport_dt, 'boolean')
                    % this function return if a casting is needed
                    % "conv_format", a library or the name of casting node
                    % will be stored in "external_lib".
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, 'boolean');
                    if ~isempty(conv_format)
                        % always add the "external_lib" to the object
                        % external libraries, (so it can be declared in the
                        % overall lustre code).
                        obj.addExternal_libraries(external_lib);
                        % cast the input to the conversion format. In our
                        % example conv_format = 'int_to_real(%s)'.
                        inputs{i} = cellfun(@(x) ...
                            nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            requires = cell(1, length(inputs{1}));
            for i=1:length(inputs{1})
                requires{i} = nasa_toLustre.lustreAst.ContractRequireExpr(inputs{1}{i});
            end
            ensure_blk = nasa_toLustre.utils.SLX2LusUtils.getpreBlock(parent, blk, 2);
            prop_ID =nasa_toLustre.utils.SLX2LusUtils.node_name_format(ensure_blk);
            
            ensures = cell(1, length(inputs{2}));
            for i=1:length(inputs{2})
                ensures{i} = nasa_toLustre.lustreAst.ContractEnsureExpr(prop_ID, inputs{2}{i});
                %prop_ID_i = sprintf('%s_%d', prop_ID, i);
                xml_trace.add_Property(...
                    ensure_blk.Origin_path, ...
                    nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent),...
                    prop_ID, i, 'ensure');
            end
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend) && isInsideContract
                blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
                code = nasa_toLustre.lustreAst.ContractModeExpr(blk_name, requires, ensures);
                obj.addCode( code );
            else
                A = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                    nasa_toLustre.lustreAst.BinaryExpr.AND, inputs{1});
                B = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                    nasa_toLustre.lustreAst.BinaryExpr.AND, inputs{2});
                prop = nasa_toLustre.lustreAst.BinaryExpr(...
                    nasa_toLustre.lustreAst.BinaryExpr.IMPLIES, A, B);
                 obj.addCode(nasa_toLustre.lustreAst.LocalPropertyExpr(...
                    prop_ID, prop));
            end
            
            
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            % add your unsuported options list here
            if ~nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent)
                obj.addUnsupported_options(...
                    sprintf('Mode block "%s" should not be outside a Contract Subsystem', HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
            
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

