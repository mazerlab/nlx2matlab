function [lfp, spk, wideband] = filter_wideband(ts, v, want, newfilts)
%
% Filter a wide band signal into lfp and spike bands.
%
% First 60hz notch filter is applied, then split into lfp and spikes
%
% ts should be in seconds
% v should be in volts
%
% returns two row vectors -- first row is TIME, second is VOLTAGE
%
% [2021-02-25]  this is ripped out of `tdtgetraw.m`
%
% [2021-02-27] slow!!
%   - filter is much faster than filtfilt, but introduces a signficant (12ms) lag..
%   - the lag with filter is basically N/2/fs, which is 12.8ms at 32000 for the hp filter
%   - is it save to just shift??
%
%
% [2021-03-21] added unit test -- called with no args will generate new filters
%   - and run through noise of delta function to test.

if nargin == 0
  figure; filter_wideband_test('delta');
  figure; filter_wideband_test('noise');
  return
end
    
persistent first_time n60 lp hp

% If `use_filter`, then just use the faster filter() function and shift the
% output back in time by the group delay to compensate for phase shifts.
% This is much faster than filtfilt() and I think basically ok for real
% signals and the simple filters used here:
use_filter = 1;

% if set, force filters to be recomputed
if exist('newfilts', 'var') && newfilts
  force_make_filts = 1;
  n60 = [];
  lp = [];
  hp = [];
else
  force_make_filts = 0;
end

notchfreq = 60;
lfpcut = 200;
spikecut = 6000;

% [2021-03-01] this is closer to SX box default settings
lfpcut = 300;
spikecut = 8000;

if ~exist('want', 'var')
  % l = lfp stream (lowpass)
  % s = spike stream (bandpass)
  % w = wideband (notch filtered only)
  want = 'sl';
end

fs = 1.0 / (ts(2)-ts(1));

if isempty(n60)
  cfile = sprintf('%s/.pyperc/.notch-%d-%.0f.mat', ...
                  getenv('HOME'), notchfreq, fs);
  if ~force_make_filts && exist(cfile, 'file')
    load(cfile, '-mat');
    if isempty(first_time)
      fprintf('[restored notch filter (fs=%.0f)]\n', fs);
    end
  else
    fprintf('[making notch filter (fs=%.0f)', fs);
    % Npoles NotchFreq Qual
    n60 = design(fdesign.notch(4, notchfreq, 5, fs));
    fprintf(']\n');
    save(cfile, 'n60');
  end    
end

if isempty(lp) && any(want=='l')
  cfile = sprintf('%s/.pyperc/.lfpcut-%d-%.0f.mat', ...
                  getenv('HOME'), lfpcut, fs);
  if ~force_make_filts && exist(cfile, 'file')
    load(cfile, '-mat');
    if isempty(first_time)
      fprintf('[restored lfpcut filter (fs=%.0f)]\n', fs);
    end
  else
    fprintf('[making lfp filter (fs=%.0f)', fs);
    % Fpass Fstop Apass Astop
    lp = design(fdesign.lowpass(lfpcut, 2*lfpcut, 0.1, 25, fs));
    fprintf(']\n');
    save(cfile, 'lp');
  end
end

if isempty(hp) && any(want=='s')
  cfile = sprintf('%s/.pyperc/.hpcut-%d-%d-%.0f.mat', ...
                  getenv('HOME'), lfpcut, spikecut, fs);
  if ~force_make_filts && exist(cfile, 'file')
    load(cfile, '-mat');
    if isempty(first_time)
      fprintf('[restored spike filter (fs=%.0f)]\n', fs);
    end
  else
    fprintf('[making spike filter (fs=%.0f)', fs);
    % default for design is an equiripple filter, which takes
    % ~20s just to compute. Kaiser looks ok -- longer filter,
    % and more group delay, but we're going to filter with
    % filtfilt, which should eliminate the (flat) group
    % delay...
    %
    % Fstop1 Fpass1 Fpass2 Fstop2 Astop1 Apass1 Astop2:
    hp = design(fdesign.bandpass(lfpcut/2, lfpcut, ...
                                 spikecut, 2*spikecut, ...
                                 200, 0.1, 200, fs), 'kaiserwin');
    fprintf(']\n');
    save(cfile, 'hp');
  end
end
first_time = 'no';

d = [ts; v];

d(2,:) = filter(n60, d(2,:));

spk = [];
lfp = [];
wideband = [];

if any(want == 'w')
  % wideband is notch filtered only.
  wideband = d;
end

if any(want == 's')
  if ~use_filter
    % filtfilt requires doubles
    spk = [d(1,:); filtfilt(hp.Numerator, 1, double(d(2,:)))];
  else
    % filter does not..
    lag = round(length(hp.Numerator) / 2);
    x = filter(hp.Numerator, 1, d(2,:));
    x = [x(1,lag:end) zeros([1 lag-1])];
    spk = [d(1,:); x];
  end
end

if any(want == 'l')
  % low pass filter and then decimate -- warning, this
  % make mean the time values end short..
  if ~use_filter
    % filtfilt requires doubles
    d(2,:) = filtfilt(lp.Numerator, 1, double(d(2,:)));
  else
    % filter does not..
    lag = round(length(lp.Numerator) / 2);
    x = filter(lp.Numerator, 1, d(2,:));
    x = [x(1,lag:end) zeros([1 lag-1])];
    d(2,:) = x;
  end
  if 1
    while (fs / 2) > (10*lfpcut)
      d = d(:, 1:2:end);
      fs = fs / 2;
    end
  end
  lfp = d;
end


function filter_wideband_test(s)

v = unifrnd(-1, 1, [1 100000]);
if strcmp(s, 'delta')
  v = v .* 0;
  v(length(v)/2) = 1;
end
ts = (1:length(v))/32000;
[lfp, spk, wideband] = filter_wideband(ts, v, 'lsw', 1);

subplot(4,1,1);
fs = 1/(wideband(1,2)-wideband(1,1));
periodogram(wideband(2,:), [], [], fs, 'power');
title('wideband');


subplot(4,1,2);
fs = 1/(spk(1,2)-spk(1,1));
periodogram(spk(2,:), [], [], fs, 'power');
title('spk');

subplot(4,1,3);
fs = 1/(lfp(1,2)-lfp(1,1));
periodogram(lfp(2,:), [], [], fs, 'power');
title('lfp');


subplot(4,1,4);
v = v .* 0; v(length(v)/2) = 1;
[lfp, spk, wideband] = filter_wideband(ts, v, 'lsw');
ix = 1:length(v);
ts = ts - mean(ts);
plot(ts(ix), v(ix), 'k-', ts(ix), spk(2,ix), 'r.-');
rms(v-spk(2,:))
xrange(-3e-3, 3e-3);



