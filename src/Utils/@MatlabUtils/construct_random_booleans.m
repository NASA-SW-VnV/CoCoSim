function vector = construct_random_booleans(nb_iterations, IMIN, IMAX, dim)
    vector = boolean(MatlabUtils.construct_random_integers(nb_iterations, IMIN, IMAX, 'uint8',dim));
end