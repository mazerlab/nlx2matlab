function snips = nlx_getRawSE(filename, range)
%function snips = nlx_getRawSE(filename, range)
%
%INPUT
%  filename - .nse file
%  range - optional vector [start, stop] times in usec
%
%OUTPUT
%
% snips - struct --
%       header: neuralynx header strings (useful parmaters here)
%           ts: timestamps for each snip in usec
%    scnumbers: recording channel?? (0-based??)
%  cellnumbers: putative cell numbers
%       params: (I think) these are the snip features extracted on-line 
%           fs: sampling rate in Hz
%            v: snip votlages in uvolts
%            t: snip time base (only 1) in usecs
%
%originally from: urut/april04

if ~exist(filename, 'file')
  snips = [];
  return
end

if ~exist('range', 'var')
  range = [];
end

FieldSelection(1) = 1;                  % timestamps   
FieldSelection(2) = 1;                  % sc numbers
FieldSelection(3) = 1;                  % cell Numbers
FieldSelection(4) = 1;                  % params ??
FieldSelection(5) = 1;                  % Data Points
ExtractHeader = 1;                      % extract header info
if isempty(range)
  ExtractMode = 1;                      % extract whole file
  ModeArray = [];                       % ignored for whole file
else
  ExtractMode = 4;                      % extract between specified timestamps
  ModeArray = range;
end

try
  [TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, header] = ...
      Nlx2MatSpike_v3(filename, FieldSelection, ExtractHeader, ...
                      ExtractMode, ModeArray);
catch
  % probably empty datafile
  snips = [];
  return
end

snips.type = 'snips';
snips.header = header;
snips.ts = TimeStamps;
snips.scnumbers = ScNumbers;
snips.cellnumbers = CellNumbers;
snips.params = Params;
snips.fs = nlx_pfind(snips.header, '-SamplingFrequency', 1);
snips.orig_thresh = nlx_pfind(snips.header, '-ThreshVal', 1);
snips.thresh = snips.orig_thresh;
snips.v = squeeze(DataPoints);
snips.v = 1e6 * snips.v * nlx_pfind(snips.header, '-ADBitVolts', 1);
offset = nlx_pfind(snips.header, '-AlignmentPt', 1);
snips.t = (1e6 .* ((1:size(snips.v,1)) - offset) ./ snips.fs)';
snips.src = filename;
snips.features = 'sx';
snips.cliprisk = 0;


% find any snips that exceed clipping threshold (95% of input range)
r = nlx_pfind(snips.header, '-InputRange', 1);
ix = find(any(abs(snips.v) > (0.95*r)));
fclip = length(ix)/size(snips.v,2);
if fclip > 0.05
  e = strsplit(nlx_pfind(snips.header, '-AcqEntName'));
  fprintf('%s: %.0f%% snips at clip risk\n', e{2}, 100*fclip);
  snips.cliprisk = 1;
end

