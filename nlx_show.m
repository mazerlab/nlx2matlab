function nlx_show(o, args)
%function nlx_show(x)
%
% generic display function for nlx data structures
%

if length(o) == 1
  clf;
  o = {o};
end

for n = 1:length(o)
  x = o{n};
  if ~isfield(x, 'type')
    error('not a known nlx data struct');
  end
  
  src = strsplit(x.src, '/');
  src = ['...' strjoin(src(end-2:end),'/')];
  src = strrep(src, '_', '\_');

  switch x.type
    case 'csc'
      hold on
      if exist('args', 'var')
        plot(x.ts(args), x.v(args));
      else
        plot(x.ts, x.v);
      end
      axis tight
      xlabel('usec');
      ylabel('uv');
      grid on;
      hold off
      
      title(src);
    
    case 'snips'
      rng = 5 * nanstd(x.v(:));
      
      % plot 1000 random snips
      subplot(2,2,1);
      hold on
      r = randperm(size(x.v,2));
      plot(x.t, x.v(:, r(1:min(1000, size(x.v,2)))));
      yrange(-rng,rng);
      ylabel('uvolts');
      xlabel('usec');
      vline(0, 'LineStyle', '-');
      if isfield(x, 'thresh')
        hline(x.thresh, 'LineStyle', '-');
      end
      grid on;
      hold off

      % plot average spike
      subplot(2,2,3);
      hold on
      plot(x.t, nanmean(x.v, 2));
      plot(x.t, nanmean(x.v, 2), 'r.');
      eshade(x.t, nanmean(x.v, 2), nanstd(x.v, [], 2));
      yrange(-rng,rng);
      vline(0, 'LineStyle', '-');
      if isfield(x, 'thresh')
        hline(x.thresh, 'LineStyle', '-');
      end
      ylabel('uvolts');
      xlabel('usec');
      title(sprintf('average; n=%d', length(x.ts)));
      grid on;
      hold off

      % plot histogram of ISIs
      %
      % Note: this is potentially misleading -- the NLX spike
      %   detection algorithm has a hard refractory period
      %   build in: "-SpikeRetriggerTime 750"
      subplot(2,2,2);
      hold on
      isis = [NaN diff(x.ts/1000)];
      if length(isis) < 2
        cla; textbox('no data', 0);
      else
        [n, edges] = histcounts(isis, 0:1:max(isis));
        edges = (edges(2:end)+edges(1:end-1)) / 2;
        n = 100 .* n ./ sum(n);
        yyaxis left
        set(bar(edges(edges<20), n(edges<20)), 'FaceColor', [0.5 0.5 0.7]);
        ylabel('%');
        yyaxis right
        plot(edges(edges<20), cumsum(n(edges<20)), 'r-');
        ylabel('cummulative %');
        xlabel('ISI ms');
      end
      hold off

      % plot waveforms for short (<2ms) ISI spikes - second
      % spike in doublet
      subplot(2,2,4);
      hold on
      ix = find(isis < 2);
      plot(x.t, nanmean(x.v(:,ix), 2));
      plot(x.t, nanmean(x.v(:,ix), 2), 'r.');
      eshade(x.t, nanmean(x.v(:,ix), 2), nanstd(x.v(:,ix), [], 2));
      yrange(-rng,rng);
      vline(0, 'LineStyle', '-');
      if ~isnan(x.thresh)
        hline(x.thresh, 'LineStyle', '-');
      end
      ylabel('uvolts');
      xlabel('usec');
      title(sprintf('shortisi (<2ms) %.2f%%', 100*length(ix)/length(isis)));
      grid on;
      hold off
      
      if x.cliprisk
        boxtitle([src ' CLIPPED']);
      else
        boxtitle(src);
      end
      
    case 'events'
      error('can''t plot events');
      
    otherwise
      error(sprintf('unknown struct type: %s', x.type));
  end
end
