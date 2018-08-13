classdef patchyObj < matlab.mixin.Copyable

    methods
        function obj = patchyObj(varargin)
            obj.load(varargin{:});
        end
        function load(obj,varargin)
            % This part is adapted from VLfeat MatConvnet: class dagnn.Layer: load
            %use varargin{:} to unpack, as the level of varargin increments 
             argStruct = patchysan.patchyObj.parseNameValue(varargin{:});
             for fields = fieldnames(argStruct)'
                 name = fields{:};
                 if isprop(obj,name)
                     obj.(name) = argStruct.(name);
                 else
                     error('Wrong property name: %s for class: %s',name,class(obj));
                 end
             end
        end
    end
  methods(Static)
      function argStruct = parseNameValue(varargin)
           % This part is adapted from VLfeat MatConvnet: class dagnn.Layer - function argsToStruct
           %    Purpose is to provide compatibility to different forms of args
           import patchysan.patchyObj
           % it does not work if varargin is already {{}} (empty in
           % previous level)
           if numel(varargin)<1
               argStruct = struct();          
           elseif numel(varargin) == 1
                    if isstruct(varargin{1})
                        argStruct = varargin{1};
                    elseif iscell(varargin{1})
                        argStruct = patchyObj.nameValue2struct(varargin{1});
                    end                 
           else % ignore the case of odd number, just let cell2struct throw the exception  
                    %use {:} to unpack if the next level is also varargin
                    argStruct =  patchyObj.nameValue2struct(varargin{:});
           end
                    
      end
      function args = nameValue2struct(varargin)
          % varargin = {n,v,n,v,...}
          args =  cell2struct(varargin(2:2:end),varargin(1:2:end),2);
      end
  end    
end
