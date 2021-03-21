function [pf, nd] = nlxexper(exper, varargin)
%function [pf, nd] = nlxexper(exper, varargin)
%
% quickly load pf and neuralynx data by exper
% varargins are `what` and `chan`, like p2mLoadNLX()
%

l = dbfind(exper, 'list');
pf = p2mLoad2(l{1});
nd = p2mLoadNLX(pf, varargin{:});
