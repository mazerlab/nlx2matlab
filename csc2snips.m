function csc2snips(expers)

if ischar(expers)
  expers = { expers };
end

for n = 1:length(expers)
  l = dbfind(expers{n}, 'list');
  pf = p2mLoad2(l{1});

  for ch = 1:64
    savefile = sprintf('%s/sefiles/csc-se%d.mat', dirname(pf.src), ch);
    if exist(savefile, 'file')
      fprintf('; exists: %s\n', savefile);
      continue;
    end
    
    x = p2mLoadNLX(pf, 'h', ch);
    thresh = 3 * std(x.csc.v);
    snips = csc_findsnips(x.csc, thresh, 0, ch);
    
    savefile = sprintf('%s/sefiles/csc-se%d.mat', dirname(pf.src), ch);
    mkdirhier(dirname(savefile));
    try
      rwsnips('save', snips, savefile);
    catch ME
      warning('error saving: %s', savefile);
      disp(ME);
    end
  end
end
