classdef snipedit < handle

  properties
    pf
    ch
    fig1
    fig2
    nd
    nclust
    buf
    pca
  end

  methods
    function obj = snipedit(exper)
      l = dbfind(exper, 'list');
      obj.pf = p2mLoad2(l{1});
      obj.ch = 1;
      obj.pca = 0;
      obj.fig1 = figure(1); clf;
      obj.fig2 = figure(2); clf;
      
      p = get(obj.fig1, 'Position');
      p(3) = 800;
      set(obj.fig1, 'Position', p);
      
      p = get(obj.fig2, 'Position');
      p(3) = 800;
      set(obj.fig2, 'Position', p);
      
      
      while obj.loadchan() ~= 1
        obj.ch = obj.ch + 1;
      end
      obj.nclust = 2;
      obj.buf = '';
      obj.draw();
      set(obj.fig1, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig2, 'KeyPressFcn', @obj.dispatch);
    end
  
    function r = loadchan(obj)
      nd = p2mLoadNLX(obj.pf, 's', obj.ch);
      if isempty(nd.snips)
        r = 0;
      else
        obj.nd = nd;
        if obj.pca && ~isempty(obj.nd.snips)
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
    end
    
    function help(obj)
      fprintf(['    f: toggle sx/pca features\n' ...
               '  n/p: next/prev chan\n' ...
               '    r: refresh\n' ...
               'ARG g: jump to channel\n' ...
               'ARG k: set # clusters\n' ...
               '  +/-: one more/less cluster\n' ...
               '    q: quit/close\n' ...
               '  0-9: add to numeric arg\n']);
    end
    
    function dispatch(obj, src, event)
      set(obj.fig1, 'KeyPressFcn', []);
      set(obj.fig2, 'KeyPressFcn', []);
      set(obj.fig1, 'Pointer', 'watch');
      set(obj.fig2, 'Pointer', 'watch');
      %debug:
      %event.Key
      switch event.Key
        case 'f'
          obj.pca = ~obj.pca;
          obj.loadchan();
          obj.draw();
        case 'n'
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
          obj.draw();
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
        case 'slash'
          obj.help();
        case 'q'
          close(obj.fig1);
          close(obj.fig2);
        otherwise
          if event.Key(1) >= '0' || event.Key(1) <= '9'
            obj.buf = [obj.buf event.Key];
          else
            obj.buf = '';
          end
      end
      set(obj.fig1, 'Pointer', 'arrow');
      set(obj.fig2, 'Pointer', 'arrow');
      set(obj.fig1, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig2, 'KeyPressFcn', @obj.dispatch);
      set(obj.fig1, 'Name', obj.buf);
      set(obj.fig2, 'Name', obj.buf);
    end
  end
end
  

