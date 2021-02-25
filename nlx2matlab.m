%nlx2matlab toolbox (mazer lab)
%--------------------------------------
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
% filter_wideband(ts, v, what)
%   - low level function to filter wideband into spikes and lfp
%   - *don't call this function directly!*
%   - ripped out of tdt loader, so code is identical
