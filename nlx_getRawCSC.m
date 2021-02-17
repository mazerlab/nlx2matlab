function csc = nlx_getRawCSC(filename, p)
%
%reads the raw data from a neuralynx CSC file.
%
%
%from: urut/april04
%

if ~exist(filename, 'file')
  csc = [];
  return
end

if ~exist('p', 'var')
  p = 0;
end

if nargin < 2
  % this seems to work to retrieve entire file
  fromInd = 0;
  toInd = +inf;
end

FieldSelection(1) = 1;                  % get timestamps (1 per block)
FieldSelection(2) = 0;                  % channel numbers
FieldSelection(3) = 1;                  % get sample freq (1 per block)
FieldSelection(4) = 0;                  % number of valid samples
FieldSelection(5) = 1;                  % actual samples (in blocks of 512)
ExtractHeader = 1;                      % header info
ExtractMode = 1;                        % extract whole file
ModeArray = [];                         % ignored for whole file

[timestamps, samplefreqs, samples, header] = ...
    Nlx2MatCSC_v3(filename, FieldSelection,...
                  ExtractHeader, ExtractMode, ModeArray);


csc.header = header;                    % text header info
csc.nblocks = size(timestamps,2);       % number of 512-sample blocks
csc.nsamples = csc.nblocks*512;         % number of actual samples
csc.fs = samplefreqs(1);                % inital sampling freq (assumes fixed)
csc.src = filename;

% not sure this is really correct:
csc.xx_isContinous = length(unique(diff(timestamps))) == 1;

% generate continue vector of timestamps in **MICROSECONDS**
csc.ts = zeros([1 length(timestamps)*512]);
ix = 1;
for n = 1:length(timestamps)
  for k = (1:512)-1
    t = timestamps(n) + (k / csc.fs * 1e6);
    csc.ts(ix) = t;
    ix = ix + 1;
  end
end

% samples should be in **microvolts**
csc.v = samples(:)';                    % flatten blocks into continuous sig

assert(length(csc.ts) == length(csc.v), ...
       'timestamp vector not same length as sample vector');

fprintf('; %s: %.1fs data\n', csc.src, (csc.ts(end)-csc.ts(1))/1e6);

if p
  plot(csc.ts, csc.v);
  axis tight
  xlabel('usec');
  ylabel('uvolts');
end
