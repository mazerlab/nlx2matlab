function d = p2mFindNLX(pf)
%function d = p2mFindNLX(pf)
%
% find nlx data directory for given pypefile
%
%  - first try to find on raid
%  - then look on windows 10 cheetah host
%

dirs = unique(arrayfun(@(x) strjoin(x.params.nlx_datadir, ''), pf.rec, 'UniformOutput', 0)');
if length(dirs) > 1
  error('can''t handle multiple nlx_datadirs');
elseif length(dirs) == 0
  error('no nlx_datadir in file');
end

u = strrep(strrep(dirs{1}, '\', '/'), 'C:', '');

% these are mazer-lab specific!

d = ['/auto/data/critters/cheetah' u];
if exist(d, 'dir')
  return
end

d = ['/auto/cheetah' u]
if exist(d, 'dir')
  return
end

d = '';
