function mkdirhier(d)
[s, r] = unix(sprintf('mkdir -p %s', d));
if s
  error(r);
end
