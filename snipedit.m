classdef snipedit < handle

  properties
    exper
    pf
    ch
    fig1
    fig2
    fig3
    nd
    nclust
    buf
    pca
    thresh
    use_csc
  end

  methods
    function obj = snipedit(exper)
      l = dbfind(exper, 'list');
      obj.pf = p2mLoad2(l{1});
      if obj.loadstate() == 0
        obj.ch = 1;
        obj.pca = 0;
        obj.thresh = 5;
        obj.use_csc = 0;
      end
      obj.exper = exper;
      obj.fig1 = figure(1); clf;
      obj.fig2 = figure(2); clf;
      obj.fig3 = figure(3); clf;

      set(obj.fig1, 'Units', 'normalized', ...
                    'Position', [0, 1, 0.4, 0.3], ...
                    'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.fig2, 'Units', 'normalized', ...
                    'Position', [0, .3, 0.7, 0.3], ...
                    'Toolbar' ,'none', 'Menubar', 'none');
      
      set(obj.fig3, 'Units', 'normalized', ...
                    'Position', [0.41, 1, 0.25, 0.3], ...
                    'Toolbar' ,'none', 'Menubar', 'none');
      
      
      
      while obj.loadchan() ~= 1
        obj.ch = obj.ch + 1;
      end
      obj.nclust = 2;
      obj.buf = '';
      obj.draw();
      set(obj.fig1, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig2, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig3, 'KeyPressFcn', @obj.dispatch);
    end
  
    function r = loadchan(obj)
      if obj.use_csc
        nd = p2mLoadNLX(obj.pf, 'h', obj.ch);
        nd.snips = csc_findsnips(nd.csc, 6, 1);
        nd.csc = [];
      else
        nd = p2mLoadNLX(obj.pf, 's', obj.ch);
        if obj.thresh > 0
          ix = find(any(nd.snips.v > obj.thresh));
          nd.snips.ts = nd.snips.ts(ix);
          nd.snips.scnumbers = nd.snips.scnumbers(ix);
          nd.snips.cellnumbers = nd.snips.cellnumbers(ix);
          nd.snips.params = nd.snips.params(:,ix);
          nd.snips.v = nd.snips.v(:,ix);
        end
      end
      if isempty(nd.snips)
        r = 0;
      else
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
    end
    
    function draw(obj)
     set(0, 'CurrentFigure', obj.fig1);
     nlx_show(obj.nd.snips);
     set(0, 'CurrentFigure', obj.fig2);
     ksnip(obj.nd.snips, obj.nclust);
     info(obj);
    end
    
    function info(obj)
      set(0, 'CurrentFigure', obj.fig3);
      s = sprintf([...
               '    f: toggle sx/pca features\n' ...
               '  n/p: next/prev chan\n' ...
               '    r: refresh\n' ...
               'ARG g: jump to channel\n' ...
               'ARG k: set # clusters\n' ...
               '  +/-: one more/less cluster\n' ...
               'ARG t: set spike threshold\n' ...
               '    q: quit/close\n' ...
               '  0-9: add to numeric arg\n']);
      s = [s sprintf('\n')];
      s = [s sprintf('     ch = %d\n', obj.ch)];
      s = [s sprintf('    pca = %d\n', obj.pca)];
      s = [s sprintf(' nclust = %d\n', obj.nclust)];
      s = [s sprintf(' thresh = %.1f\n', obj.thresh)];
      s = [s sprintf('use\\_csc = %d\n', obj.use_csc)];
      s = [s sprintf('\n\nARG: \\bf{%s}\n', obj.buf)];
      cla; textbox(s, 0);
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
      set(obj.fig1, 'KeyPressFcn', []);
      set(obj.fig2, 'KeyPressFcn', []);
      set(obj.fig3, 'KeyPressFcn', []);
      set(obj.fig1, 'Pointer', 'watch');
      set(obj.fig2, 'Pointer', 'watch');
      set(obj.fig3, 'Pointer', 'watch');
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
          %obj.use_csc = ~obj.use_csc;
          obj.info()
        case 't'
          t = obj.thresh;
          obj.thresh = str2num(obj.buf);
          if isempty(obj.thresh)
            obj.thresh = 0;
          end
          obj.buf = '';
          obj.info()
          if t ~= obj.thresh
            obj.loadchan();
            obj.draw();
          end
        case 'g'
          obj.ch = min(64, max(1, str2num(obj.buf)));
          obj.buf = '';
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
          obj.nclust = max(2, str2num(obj.buf));
          obj.buf = '';
          obj.draw();
        case 'equal'
          obj.nclust = obj.nclust+1;
          obj.draw();
        case 'hyphen'
          n = max(2,obj.nclust-1);
          if n ~= obj.nclust
            obj.nclust = n;
            obj.draw();
          end
        case 'q'
          obj.savestate();
          close(obj.fig1);
          close(obj.fig2);
          close(obj.fig3);
        case 's'
          obj.savestate();
        case 'l'
          obj.loadstate();
        case 'escape'
          obj.buf = '';
          obj.info()
        case 'period'
          obj.buf = [obj.buf '.'];
        otherwise
          if length(event.Key) == 1
            if event.Key(1) >= '0' || event.Key(1) <= '9'
              obj.buf = [obj.buf event.Key];
            else
              obj.buf = '';
            end
            obj.info()
          end
      end
      try
        set(obj.fig1, 'Pointer', 'arrow');
        set(obj.fig2, 'Pointer', 'arrow');
        set(obj.fig3, 'Pointer', 'arrow');
        set(obj.fig1, 'KeyPressFcn', @obj.dispatch);
        set(obj.fig2, 'KeyPressFcn', @obj.dispatch);
        set(obj.fig3, 'KeyPressFcn', @obj.dispatch);
      end
    end
  end
end
  

