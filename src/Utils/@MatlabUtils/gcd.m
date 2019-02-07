
function st = gcd(T)
    st = max(T);
    for i=1:numel(T)
        st = gcd(st*10000,T(i)*10000)/10000;
    end
end
