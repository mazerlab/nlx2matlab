function snips = pcasnip(snips, np)
%function snips = pcasnip(snips, np)
%
% replace feature params extracted on line by NLX SE box
% with PC1-8 loadings.
%

if ~exist('np', 'var')
  np = 4;                               % default for SX box
end

if size(snips.v,2) < np
  error(sprintf('pcasnip requires >%d examples', np));
end
[pcs, scores, latent] = pca(snips.v');
snips.params = scores(:,1:np)';

% figure out how many PCs cover 90% of the data
auto_np = max(find(cumsum(latent./sum(latent)) < 0.9));
fprintf('pcasnip: recommend <= %d PCs\n', auto_np);

snips.features = 'pca';

