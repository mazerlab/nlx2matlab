function p = nlx_pfind(header, name, numeric)
%function p = nlx_pfind(header, name, numeric)
%
%  Get parameter from a nlx header block (cell array of strings)
%
%  If `numeric` is true, then try to convert to number

if ~exist('numeric', 'var')
  numeric = 0;
end

n = find(strncmp(name, header, length(name)));
if isempty(n)
  p = [];
elseif length(n) > 1
  error('more than one matching parameter in header');
else
  p = header{n};
  if numeric
    p = strsplit(p);
    p = str2num(p{2});
  end
end
  