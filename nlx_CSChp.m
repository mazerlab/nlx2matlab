function csc = nlx_CSChp(csc)
%function csc = nlx_CSChp(csc)
%
% high pass filter CSC data
%
%   Basically highpass filters the entire CSC dataset and puts it
%   back into the structure tagging it as already filtered.
%


if isfield(csc, 'ishp')
  warning('csc already filtered - skipping');
else
  [~, s, ~] = filter_wideband(csc.ts/1e6, csc.v, 's');
  csc.v = s(2,:);
  csc.ishp = 1;                         % flag to prevent repeat filtering
end
