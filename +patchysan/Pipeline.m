classdef Pipeline < patchysan.patchyObj
    properties
        params patchysan.Parameter
    end
   properties (Access = {?patchysan.Pipeline, ?patchysan.PatchySan}, Hidden, Transient)
        MainFrame patchysan.PatchySan 
   end
 
  methods
      function obj = Pipeline(varargin)
          import patchysan.*;
          if numel(varargin)==1 && isa(varargin{1},'PatchySan') %fullname patchysan.PatchySan
              obj.params = varargin{1}.params;
          else
            obj.load(varargin{:});
          end
            if ~isa(obj.params,'Parameter') %fullname patchysan.Parameter
                error('Property: params not a valid struct');
            end
            %assert(isempty(obj.internalOverride)  || isa(obj.internalOverride,'function_handle'));
        end         
      
      function [outputs]  = execute(obj,inputs,params,varargin)
            outputs = {};
      end    
      function obj = attach(obj,patchy)
          obj.MainFrame = patchy;
      end
  end
    
end