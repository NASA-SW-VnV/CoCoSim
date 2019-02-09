
function shapeNodeSign = getShapeBoundingNodeSign(dims)
    % generating sign for nodes bounding element for up to 7
    % dimensions
    shapeNodeSign = [];
    if dims == 1
        shapeNodeSign = [-1;1];
        return;
    elseif dims == 2
        shapeNodeSign = [-1 -1;-1 1;1 -1; 1 1];
        return;
    elseif dims == 3
        shapeNodeSign = [-1 -1 -1;-1 -1 1;-1 1 -1; -1 1 1;1 -1 -1;1 -1 1;1 1 -1; 1 1 1];
        return;
    elseif dims == 4
        shapeNodeSign = [-1    -1    -1    -1;-1    -1    -1     1;-1    -1     1    -1;
            -1    -1     1     1;-1     1    -1    -1;-1     1    -1     1;
            -1     1     1    -1;-1     1     1     1;1    -1    -1    -1;
            1    -1    -1     1;1    -1     1    -1;1    -1     1     1;1     1    -1    -1;
            1     1    -1     1;1     1     1    -1;1     1     1     1     ];
        return;
    elseif dims == 5
        shapeNodeSign = [];
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
                            shapeNodeSign(index,:) = [ai aj ak al am];
                        end
                    end
                end
            end
        end
        Ns{5} = shapeNodeSign;
        return;
    elseif dims == 6
        shapeNodeSign = [];
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
                                shapeNodeSign(index,:) = [ai aj ak al am an];
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
                                    shapeNodeSign(index,:) = [ai aj ak al am an ao];
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

