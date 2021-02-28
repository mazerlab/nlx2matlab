function events = nlx_getRawEvents(filename, range)
%
%extracts events from a neuralynx events file.
%
%INPUT
%  filename - .nev file
%  range - optional vector [start, stop] times in usec   <-- THIS DOESN'T WORK
%    loading events is fast -- just load them all!
%
%OUTPUT
% events - structure --
%      header: neuralynx header strings (useful parmaters here)
%          ts: event timestamps in usec
%        ttls: state of ttl line (0/1)
%        strs: name of each event as string
%         ids: this indicate which line the ttl events correspond to
%      extras: no idea what this is ???
%
%originally from urut/may04

if ~exist(filename, 'file')
  events = [];
  return
end

if ~exist('range', 'var')
  range = [];
else
  warning('range arg not implemented -- loading all');
  range = [];
end

FieldSelection(1) = 1;                  % timestamps
FieldSelection(2) = 1;                  % event ids
FieldSelection(3) = 1;                  % ttls
FieldSelection(4) = 1;                  % extras
FieldSelection(5) = 1;                  % event strings
ExtractHeader = 1;                      % get header
if isempty(range)
  ExtractMode = 1;                      % extract whole file
  ModeArray = [];                       % ignored for whole file
else
  % this is broken -- causes matlab to crash
  ExtractMode = 4;                      % extract between specified timestamps
  ModeArray = range;
end

% Nlx2MatEV_v3:
%  number of outputs will be sum(FieldSelection)+1 -- one output for
%  each field requested, plus the header. Output order is:
%    ts, ids, ttls, extra, strs, header
%  with anything not requested skipped.

[timestamps, ev_ids, ttls, extras, ev_strs, header] = ...
    Nlx2MatEV_v3(filename, FieldSelection, ExtractHeader, ExtractMode);


events.type = 'events';
events.header = header;
events.ts = timestamps';
events.ttls = ttls';
events.strs = ev_strs;
events.ids = ev_ids;
events.extras = extras;
events.src = filename;

