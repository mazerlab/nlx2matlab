function rv = rdraw(k, v)

if k < 1
  k = round(k * length(v));
end
    
ns = randperm(length(v));
rv = v(ns(1:min(k, length(v))));


