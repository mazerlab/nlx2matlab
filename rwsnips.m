function snips = rwsnips(dir, snips, savefile)
%function snips = rwsnips(dir, snips, savefile)
%
% save/load snip struct to file
%

switch dir
  case 'save'
    xx = struct();
    xx.snips = snips;
    save(savefile, 'xx');
    fprintf('; wrote snips to: %s\n', savefile);
    snips = [];
  case 'load'
    try
      xx = load(savefile);
      snips = xx.xx.snips;
      if isfield(snips, 'sxthresh')
	snips.orig_thresh = snips.sxthresh;
	snips = rmfield(snips, 'sxthresh');
      end
      if ~isfield(snips, 'orig_thresh')
	snips.orig_thresh = snips.thresh;
      end
    catch
      snips = [];
    end
  otherwise
    error('rwsnips: unknown option -- %s', dir);
  end
end
