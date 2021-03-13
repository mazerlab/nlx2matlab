function [snips, clusterplots] = ksnip(snips, nc)
%function ksnip(snips, nc)
%
% Simple k-means clustering of snips based on hardware-extract features
% (from the CheetahSX box).
%
% currently this just DISPLAYs the k-means results -- doesn't actually
% 

if isempty(snips.params)
  error('missing snip/SE params');
end

% should only use 1st 4 PCs -- SX params 5-8 are dubious..
np = size(snips.params,1);
np = 4;


% save state of random number generator for reproducibility
rs = rng; rng(1);
idx = kmeans(snips.params(1:np,:)', nc);
rng(rs);

% store sort kmeans results back in snip
snips.sortcode = char('a' + idx - 1)';

% select data random subset
% this may not be a good idea - if one class is much more frequent
% than the others, the rare class will get obscured..
MAXSCATTER=1000;
ix = rdraw(MAXSCATTER, 1:size(snips.params,2));
p = snips.params(:,ix);
idx2 = idx(ix);

clf;

% feature plots
row = 0; col = 0;
cmap = lines(nc);
for n = 1:np
  for k = 1:np
    if k <= n
      if k ~= n
        subplot(np, 2*np, 1+(row*2*np)+col);
        col = col + 1;

        scatter(p(n,:), p(k,:), 2, cmap(idx2,:), '.');
        %axis tight;
        %axis equal;
        set(gca, 'YTickLabel', {},  'XTickLabel', {}, ...
                 'YTick', [],  'XTick', []);
        box on;
      end
    end
  end
  row = row + 1;
  col = 0;
end

% waveform plots
cmap = [0 0 0; cmap];
subplot(3, 3, 2);
leg = {};
for n = 0:nc
  if n == 0
    ix = 1:length(idx);
  else
    ix = find(idx == n);
  end
  %fprintf('%d: %d\n', n, length(ix));
  l = plot(snips.t, mean(snips.v(:, ix), 2), '-');
  set(l, 'Color', cmap(n+1,:));
  if n >= 0
    set(l, 'LineWidth', 1);
  end
  hold on
  
  if n == 0
    leg{n+1} = 'all';
  else
    leg{n+1} = char('a' + n - 1);
  end
end
hold off
xlabel('um');
ylabel('uvolt');
title('waveforms');
hline(0, 'LineStyle', '-');
sig = std(snips.v(:));
hline(-3*sig, 'LineStyle', ':');
hline(3*sig, 'LineStyle', ':');
legend(leg, 'location', 'bestoutside');

% ISI histograms
subplot(3, 3, 5);
for n = 0:nc
  if n == 0
    ix = 1:length(idx);
  else
    ix = find(idx == n);
  end
  isis = diff(snips.ts(ix))/1000;
  [c, x] = histcounts(isis, 0:20);
  x = (x(2:end)+x(1:end-1)) / 2;
  c = 100 .* c ./ length(ix);
  l = plot(x, c, '-');
  set(l, 'Color', cmap(n+1,:));
  if n >= 0
    set(l, 'LineWidth', 1);
  end
  hold on
end
hold off
xlabel('ms');
ylabel('%');
title('isi');
legend(leg, 'location', 'bestoutside');

% bycluster waveform plots

a = [];
for n = 1:nc
  subplot(nc, 3, 3*n);
  ix = rdraw(1000, find(idx == n));
  plot(snips.t, snips.v(:, ix), '-', 'Color', [cmap(n+1,:) 0.2]);
  if length(snips.q) >= n
    ylabel(sprintf('%d %s', n, snips.q{n}));
  else
    ylabel(n);
  end
  a = [a; axis];
end
% set all to same yrange for comparison
if nc > 1
  a = max(a(:, 3:4));
else
  a = a(3:4);
end
for n = 1:nc
  subplot(nc, 3, 3*n);
  yrange(a(1), a(2));
  if nargout > 1
    clusterplots(n) = cla;
  end
end

src = strsplit(snips.src, '/');
src = ['...' strjoin(src(end-2:end),'/')];
src = strrep(src, '_', '\_');
boxtitle(sprintf('%s [features:%s]', src, snips.features));

