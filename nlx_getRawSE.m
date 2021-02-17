function snips = nlx_getRawSE(filename, p)

if ~exist(filename, 'file')
  snips = [];
  return
end

if ~exist('p', 'var')
  p = 0;
end

FieldSelection(1) = 1;                  % timestamps   
FieldSelection(2) = 1;                  % sc numbers
FieldSelection(3) = 1;                  % cell Numbers
FieldSelection(4) = 1;                  % params ??
FieldSelection(5) = 1;                  % Data Points
ExtractHeader = 1;                      % extract header info
ExtractMode = 1;                        % extract entire file
ModeArray=[];                           % entire file doesn't need range

[TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, header] = ...
    Nlx2MatSpike_v3(filename, FieldSelection, ExtractHeader, ...
                    ExtractMode, ModeArray);

snips.header = header;
snips.timestamps = TimeStamps;
snips.v = squeeze(DataPoints);
snips.scnumbers = ScNumbers;
snips.cellnumbers = CellNumbers;
snips.params = Params;
snips.fs = str2num(findp(snips.header, '-SamplingFrequency'));
snips.t = (1e6 .* ((1:size(snips.v,1)) - 1) / snips.fs)';

if p
  subplot(2,1,1);
  % plot 1000 random snips
  r = randperm(size(snips.v,2));
  plot(snips.t, snips.v(:, r(1:1000)));
  ylabel('uvolts');
  xlabel('usec');
  
  subplot(2,1,2);
  plot(snips.t, mean(snips.v, 2));
  eshade(snips.t, mean(snips.v, 2), std(snips.v, [], 2));
  ylabel('uvolts');
  xlabel('usec');
end

function v = findp(h, p)
% pull parameter from header data
v = find(strncmp(p, h, length(p)));
if ~isempty(v)
  v = h{v};
  v = strsplit(v);
  v = strjoin(v(2:end));
end

