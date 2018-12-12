function [order] = canon(subGraph, classes,flag)
%  Usage: invoke nauty to find the canonical labelling
%  --Input--
%  -subGraph: the adjacency matrix of the graph to find cl
%  -classes: the colors of the subGraph nodes
%  --Output--
%  -order: the position vector of vertices in the new graph
%          e.g., original label = [1 2 3 4 5], canonical 
%          label = [3 1 2 4 5], then order = [2 3 1 4 5]
%
%  *author: Muhan Zhang,  Washington University in St. Louis
%
% * Change:
%               (1) command was modified for Windows Env. 
%               (2) Input is sanitized.

%% sanitize the input - to prevent crash
dim_graph = size(subGraph);
% check if square matrix
assert(ismatrix(subGraph) && numel(dim_graph)==2 && ~diff(dim_graph),'Not Square Matrix');
% Symmetric -> conditions in builtin graph.m 
% Note: matrix contains NaN would be detected by issymmetric. But digraph
% is allowed and hence not required to check if the adj is symmetric
assert((isnumeric(subGraph) || islogical(subGraph)) && ~sum(isnan(subGraph(:))),'Not Numeric or has NaN');

%%  Must be dense matrix and double. Logical will crash NAUTY
subGraph = full(double(subGraph~=0));


%% Main script
K = size(subGraph, 1);
if nargin < 2
    classes = ones(K, 1);
end

% Reorder subGraph to let adjacent vertices have the same colors
% The colors must be like [1, 2, 1, 3, 3], must not be like 
% [1, 2, 1, 4, 4]. Colors must be continuous from 1 to n.
[classes, order] = sort(classes);  % to sort the colors
subgraph1 = subGraph(order, order);

% Prepare the input to canonical.c
classes = [classes; classes(end) + 1];
colors_nauty = 1 - diff(classes);
num_edges = nnz(subgraph1);
degrees = sum(subgraph1, 2);

% Check if canonical.c has been compiled to mex function
if nargin < 3
    flag = exist(['canonical.' mexext],'file');
end
%flag = 0;  % let it be compiled every time
if flag == 0
    !del canonical.mex*;
    cd software/nauty26r11;
    !copy ..\..\canonical.c .;
   mex canonical.c nauty.c nautil.c naugraph.c schreier.c naurng.c nausparse.c
    !copy canonical.mex* ..\..\;
    cd ../..;
end

% Run nauty to find canonical labeling
clabels = canonical((subgraph1), num_edges, degrees, colors_nauty');
clabels = clabels + 1;
order = order(clabels);

