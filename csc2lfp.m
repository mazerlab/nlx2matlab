function csc2lfp(expers)
%function csc2lfp(expers)
%
% extract lfp data from raw CSC data files - modified version of csc2snip.m
%
%
% expers can be 'bertNNNN' or {'bertNNNN', 'bertXXXX' ...} or empty.
% if empty, will use elog data to generate list of experiments and
% work backwards from most recent experiment and stop when it detects
% preprocessing has already been done.
%

halt_on_first_dup = 0;

if ~exist('expers', 'var')
  % if no expers specified, try to get a list and work backwards..
  x = dbfind('bert14%%.%.000', 'list');
  x = cellfun(@(x) basename(x), x, 'uniformoutput', 0);
  expers = {};
  for n = 1:length(x)
    y = strsplit(x{n}, '.');
    expers{length(expers)+1} = y{1};
  end
  % stop as soon as you find a file already exracted
  halt_on_first_dup = 1;
  expers = expers(end:-1:1);
else
  if ischar(expers)
    expers = { expers };
  end
end

for n = 1:length(expers)
  l = dbfind(expers{n}, 'list');
  pf = p2mLoad2(l{1});

  for ch = 1:64
    savefile = sprintf('%s/sefiles/csc-lfp%d.mat', dirname(pf.src), ch);
    if exist(savefile, 'file')
      if halt_on_first_dup
        return
      end
      fprintf('; exists: %s\n', savefile);
      continue;
    end

    fprintf(';;; processing %s\n', expers{n});

    x = p2mLoadNLX(pf, 'l', ch);
    
    savefile = sprintf('%s/sefiles/csc-lfp%d.mat', dirname(pf.src), ch);
    mkdirhier(dirname(savefile));
    try
      rwcsc('save', x.csc, savefile);
    catch ME
      error('error saving: %s\n<%s>', savefile, ME.message);
    end
  end
end


