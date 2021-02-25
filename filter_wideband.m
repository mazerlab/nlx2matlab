function [lfp, spk, wideband] = filter_wideband(ts, v, want)
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

persistent n60 lp hp

notchfreq = 60;
lfpcut = 200;
spikecut = 5000;

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
  if exist(cfile, 'file')
    load(cfile);
    fprintf('[restored notch filter (fs=%.0f)]\n', fs);
  else
    fprintf('[making notch filter (fs=%.0f)', fs);
    % Npoles NotchFreq Qual
    n60 = design(fdesign.notch(4, notchfreq, 10, fs));
    fprintf(']\n');
    save(cfile, 'n60');
  end    
end

if isempty(lp) && any(want=='l')
  cfile = sprintf('%s/.pyperc/.lfpcut-%d-%.0f.mat', ...
                  getenv('HOME'), lfpcut, fs);
  if exist(cfile, 'file')
    load(cfile);
    fprintf('[restored lfpcut filter (fs=%.0f)]\n', fs);
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
  if exist(cfile, 'file')
    load(cfile);
    fprintf('[restored spike filter (fs=%.0f)]\n', fs);
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
                                 spikecut, 2*spikecut, 25, 0.1, 25, fs), ...
                'kaiserwin');
    fprintf(']\n');
    save(cfile, 'hp');
  end
end

d = [ts; v];

d(2,:) = filter(n60, d(2,:));

spk = [];
lfp = [];
wideband = [];

if any(want == 'w')
  wideband = d;
end

if any(want == 's')
  spk = [d(1,:); filtfilt(hp.Numerator, 1, d(2,:))];
end

if any(want == 'l')
  % low pass filter and then manually decimate -- warning, this
  % make mean the time values end short..
  d(2,:) = filtfilt(lp.Numerator, 1, d(2,:));
  while (fs / 2) > (2*lfpcut)
    d = d(:, 1:2:end);
    fs = fs / 2;
  end
  lfp = d;
end




