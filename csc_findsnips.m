function snips = csc_findsnips(csc, th, sig, ch)

if exist('ch', 'var')
  ch = 0;
end

% these match SX default settings
PRE=8;
POST=32-8-1;

t = csc.ts;
v = csc.v;

if sig
  % n * sigma
  thresh = th * std(v);
else
  % actual uvolts
  thresh = th;
end

if thresh > 0
  ix = find(diff(v > thresh) > 0);
else
  ix = find(diff(v < thresh) > 0);
end

x = -PRE:POST;
x = x-1;
s = zeros([size(ix,2) size(x,2)]);
for n = 1:length(ix)
  try
    s(n,:) = v((ix(n)-PRE):(ix(n)+POST));
  catch
    % ran off the ends of the data
    s(n,:) = NaN .* x;
  end
end

snips.type = 'snips';
snips.header = csc.header;
snips.src = csc.src;
snips.ts = t(ix);
snips.scnumbers = ch + zeros([1 length(ix)]);
snips.cellnumbers = ones([1 length(ix)]);
snips.params = [];
snips.fs = csc.fs;
snips.v = s';
snips.t = 1e6 .* x' ./ csc.fs;          % zero in middle (se is 0 at start)

snips.thresh = thresh;
snips.orig_thresh = thresh;

snips.cliprisk = 0;                     % this needs to be fixed!
