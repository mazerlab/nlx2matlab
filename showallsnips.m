function showallsnips(exper, src, varargin)

opts.autoscale = 0;                     % scale each plot to max (vs all same)
opts.meanonly = 0;                      % no traces
opts.save = 0;

if nargin == 0
  % no args -- try to find exper in current directoy and process in place
  [s, exper] = unix('ls *.000x | head -1 | awk -F. ''{print $1}''');
  exper = exper(1:end-1);
  showallsnips(exper, 'all', 'save');
  return;
end

if ~exist('src', 'var')
  src = 'se';
end
if strcmp(src, 'all')
  showallsnips(exper, 'sx', varargin{:});
  showallsnips(exper, 'csc-se', varargin{:});
  showallsnips(exper, 'se', varargin{:});
  return
end

n = 1;
while n < length(varargin)
  arg = varargin{n};
  switch arg
    case 'autoscale'
      opts.autoscale = 1;
    case 'meanonly'
      opts.meanonly = 1;
    case 'save'
      opts.save = 1;
    otherwise
      error('unknown arg: %s', arg);
  end
  n = n + 1;
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
      error('src must be: ''all'', ''sx'', ''se'' or ''csc-se''');
  end
  if ~isempty(snips)
    plotsnips(snips, ch, opts);
    t = title(sprintf('Ch%d:%d', ch, size(snips.v,2)));
    yr = [yr; get(gca, 'ylim')];
  else
    t = title(sprintf('Ch%d:%d', ch, 0));
  end
  set(t, 'FontWeight', 'normal');
  
  ax = [ax gca];
  if 0
    if ch < 33
      set(gca, 'color', [.6 .5 .5]);
    else
      set(gca, 'color', [.5 .6 .5]);
    end
  end
  fprintf('.');
end
fprintf('\n');
if ~opts.autoscale
  if ~isempty(yr)
    rng = [max(-120, min(yr(:,1))) min(120, max(yr(:,2)))]; 
    set(ax, 'YLim', rng);
  end
end

for n = 1:length(ax)
  set(gcf, 'CurrentAxes', ax(n));
  vline(0, 'LineStyle', '-', 'Color', 'b');
  hline(0, 'LineStyle', '-', 'Color', 'b');
end
ylabel('uvolts');
xlabel('usec');

boxtitle(sprintf('exper=%s  src=%s', exper, src));

if opts.save
  png = sprintf('%s-%s.png', exper, src);
  pdf = sprintf('%s-%s.pdf', exper, src);
  exportgraphics(gcf, png, 'resolution',300);
  unix(sprintf('convert -resize 75%% %s %s %s', png, pdf));
end

function plotsnips(x, n, opts)

y = nanmean(x.v, 2);
if opts.meanonly
  plot(x.t, y, 'k-');
  eshade(x.t, y, nanstd(x.v, [], 2));
else
  r = rdraw(200, 1:size(x.v,2));
  plot(x.t, x.v(:, r), 'Color', [0 0 0 .1], 'LineWidth', 0.1);
  hold on;
  plot(x.t, y, 'g-', 'LineWidth', 1);
  hold off;
end
axis tight;
hline(x.thresh, 'LineStyle', '-', 'Color', 'r');
hline(x.orig_thresh, 'LineStyle', ':', 'Color', 'r');
