function pf = p2mnlxselect(pf, ch, cellnum)
%function pf = p2mnlxselect(pf, ch, cellnum)
%
% Select spikes from neuralynx data for processing. This replaces
% the spike_times on each trial with aligned snip data from the
% SX recording system.
%
% Search order is as follows:
%  1. Curated snipedit response (seNN.mat)
%  2. Raw CSC snips (csc-seNN.mat)
%  3. Raw SE snips right off the SX box  (SEnn.nsc)
% 
%INPUT
% pf - standard pypefile data strut
% ch - channel number (1-64)
% cellnum - can be 0 for all units, 1-n or a-z to specify specific
%   sorts from snipedit. if no ch/cellnum are provided, reverts back
%   to ttl times.
%
%OUTPUT
% new pf with updated spike_times
% note: pf.sortcode is added to hold the label for requested sort.
%


if nargin < 2
  % no ch/cellnum args, restore TTL data
  for n = 1:length(pf.rec)
    pf.rec(n).spike_times = pf.rec(n).ttl_times;
  end
  if isfield(pf, 'sortcode')
    pf = rmfield(pf, 'sortcode');
  end
  return
end

if nargin == 2 || isempty(cellnum)
  % raw, unsorted codes
  cellnum = 0;
elseif ischar(cellnum)
  % named sort code: a, b, c...
  cellnum = 1 + cellnum - 'a';
end

if ~exist(pf.src, 'file')  
  % these are files that were probably manually moved and the sql
  % database updated manually
  if length(l) < 1
    error('%s has been moved - please regenerate .p2m!', pf.src);
  end
  pf.src = l{1};
end

d = dirname(pf.src);

sefile = sprintf('%s/sefiles/se%d.mat', d, ch);
cscsefile = sprintf('%s/sefiles/csc-se%d.mat', d, ch);
if exist(sefile, 'file')
  snips = rwsnips('read', [], sefile);
  nd = p2mLoadNLX(pf, 'e', ch);
  nd.snips = snips;
  fprintf('loaded %s\n', basename(sefile));
elseif exist(cscsefile, 'file')
  snipfile = sprintf('%s/sefiles/csc-se%d.mat', d, ch);
  snips = rwsnips('read', [], cscsefile);
  nd = p2mLoadNLX(pf, 'e', ch);
  nd.snips = snips;
  fprintf('loaded %s\n', basename(cscsefile));
else
  nd = p2mLoadNLX(pf, 'se', ch);
  fprintf('loaded raw SX SE files\n');
end

tt = p2mSyncNLX(pf, nd);
for n = 1:length(pf.rec)
  % start/stop times on pype side (ms)
  [~, pstart] = p2mFindEvents(pf, n, 'start');
  [~, pstop] = p2mFindEvents(pf, n, 'start');

  % start/stop times on nlx side (usec)
  nstart = tt.start(n);
  nstop = tt.stop(n);
  
  % find all matching spikes
  if cellnum > 0
    % match specified sort
    ix = find(nd.snips.ts >= nstart & ...
              nd.snips.ts < nstop & ...
              nd.snips.cellnumbers == cellnum);
  else
    % match all sorts
    ix = find(nd.snips.ts >= nstart & ...
              nd.snips.ts < nstop);
  end
  pf.rec(n).spike_times = (nd.snips.ts(ix) - nstart) ./ 1000.0;
  %fprintf('%d: %d\n', n, length(ix));
end

if cellnum > 0
  pf.sortcode = sprintf('nlxCh%02d%c', ch, 'a'+cellnum-1);
else
  pf.sortcode = sprintf('nlxCh%02d%c', ch, '*');
end
