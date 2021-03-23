function nlxscanner(exper, curonly)
%function nlxscanner(exper, curonly)
%
% quickly scan through experiments (one or all) to check for
% missing snip data.
%
%INPUT
% exper - experiment as string or empty ('') for all
% curonly - look for curated snips only? default is everything
%
%OUTPUT
% none

if ~exist('curonly')
  curonly = 0;
end

if exist('exper', 'var') && ~isempty(exper)
  expers = {exper};
  x = dbfind(sprintf('%s.%.000', exper), 'list');
  dirs = {dirname(x{1})};
else
  % find list of all bert expers starting with bert1421
  fl = dbfind('bert%.%.000', 'list');
  x = cellfun(@(x) strsplit(basename(x), '.'), fl, 'uniformoutput', 0);
  expers = {};
  dirs = {};
  for n=1:length(x)
    k = str2num(x{n}{1}(end-3:end));
    if k >= 1421 & k < 1999
      expers{length(expers)+1} = x{n}{1};
      dirs{length(dirs)+1} = dirname(fl{n});
    end
  end
end


fprintf('%s ', '        ');
for ch = 1:64
  if ch >= 10
    if curonly
      fprintf('%d|', floor(ch/10));
    else;
      fprintf('%d%d|', floor(ch/10), floor(ch/10))
    end
  else
    if curonly
      fprintf(' |');
    else
      fprintf('  |');
    end
  end
end
fprintf('\n');

fprintf('%s ', '        ');
for ch = 1:64
  if curonly
    fprintf('%d|', rem(ch, 10));
  else
    fprintf('%d%d|', rem(ch, 10), rem(ch, 10));
  end
end
fprintf('\n');

fprintf('%s ', '        ');
for ch = 1:64
  if curonly
    fprintf('-+');
  else
    fprintf('--+');
  end
end
fprintf('\n');

%
% a note about cellnumbers -- SE files the snips are cellnumber==0,
% once ksnip has been applied -- the clusters are cellnumer==1,2...
%

for n = 10:length(expers)
  fprintf('%s ', expers{n});
  for ch = 1:64
    sefile = sprintf('%s/sefiles/se%d.mat', dirs{n}, ch);
    sefiles(n,ch,1) = exist(sefile, 'file');
    if sefiles(n,ch,1)
      s = rwsnips('read', [], sefile);
      sefiles(n,ch,2) = length(unique(s.cellnumbers));
      fprintf('%d', sefiles(n,ch,2));
    else
      sefiles(n,ch,2) = -1;
      fprintf('x');
    end
    if ~curonly
      sefiles(n,ch,3) = exist(sprintf('%s/sefiles/csc-se%d.mat', dirs{n}, ch), 'file');
      if sefiles(n,ch,3)
        fprintf('1');
      else
        fprintf('x');
      end
    end
    fprintf('|');
  end
  fprintf('\n');
end
fprintf('\nx: missing\nN: # sortcodes\n');
if curonly
  fprintf('curated snips only (se.mat)\n');
else
  fprintf('col 1: curated snips; col 2: csc-se\n');
end
