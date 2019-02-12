function vector = construct_random_integers(nb_iterations, IMIN, IMAX, dt, dim)
    if numel(dim)==1
        vector = randi([IMIN, IMAX], [nb_iterations,dim],dt);
    else
        vector = randi([IMIN, IMAX], [dim,nb_iterations],dt);
    end
end