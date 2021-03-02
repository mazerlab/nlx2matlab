function ksnip(snips, nc)
%function ksnip(snips, nc)
%
% Simple k-means clustering of snips based on hardware-extract features
% (from the CheetahSX box).
%

if isempty(snips.params)
  error('missing snip/SE params');
end


idx = kmeans(snips.params', nc);
cmap = lines(nc);

np = size(snips.params,1);
pn = 0;
for n = 1:np
  for k = 1:np
    pn = pn + 1;
    if k <= n
      subplot(np, np, pn);
      scatter(snips.params(n,:), snips.params(k,:), 2, cmap(idx,:), 'filled');
      xlabel(n); ylabel(k);
      axis tight;
      axis off;
    end
  end
end

cmap = [0 0 0; cmap];
subplot(3, 3, 3);
for n = 0:nc
  if n == 0
    ix = 1:length(idx);
  else
    ix = find(idx == n);
  end
  fprintf('%d: %d\n', n, length(ix));
  l = plot(snips.t, mean(snips.v(:, ix), 2), '-');
  set(l, 'Color', cmap(n+1,:));
  if n >= 0
    set(l, 'LineWidth', 3);
  end
  hold on
end
hold off
xlabel('um');
ylabel('uvolt');
title('waveforms');

subplot(3, 3, 6);
for n = 0:nc
  if n == 0
    ix = 1:length(idx);
  else
    ix = find(idx == n);
  end
  isis = diff(snips.ts(ix))/1000;
  [c, x] = histcounts(isis, 0:50);
  x = (x(2:end)+x(1:end-1)) / 2;
  c = 100 .* c ./ length(ix);
  l = plot(x, c, '-');
  set(l, 'Color', cmap(n+1,:));
  if n >= 0
    set(l, 'LineWidth', 3);
  end
  hold on
end
hold off
xlabel('ms');
ylabel('%');
title('isi');
legend

src = strsplit(snips.src, '/');
src = ['...' strjoin(src(end-2:end),'/')];
src = strrep(src, '_', '\_');

suptitle(src);

