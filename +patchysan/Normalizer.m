classdef Normalizer <patchysan.Pipeline
 properties
    %params = patchysan.Parameter() %moved to superclass
end
properties (Constant,Access = protected)   
    centrality_type = {'degree' , 'outdegree' , 'indegree' , 'closeness' , 'incloseness' , 'outcloseness' , 'betweenness' , 'pagerank' , 'eigenvector' , 'hubs' , 'authorities'};
end

methods
    
      function obj = Normalizer(varargin)
           % import patchysan.* %inport is useless. Still needs fullname of
           % the superclass
            obj@patchysan.Pipeline(varargin{:});
      end      
        
     function [outputs]  = execute(obj,inputs,params,varargin)
         % inputs: {graph, adj, root node}
         import patchysan.patchyObj
         import patchysan.Normalizer
         if nargin<3 || numel(params)<1
             params = {obj.params};
         end
         gDegree = degree(inputs{1});
         limit = max(gDegree(:))*params{1}.fieldSize;
         % inputs{1}.Edges{:,:},inputs{3} --> Edge, root
         receptiveField = Normalizer.bfsearch3(inputs{1}.Edges.EndNodes,inputs{3},limit,0);
         outputs = nonzeros(obj.graph_normalize(inputs{1},receptiveField,params{1}));
         obj.MainFrame.fieldseq = outputs;
     end       
end

methods(Access = protected)

%% Receptive Field Normalization
    function sorted=graph_normalize(obj,graphInput,neighbor,params)
    % Usage: graphInput Normalization
    % -- Input--
    % graphInput: a matlab graphInput/digraph object.
    % neighbor: Neighbors fetched by BFS.
    % params.fieldSize: size of Neighborhood.
    % params.normalizeType: Ranking function. Ident/WL/Centrality. See readGraphs.m
    % params.countDistance: determine whether distance to the root node affect the ranking.
    % -- Output --
    % A sorted Node list with size [params.fieldSize]. Represent the receptive field.
        %first column is nodeId
        import patchysan.Normalizer
        hasClass = 0;
        hasDummy = 0;


        if params.countDistance
            sortrowsTarget = [2 -3 -4];
        else
              sortrowsTarget = [-3 -4];
        end

        nodeList = nonzeros(neighbor(:,1));
        subGraph = subgraph(graphInput,nodeList);
        adjSub = adjacency(subGraph);
             if strcmp(params.normalizeType,'wl')
                 %disp('cent');
                hasClass = 1;
                labels = wl_equivalence_classes(adjSub);

            elseif   strcmp(params.normalizeType,'ident') 
                    %simply return with cut
                    cut = min(params.fieldSize,length(neighbor));
                    sorted = neighbor(1:cut,1);
                    sorted =  Normalizer.trimList(sorted,params.fieldSize);
                   return;
           elseif   strcmp(params.normalizeType,'nauty')
                hasClass = 1;
                 labels = canon(full(adjSub),wl_equivalence_classes(adjSub));     
            else
               labels = centrality(subGraph,params.normalizeType);
            end     

        if isempty(nodeList)
            sorted  = neighbor(:,1);
            sorted =  Normalizer.trimList(sorted,params.fieldSize);
            return;
        elseif length(nodeList)<length(neighbor)
            hasDummy = 1;
            assert(sum(neighbor(1:length(nodeList),1)==nodeList)==length(nodeList));
            %subGraph = subgraph(graphInput,nodeList);
            % Mark: Branch was here
           %labels = [labels;zeros(length(neighbor)-length(nodeList),1)];
          %  sorted = sortrows([neighbor,labels],sortrowsTarget); % original Id, distance, labeling(1d-WL)
        else
           %subGraph = subgraph(graphInput,nodeList);
            %labels = wl_equivalence_classes(adjacency(subGraph));     
             %perform secondary sort
            %sorted = sortrows([neighbor,labels],sortrowsTarget); % original Id, distance, labeling(1d-WL)
        end
      if ~hasClass
          cLabels  =  canon(full(adjSub),wl_equivalence_classes(adjSub));   
      else
          cLabels  =  canon(full(adjSub),labels(:,1));   
      end
      %note: if dummy nodes are all zeros, it might affect sortrows. 
      % Since neighbors is already filled with dummy nodes, so dummy nodes must
      % be filled into cLabels and labels before sortrows, but the value of
      % distance in neighbor:[node distance] must not be 0.

      if hasDummy
          labels = [labels;zeros(length(neighbor)-length(nodeList),1)];
          cLabels = [cLabels;zeros(length(neighbor)-length(nodeList),1)];
      end
      sorted = sortrows([neighbor,labels,cLabels],sortrowsTarget); % original Id, distance, labeling(1d-WL)
      %slice and drop other info
      sorted =  Normalizer.trimList(sorted,params.fieldSize);
    end

    
