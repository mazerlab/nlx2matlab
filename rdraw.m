function rv = rdraw(k, v)
ns = randperm(length(v));
rv = v(ns(1:min(k, length(v))));


