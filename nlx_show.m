function nlx_show(o, args)
%function nlx_show(x)
%
% generic display function for nlx data structures
%

if length(o) == 1
  o = {o};
else
  clf;
end

for n = 1:length(o)
  x = o{n};
  if ~isfield(x, 'type')
    error('not a known nlx data struct');
  end

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
      hold off
    
    case 'snips'
      subplot(2,1,1);
      hold on
      % plot 1000 random snips
      r = randperm(size(x.v,2));
      plot(x.t, x.v(:, r(1:1000)));
      ylabel('uvolts');
      xlabel('usec');
      
      subplot(2,1,2);
      hold on
      plot(x.t, mean(x.v, 2));
      eshade(x.t, mean(x.v, 2), std(x.v, [], 2));
      ylabel('uvolts');
      xlabel('usec');
      hold off
      
    case 'events'
      error('can''t plot events');
      
    otherwise
      error(sprintf('unknown struct type: %s', x.type));
  end
end
