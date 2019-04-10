function extNode =  get_wrapper_node(~,blk,...
    blkParams,inputs,preLookUpExtNode,interpolationExtNode)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Lookup_nD
     
    extNode = ...
        nasa_toLustre.blocks.Lookup_nD_To_Lustre.get_Lookup_nD_Dynamic_wrapper(...
        blkParams,inputs,preLookUpExtNode,interpolationExtNode);
    extNode.setMetaInfo('external node code for doing Lookup_nD');        

end

