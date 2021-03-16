function snips = subsnips(snips, ix)
%function snips = subsnips(snips, ix)
%
% take a subset of snips, preserving everything else in struct
% 

if length(ix) > 0
  snips.ts = snips.ts(ix);
  snips.scnumbers = snips.scnumbers(ix);
  snips.cellnumbers = snips.cellnumbers(ix);
  if ~isempty(snips.params)
    snips.params = snips.params(:,ix);
  end
  snips.v = snips.v(:,ix);
end
