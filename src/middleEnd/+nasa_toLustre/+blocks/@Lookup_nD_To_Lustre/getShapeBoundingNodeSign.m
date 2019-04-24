function boundNodeOrder = getShapeBoundingNodeSign(dims)
    % generating sign for nodes bounding element for up to 7
    % dimensions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % define the coordinate of a dimension increases from node 1 to node
    % 2.  Linear shape function S1 is 0 at node 1 and 1 at node2.  Linear shape
    % function S2 is 1 at node 2 and 0 at node 1.  F1 (fraction) is 1 at
    % node 1 and 0 at node 2.  F2 is 1 at node 1 and 0 at node2.  
    % The f returns in PreLookup is F2.  
    % F2 = S1 and F1 = S2.  
    % boundNodeOrder 
    % defines the inline node order of the bounding corner nodes.  For a
    % node, if the value of the boundNodeOrder for a dimension is -1, then use
    % F1 and use F2 if the boundNodeOrder for that dimension is 1.
    
    boundNodeOrder = [];
    if dims == 1
        boundNodeOrder = [-1;1];
        return;
    elseif dims == 2
        boundNodeOrder = [-1 -1;-1 1;1 -1; 1 1];
        return;
    elseif dims == 3
        boundNodeOrder = [-1 -1 -1;-1 -1 1;-1 1 -1; -1 1 1;1 -1 -1;1 -1 1;1 1 -1; 1 1 1];
        return;
    elseif dims == 4
        boundNodeOrder = [-1    -1    -1    -1;-1    -1    -1     1;-1    -1     1    -1;
            -1    -1     1     1;-1     1    -1    -1;-1     1    -1     1;
            -1     1     1    -1;-1     1     1     1;1    -1    -1    -1;
            1    -1    -1     1;1    -1     1    -1;1    -1     1     1;1     1    -1    -1;
            1     1    -1     1;1     1     1    -1;1     1     1     1     ];
        return;
    elseif dims == 5
        boundNodeOrder = [];
        index = 0;
        for i=1:2
            for j=1:2
                for k=1:2
                    for l=1:2
                        for m=1:2
                            ai = (-1)^i;
                            aj = (-1)^j;
                            ak = (-1)^k;
                            al = (-1)^l;
                            am = (-1)^m;
                            index = index + 1;
                            boundNodeOrder(index,:) = [ai aj ak al am];
                        end
                    end
                end
            end
        end
        Ns{5} = boundNodeOrder;
        return;
    elseif dims == 6
        boundNodeOrder = [];
        index = 0;
        for i=1:2
            for j=1:2
                for k=1:2
                    for l=1:2
                        for m=1:2
                            for n=1:2
                                ai = (-1)^i;
                                aj = (-1)^j;
                                ak = (-1)^k;
                                al = (-1)^l;
                                am = (-1)^m;
                                an = (-1)^n;
                                index = index + 1;
                                boundNodeOrder(index,:) = [ai aj ak al am an];
                            end
                        end
                    end
                end
            end
        end
        return;
    elseif dims == 7
        for i=1:2
            for j=1:2
                for k=1:2
                    for l=1:2
                        for m=1:2
                            for n=1:2
                                for o=1:2
                                    ai = (-1)^i;
                                    aj = (-1)^j;
                                    ak = (-1)^k;
                                    al = (-1)^l;
                                    am = (-1)^m;
                                    an = (-1)^n;
                                    ao = (-1)^o;
                                    index = index + 1;
                                    boundNodeOrder(index,:) = [ai aj ak al am an ao];
                                end
                            end
                        end
                    end
                end
            end
        end
        return;
    else
        return;
    end
end

