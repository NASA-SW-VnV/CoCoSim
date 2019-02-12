
function [codes, product_out, addVars] = matrix_multiply_pair(m1_dim, m2_dim, ...
        input_m1, input_m2, output_m, zero, pair_number,...
        OutputDT, tmp_prefix, conv_format)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    % adding additional variables for inside matrices.  For
    % AxBxCxD, B and C are inside matrices and needs additional
    % variables

    initCode = zero;
    m=m1_dim.dims(1,1);
    if numel(m1_dim.dims) > 1
        n=m1_dim.dims(1,2);
    else
        n = 1;
    end
    if numel(m2_dim.dims) > 1
        l=m2_dim.dims(1,2);
    else
        l = 1;
    end
    addVars = {};
    if numel(output_m) == 0
        index = 0;
        addVars = cell(1, m*l);
        product_out = cell(1, m*l);
        for i=1:m
            for j=1:l
                index = index+1;
                product_out{index} = VarIdExpr(...
                    sprintf('%s_matrix_mult_%d_%d',...
                    tmp_prefix, pair_number,index));
                addVars{index} = LustreVar(...
                    product_out{index}, OutputDT);
            end
        end
    else
        product_out = output_m;
    end
    % doing matrix multiplication, A = BxC
    codes = cell(1, m*l);
    codeIndex = 0;
    for i=1:m      %i is row of result matrix
        for j=1:l      %j is column of result matrix
            codeIndex = codeIndex + 1;
            code = initCode;
            for k=1:n
                aIndex = sub2ind([m,n],i,k);
                bIndex = sub2ind([n,l],k,j);
                code = BinaryExpr(BinaryExpr.PLUS, ...
                    code, ...
                    BinaryExpr(BinaryExpr.MULTIPLY, ...
                    input_m1{1,aIndex},...
                    input_m2{1,bIndex}),...
                    false);
                %sprintf('%s + (%s * %s)',code, input_m1{1,aIndex},input_m2{1,bIndex});
                %diag = sprintf('i %d, j %d, k %d, aIndex %d, bIndex %d',i,j,k,aIndex,bIndex);
            end
            productOutIndex = sub2ind([m,l],i,j);
            if ~isempty(conv_format) && ~isempty(output_m)
                code =nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format, code);
            end
            codes{codeIndex} = LustreEq(product_out{productOutIndex}, code) ;
        end

    end
end
