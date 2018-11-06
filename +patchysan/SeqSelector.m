classdef SeqSelector < patchysan.Pipeline
properties
    internalOverride = []
end
properties (Constant,Access = protected)   
    centrality_type = {'degree' , 'outdegree' , 'indegree' , 'closeness' , 'incloseness' , 'outcloseness' , 'betweenness' , 'pagerank' , 'eigenvector' , 'hubs' , 'authorities'};
end
  methods
     function [outputs]  = execute(obj,inputs,params,varargin)
         % inputs: {graph, adj}
         import patchysan.*
         if nargin<3 || numel(params)<1
             params = {obj.params};
         end
         outputs = obj.getNodeSequence(inputs{1},inputs{2},params{1});
         obj.MainFrame.nodeseq = outputs;
     end       
      
      function obj = SeqSelector(varargin)
          obj@patchysan.Pipeline(varargin{:});
          assert(isempty(obj.internalOverride)  || isa(obj.internalOverride,'function_handle'));
        end   
     
      function nodeSeq = getNodeSequence(obj,graphInput,currAdj,params)
        if nargin < 2+1
            error('Insufficient Input Args');
        end
        if nargin < 3+1
            params = obj.params;
        end
        sequenceType = params.sequenceType;
        seqStep = params.seqStep;
        nodeLength=params.nodeLengthValue;
        if isa(sequenceType,'char')
            switch sequenceType
                  % Redundant. Simply for troubleshooting
                  %   canon(full(adjSub)
                  case('wl')
                      labels = wl_equivalence_classes(currAdj);
                      sequencing = [labels canon(full(currAdj),labels)];
                      sortTarget = [-1 2];
                  case('nauty')                
                      sequencing = canon(full(currAdj),wl_equivalence_classes(currAdj));
                       sortTarget = -1;
                  case('rw')

                  case patchysan.SeqSelector.centrality_type
                      sequencing =[centrality(graphInput,sequenceType)  canon(full(currAdj),wl_equivalence_classes(currAdj))];
                      sortTarget = [-1 2];
                case 'override'
                    [sequencing, sortTarget]  = obj.internalOverride(graphInput,currAdj);                  
                otherwise
                    error('Unknown code branch for Sequencing: %s',sequenceType);
            end
        elseif isa(sequenceType,'function_handle')
                    nodeSeq = sequenceType(graphInput,currAdj,params);
                    return;
        else
            disp(sequenceType)
            error('Unknown Node Sequence Selector');
        end


          % Break tie for Sequencing as well
          % the nodeSeq is the indices of the vector, and the indices are the
          % vertices of graphs
             [~,nodeSeq] = sortrows(sequencing,sortTarget);
             % in case step >1. Pseudo Node is done in the input{ii} phase below.
           extendedLength = 1+seqStep*(nodeLength-1);
           if extendedLength<=length(nodeSeq)
                nodeSeq = nodeSeq(1:seqStep:extendedLength);
           else
                nodeSeq = nodeSeq(1:seqStep:end);
           end
        %stride moves to cnn - more flexibility. - or you need to run
        %patchysan each time you change the stride
        end          
  end    
  % end of methods
end