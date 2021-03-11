function ksnip(snips, nc)
%function ksnip(snips, nc)
%
% Simple k-means clustering of snips based on hardware-extract features
% (from the CheetahSX box).
%

if isempty(snips.params)
  error('missing snip/SE params');
end

% should only use 1st 4 PCs -- SX params 5-8 are dubious..
np = size(snips.params,1);
np = 4;


idx = kmeans(snips.params(1:np,:)', nc);
cmap = lines(nc);

% select data random subset
% this may not be a good idea - if one class is much more frequent
% than the others, the rare class will get obscured..
MAXSCATTER=1000;
ix = randperm(size(snips.params,2));
ix = ix(1:min(size(snips.params,2),MAXSCATTER));
p = snips.params(:,ix);
idx = idx(ix);

clf;
pn = 0;
for n = 1:np
  for k = 1:np
    pn = pn + 1;
    if k <= n
      if k ~= n
        subplot(np, np, pn);
        scatter(p(n,:), p(k,:), 2, cmap(idx,:), '.');
        axis tight;
        axis off;
        axis equal;
      end
    end
  end
end

cmap = [0 0 0; cmap];
subplot(3, 3, 3);
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

subplot(3, 3, 6);
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

src = strsplit(snips.src, '/');
src = ['...' strjoin(src(end-2:end),'/')];
src = strrep(src, '_', '\_');
boxtitle(sprintf('%s [features:%s]', src, snips.features));


