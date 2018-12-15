function [acc,rocpack] = kfold_test(net,graphDB,useGPU,useTest)
% Generalized helper function to test the model.
% -- Input --
% net: the network to test.
% graphDB: the input data, labels, and meta data.
% useGPU: use gpuArray or not.
% useTest
%		 --  0: then test for K-fold CV. The indices test data are the  specified by graphDB.data.set(...) ==2.
%		 --  1: Use the test input/label in graphDB.test, which is defined in readGraphs. 
%		 --  larger than 1: Use training set in K-fold CV to get the training accuracy.
% -- Output --
% acc: the accuracy.

%by default, use GPU
net2=net;
net2.mode = 'test' ;
net2.conserveMemory = false;
 net2.move('gpu');
 if nargin <4
     useTest = 0;
 end
%%  Grab input data
if ~useTest
    graphvec =graphDB.data.input(:,:,:,graphDB.data.set==2);
    labels = graphDB.data.label(:,:,:,graphDB.data.set==2);  
elseif useTest ==1
     graphvec =graphDB.test.input ;
    labels = graphDB.test.label;    
elseif useTest >1
    % train error, if using outside
     [~,~,~,ss] = size(graphDB.data.input);
     graphDB.data.set = ones(1,ss);
     graphDB.data.set((floor(ss*0.8)+1):end) = 2;
    graphvec =graphDB.data.input(:,:,:,graphDB.data.set~=2);
    labels = graphDB.data.label(:,:,:,graphDB.data.set~=2);       
end
[~,~,~,dataSize] =size(graphvec);% length(graphvec);
%% Preparation
%batch_size = dataSize;
%{
[w ,h] = size(test_input{1});
[w2, h2]=size(test_label{1});
graphvec = zeros(w,h,1,batch_size);
labels =zeros(w2,h2,1,batch_size);
for ii=1:batch_size
     graphvec(:,:,:,ii) = test_input{ii};
     labels(:,:,:,ii) = test_label{ii};
end
%}

if nargin>2 || useGPU
    graphvec= gpuArray(single(graphvec));
elseif ~useGPU
    graphvec= (single(graphvec));
end
net2.eval({net.layers(1).inputs{:},graphvec });
%toc;
index = net2.getVarIndex( net.layers(end-2).outputs{:});
result = gather(net2.vars(index).value);

softmax_var =vl_nnsoftmax(result); %vl_nnsoftmax
label_result = squeeze(softmax_var)>=0.5;
label_truth = squeeze(labels)>0;
%compare label_result(1,:) 
fprintf('# of pos:%d, # of neg: %d\n',numel(label_truth(label_truth~=0)),numel(label_truth(label_truth==0)))
 acc = sum(label_result(2,:)==transpose(label_truth))/dataSize;

 % good = 1  --> negative; a little tricky here. Will fix in future
 % so tpf is true 0 here
 trueLabel = 0;
 tpf = 1/sum(label_truth==trueLabel);
 fpf = 1/sum(label_truth==trueLabel);
 rocpack.tpf = tpf;
 rocpack.fpf = fpf;
end