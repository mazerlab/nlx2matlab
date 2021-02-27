function nlx_show(x, args)
%function nlx_show(x)
%
% generic display function for nlx data structures
%

if ~isfield(x, 'type')
  error('not a known nlx data struct');
end

switch x.type
  case 'csc'
    if exist('args', 'var')
      plot(x.ts(args), x.v(args));
    else
      plot(x.ts, x.v);
    end
    axis tight
    xlabel('usec');
    ylabel('uv');
    
  case 'snips'
    subplot(2,1,1);
    % plot 1000 random snips
    r = randperm(size(x.v,2));
    plot(x.t, x.v(:, r(1:1000)));
    ylabel('uvolts');
    xlabel('usec');
    
    subplot(2,1,2);
    plot(x.t, mean(x.v, 2));
    eshade(x.t, mean(x.v, 2), std(x.v, [], 2));
    ylabel('uvolts');
    xlabel('usec');
    
  case 'events'
    error('can''t plot events');
    
  otherwise
    error(sprintf('unknown struct type: %s', x.type));
end
