classdef PatchySan < patchysan.patchyObj
  properties
    graphs cell
    adjMatrix  cell
    node_attributes cell
    edge_attributes   cell 
    class cell
    params =patchysan.Parameter()
    meta = struct()
    
    
    input
    % By default identical to output
    label
  end
    properties (Access = {?patchysan.Pipeline, ?patchysan.PatchySan}, Hidden, Transient)
        %temporal variables
        nodeseq double
        fieldseq double
        featsize double
        attributes_all cell
   end 
  
  properties(Transient)
      %% Delayed assignment
    sequencer patchysan.Pipeline 
    normalizer patchysan.Pipeline 
    attrFuser patchysan.Pipeline  
    gatherer patchysan.Pipeline
    attrChannel double
  end
  
  
  methods
  
    %% Constructor  
    function obj = PatchySan(varargin)
        %must unpack/flatten with {:}
      import patchysan.*
      % still needs full name even with import
      obj@patchysan.patchyObj(varargin{:}); 
      obj.sequencer = SeqSelector(obj).attach(obj);%Sequencer('params',obj.params).attach(obj);
      obj.normalizer =  Normalizer(obj).attach(obj);%Normalizer('params',obj.params).attach(obj);
      obj.attrFuser =  Prepare(obj).attach(obj);%Prepare('params',obj.params).attach(obj);
    end
    
    % opposite of pipeline.attach(patchy): patchy.addPipeline(pipeline)
    function addPipeline(obj,pipeline)
        pipeline.MainFrame = obj;
    end
    
    %% Evaluation
    function evaluate(obj)
        % attributes_all is assigned here, as well as featureParser
        obj.attrFuser.execute();
        
        numGraphs  = numel(obj.graphs);
        obj.input = zeros(obj.params.attrRow,obj.nodeLengthValue,obj.attrChannel,numGraphs);
       % Default: classification only
        obj.label = zeros(1,1,1,numGraphs);
        % For each graph:
        for graphId = 1:numGraphs
            % inputs for SeqSelector: {graph, adj}, the third slot is used
            % by Normalizer so this cell can be reused.
            g_inputs = {obj.graphs{graphId},adjacency(obj.graphs{graphId}),0};
            % Select the node Sequence
            %           implicit setter: obj.nodeseq is assigned in
            %           obj.sequencer.execute
            % obj.sequencer.execute(g_inputs,obj.params);
            
            nodeSequence = transpose(obj.sequencer.execute(g_inputs,obj.params));
            for nodeId = 1: numel(nodeSequence) 
                node = nodeSequence(nodeId);
                g_inputs{3} = node;
                % inputs for Normalizer: {graph, adj, root node}
                indexer = obj.attrFuser.featureParser{graphId};
                
                % implicit setter for obj.fieldseq -  debug
                % nonzeros already applied
                receptiveField = obj.normalizer.execute(g_inputs,obj.params);
                featureSlice = indexer(receptiveField);
                fieldStartIndex = (nodeId-1)*obj.params.fieldSize+1;
                obj.input(:,fieldStartIndex:fieldStartIndex+numel(featureSlice)-1,:,graphId)  =obj.attributes_all{graphId}(:,featureSlice,:);
            end
               
                obj.label(:,:,:,graphId) = obj.class{graphId};
        end
        
   end
    
    %% Setter
    % use obj.load
    
    
  end      
      

methods(Static)
 
end
    %% Todo
 %{ 
methods (Access = protected)
    function deepCopy = copyElement(obj)
      deepCopy = patchysan.PatchySan.loadobj(obj.saveobj());
    end
end
  %}
end