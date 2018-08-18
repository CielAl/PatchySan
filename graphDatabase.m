function graphDB = graphDatabase(graph_name,graphs,input,output,params)
graphDB.meta.name = graph_name;
sample_size = length(input);
index = randperm(sample_size);

% Meta info.
graphDB.meta.graphInput=graphs;

%
graphDB.meta = params;
graphDB.meta.attrDim = 1;



[w ,h,c] = size(input{1});
[w2, h2,c2]=size(output{1});
%standardize

graphvec = zeros(w,h,c,sample_size);
labels =zeros(w2,h2,c2,sample_size);

% no cut
cut =floor(sample_size*0.8);

% Extend to 4-d array, so that it can be used for current CNN architecture directly.
for ii=1:sample_size
     graphvec(:,:,:,ii) = single(input{ii});
     labels(:,:,:,ii) = single(output{ii});
end

graphvec = zscore(graphvec,0,4);

graphDB.data.input = graphvec(:,:,:,index);%(index(1:cut));
graphDB.data.label = labels(:,:,:,index);%(index(1:cut));

% Independent test data. Useless here.
graphDB.test.input = graphvec(:,:,:,index(cut+1:end)); %index
graphDB.test.label = labels(:,:,:,index(cut+1:end));
graphDB.meta.indice = index;
graphDB.meta.channel = c;
graphDB.meta.cut = cut;
end