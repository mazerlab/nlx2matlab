classdef snipedit < handle

  properties
    exper
    pf
    ch
    fig0, fig1, fig2, fig3
    nd
    cscdata
    cscn
    nclust
    buf
    pca
    thresh
    use_csc
    busy
    r
  end

  properties (Constant)
    NCHAN = 64;
  end
  
  methods
    function obj = snipedit(exper, ch)
      obj.buf = '';
      
      l = dbfind(exper, 'list');
      obj.pf = p2mLoad2(l{1});
      obj.exper = exper;
      obj.nd = [];
      obj.cscdata = [];
      obj.cscn = -1;
      
      obj.rwqual('load');
      
      if exist('ch', 'var')
	obj.ch = ch;
      end

      n = 100;
      obj.fig0 = figure(n); clf; n = n + 1;
      obj.fig1 = figure(n); clf; n = n + 1;
      obj.fig2 = figure(n); clf; n = n + 1;
      obj.fig3 = figure(n); clf; n = n + 1;
      
      set(obj.fig0, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Position', [0, 1, 0.66, 0.03], ...
          'Toolbar' ,'none', 'Menubar', 'none');

      buts = [];
      labels = { {'keep>', 'comma'}, ...
		 {'<', 'p'}, {'>', 'n'}, ...
		 {'SU', 's'}, {'MU', 'm'}, {'junk', 'x'}, {'Check', 'z'}, ...
		 {'k++', 'equal'}, {'k--', 'hyphen'}, ...
		 {'pca', 'f'}, {'Quit', 'q'} };

      for n = 1:length(labels)
	buts(n) = uicontrol(obj.fig0, 'Style', 'pushbutton', ...
			    'String', labels{n}{1});
	if n < 2
	  pn = get(buts(n), 'Position');
	  pn(2) = 1;
	  set(buts(n), 'Position', pn);
	else
	  pn = get(buts(n), 'Position');
	  pl = get(buts(n-1), 'Position');
	  set(buts(n), 'Position', [pl(1)+pl(3) pl(2) pn(3) pl(4)]);
	end
	set(buts(n), 'Callback', {@obj.dispatch, labels{n}{2}});
      end

      set(obj.fig1, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
	  'Position', [0, .58, 0.4, 0.3], ...
          'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.fig2, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Position', [0, .25, 0.66, 0.3], ...
          'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.fig3, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Position', [0.41, 0.58, 0.25, 0.3], ...
          'Toolbar' ,'none', 'Menubar', 'none');

      while 1
	obj.selectchan(obj.ch)
	if obj.loadchan()
	  break;
	end
	obj.selectchan(obj.ch);
      end
      obj.draw();
      
      obj.busy = 1;
      set(obj.fig0, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig1, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig2, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig3, 'KeyPressFcn', @obj.dispatch);
      obj.busy = 0;
    end

    function selectchan(obj, n)
      if n > obj.NCHAN
	n = 1;
      elseif n < 1
	n = obj.NCHAN;
      end
      obj.ch = n;
      obj.thresh = obj.r{obj.ch}.thresh;
      obj.nclust = obj.r{obj.ch}.nclust;
      obj.pca = obj.r{obj.ch}.pca;
      obj.use_csc = obj.r{obj.ch}.use_csc;
    end
      
    
    function r = loadchan(obj)
      obj.msg(sprintf('loading ch%d', obj.ch));
      
      if obj.use_csc
        if obj.cscn ~= obj.ch
          obj.msg(sprintf('loading csc%d', obj.ch));
          obj.cscdata = p2mLoadNLX(obj.pf, 'h', obj.ch);
          obj.cscn = obj.ch;
        end
	if obj.thresh == 0
	  %% if no threshold set, start at 4 sigma
	  obj.thresh = 4 * std(obj.cscdata.csc.v);
	end
        obj.cscdata.snips = csc_findsnips(obj.cscdata.csc, obj.thresh, 0);
        nd = obj.cscdata;
        nd.csc = [];
      else
        nd = p2mLoadNLX(obj.pf, 's', obj.ch);
	if isempty(nd.snips)
	  %% empty snip file
	  r = 0;
	  return;
	end
	%% artifact rejection - anything >+-200uv is artifact
	nd.snips = subsnips(nd.snips, find(~any(abs(nd.snips.v) > 200)));

	%% this allows setting threshold, but will adjust to make
	%% sure some spikes are found (enough for pca)
	while obj.thresh > 0
	  ix = find(any(nd.snips.v > obj.thresh));
	  if length(ix) > 10
	    %% perhaps should look only at the alignment point?
	    nd.snips = subsnips(nd.snips, ix);
	    nd.snips.thresh = obj.thresh;
	    break;
	  else
	    obj.thresh
	  end
	  
	  %% go down in steps of 10uv until 0 - if get to zero, then there were
	  %% really no snips to start with.
	  obj.thresh = max(0, obj.thresh - 10);
        end
      end
      
      if isempty(nd.snips) || size(nd.snips.v, 2) < 10
	% no (or almost no snips in datafile)
        r = 0;
      else
	r = 1;

	if obj.nclust == length(obj.r{obj.ch}.q)
	  %% no change in number of clusters, keep previous quality evals
	  nd.snips.q = obj.r{obj.ch}.q;
	else
	  %% changed nclust, reset sort quality evals back 'u'
	  nd.snips.q = char('u'+0*(1:obj.nclust));
	end
	%% no features params because loaded from csc, force pca
        if ~isfield(nd.snips, 'params') || isempty(nd.snips.params)
          obj.pca = 1;
        end
	if obj.pca || isempty(nd.snips.params)
	  nd.snips = pcasnip(nd.snips);
	end
        obj.nd = nd;
      end
      obj.msg();
    end
    
    function draw(obj)
      set(0, 'CurrentFigure', obj.fig1);
      nlx_show(obj.nd.snips);
      set(0, 'CurrentFigure', obj.fig2);
      obj.nd.snips = ksnip(obj.nd.snips, obj.nclust);
      obj.msg();
    end
    
    function msg(obj, working)
      set(0, 'CurrentFigure', obj.fig3);
      if nargin > 1 && ~isempty(working)
        cla; textbox(working, 0); drawnow;
      else
        s = sprintf([...
		      '     f: toggle sx/pca features\n' ...
		      'n/p/Ng: next/prev/jump chan\n' ...
		      '+/-/Nk: set # clusters\n' ...
		      '    Nt: set threshold (or up/down arrows)\n' ...
		      ' Nsmxz: mark kluster SU, MU, garbage, check\n']);
        s = [s sprintf('\n')];
        s = [s sprintf('  exper = %s\n', obj.exper)];
        s = [s sprintf('    pca = %d\n', obj.pca)];
        s = [s sprintf(' nclust = %d\n', obj.nclust)];
        if obj.thresh > 0
          s = [s sprintf(' thresh = %.1f\n', obj.thresh)];
        else
          s = [s sprintf(' thresh = none\n')];
        end
        s = [s sprintf('use\\_csc = %d\n', obj.use_csc)];
	
        s = [s sprintf('\n---> #%d %s\n', obj.ch, obj.nd.snips.q)];
	
        s = [s sprintf('\nARG: \\bf{%s}\n', obj.buf)];
        cla; textbox(s, 0);
      end
    end

    function snips = rwsnips(obj, do)
      savefile = sprintf('%s/_se%d.mat', dirname(obj.pf.src), obj.ch);
      switch do
	case 'save'
	  xx = struct();
	  xx.snips = obj.nd.snips;
	  save(savefile, 'xx');
	  fprintf('; wrote snips to: %s\n', savefile);
	  snips = [];
	case 'load'
	  try
	    xx = load(savefile);
	    snips = xx.xx.snips;
	  catch
	    snips = [];
	  end
      end
    end

    function rwqual(obj, do)
      savefile = sprintf('%s/_%s.snips.mat', dirname(obj.pf.src), obj.exper);
      
      switch do
	case 'save'
	  xx = struct();
	  xx.r = obj.r;
	  xx.ch = obj.ch;
	  save(savefile, 'xx');
	  fprintf('; wrote to: %s\n', savefile);
	case 'load'
	  try
	    xx = load(savefile);
	    obj.r = xx.xx.r;
	    obj.ch = xx.xx.ch;
	  catch
	    %% file doesn't exist -- initialize r and save
	    fprintf('; missing %s (initializing)\n', savefile);
	    for n = 1:obj.NCHAN
	      obj.r{n}.q = 'uu';
	      obj.r{n}.thresh = 0;
	      obj.r{n}.nclust = 2;
	      obj.r{n}.pca = 1;
	      obj.r{n}.use_csc = 0;
	    end
	    obj.ch = 1;
	    obj.rwqual('save');
	  end
      end
    end

    function r = arg(obj)
      r = str2num(obj.buf);
      if isempty(r), r = 1; end
      obj.buf = '';
      obj.msg();
    end

    function gochan(obj, abs, rel)
    
      while 1
	    obj.selectchan(obj.ch + 1);
            if obj.loadchan()
	      break;
            end
            fprintf('no snips on ch %d\n', obj.ch);
          end
          obj.draw();
      

    function dispatch(obj, src, event, key)
      if obj.busy
	return
      end
      obj.busy = 1;

      if ~exist('key', 'var')
	key = event.Key;
      else
	key;
      end

      switch key
	case 'f'
          obj.pca = ~obj.pca;
          obj.loadchan();
          obj.draw();
	case {'space', 'n'}
          while 1
	    obj.selectchan(obj.ch + 1);
            if obj.loadchan()
	      break;
            end
            fprintf('no snips on ch %d\n', obj.ch);
          end
          obj.draw();
	case 'p'
          while 1
	    obj.selectchan(obj.ch - 1)
            if obj.loadchan()
	      break;
            end
            fprintf('no snips on ch %d\n', obj.ch);
          end
          obj.draw();
	case 'r'
          obj.loadchan();
          obj.draw();
	case 'c'
	  %% not yet: very, very slow
          obj.use_csc = ~obj.use_csc;
          obj.loadchan();
          obj.msg()
	case 'uparrow'
          t = obj.thresh;
          obj.thresh = obj.thresh + 5;
          obj.msg()
          obj.loadchan();
          obj.draw();
	case 'downarrow'
          t = obj.thresh;
          obj.thresh = max(1, obj.thresh - 5);
          obj.msg()
          obj.loadchan();
          obj.draw();
	case 't'
          t = obj.thresh;
          obj.thresh = obj.arg()
          obj.msg()
          if t ~= obj.thresh
            obj.loadchan();
            obj.draw();
          end
	case 'g'
	  obj.selectchan(obj.arg());
          while 1
            if obj.loadchan()
              break;
            end
            fprintf('no snips on ch %d\n', obj.ch);
            obj.selectchan(obj.ch + 1);
          end
          obj.draw();
	case 'k'
          obj.nclust = max(1, obj.arg());
	  obj.nd.snips.q = char('u'+0*(1:obj.nclust));
          obj.msg('clustering');
          obj.draw();
	case 'equal'
          obj.nclust = obj.nclust+1;
	  obj.nd.snips.q = char('u'+0*(1:obj.nclust));
          obj.msg('clustering');
          obj.draw();
	case 'hyphen'
          n = max(1, obj.nclust-1);
          if n ~= obj.nclust
            obj.nclust = n;
	    obj.nd.snips.q = char('u'+0*(1:obj.nclust));
            obj.msg('clustering');
            obj.draw();
          end
	case 'q'
          close(obj.fig0);
          close(obj.fig1);
          close(obj.fig2);
          close(obj.fig3);
	case 'escape'
          obj.arg();
          obj.msg();
	case 's'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 's';
	  obj.msg();
	case 'm'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 'm';
	  obj.msg();
	case 'x'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 'g';
	  obj.msg();
	case 'z'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 'c';
	  obj.msg();
	case 'comma'
	  obj.r{obj.ch}.q = obj.nd.snips.q;
	  obj.r{obj.ch}.thresh = obj.thresh;
	  obj.r{obj.ch}.nclust = obj.nclust;
	  obj.r{obj.ch}.pca = obj.pca;
	  obj.r{obj.ch}.use_csc = obj.use_csc;
	  obj.rwqual('save');
	  obj.rwsnips('save');
	  obj.showr(obj.ch:obj.ch);
	case 'period'
          obj.buf = [obj.buf '.'];
	otherwise
          if length(key) == 1
            if key(1) >= '0' || key(1) <= '9'
              obj.buf = [obj.buf key];
            else
              obj.buf = '';
            end
            obj.msg()
          end
      end
      obj.busy = 0;
    end

    function showr(obj, ix)
      if nargin == 1
	ix = 1:length(obj.r);
      end
      
      for n = ix
	fprintf('%2d: %3.1f %2.0f %2.0f %2.0f %s\n', ...
		n, obj.r{n}.thresh, obj.r{n}.nclust, ...
		obj.r{n}.pca,  obj.r{n}.use_csc, ...
		obj.r{n}.q);
      end
    end
  end
  
end %classdef

