%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Khanh Tringh <khanh.v.trinh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function body = get_Det_Adjugate_Code(n,det,a,adj)
        body = {};
    body{1} = nasa_toLustre.lustreAst.AssertExpr(nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.NEQ, ...
        det, nasa_toLustre.lustreAst.RealExpr('0.0')));
    if n == 2
        % det
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,1},a{2,2}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,2},a{2,1}, [], [], [], 'real');
        body{end + 1} = nasa_toLustre.lustreAst.LustreEq(det,nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        % adjugate & inverse
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,1},a{2,2});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,2},nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG,a{1,2}));
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,1},nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NEG,a{2,1}));
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,2},a{1,1});
    elseif n == 3
        % define det
        term1 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,1},adj{1,1}, [], [], [], 'real');
        term2 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,2},adj{2,1}, [], [], [], 'real');
        term4 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,term1,term2);
        term3 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,3},adj{3,1}, [], [], [], 'real');
        body{end + 1} = nasa_toLustre.lustreAst.LustreEq(det,nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,term4,term3));
        % define adjugate
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,2},a{3,3}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,3},a{3,2}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,3},a{3,1}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,1},a{3,3}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,1},a{3,2}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{3,1},a{2,2}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,3},a{3,2}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{3,3},a{1,2}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,1},a{3,3}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,3},a{3,1}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,2},a{3,1}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{3,2},a{1,1}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,2},a{2,3}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,2},a{1,3}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,3},a{2,1}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,3},a{1,1}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
        term1 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,1},a{2,2}, [], [], [], 'real');
        term2 = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,1},a{1,2}, [], [], [], 'real');
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,term1,term2));
    elseif n  == 4
        % define det
        term1 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{1,1},adj{1,1}, [], [], [], 'real');
        term2 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{2,1},adj{1,2}, [], [], [], 'real');
        term3 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{3,1},adj{1,3}, [], [], [], 'real');
        term4 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,a{4,1},adj{1,4}, [], [], [], 'real');
        term5 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,term1,term2);
        term6 =  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,term3,term4);
        body{end + 1} = nasa_toLustre.lustreAst.LustreEq(det,nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS,term5,term6));
        % define adjugate
        %   adj11
        list{1} = {a{2,2},a{3,3},a{4,4}};
        list{2} = {a{2,3},a{3,4},a{4,2}};
        list{3} = {a{2,4},a{3,2},a{4,3}};
        list{4} = {a{2,4},a{3,3},a{4,2}};
        list{5} = {a{2,3},a{3,2},a{4,4}};
        list{6} = {a{2,2},a{3,4},a{4,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %   adj12
        list{1} = {a{1,4},a{3,3},a{4,2}};
        list{2} = {a{1,3},a{3,2},a{4,4}};
        list{3} = {a{1,2},a{3,4},a{4,3}};
        list{4} = {a{1,2},a{3,3},a{4,4}};
        list{5} = {a{1,3},a{3,4},a{4,2}};
        list{6} = {a{1,4},a{3,2},a{4,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %   adj13
        list{1} = {a{1,2},a{2,3},a{4,4}};
        list{2} = {a{1,3},a{2,4},a{4,2}};
        list{3} = {a{1,4},a{2,2},a{4,3}};
        list{4} = {a{1,4},a{2,3},a{4,2}};
        list{5} = {a{1,3},a{2,2},a{4,4}};
        list{6} = {a{1,2},a{2,4},a{4,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %     adj14
        list{1} = {a{1,4},a{2,3},a{3,2}};
        list{2} = {a{1,3},a{2,2},a{3,4}};
        list{3} = {a{1,2},a{2,4},a{3,3}};
        list{4} = {a{1,2},a{2,3},a{3,4}};
        list{5} = {a{1,3},a{2,4},a{3,2}};
        list{6} = {a{1,4},a{2,2},a{3,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{1,4},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj21
        list{1} = {a{2,4},a{3,3},a{4,1}};
        list{2} = {a{2,3},a{3,1},a{4,4}};
        list{3} = {a{2,1},a{3,4},a{4,3}};
        list{4} = {a{2,1},a{3,3},a{4,4}};
        list{5} = {a{2,3},a{3,4},a{4,1}};
        list{6} = {a{2,4},a{3,1},a{4,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj22
        list{1} = {a{1,1},a{3,3},a{4,4}};
        list{2} = {a{1,3},a{3,4},a{4,1}};
        list{3} = {a{1,4},a{3,1},a{4,3}};
        list{4} = {a{1,4},a{3,3},a{4,1}};
        list{5} = {a{1,3},a{3,1},a{4,4}};
        list{6} = {a{1,1},a{3,4},a{4,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj23
        list{1} = {a{1,4},a{2,3},a{4,1}};
        list{2} = {a{1,3},a{2,1},a{4,4}};
        list{3} = {a{1,1},a{2,4},a{4,3}};
        list{4} = {a{1,1},a{2,3},a{4,4}};
        list{5} = {a{1,3},a{2,4},a{4,1}};
        list{6} = {a{1,4},a{2,1},a{4,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj24
        list{1} = {a{1,1},a{2,3},a{3,4}};
        list{2} = {a{1,3},a{2,4},a{3,1}};
        list{3} = {a{1,4},a{2,1},a{3,3}};
        list{4} = {a{1,4},a{2,3},a{3,1}};
        list{5} = {a{1,3},a{2,1},a{3,4}};
        list{6} = {a{1,1},a{2,4},a{3,3}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{2,4},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj31
        list{1} = {a{2,1},a{3,2},a{4,4}};
        list{2} = {a{2,2},a{3,4},a{4,1}};
        list{3} = {a{2,4},a{3,1},a{4,2}};
        list{4} = {a{2,4},a{3,2},a{4,1}};
        list{5} = {a{2,2},a{3,1},a{4,4}};
        list{6} = {a{2,1},a{3,4},a{4,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj32
        list{1} = {a{1,4},a{3,2},a{4,1}};
        list{2} = {a{1,2},a{3,1},a{4,4}};
        list{3} = {a{1,1},a{3,4},a{4,2}};
        list{4} = {a{1,1},a{3,2},a{4,4}};
        list{5} = {a{1,2},a{3,4},a{4,1}};
        list{6} = {a{1,4},a{3,1},a{4,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj33
        list{1} = {a{1,1},a{2,2},a{4,4}};
        list{2} = {a{1,2},a{2,4},a{4,1}};
        list{3} = {a{1,4},a{2,1},a{4,2}};
        list{4} = {a{1,4},a{2,2},a{4,1}};
        list{5} = {a{1,2},a{2,1},a{4,4}};
        list{6} = {a{1,1},a{2,4},a{4,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %     adj34
        list{1} = {a{1,4},a{2,2},a{3,1}};
        list{2} = {a{1,2},a{2,1},a{3,4}};
        list{3} = {a{1,1},a{2,4},a{3,2}};
        list{4} = {a{1,1},a{2,2},a{3,4}};
        list{5} = {a{1,2},a{2,4},a{3,1}};
        list{6} = {a{1,4},a{2,1},a{3,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{3,4},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %   adj41
        list{1} = {a{2,3},a{3,2},a{4,1}};
        list{2} = {a{2,2},a{3,1},a{4,3}};
        list{3} = {a{2,1},a{3,3},a{4,2}};
        list{4} = {a{2,1},a{3,2},a{4,3}};
        list{5} = {a{2,2},a{3,3},a{4,1}};
        list{6} = {a{2,3},a{3,1},a{4,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{4,1},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj42
        list{1} = {a{1,1},a{3,2},a{4,3}};
        list{2} = {a{1,2},a{3,3},a{4,1}};
        list{3} = {a{1,3},a{3,1},a{4,2}};
        list{4} = {a{1,3},a{3,2},a{4,1}};
        list{5} = {a{1,2},a{3,1},a{4,3}};
        list{6} = {a{1,1},a{3,3},a{4,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{4,2},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        %    adj43
        list{1} = {a{1,3},a{2,2},a{4,1}};
        list{2} = {a{1,2},a{2,1},a{4,3}};
        list{3} = {a{1,1},a{2,3},a{4,2}};
        list{4} = {a{1,1},a{2,2},a{4,3}};
        list{5} = {a{1,2},a{2,3},a{4,1}};
        list{6} = {a{1,3},a{2,1},a{4,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{4,3},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
        % adj44
        list{1} = {a{1,1},a{2,2},a{3,3}};
        list{2} = {a{1,2},a{2,3},a{3,1}};
        list{3} = {a{1,3},a{2,1},a{3,2}};
        list{4} = {a{1,3},a{2,2},a{3,1}};
        list{5} = {a{1,2},a{2,1},a{3,3}};
        list{6} = {a{1,1},a{2,3},a{3,2}};
        terms = cell(1,6);
        for i=1:6
            terms{i} = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.MULTIPLY,list{i}, 'real');
        end        
        termPos = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{1},terms{2},terms{3}});
        termNeg = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(nasa_toLustre.lustreAst.BinaryExpr.PLUS,{terms{4},terms{5},terms{6}});
        body{end+1} = nasa_toLustre.lustreAst.LustreEq(adj{4,4},nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MINUS,termPos,termNeg));
    else
        display_msg(...
            sprintf('Option Matrix(*) with divid is not supported in block LustMathLib'), ...
            MsgType.ERROR, 'LustMathLib', '');
        return;
    end
end
