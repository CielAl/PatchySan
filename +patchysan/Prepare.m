classdef Prepare < patchysan.Pipeline
    %% No permutation. attributes are 1-d or 2-d.
%% subsindex
    properties
        %todo
        fuser function_handle 
        featureParser cell 
       % params =  patchysan.Parameter();
       
       nodeLength double
       attrChannel double
    end
    
  methods      
      function obj = Prepare(varargin)
                obj@patchysan.Pipeline(varargin{:});
      end            
      function [output] = execute(obj)
                 obj.getNodeLength().allocateInput();
                 output = obj.MainFrame.attributes_all;
      end
      
      %% The whole slice. Matrix(1:end) is much slower than use Matrix directly without indexing.
      function [attribute,featChannel,slicemark] = getAttrById(obj,typeList,id)
          import patchysan.Prepare
          featCount = numel(typeList);
          attrCell = cell(1,featCount);
          featChannel = 0;
          slicemark = zeros(featCount,2);
          for ii = 1:featCount
              [attrCell{ii},currChannel,slicemark(ii,:)] = obj. prepareAttr(obj.MainFrame.graphs{id},obj.MainFrame.node_attributes{id},obj.MainFrame.edge_attributes{id},typeList{ii});
            featChannel = featChannel + currChannel;
          end
         attribute = cat(3,attrCell{:});  %  Do not use cell2mat(attrCell) if attributes contains single column vectors - matlab will drop the last singleton dimension.
      end      
      
      

       %% Fuse the attribute
        % - if prepare field by field, the overhead may be huge, including the part to calculate feature size to allocate the attribute array 
        function [currAttribute, featChannel,featpart] = prepareAttr(obj,graph,node_attributes,edge_attributes,attrType,varargin)
				% for pre-defined branches, varargin{1} is the nodeList. 
				% if varargin is empty, matrix(varargin{:}) returns matrix itself: the whole slice
                
                %featpart: mark of feature partitions [length, {slicedim 1:row  2: row+column}]
                %             # If slicedim = 1, it means this segment of
                %              features are with fixed length, e.g. node
                %              attributes. 
                %             # If slicedim = 2, it represents edgewise feature. 
                %              The length stored == # of nodes while the actual length fetched is the # of fieldSize 
               if isa(attrType,'char')
                   switch(lower(attrType))
                       case  'fuse'
                            currAttribute = [degree(graph,(varargin{:})), node_attributes(varargin{:}), full(edge_attributes(varargin{:}))];
                            featpart = [1,1; numel(varargin{:}) 1; size(edge_attributes(varargin{:}),2) 2];
                            featChannel=1+numel(varargin{:})+obj.params.fieldSize; 
                       case  'node'
                            currAttribute = node_attributes(varargin{:});
                            featChannel= size(currAttribute,3); 
                            featpart = [featChannel,1];
                       case 'degree'
                            currAttribute = permute(degree(graph,varargin{:}),[3 1 2]); % The 2nd dimension, which is singleton, will be removed.
                                                                                                                           % But it will still serve as transpose here.
                            featpart = [1 1];
                            featChannel= size(currAttribute,3); 
                       case  'edge'
                           currAttribute = full(edge_attributes(varargin{:}));
                           featpart = [size(edge_attributes(varargin{:}),2),2];
                           featChannel = obj.params.fieldSize;
                       case 'fuser'
                        % Function handle that does not support varargin
                        % but use obj.params/obj.MainFrame.params 
                           [currAttribute,featpart,featChannel] = obj.fuser(graph,node_attributes,edge_attributes);
                       otherwise 
                           error('unknown attribute type %s',attrType);
                   end
               elseif isa(attrType,'function_handle')
                   % Function handle that support varargin as extra args
                   % Provide compatability to my old implementations only.
                    [currAttribute,featpart,featChannel] = attrType(graph,node_attributes,edge_attributes,varargin);
               else
                      error('Attribute Type must be string or function handle');
               end
               %featsize= size(currAttribute); 
        end     
      
      

              
          
      
  end
  
  methods(Access = protected)
      
    function obj = getNodeLength(obj)
		flag = obj.params.nodeLengthType;
        numGraphs = length(obj.MainFrame.graphs);
        maxLength = 0;
        obj.nodeLength = 0;
        assert(numGraphs>0,'graph num must be positive');
        for ii = 1:numGraphs
                if isa(obj.MainFrame.graphs{ii},'graph')
                    curr =  size(obj.MainFrame.graphs{ii}.Nodes,1);
                    obj.nodeLength = obj.nodeLength +curr;
                elseif isAdj(obj.MainFrame.graphs{ii})
                    curr = size(obj.MainFrame.graphs,1);
                    obj.nodeLength = obj.nodeLength + curr;
                else
                    error('obj.MainFrame.graphs{%d} is not valid type',ii);
                end
                if curr > maxLength
                    maxLength = curr;
                end
        end
        switch(lower(flag))
            case 'average'
                obj.nodeLength = ceil(obj.nodeLength / numGraphs);
            case 'max'    
                obj.nodeLength  = maxLength;
        end
		obj.params.nodeLengthValue = obj.nodeLength;
    end
 
    function [obj]  = allocateInput(obj)
          %inputs {}.   directly operate on obj.MainFrame.graphs
          % setter: obj.MainFrame.attributes_all contains all attributes
          import patchysan.*;
          numGraphs = numel(obj.MainFrame.graphs);
          featureSize=  zeros(1,numGraphs);
          obj.MainFrame.input = cell(1,numGraphs);
          for ii = 1:numGraphs
              [obj.MainFrame.attributes_all{ii},feat,slicemark]  = obj.getAttrById(obj.params.featureType,ii);
              %manual override - if attrSlice is given - default is empty i.e. bypass this step 
              if ~isempty(obj.params.attrSlice)
                  obj.MainFrame.attributes_all{ii} = obj.MainFrame.attributes_all{ii}(:,obj.params.attrSlice);
                  feat = numel(obj.params.attrSlice);
              end
              featureSize(ii) = feat;
              %empty input
              obj.MainFrame.input{ii} = zeros(obj.params.attrRow,obj.params.fieldSize*(obj.params.nodeLengthValue),obj.params.attrChannel); 
              obj.featureParser{ii} = obj.parseSlice(slicemark);
          end
          %obj.
          obj.MainFrame.attrChannel = max(featureSize);
          %temp
          obj.attrChannel = obj.MainFrame.attrChannel;
          %outputs = {obj.MainFrame.attrChannel};
          
          %% Todo Parse slicemark 
      end     
  end
  methods(Access = public)
      function indexer = parseSlice(obj,slicemark)
          import patchysan.*;
          %%featpart: mark of feature partitions [length, {slicedim 1:row  2: row+column}]
           
          endInd = transpose(cumsum(slicemark(:,1),1));
          startInd = [1 endInd(1:end-1)+1];
          %columns that should be shrunk
         % shrinkage = find(slicemark(:,2)==2);
          %replacer = @(endIndex)  endIndex(endIndex==2) = -1
          fieldSize = obj.params.fieldSize;
          indexer = @(nodeSeq) Prepare.assembleIndexHelper(nodeSeq,startInd,endInd,transpose(slicemark(:,2)),fieldSize);
      end
  end
methods(Static)
      function z = assembleIndexHelper(nodeSeq,startInd,endInd,featpart,fieldSize)
          import patchysan.*
          inputs.fieldSize = fieldSize;
          inputs.nodeSeq = nodeSeq;
          inputs = repmat(inputs,1,numel(startInd));
          z = cell2mat(arrayfun(@Prepare.assembleIndex,startInd, endInd,featpart,inputs,'UniformOutput',0));
      end
      function z = assembleIndex(startInd,endInd,mark,input)
        if mark==1
            z = startInd:endInd;
        else
            % offset on startInd is 0 : minus 1
            assert(all(input.nodeSeq>0),'node Seq contains negative values. NodeSeq:%s',num2str(input.nodeSeq));
            assert(endInd-startInd+1>=numel(unique(input.nodeSeq)),'# of unique node in node Sequence longer than # of column in edge-wise attribute \n endInd:%d; startInd:%d, nodeSeq:%s',endInd,startInd,num2str(input.nodeSeq));
            z = padarray(startInd-1+input.nodeSeq,[0,input.fieldSize - numel(input.nodeSeq)],0,'post');
        end
      end
    
    
end
    
end