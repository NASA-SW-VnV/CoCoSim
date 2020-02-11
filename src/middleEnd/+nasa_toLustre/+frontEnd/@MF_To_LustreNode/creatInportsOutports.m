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
function [blk, Inputs, Outputs] = creatInportsOutports(blk)

    
    content = struct();
    if isfield(blk, 'Inputs')
        Inputs = blk.Inputs;
    else
        Inputs = {};
    end
    Outputs = blk.Outputs;
    for i=1:numel(Inputs)
        in = Inputs{i};
        % add additional information to consider it as Simulink Inport
        port = in.Port;
        in.Port = num2str(port);%as Inport
        in.BlockType = 'Inport';
        in.Origin_path = fullfile(blk.Origin_path, in.Name);
        in.Path = fullfile(blk.Path, in.Name);
        in.CompiledPortWidths.Outport = blk.CompiledPortWidths.Inport(port);
        in.CompiledPortWidths.Inport = [];
        CompiledType = blk.CompiledPortDataTypes.Inport(port);
        in.CompiledPortDataTypes.Outport = CompiledType;
        in.CompiledPortDataTypes.Inport = {};
        in.BusObject = '';
        content.(in.Name) = in;
        % add input to data map
        Inputs{i} = buildData(Inputs{i}, CompiledType);
    end
    for i=1:numel(Outputs)
        out = Outputs{i};
        port = out.Port;
        out.Port = num2str(port);%as Outport
        out.BlockType = 'Outport';
        out.Origin_path = fullfile(blk.Origin_path, out.Name);
        out.Path = fullfile(blk.Path, out.Name);
        out.CompiledPortWidths.Inport = blk.CompiledPortWidths.Outport(port);
        out.CompiledPortWidths.Outport = [];
        CompiledType = blk.CompiledPortDataTypes.Outport(port);
        out.CompiledPortDataTypes.Inport = CompiledType;
        out.CompiledPortDataTypes.Outport = {};
        out.BusObject = '';
        content.(out.Name) = out;
        % add input to data map
        Outputs{i} = buildData(Outputs{i}, CompiledType);
    end
    blk.Content = content;
end
function data = buildData(d, CompiledType)
    data = d;
    data.LusDatatype = nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt( CompiledType);
    data.Datatype = CompiledType;
    data.CompiledType = CompiledType;
    data.InitialValue = '0';
end