end
    
methods(Static)
%% Trim the node list
    function sorted = trimList(sorted,limit)
      if length(sorted)>limit
         sorted = sorted(1:limit,1);
      else
          sorted = sorted(:,1);
      end
    end 
%% BFS 
% Todo - should support undirected
    function [neighbor] = bfsearch3(adj, s, limit,isDirected)
    % A BFS implementation based on Java.
    % -- Input --
    % adj: Adjacency List
    % s: root node
    % limit: size. Default is the size of the entire graph. The gnorm.m will do the normalization.
    % -- Output --
    % neighbor: node sequence from BFS.
    % edgeToNew: Only for Debug/Troubleshooting
     import patchysan.SeqSelector
     if nargin<4
         isDirected = 1;
     end
     if ~isDirected
         adj = unique([adj; flip(adj,2)],'rows');
     end
       nodeList = unique(adj);
       maxNode = size(nodeList,1);
       maxIndex = max(max(adj));
       map =zeros(1,maxIndex); % java.util.HashMap();              
      % In case of adjacency matrix, but then all below shall be reworked.
      %  maxNode =  size(adj,1); 

    if nargin<=2
        limit = maxNode;
    end
    if size(adj,2)  ==3
        %% If weight came in

    end
    % Avoid doing bfs to the entire graph.
            % assume the adj contains no repeated edges
            neighbor = zeros(limit,2);
            %initial distance all inf
            neighbor(:,2) = inf;

            %find destination of starting vertex. trim by limit
            %hence the length of result is no more than limit
            [r,~]=find(adj(:,1)==s & adj(:,2)~=s,limit,'last');
            initIndex = length(r)+1;
            %partial output: distance 0
            neighbor(1,:) = [s,0];
            %initIndex >1 means there is at least one node in r, i.e.
            %first generations of children.
            if initIndex > 1
                %ones: distance 1
                neighbor(2:initIndex,:) = [adj(r,2),ones(length(r),1)];          
            end
            %edgeToNew = [s*ones(length(r),1),adj(r,2)];

            %% if either empty or exactly same size then return directly
            if initIndex < 1 || initIndex ==limit
                return
            else
                %disclaimer: all vectors popped from queue are column vector,
                %no matter whether they are row vec before pushed into the
                %queue.
                %queue is the list of nodes to be processed (find child)
                queue = java.util.LinkedList();
                %queue = zeros(1,maxNode);       

               % listPosition = 1;
                %% add init results
                for ii = 1:initIndex
                     curr = neighbor(ii,:);
                     assert(length(curr)==2 && length(curr(1))==1); 
                     queue.add(curr);
                     % listPosition init = 1
                     %queue(listPosition) = curr;
                    % listPosition = listPosition+1;
                     map(curr(1)) = true;
                end
                %remove s from the queue as it is done already.
                queue.remove;

                 %ii = initIndex+1;
                while initIndex < limit  
                     %queue.size
                     %read nodes in queue
                    if queue.size>0
                        candidate = queue.remove;
                        %maxNode is a loose upperbound. Won`t exceed the max
                        %number of neighbors
                        [r,~]=find(adj(:,1)==candidate(1) & adj(:,2)~=candidate(1),maxNode,'last');
                        % if not empty result,
                        if ~isempty(r)
                            %add to neighbor
                            len = length(r);
                            %This (right side) cannot check visisted nodes: neighbor(initIndex+1:initIndex+len) = adj(r,2);
                            %jj is the index for non-visited nodes, otherwise
                            %there will be holes in the list.
                            %So instead, using hashMap
                            jj=1;
                            for ii = 1:len%min(len,limit - initIndex)
                                if map(adj(r(ii),2))
                                    sprintf('visited:%d',adj(r(ii),2));   
                                    %jj = jj-1;
                                    continue
                                end
                                dist = candidate(2)+1;
                                assert(isscalar(dist));
                                % Well, actually, ii is scalar here.
                                neighbor(jj+initIndex,:) = [adj(r(ii),2),dist*ones(length(r(ii)),1)];%adj(r(ii),2); % [adj(r(ii),2),dist*ones(length(r),1)];
                                % edgeToNew  = [ edgeToNew ;[candidate(1),adj(r(ii),2)]];
                                %% addqueue:ii is scalar
                                queue.add([adj(r(ii),2),dist]);
                                map(adj(r(ii),2)) = true;
                                jj = jj +1;
                            end
                            initIndex = initIndex+jj-1; % -1 to compensate jj++ in the last iteration
                            continue;
                        end
                    else
                       %no more valid results
                        break;
                    end

                    %just some insurance for debugging here
                    %ii = ii + 1;
                end    
            end
    end    
    
    
end
    
end