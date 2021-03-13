function nlxdata = p2mLoadNLX(pf, what, chan)
%function nlxdata = p2mLoadNLX(pf, what, chan)
%
% find and load nlx data matching pypefile
% NOTE: this actually loads the entire datadir that contains the pf
%
%INPUT
%  pf - pypefile
%  what - string specifying what to load - one char for each datatype
%    e: event data (always loaded)
%    c: raw csc
%    h: high pass filtered
%    s: snip/se data
%  chan - channel number (starting with 1)
%
% 

dd = p2mFindNLX(pf);

if ~exist('chan', 'var')
  chan = NaN;
end
nlxdata.chan = chan;

if ~exist('what', 'var')
  what = '';
end

nlxdata.events = nlx_getRawEvents([dd '/Events.nev']);
nlxdata.csc = [];
nlxdata.snips = [];

if any(what == 'c')
  nlxdata.csc = nlx_getRawCSC([dd sprintf('/CSC%d.ncs', chan)]);
end
if any(what == 'h')
  nlxdata.csc = nlx_getRawCSC([dd sprintf('/CSC%d.ncs', chan)]);
  nlxdata.csc = nlx_CSChp(nlxdata.csc);
end
if any(what == 's')
  nlxdata.snips = nlx_getRawSE([dd sprintf('/SE%d.nse', chan)]);
end

