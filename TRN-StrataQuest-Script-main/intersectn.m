function out = intersectn(varargin)

% INTERSECTN functions similarly to INTERSECT, but has some added
% flexibility. For example, if you input three arrays and want to find
% items that are in at least two of them, INTERSECT is incapable of doing
% this, but INTERSECTN will do it.
%
% OUT = INTERSECTN(IN1,IN2,...,MATCHES)
%
% Inputs: IN1,IN2,... are cell arrays of strings or numerical vectors.
%         MATCHES is a scalar, the number of matches that are required.
%
% For example, if you have three sets of fruit names, and you want to
% return any fruits that show up in at least two of these sets, use:
%    OUT = INTERSECTN(IN1,IN2,IN3,2)
%
% Example:
%    fruit{1} = {'apple','banana','cherry','orange'};
%    fruit{2} = {'apple','cherry','lemon','tangerine'};
%    fruit{3} = {'apple','lemon','lime','peach'};
%    fruit{4} = {'apple','lemon','orange','coconut'};
%
%    out = intersectn(fruit{:},4)
%        returns: 'apple'
%
%    out = intersectn(fruit{:},3)
%        returns: {'apple','lemon'}
%
%    out = intersectn(fruit{:},2)
%        returns: {'apple','cherry','lemon','orange'}
%
% Copyright (C) 2011 Jeremy Brower.
% jeremy.brower@gmail.com


if ~isnumeric(varargin{nargin})
    error('Last input argument to INTERSECTN must be a scalar.')
end

if varargin{nargin} > nargin-1
    error('Group size cannot be larger than the number of groups.')
end

for i = 1:nargin-1
    v{i} = varargin{i};
end

n = nargin-1;             %-- # of input sets
k = varargin{nargin};     %-- # of required matches
c = combnk(1:n,k);        %-- possible combinations of n & k
iter = size(c,1);         %-- # of combinations of n & k

for i = 1:iter
    sets{i} = v{c(i,1)};
    for j = 2:k
        sets{i} = intersect(sets{i},v{c(i,j)});
    end
end
out = sets{1};
for i = 2:iter
    out = union(out,sets{i});
end


 



