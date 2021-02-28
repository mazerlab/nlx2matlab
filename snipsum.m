function snipsum(p)
%function snipsum(p)
%
% generate a single pdf that summarizes all the SE
% files associated with the specified pypefile.
%
%INPUT
%  p - pypefile or exper/pattern
%
%OUTPUT
% each SE plot is written to pdf in /tmp and then
% merged at the end into single pdf
%
% This is overal pretty fast on the cluster
% with PARFOR.

NC=64;

if isstruct(p)
  pf = p;
else
  files = dbfind(p, 'list', 'all');
  if length(files) == 0
    error('no matching files');
  end
  pf = p2mLoad2(files{1});
end
dd = p2mFindNLX(pf);

exper = strsplit(pf.src, '/');
exper = strsplit(exper{end}, '.');
exper = exper{1};

NC=64;

temp_ofs = {};
parfor n = 1:NC
  f = [dd sprintf('/SE%d.nse', n)];
  of = sprintf('/tmp/%s-SE%02d.pdf', exper, n);
  if exist(f, 'file')
    x = nlx_getRawSE(f);
    if isempty(x)
      clf;
      textbox(sprintf('%s: NO DATA', of), 0);
      x = [];
      fprintf('%s -- NO DATA\n', f);
    else
      nlx_show(x);
      fprintf('%s -- ok\n', f);
    end
    print(gcf, of, '-dpdf');
    temp_ofs{n} = of;
  end
end

of = sprintf('%s-snips.pdf', exper);
[s, w] = unix(sprintf('pdftk %s cat output %s', strjoin(temp_ofs), of));
[~, ~] = unix(sprintf('/bin/rm %s', strjoin(temp_ofs)));
if s == 0
  fprintf('wrote: %s\n', of);
else
  error(w);
end
