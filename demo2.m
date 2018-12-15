%demo2
%load('F:\CWRU BME Project\PatchySan\data\centroidsSet.mat')
%load('F:\CWRU BME Project\PatchySan\data\edge_attributes.mat')
%load('F:\CWRU BME Project\PatchySan\data\graphs.mat')
%load('F:\CWRU BME Project\PatchySan\data\labels.mat')
%load('F:\CWRU BME Project\PatchySan\data\node_attributes.mat')

import patchysan.*;
params = patchysan.Parameter('fieldSize',5,'sequenceType','wl','featureType',{'node','edge'});
testPatchy = patchysan.PatchySan('params',params);

testPatchy.graphs = graphs;
testPatchy.node_attributes = node_attributes;
testPatchy.edge_attributes = edge_attributes;
testPatchy.class = labels;
tic;
testPatchy.eval();
toc;
beep
[input,output] = testPatchy.fetch();
save input input
save output output
graphDB = graphDatabase('YTMA',1,graphs,input,output,testPatchy.params);
%% Net

%standardize makes it worse
% too many epoch sucks
% [1 5 32] [1 5 32] [1 5 12] . The third layer makes training error 
% significantly lower
% [1 5 32] [1 5 32]  [1 5 12] [1 1 10]  test error down
% FC too thing or to dense will hurt the training acc
% Flatten with relu sucks
% Flatten witn dropout sucks
% 1x1xNx2 without dropout sucks

% ??? increase width?
 miniBatch =32;
 epoch =35;
 hyperparameter = [miniBatch,epoch];
 tic;
 [net]=graphNet3(graphDB.meta);%graphNet(graphDB.meta);
 [acc,list,net,trainList,netList]= kfold_train(hyperparameter,graphDB,@graphNet3,1,[1,1],net);
 toc;
 
 
 %% debug
 params2 = patchysan.Parameter('featureType',{'node','betweenness','edge'});
testPatchy2 = patchysan.PatchySan('params',params);

 testPatchy2.graphs = graphs(1);
testPatchy2.node_attributes = node_attributes(1);
testPatchy2.edge_attributes = edge_attributes(1);
testPatchy2.class = labels;
testPatchy2.eval();
graphDB2 = graphDatabase('YTMA',1,graphs,input,output,testPatchy.params);