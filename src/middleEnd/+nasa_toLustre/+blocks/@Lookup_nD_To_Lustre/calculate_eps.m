
function ep = calculate_eps(BP, j)
    fraction = 1e6;
    if j == 1
        ep = abs(BP(2) - BP(1)) / fraction;
    elseif j == numel(BP)
        ep = abs(BP(j-1) - BP(j)) / fraction;
    else
        ep = min(abs(BP(j-1) - BP(j)), abs(BP(j+1) - BP(j))) / fraction;
    end
end
