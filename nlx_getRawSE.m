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

[TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, header] = ...
    Nlx2MatSpike_v3(filename, FieldSelection, ExtractHeader, ...
                    ExtractMode, ModeArray);

snips.type = 'snips';
snips.header = header;
snips.ts = TimeStamps;
snips.scnumbers = ScNumbers;
snips.cellnumbers = CellNumbers;
snips.params = Params;
snips.fs = nlx_pfind(snips.header, '-SamplingFrequency', 1);
snips.v = squeeze(DataPoints);
snips.v = 1e6 * snips.v * nlx_pfind(snips.header, '-ADBitVolts', 1);
snips.t = (1e6 .* ((1:size(snips.v,1)) - 1) / snips.fs)';

