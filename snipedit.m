classdef snipedit < handle

  properties
    exper
    pf
    ch
    fig1
    fig2
    fig3
    nd
    cscdata
    cscn
    nclust
    buf
    pca
    thresh
    use_csc
    busy
  end

  methods
    function obj = snipedit(exper)
      l = dbfind(exper, 'list');
      obj.pf = p2mLoad2(l{1});
      obj.nd = [];
      obj.cscdata = [];
      obj.cscn = -1;
      if obj.loadstate() == 0
        obj.ch = 1;
        obj.pca = 0;
        obj.thresh = 5;
        obj.use_csc = 0;
      end
      obj.exper = exper;
      obj.fig1 = figure(100); clf;
      obj.fig2 = figure(101); clf;
      obj.fig3 = figure(102); clf;

      set(obj.fig1, 'Units', 'normalized', ...
                    'NumberTitle', 'off', ...
                    'Position', [0, 1, 0.4, 0.3], ...
                    'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.fig2, 'Units', 'normalized', ...
                    'NumberTitle', 'off', ...
                    'Position', [0, .3, 0.65, 0.3], ...
                    'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.fig3, 'Units', 'normalized', ...
                    'NumberTitle', 'off', ...
                    'Position', [0.41, 1, 0.25, 0.3], ...
                    'Toolbar' ,'none', 'Menubar', 'none');
      
      while obj.loadchan() ~= 1
        obj.ch = obj.ch + 1;
      end
      obj.nclust = 2;
      obj.buf = '';
      obj.draw();
      
      obj.busy = 1;
      set(obj.fig1, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig2, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig3, 'KeyPressFcn', @obj.dispatch);
      obj.busy = 0;
    end
  
    function r = loadchan(obj)
      obj.msg(sprintf('loading ch%d', obj.ch));
      if obj.use_csc
        if obj.cscn == obj.ch
          fprintf('already loaded csc\n');
        else
          obj.msg(sprintf('loading csc%d', obj.ch));
          obj.cscdata = p2mLoadNLX(obj.pf, 'h', obj.ch);
          obj.cscn = obj.ch;
        end
        if obj.thresh > 0
          obj.cscdata.snips = csc_findsnips(obj.cscdata.csc, obj.thresh, 0);
        else
          % 4 sigma to start
          obj.cscdata.snips = csc_findsnips(obj.cscdata.csc, 4, 1);
        end
        nd = obj.cscdata;
        nd.csc = [];
      else
        nd = p2mLoadNLX(obj.pf, 's', obj.ch);
        if ~isempty(nd.snips)
          % artifact rejection!
          ix = find(~any(abs(nd.snips.v) > 200));
          if length(ix) ~= size(nd.snips,2)
            fprintf('rejected %.03f%% artifacts\n', ...
                    100 * (1 - length(ix) / size(nd.snips.v,2)));
            nd.snips.ts = nd.snips.ts(ix);
            nd.snips.scnumbers = nd.snips.scnumbers(ix);
            nd.snips.cellnumbers = nd.snips.cellnumbers(ix);
            nd.snips.params = nd.snips.params(:,ix);
            nd.snips.v = nd.snips.v(:,ix);
          end
          if obj.thresh > 0
            ix = find(any(nd.snips.v > obj.thresh));
            ix = find(nd.snips.v(8,:) > obj.thresh);
            nd.snips.ts = nd.snips.ts(ix);
            nd.snips.scnumbers = nd.snips.scnumbers(ix);
            nd.snips.cellnumbers = nd.snips.cellnumbers(ix);
            nd.snips.params = nd.snips.params(:,ix);
            nd.snips.v = nd.snips.v(:,ix);
            nd.snips.thresh = obj.thresh;
          end
        end
        obj.nd.snips = nd.snips;
      end
      if isempty(nd.snips)
        r = 0;
      else
        nd.snips.q = {};
        obj.nd = nd;
        % no params because loaded from csc
        if ~isfield(obj.nd.snips, 'params') || isempty(obj.nd.snips.params)
          obj.pca = 1;
        end
        if (obj.pca && ~isempty(obj.nd.snips)) || ...
              ~isfield(obj.nd.snips, 'params')
          obj.nd.snips = pcasnip(obj.nd.snips);
        end
        r = 1;
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
            '     r: refresh\n' ...
            '+/-/Nk: set # clusters\n' ...
            '    Nt: set threshold (or up/down arrows)\n' ...
            ' Nsmxz: mark kluster SU, MU, garbage, check\n' ...
            '     q: quit/close\n' ...
            ' [0-9]: add to numeric arg (N)\n']);
        s = [s sprintf('\n')];
        s = [s sprintf('  exper = %s\n', obj.exper)];
        s = [s sprintf('     ch = %d\n', obj.ch)];
        s = [s sprintf('    pca = %d\n', obj.pca)];
        s = [s sprintf(' nclust = %d\n', obj.nclust)];
        if obj.thresh > 0
          s = [s sprintf(' thresh = %.1f\n', obj.thresh)];
        else
          s = [s sprintf(' thresh = none\n')];
        end
        s = [s sprintf('use\\_csc = %d\n', obj.use_csc)];
        s = [s sprintf('\nARG: \\bf{%s}\n', obj.buf)];
        cla; textbox(s, 0);
      end
      savestate(obj);
    end
    
    function savestate(obj)
      s = jsonencode(struct('exper', obj.exper, ...
                            'ch', obj.ch, ...
                            'pca', obj.pca, ...
                            'use_csc', obj.use_csc, ...
                            'thresh', obj.thresh, ...
                            'nclust', obj.nclust));
      f = fopen('~/.snipeditrc', 'w');
      fwrite(f, s);
      fclose(f);
    end

    function r = arg(obj)
      r = str2num(obj.buf);
      if isempty(r), r = 1; end
      obj.buf = '';
      obj.msg();
    end

    function r = loadstate(obj)
      r = 0;
      try
        f = fopen('~/.snipeditrc', 'r');
        if f > 0
          s = jsondecode(char(fread(f, 'char')'));
          fclose(f);
          obj.ch = s.ch;
          obj.exper = s.exper;
          obj.pca = s.pca;
          obj.nclust = s.nclust;
          obj.thresh = s.thresh;
          obj.use_csc = s.use_csc;
          r = 1;
        end
      end
    end


    function dispatch(obj, src, event)
      if obj.busy
        return
      end
      obj.busy = 1;

      %debug:
      %event.Key
      switch event.Key
        case 'f'
          obj.pca = ~obj.pca;
          obj.loadchan();
          obj.draw();
        case {'space', 'n'}
          while 1
            obj.ch = obj.ch + 1;
            if obj.ch > 64, obj.ch = 1; end
            if obj.loadchan()
              break;
            end
            fprintf('no snips on ch %d\n', obj.ch);
          end
          obj.draw();
        case 'p'
          while 1
            obj.ch = obj.ch - 1;
            if obj.ch < 1, obj.ch = 64; end
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
          % not yet: very, very slow
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
          obj.ch = min(64, obj.arg);
          while 1
            if obj.loadchan()
              break;
            end
            fprintf('no snips on ch %d\n', obj.ch);
            obj.ch = obj.ch + 1;
            if obj.ch > 64, obj.ch = 1; end
          end
          obj.draw();
        case 'k'
          obj.nclust = max(1, obj.arg());
          obj.msg('clustering');
          obj.draw();
        case 'equal'
          obj.nclust = obj.nclust+1;
          obj.draw();
        case 'hyphen'
          n = max(1, obj.nclust-1);
          if n ~= obj.nclust
            obj.nclust = n;
            obj.draw();
          end
        case 'q'
          obj.savestate();
          close(obj.fig1);
          close(obj.fig2);
          close(obj.fig3);
        case 'escape'
          obj.arg();
          obj.msg();
        case 's'
          obj.nd.snips.q{max(1,obj.arg())} = 'su';
          obj.draw()
        case 'm'
          obj.nd.snips.q{max(1,obj.arg())} = 'mu';
          obj.draw()
        case 'x'
          obj.nd.snips.q{max(1,obj.arg())} = 'garbage';
          obj.draw()
        case 'z'
          obj.nd.snips.q{max(1,obj.arg())} = 'check';
          obj.draw()
        case 'period'
          obj.buf = [obj.buf '.'];
        otherwise
          if length(event.Key) == 1
            if event.Key(1) >= '0' || event.Key(1) <= '9'
              obj.buf = [obj.buf event.Key];
            else
              obj.buf = '';
            end
            obj.msg()
          end
      end
      obj.busy = 0;
    end
  end
end
  

