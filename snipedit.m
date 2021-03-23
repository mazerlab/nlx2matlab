classdef snipedit < handle

  properties
    exper
    pf
    ch
    figs, menubar, snipplot, msgwin, ksnipplot
    nd
    nclust
    buf
    pca
    thresh
    use_csc
    busy
    r
    src
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
      
      obj.rwqual('read');
      
      if exist('ch', 'var')
	obj.ch = ch;
      end

      n = 100;
      obj.menubar = figure(n); clf; n = n + 1;
      obj.snipplot = figure(n); clf; n = n + 1;
      obj.ksnipplot = figure(n); clf; n = n + 1;
      obj.msgwin= figure(n); clf; n = n + 1;
      obj.figs = {obj.menubar obj.snipplot obj.ksnipplot obj.msgwin};
      
      set(obj.menubar, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Toolbar' ,'none', 'Menubar', 'none');
      set(obj.snipplot, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Toolbar' ,'none', 'Menubar', 'none');
      set(obj.msgwin, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Toolbar' ,'none', 'Menubar', 'none');
      set(obj.ksnipplot, 'Units', 'normalized', ...
          'NumberTitle', 'off', ...
          'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.menubar, 'Position', [0 .89 0.38 0.03]);  % menubar
      set(obj.snipplot, 'Position', [0 .46 .22 0.4]);    % snip plot
      set(obj.msgwin, 'Position', [0.22 .46 .16 0.4]); % messages
      set(obj.ksnipplot, 'Position', [0 .04 0.38 0.4]);  % kmeans
      
      buts = [];
      labels = { {'good >', 'comma'}, ...
		 {'good', 'w'}, ...
		 {'<', 'p'}, {'>', 'n'}, ...
		 {'su', 's'}, {'mu', 'm'}, {'junk', 'j'}, {'unsorted', 'u'}, ...
		 {'k++', 'equal'}, {'k--', 'hyphen'}, ...
		 {'pca', 'f'}, {'quit', 'q'}, {'reset', 'r'} };

      for n = 1:length(labels)
	buts(n) = uicontrol(obj.menubar, 'Style', 'pushbutton', ...
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

      obj.gochan(obj.ch, 1);
      
      obj.busy = 1;
      for n = 1:length(obj.figs)
	set(obj.figs{n}, 'KeyPressFcn', @obj.dispatch);
      end
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
      
    
    function r = loadchan(obj, forceraw)
      if ~exist('forceraw', 'var')
	forceraw = 0;
      end
      obj.msg(sprintf('loading ch%d', obj.ch));

      nd = [];

      s = obj.rwsnips('read');
      if (isempty(s) || forceraw) && obj.use_csc
	%% try to use csc-se.mat files
	s = findrawsnips(obj);
	if ~isempty(s)
          nd = p2mLoadNLX(obj.pf, 'e', obj.ch);
	  nd.snips = s;
	  obj.nclust = 1;
	  nd.snips.q = 'u';
	else
	  %% csc-se doesn't exist -- use se
	  obj.use_csc = 0;
	  waitfor(warndlg(sprintf('%s:%d no csc2snip; using SE data', ...
				  obj.exper, obj.ch), 'Warning'));
	end
      end
	  
      if (isempty(s) || forceraw) && ~obj.use_csc
	%% try to use se.mat files
        nd = p2mLoadNLX(obj.pf, 's', obj.ch);
	if ~isempty(nd.snips)
	  obj.nclust = 1;
	  nd.snips.q = 'u';
	end
      end
      
      if isempty(nd)
	%% not raw -- use snipedit se.mat save files
        nd = p2mLoadNLX(obj.pf, 's', obj.ch);
	nd.snips = s;
      end
      
      if isempty(nd.snips)
	%% no data file
	r = 0;
	return;
      end
      
      
      %% artifact rejection - anything >+-200uv is artifact
      nd.snips = subsnips(nd.snips, find(~any(abs(nd.snips.v) > 200)));

      %% this allows setting threshold, but will adjust to make
      %% sure some spikes are found (enough for pca)
      t0  = find(nd.snips.t == 0);
      while obj.thresh > 0
	%% bad - any volt over thresh:
	%% ix = find(any(nd.snips.v > obj.thresh));
	%% better - only consider voltage at time 0
	ix = find(nd.snips.v(t0,:) > obj.thresh);
	if length(ix) > 10
	  nd.snips = subsnips(nd.snips, ix);
	  nd.snips.thresh = obj.thresh;
	  break;
	end
	%% go down in steps of 10uv (limit is 0) - if get to zero, then
	%% there were probably no real snips to start with.
	obj.thresh = max(0, obj.thresh - 1);
      end
      
      if isempty(nd.snips) || size(nd.snips.v, 2) < 10
	% no (or almost no) snips in datafile (after thresh applied)
        r = 0;
      else
	r = 1;
	if isfield(nd.snips, 'q')
	  %% loaded data from se-mat file, already has some info, use it.
	  obj.nclust = length(nd.snips.q);
	else
	  %% fresh look
	  if obj.nclust == length(obj.r{obj.ch}.q)
	    %% no change in number of clusters, keep previous quality evals
	    nd.snips.q = obj.r{obj.ch}.q;
	  else
	    %% changed nclust, reset sort quality evals back 'u'
	    nd.snips.q = char('u'+0*(1:obj.nclust));
	  end
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
      set(0, 'CurrentFigure', obj.snipplot);
      nlx_show(obj.nd.snips);
      
      set(0, 'CurrentFigure', obj.ksnipplot);
      obj.nd.snips = ksnip(obj.nd.snips, obj.nclust);

      obj.msg();
    end
    
    function msg(obj, working)
      set(0, 'CurrentFigure', obj.msgwin);
      if nargin > 1 && ~isempty(working)
        cla; textbox(working, 0); drawnow;
      else
        s = sprintf([...
		      '     f: toggle sx/pca features\n' ...
		      '     r: reload snip data\n' ...
		      'n/p/Ng: next/prev/jump chan\n' ...
		      '+/-/Nk: set # clusters\n' ...
		      '    Nt: set threshold (or up/down arrows)\n' ...
		      ' Nsmju: mark SU, MU, junk, unsorted/check\n']);
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
    
    function snips = rwsnips(obj, dir)
      savefile = sprintf('%s/sefiles/se%d.mat', dirname(obj.pf.src), obj.ch);
      mkdirhier(dirname(savefile));
      if ~isempty(obj.nd)
	s = obj.nd.snips;
      else
	s = [];
      end
      snips = rwsnips(dir, s, savefile);
    end

    function snips = findrawsnips(obj)
      savefile = sprintf('%s/sefiles/csc-se%d.mat', dirname(obj.pf.src), obj.ch);
      snips = rwsnips('read', [], savefile);
      if ~isempty(snips)
	fprintf('; raw: found csc-se file\n');
      elseif isempty(snips)
	nd = p2mLoadNLX(obj.pf, 's', obj.ch);
	snips = nd.snips;
	if ~isempty(snips)
	  fprintf('; raw: found se file\n');
	end
      end
    end
    
    function rwqual(obj, dir)
      savefile = sprintf('%s/sefiles/%s.qual.mat', dirname(obj.pf.src), obj.exper);
      csvfile = sprintf('%s/sefiles/%s.qual.csv', dirname(obj.pf.src), obj.exper);
      mkdirhier(dirname(savefile));
      switch dir
	case {'write', 'save'}
	  xx = struct();
	  xx.r = obj.r;
	  xx.ch = obj.ch;
	  save(savefile, 'xx');
	  fprintf('; wrote to: %s\n', savefile);
	  fid = fopen(csvfile, 'w');
	  fprintf(fid, 'ch,thresh,nclust,pca,use_csc,q\n');
	  for n = 1:obj.NCHAN
	    fprintf(fid, '%d,%f,%d,%d,%d,"%s"\n', ...
		    n, obj.r{n}.thresh, obj.r{n}.nclust, ...
		    obj.r{n}.pca, obj.r{n}.use_csc, obj.r{n}.q);
	  end
	  fclose(fid);
	  fprintf('; wrote to: %s\n', csvfile);
	case {'read', 'load'}
	  try
	    xx = load(savefile, '-mat');
	    obj.r = xx.xx.r;
	    obj.ch = xx.xx.ch;	% restore to last channel
	  catch
	    %% file doesn't exist -- initialize r and save
	    fprintf('; missing %s (initializing)\n', savefile);
	    fid = fopen(csvfile, 'w');
	    for n = 1:obj.NCHAN
	      obj.r{n}.q = 'u';
	      obj.r{n}.thresh = 0;
	      obj.r{n}.nclust = 1;
	      obj.r{n}.pca = 1;
	      obj.r{n}.use_csc = 0;
	    end
	    obj.ch = 1;
	    obj.rwqual('write');
	  end
	otherwise
	  error('rwqual: unknown option -- %s', dir);
        end
    end

    function r = arg(obj)
      r = str2num(obj.buf);
      if isempty(r), r = 1; end
      obj.buf = '';
      obj.msg();
    end

    function gochan(obj, abs, rel)
      if isempty(abs)
	obj.ch = obj.ch + rel;
      else
	obj.ch = abs;
	rel = 1;
      end
      
      while 1
	obj.selectchan(obj.ch);
        if obj.loadchan()
	  break;
        end
        fprintf('no snips on ch %d\n', obj.ch);
	obj.ch = obj.ch + rel;
      end
      obj.draw();
    end

    function commit(obj)
      obj.r{obj.ch}.q = obj.nd.snips.q;
      obj.r{obj.ch}.thresh = obj.thresh;
      obj.r{obj.ch}.nclust = obj.nclust;
      obj.r{obj.ch}.pca = obj.pca;
      obj.r{obj.ch}.use_csc = obj.use_csc;
      obj.rwqual('write');
      obj.rwsnips('write');
    end

    function closeall(obj)
      for n = 1:length(obj.figs)
	close(obj.figs{n});
      end
    end
      

    function dispatch(obj, src, event, key)
      if obj.busy
	return
      end
      obj.busy = 1;

      if strcmp(event.EventName, 'KeyPress')
	if event.Character < 32
	  key = event.Key;
	else
	  key = event.Character;
	end
      end

      switch key
	case 'f'
          obj.pca = ~obj.pca;
          obj.loadchan();
          obj.draw();
	case {'p', 'leftarrow'}
	  obj.gochan([], -1);
	case 'g'
	  obj.gochan(obj.arg(), 1);
	case {' ', 'n', 'rightarrow'}
	  obj.gochan([], 1);
	case 'r'
          obj.loadchan(1);
          obj.draw();
	case 'C'
          obj.use_csc = ~obj.use_csc;
          obj.loadchan(1);
          obj.draw();
          obj.msg()
	case 'c'
          obj.use_csc = ~obj.use_csc;
          obj.loadchan(0);
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
          obj.thresh = obj.arg();
          obj.msg();
          obj.loadchan();
          obj.draw();
	case 'k'
          obj.nclust = max(1, obj.arg());
	  obj.nd.snips.q = char('u'+0*(1:obj.nclust));
          obj.msg('clustering');
          obj.draw();
	case {'add', 'equal'}
          obj.nclust = obj.nclust+1;
	  obj.nd.snips.q = char('u'+0*(1:obj.nclust));
          obj.msg('clustering');
          obj.draw();
	case {'subtract', 'hyphen'}
          n = max(1, obj.nclust-1);
          if n ~= obj.nclust
            obj.nclust = n;
	    obj.nd.snips.q = char('u'+0*(1:obj.nclust));
            obj.msg('clustering');
            obj.draw();
          end
	case 'q'
	  obj.commit();
	  obj.closeall();
	case 'Q'
	  obj.closeall();
	case 'escape'
          obj.arg();
          obj.msg();
	case 's'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 's';
	  obj.msg();
	case 'm'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 'm';
	  obj.msg();
	case 'j'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 'j';
	  obj.msg();
	case 'u'
	  obj.nd.snips.q(min(obj.nclust, max(1,obj.arg()))) = 'u';
	  obj.msg();
	case 'w'
	  obj.commit()
	case ','
	  obj.commit()
	  obj.gochan([], 1);
	case 'backspace'
	  if length(obj.buf) > 0
	    obj.buf = obj.buf(1:end-1);
	    obj.msg();
	  end
	case 'period'
          obj.buf = [obj.buf '.'];
	  obj.msg();
	otherwise
          if length(key) == 1
            if key >= '0' && key <= '9'
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

