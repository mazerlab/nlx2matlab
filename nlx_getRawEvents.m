function events = nlx_getRawEvents(filename)
%
%extracts events from a neuralynx events file.
%
%urut/may04

if ~exist(filename, 'file')
  events = [];
  return
end

FieldSelection(1) = 1;                  % timestamps
FieldSelection(2) = 1;                  % event ids
FieldSelection(3) = 1;                  % ttls
FieldSelection(4) = 1;                  % extras
FieldSelection(5) = 1;                  % event strings
ExtractHeader = 1;                      % get header
ExtractMode = 1;                        % read whole file

% Nlx2MatEV_v3:
%  number of outputs will be sum(FieldSelection)+1 -- one output for
%  each field requested, plus the header. Output order is:
%    ts, ids, ttls, extra, strs, header
%  with anything not requested skipped.

[timestamps, ev_ids, ttls, extras, ev_strs, header] = ...
    Nlx2MatEV_v3(filename, FieldSelection, ExtractHeader, ExtractMode);


events.header = header;
events.timestamps = timestamps';
events.ttls = ttls';
events.strs = ev_strs;
events.ev_ids = ev_ids;
events.extras = extras;
