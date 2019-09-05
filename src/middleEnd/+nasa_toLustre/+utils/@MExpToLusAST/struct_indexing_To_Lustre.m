function [code, exp_dt, dim, extra_code] = struct_indexing_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            
    % Do not forget to update exp_dt in each switch case if needed
    exp_dt = nasa_toLustre.utils.MExpToLusDT.expression_DT(tree, args);
    tree_ID = tree.ID;
    dim = [];
    extra_code = {};
    switch tree_ID
        case {'coder'}
            %ignore these Matlab class
            code = {};
            exp_dt = '';
            
        otherwise
            ME = MException('COCOSIM:TREE2CODE', ...
                'Expression "%s" is not supported in Block %s.',...
                tree.text, args.blk.Origin_path);
            throw(ME);
    end
    
end

