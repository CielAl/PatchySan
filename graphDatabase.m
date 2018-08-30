function graphDB = graphDatabase(graph_name,clones,varargin)
graphDB.meta.name = graph_name;
import patchysan.*;

if numel(varargin)==4
    [graphs,input,output,params] = deal(varargin{:});
elseif ~isempty(varargin) && isa(varargin{1},'PatchySan')
    patchysanIn = varargin{1};
    graphs = patchysanIn.graphs;
    input = patchysanIn.input;
    output = patchysanIn.output; 
    params = patchysanIn.params;
else
    error('Unsupported Input');
end
% Meta info.
graphDB.meta.graphInput=graphs;

%
graphDB.meta = struct(params);



    if isa(input,'cell')
        sample_size = length(input);
        [w ,h,c] = size(input{1});
        [w2, h2,c2]=size(output{1});
        %standardize
        graphvec = zeros(w,h,c,sample_size);
        labels =zeros(w2,h2,c2,sample_size);

        % Extend to 4-d array, so that it can be used for current CNN architecture directly.
         for ii=1:sample_size
             graphvec(:,:,:,ii) = single(input{ii});
             labels(:,:,:,ii) = single(output{ii});
        end
    else
        [w ,h,c,d] = size(input);
        [w2, h2,c2,d2]=size(output);
        sample_size = size(input,4);
        graphvec = single(input);
        labels = single(output);
    end
    %fine above
    
    %% Start shuffling by groups
    % Note that originally the first half is all 1 while the rest are all 0. So should shuffle by group before
    % Cut out the test set.
    cutFactor = 0.8;
    cut =floor(sample_size*cutFactor);
 
   % index = 1:cut;
    %% result of squeeze is a column cell array - transpose to be row
    graphvec_group =  transpose(squeeze(mat2cell(graphvec, w,h,c,clones*ones(1,sample_size/clones))));
    labels_group = transpose(squeeze(mat2cell(labels, w2,h2,c2,clones*ones(1,sample_size/clones))));
    assert(rem(sample_size,clones)==0);
    numGroups = numel(labels_group);  
	cellAll  = randperm(numGroups);
	%% Shuffle all groups first
	graphvec_group = graphvec_group(cellAll);
	labels_group = labels_group(cellAll);
	
    groupSlice = floor(numGroups*cutFactor);    
    %% Shuffle the portion of train. leave groups of test untouched.
    graphvec_group = [cellfun(@(x) x(:,:,:,randperm(clones)) ,graphvec_group(1:groupSlice),'UniformOutput',false),graphvec_group(groupSlice+1:end)];
    labels_group = [cellfun(@(x) x(:,:,:,randperm(clones)) , labels_group(1:groupSlice),'UniformOutput',false) ,labels_group(groupSlice+1:end)];
    cell_index= randperm(groupSlice);
    graphvec_group(1:groupSlice) = graphvec_group(cell_index);
    labels_group(1:groupSlice) = labels_group(cell_index);
    
    %%  use cat. cannot specify dim in cell2mat
    graphvec = cat(4,graphvec_group{:});
    labels = cat(4,labels_group{:});
    % already shuffle the data in levels of groups
    %index = randperm(sample_size);

    
    
    
%graphvec = zscore(graphvec,0,4);

%Assume clones is even, then 0.5 must exactly cut through groups.
%% Cut already applied
graphDB.data.input = graphvec(:,:,:,1:cut);
graphDB.data.label = labels(:,:,:,1:cut);

% Independent test data. Useless here.
graphDB.test.input = graphvec(:,:,:,(cut+1:end)); %index
graphDB.test.label = labels(:,:,:,(cut+1:end));
graphDB.meta.indice = 1:cut;
%assure it
graphDB.meta.attrChannel = c;
graphDB.meta.cut = cut;
end