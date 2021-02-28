function csc = nlx_getRawCSC(filename, range)
%
%reads the raw data from a neuralynx CSC file.
%
%INPUT
%  filename - .nsc file
%  range - optional vector [start, stop] times in usec
%
%OUTPUT
%
% csc - struct --
%    header: neuralynx header strings (useful parmaters here)
%   nblocks: number of 512 sample bloxk
%  nsamples: number of samples
%        fs: sampling rate in hz
%       src: original datafile name
%        ts: time points (usec)
%         v: voltages (uvolts)
%
%originally from: urut/april04

if ~exist(filename, 'file')
  csc = [];
  return
end

if ~exist('range', 'var')
  range = [];
end

FieldSelection(1) = 1;                  % get timestamps (1 per block)
FieldSelection(2) = 0;                  % channel numbers
FieldSelection(3) = 1;                  % get sample freq (1 per block)
FieldSelection(4) = 0;                  % number of valid samples
FieldSelection(5) = 1;                  % actual samples (in blocks of 512)
ExtractHeader = 1;                      % header info
if isempty(range)
  ExtractMode = 1;                      % extract whole file
  ModeArray = [];                       % ignored for whole file
else
  ExtractMode = 4;                      % extract between specified timestamps
  ModeArray = range;
end

try
  [timestamps, samplefreqs, samples, header] = ...
      Nlx2MatCSC_v3(filename, FieldSelection,...
                    ExtractHeader, ExtractMode, ModeArray);
catch
  csc = [];
  return
end


csc.type = 'csc';

csc.header = header;                    % text header info
csc.nblocks = size(timestamps,2);       % number of 512-sample blocks
csc.nsamples = csc.nblocks*512;         % number of actual samples
csc.fs = samplefreqs(1);                % inital sampling freq (assumes fixed)
csc.src = filename;

% not sure this is really correct:
csc.xx_isContinous = length(unique(diff(timestamps))) == 1;

% generate continue vector of timestamps in **MICROSECONDS**
if 1
  % fast
  t = (0:511) / csc.fs * 1e6;
  %t = 0:9;
  %timestamps = [0 100 110];
  x = repmat(t, [size(timestamps,2) 1]);
  y = repmat(timestamps, [size(t,2) 1])';
  xy=x+y; xy = xy';
  csc.ts = xy(:)';
else
  % slow version
  csc.ts = zeros([1 length(timestamps)*512]);
  ix = 1;
  for n = 1:length(timestamps)
    for k = (1:512)-1
      t = timestamps(n) + (k / csc.fs * 1e6);
      csc.ts(ix) = t;
      ix = ix + 1;
    end
  end
end

% flatten 512samp nks into continuous sig
csc.v = samples(:)';
% convert ADC units to actual MICROVOLTS
csc.v = 1e6 .* csc.v .* nlx_pfind(csc.header, '-ADBitVolts', 1);


assert(length(csc.ts) == length(csc.v), ...
       'timestamp vector not same length as sample vector');

fprintf('; %s: %.1fs data\n', csc.src, (csc.ts(end)-csc.ts(1))/1e6);

