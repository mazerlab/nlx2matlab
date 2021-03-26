function csc = rwcsc(dir, csc, savefile)
%function csc = rwcsc(dir, csc, savefile)
%
% save/load csc struct to file
%
% this works, but resulting files are enormous..
% would be better to do some sort of delta compression

%error('don''t use rwcsc -- this is NOT efficient');

SCALE=1;

switch dir
  case {'write', 'save'}
    xx = struct();
    xx.csc = csc;
    
    % - voltages are in uv -- scale up, round and convert to 16
    %   bit signed ints to save space. This preserves better than
    %   0.01uv precision (std/rms) at ~4x space savings..
    % - compression is reversed on load by this function
    % - for CSC/LFP files, there can be some clipping and artifacts
    %   on original wavforms and compression can cause apparent rms
    %   errors, but safe to ignore (I think, JM).
    
    if SCALE
      xx.csc.scale = 1 / 10;
      v = xx.csc.v;
      xx.csc.v = int16(round(xx.csc.v ./ xx.csc.scale));
      keyboard
    end
    err = rms((double(xx.csc.v(:)) .* xx.csc.scale) - csc.v(:));
    save(savefile, 'xx');
    fprintf('; wrote csc to: %s (err=%fuv)\n', savefile, err);
  case {'read', 'load'}
    try
      xx = load(savefile, '-mat');
      csc = xx.xx.csc;
      if isfield(csc, 'scale')
	csc.v = double(csc.v) .* csc.scale;
        csc = rmfield(csc, 'scale');
      end
    catch ME
      if strcmp(ME.identifier, 'MATLAB:load:couldNotReadFile')
        warning('%s missing', savefile);
        csc = [];
      else
        rethrow(ME);
      end
    end
  otherwise
    error('rwcsc: unknown option -- %s', dir);
  end
end
