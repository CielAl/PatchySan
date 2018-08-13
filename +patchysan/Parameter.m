classdef Parameter <patchysan.patchyObj
    properties
        parallel = 0
        gpu = 1
        fieldSize = 5
        encode = 0
        normalizeType = 'wl'
        Directed = 0
        sequenceType = 'wl'
        countDistance = 1
        seqStep = 2
        %
        
        %by default, all features channels are prepared
        extraFeature = 'none'
        % There are no default value for attrChannel: either predefined or
        % calculated from data.

        
        % if defined - slice if from the fused feature
        attrSlice = []
        % compatibility for old code (procedural)
        normalizer = @gnorm
        
        attrChannel = []        
        attrRow = 1        
        nodeLengthType = 'average'           
        nodeLengthValue double = -1    
        featureType = {'degree','node','edge'};
        featurePartition
    end
  
  methods
    function obj = Parameter(varargin)
         obj.load(varargin{:});
    end
  end     


end