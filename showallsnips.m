function showallsnips(exper, src)

if ~exist('src', 'var')
  src = 'se';
end
if strcmp(src, 'all')
  showallsnips(exper, 'sx');
  showallsnips(exper, 'csc-se');  
  showallsnips(exper, 'se');
  return
end

l = dbfind(exper, 'list');
pf = p2mLoad2(l{1});

figure;
set(gcf, ...
    'Units', 'inches', ...
    'Position', [0.1 0.1 17 10]);
yr = [];
ax = [];
for ch = 1:64
  subplot(8,8,ch);
  switch src
    case 'sx'
      nd = p2mLoadNLX(pf, 's', ch);
      snips = nd.snips;
    case 'se'
      f = sprintf('%s/sefiles/se%d.mat', dirname(pf.src), ch);
      snips = rwsnips('load', [], f);
    case 'csc-se'
      f = sprintf('%s/sefiles/csc-se%d.mat', dirname(pf.src), ch);
      snips = rwsnips('load', [], f);
    otherwise
      error('src must be: ''sx'', ''se'' or ''csc-se''');
  end
  if ~isempty(snips)
    plotsnips(snips, ch);
    t = title(sprintf('Ch%d:%d', ch, size(snips.v,2)));
    yr = [yr; get(gca, 'ylim')];
  else
    t = title(sprintf('Ch%d:%d', ch, 0));
  end
  set(t, 'FontWeight', 'normal');
  
  ax = [ax gca];
  if ch < 33
    set(gca,'color', [0.5 0.9 0.9]);
  else
    set(gca,'color', [0.5 0.5 0.9]);
  end
  fprintf('.');
end
fprintf('\n');
if ~isempty(yr)
  rng = [max(-120, min(yr(:,1))) min(120, max(yr(:,2)))]; 
 set(ax, 'YLim', rng);
end

for n = 1:length(ax)
  set(gcf, 'CurrentAxes', ax(n));
  vline(0, 'LineStyle', '-', 'Color', 'b');
  hline(0, 'LineStyle', '-', 'Color', 'b');
end
ylabel('uvolts');
xlabel('usec');

boxtitle(sprintf('exper=%s  src=%s', exper, src));
%png(sprintf('%s-%s.png', exper, src));

function plotsnips(x, n)

r = rdraw(200, 1:size(x.v,2));
plot(x.t, x.v(:, r), 'Color', [0 0 0 .1]);
hold on;
set(plot(x.t, nanmean(x.v, 2), 'g-'), 'LineWidth', 1);
hold off;
axis tight;
hline(x.thresh, 'LineStyle', '-', 'Color', 'r');
hline(x.orig_thresh, 'LineStyle', ':', 'Color', 'r');
