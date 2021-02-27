function nlxts = p2mSyncNLX(pf, nlxdata)
%function nlxts = p2mSyncNLX(pf, nlxdata)
%
% find nlx timestamps for the start and stop of each pype file
%
% nlxdata is data loaded using p2mLoadNLX() -- only the event data is required for
% this sync process, so if you don't supply nlxdata, it will try to load it
% automatically using p2mnLoadlx().
%
% a bunch of sanity checking is done here just to be safe
%
%INPUT
%  pf - pypefile
%  nlxdata - data loaded with p2mLoadNLX() - if not provided, will load automatically
% 
%OUTPUT
%  nlxts - structure with timestamps in usec (standard NLX time)
%    start: trial start time - corresponds to pype `start` event
%    stop: trial stop time - corresponds to pype `stop` event
%

if ~exist('nlxdata', 'var')
  % if not specified, load just the event data (this is fast!)
  nlxdata = p2mLoadNLX(pf);
end

START = 'TTL Input on AcqSystem1_0 board 0 port 0 value (0x0001).';
STOP  = 'TTL Input on AcqSystem1_0 board 0 port 0 value (0x0000).';

%DEBUG% errs = [];
for n = 1:length(pf.rec)
  % first find the trial start event
  trialid = pf.rec(n).params.nlx_recstart_hash;
  trial_start_ix = find(cellfun(@(x) ~isempty(x), strfind(nlxdata.events.strs, trialid)));
  assert(~isempty(trial_start_ix), 'missing trial uuid');

  ttl_high_ix = 0;
  ttl_low_ix = 0;
  
  % first look forwards to find next TTL 1->0 transition (end)
  k = trial_start_ix + 1;
  while k <= length(nlxdata.events.strs)
    if strcmp(nlxdata.events.strs{k}, STOP)
      ttl_low_ix = k;
      break
    end
    k = k + 1;
  end
  assert(ttl_low_ix > 0, 'missing TTL low');
  
  % now look backwards to find TTL 0-> transition (start)
  %
  % looking for end first is important because the start can occur before OR after
  % the trialid, but end can only occur after the trialid!
  k = k - 1;
  while k > 0
    if strcmp(nlxdata.events.strs{k}, START)
      ttl_high_ix = k;
      break
    end
    k = k - 1;
  end
  assert(ttl_high_ix > 0, 'missing TTL high');
  
  nlxts.start(n) = nlxdata.events.ts(ttl_high_ix);
  nlxts.stop(n) = nlxdata.events.ts(ttl_low_ix);
  
  ttl_high = nlxdata.events.ts(ttl_high_ix);
  ttl_low = nlxdata.events.ts(ttl_low_ix);

  % sanity check: make sure nlx trial duration is within 2ms of the pypefile duration
  [~, pstart] = p2mFindEvents(pf, n, 'start');          % pstart should always be zero...  
  [~, pstop] = p2mFindEvents(pf, n, 'stop');
  
  err = (pstop-pstart)-(1e-3 * (nlxts.stop(n)-nlxts.start(n)));
  assert(abs(err) < 2, 'mismatch in trial duration >2ms');
  %DEBUG% errs = [errs err];
end

%DEBUG% histogram(errs);
