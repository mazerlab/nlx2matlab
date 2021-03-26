function csc = nlx_CSClp(csc)
%function csc = nlx_CSClp(csc)
%
% low pass filter CSC data
%
%   Basically highpass filters the entire CSC dataset and puts it
%   back into the structure tagging it as already filtered.
%

if isfield(csc, 'islp')
  warning('csc already filtered - skipping');
else
  [l, ~, ~] = filter_wideband(csc.ts/1e6, csc.v, 'l');
  
  csc.fs = 1/diff(l(1,1:2));            % lfp is decimated from original CSC freq
  csc.v = l(2,:);
  csc.ts = l(1,:);
  csc.islp = 1;                         % flag to prevent repeat filtering
  
  % these no longer apply:
  csc.nsamples = NaN;
  csc.nblocks = NaN; 
end
