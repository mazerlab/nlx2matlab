function snips = rwsnips(dir, snips, savefile)
%function snips = rwsnips(dir, snips, savefile)
%
% save/load snip struct to file
%

SCALE=1;

switch dir
  case {'write', 'save'}
    xx = struct();
    xx.snips = snips;
    
    % - snip voltages are in uv -- scale up, round and convert to 16
    %   bit signed ints to save space. This preserves better than
    %   0.01uv precision (std/rms) at ~4x space savings..
    % - compression is reversed on load by this function
    %
    if SCALE
      xx.snips.scale = 1 / 100;
      xx.snips.v = int16(round(xx.snips.v ./ xx.snips.scale));
    end
    err = rms((double(xx.snips.v(:)) .* xx.snips.scale) - snips.v(:));
    save(savefile, 'xx');
    fprintf('; wrote snips to: %s (err=%fuv)\n', savefile, err);
  case {'read', 'load'}
    try
      xx = load(savefile, '-mat');
      snips = xx.xx.snips;
      if isfield(snips, 'sxthresh')
	snips.orig_thresh = snips.sxthresh;
	snips = rmfield(snips, 'sxthresh');
      end
      if ~isfield(snips, 'orig_thresh')
	snips.orig_thresh = snips.thresh;
      end
      if isfield(snips, 'scale')
	snips.v = double(snips.v) .* snips.scale;
        snips = rmfield(snips, 'scale');
      end
    catch ME
      if strcmp(ME.identifier, 'MATLAB:load:couldNotReadFile')
        warning('%s missing', savefile);
        snips = [];
      else
        rethrow(ME);
      end
    end
  otherwise
    error('rwsnips: unknown option -- %s', dir);
  end
end
