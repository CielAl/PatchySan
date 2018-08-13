     

%% Field by field - not recommended
      function getAttrByIdField(obj,typeList,id,nodeList)
          import patchysan.Prepare
          featCount = numel(typeList);
          attrCell = cell(1,featCount);
          for ii = 1:featCount
              [attrCell{ii},~] = obj. prepareAttr(obj.MainFrame.graphs{id},obj.MainFrame.node_attributes{id},obj.MainFrame.edge_attributes{id},attrType,nodeList);
          end
          obj.MainFrame.attributes = cell2mat(attrCell);
      end
      
      
            
      %% Get Full slice
      % To minimize the quantity of code, define the source of input 
      % in upper levels of function calls (helper functions like getAttr with different design of signatures)
      % (i.e. position of graph in the cell PatchySan.graphs, or range of node ids)    
       function attr = getAttrFull(obj,typeList,graph,adjMatrix,nucleiFeatures)
          import patchysan.Prepare
          featCount = numel(typeList);
          attrCell = cell(1,featCount);
          for ii = 1:featCount
              [attrCell{ii},~] = obj.prepareAttr(graph,adjMatrix,typeList{ii},nucleiFeatures);
          end
          attr = cell2mat(attrCell);
       end
      