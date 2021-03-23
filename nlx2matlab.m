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
% csc = nlx_CSChp(csc)
%   - hight pass filter CSC data to extract spikes
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
% snips = csc_findsnips(csc, threshold, sig, ch)
%   - extract snips from high-passfiltered CSC dataset
%   - if sig is 1, then threshold is in units of `sigma`, otherwise
%     in uvolts.
%
% csc2snips(expers)
%   - batch application of csc_findsnips()
%   - can specify one or a list of expers or nothing and
%     let it try to find recent datasets to preprocess
%   - should be able to just do `csc2snips;` at the end
%     of each day and let it do it's thing.
%
% [lfp, spk, wideband] = filter_wideband(ts, v, want)
%
% snips = ksnip(snips, nc)
%   - do kmeans clustering on snips using .params as features
%   - applies the clustering solution to the snip.cellnumner
%
% snips = pcasnip(snips, np)
%  - do PCA on the snips and insert loading into snip.params
%    as replacement for SX hand-coded "features".
%
% snips = rwsnips(dir, snips, savefile)
%  - read or write snip struct to .mat file
%  - to save: rwsnips('save', snips, outfile)
%  - to load: rwsnips('load', [], infile)
%
% snips = subsnips(snips, ix)
%  - extract snips specified by ix-vector into a new
%    snip structure
%
%
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
%mlab specific function
%----------------------------------
%
% showallsnips(exper, src, varargin)
%   - generate summary plots of snip waveforms for all chann3els
%   - this can look at CSC, SE or 'committed' data from snipedit.m
%
% pf = p2mnlxselect(pf, ch, cellnum)
%   - pull spike times from snip data files for analysis
%   - uses p2mSyncNLX to align spike times between NLX and pype data
%     streams.
%
% nlxscanner(exper, curonly)
%   - look through databse for missing curated snip data
%
