%MLAB nlx2matlab toolbox
%--------------------------------------
%
% This is a toolbox for loading and manipulating neuralynx data files and syncing 
% them with pype datafiles.
%
% csc = nlx_getRawCSC(cscfilename)
%   - load neuralynx .nsc file into useful struct
%
% events = nlx_getRawEvents(eventfilename)
%   - load neuralynx .nev file into useful struct
%
% snips = nlx_getRawSE.m(sefilename)
%   - load neuralynx .nse file into useful struct
%
% nlx_show(datastruct)
%   - smart data display tool -- tries to figure out what datastruct
%     is and plot it intelligently.
%
% value = nlx_pfind(header, parametername)
%   - lookup named paramter in csc, events or snips struct from loaders
%
% csc = nlx_CSChp(csc)
%   - high pass filter CSC struct to get rid of LFP - returns new CSC struct
%   - generally should replace csc with filtered csc to same memory
%
% [lfp, spks, wideband] = filter_wideband(ts, v, what)
%   - low level function to filter wideband into spikes and lfp
%   - *don't call this function directly!*
%   - ripped out of tdt loader, so code is identical
%
%pype specific function
%----------------------------------
%
% datadir = p2mFindNLX(pf)
%   - find nlx data directory for pypefile
%
% nlxdata = p2mLoadNLX(pf, what, chan)
%   - find nlx data matching specified pypefile and load it
%   - can load any combination of events, CSC, filtered CSC or SE datastreams
%   - nlxdata will have .events, .csc and .snips fields
%
% startstops = p2mSyncNLX(pf, nlxdata)
%   - finds all trial start/stop events in the nlxdata timebase
%   - nlxdata is optional -- only event data are needed. If you have it, you can
%     pass it in, otherwise will load automatically using p2mLoadNLX()
%
