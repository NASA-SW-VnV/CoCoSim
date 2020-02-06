%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
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
function [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n)
    % support 2x2 matrix inversion
    % support 3x3 matrix inversion
    % support 4x4 matrix inversion
    % contract for 2x2 to 7x7 matrix inversion
    opens = {};
    abstractedNodes = {};
    external_nodes_i ={};
    node_name = sprintf('_inv_M_%dx%d',n,n);
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setIsMain(false);
    vars = {};
    body = {};
    
    % inputs & outputs
    % a: inputs, ai: outputs
    a = cell(n,n);
    ai = cell(n,n);
    for i=1:n
        for j=1:n
            a{i,j} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('a%d%d',i,j));
            ai{i,j} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('ai%d%d',i,j));
        end
    end
    inputs = cell(1,n*n);
    outputs = cell(1,n*n);
    inline_a = cell(1,n*n);
    inline_ai = cell(1,n*n);
    counter = 0;
    for j=1:n
        for i=1:n
            counter = counter + 1;
            inline_a{counter} = a{i,j};
            inline_ai{counter} = ai{i,j};
            inputs{counter} = nasa_toLustre.lustreAst.LustreVar(a{i,j},'real');
            outputs{counter} = nasa_toLustre.lustreAst.LustreVar(ai{i,j},'real');
        end
    end
    if LusBackendType.isKIND2(lus_backend)
        contractBody = getContractBody_nxn_inverstion(n,inline_a,inline_ai);
        contract = nasa_toLustre.lustreAst.LustreContract();
        contract.setBodyEqs(contractBody);
        node.setLocalContract(contract);
    end
    % inversion and contract
    if  n > 4 || LusBackendType.isKIND2(lus_backend)
        node.setIsImported(true);
        abstractedNodes = {sprintf('Inverse Matrix of dimension %d', n)};
    elseif n <= 4
        vars = cell(1,n*n+1);
        det = nasa_toLustre.lustreAst.VarIdExpr('det');
        vars{1} = nasa_toLustre.lustreAst.LustreVar(det,'real');
        % adj: adjugate
        adj = cell(n,n);
        for i=1:n
            for j=1:n
                adj{i,j} = nasa_toLustre.lustreAst.VarIdExpr(sprintf('adj%d%d',i,j));
                vars{(i-1)*n+j+1} = nasa_toLustre.lustreAst.LustreVar(adj{i,j},'real');
            end
        end
        
        body = get_Det_Adjugate_Code(n,det,a,adj);
        
        % define inverse
        for i=1:n
            for j=1:n
                body{end+1} = nasa_toLustre.lustreAst.LustreEq(ai{i,j},...
                nasa_toLustre.lustreAst.BinaryExpr(...
                nasa_toLustre.lustreAst.BinaryExpr.DIVIDE, adj{i,j}, det, [], [], [], 'real'));
            end
        end
    else
        display_msg(...
            sprintf('Matrix inversion for higher than 4x4 matrix is not supported in LustMathLib'), ...
            MsgType.ERROR, 'LustMathLib', '');
        
    end
    
    % set node
    node.setInputs(inputs);
    node.setOutputs(outputs);
    node.setBodyEqs(body);
    node.setLocalVars(vars);
    
end
