function snips = pcasnip(snips, np)
%function snips = pcasnip(snips, np)
%
% replace feature params extracted on line by NLX SE box
% with PC1-8 loadings.
%


if ~exist('np', 'var')
  np = 8;                               % default for SX box
end

[pcs, scores, latent] = pca(snips.v');
snips.params = scores(:,1:np)';
