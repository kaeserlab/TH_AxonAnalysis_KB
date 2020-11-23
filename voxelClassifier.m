function [vlL,vlP] = voxelClassifier(V,model,varargin)
% [vlL,vlP] = voxelClassifier(V,model,varargin)
% applies model trained with 'voxelClassifierTrain' to segment a volume (3D image)
% see ...IDAC_git/common/imageSegmentation/VoxelClassifier/ReadMe.txt for more details
%
% V
% volume to be segmented
% (should be loaded with volumeRead, to keep format compatible with that used by voxelClassifierTrain)
%
% model
% single-layer random forest model, trained with 'voxelClassifierTrain'
%
% ----- varargin -----
%
% nSubsets, default 100
% the set of voxels to be classified is split in this many subsets;
% if nSubsets > 1, the subsets are classified using 'parfor' with
% the currently-opened parallel pool (or a new default one if none is open);
% see vlClassify.m for details;
% it's recommended to set nSubsets > the number of cores in the parallel pool;
% this can make classification substantially faster than when a
% single thread is used (nSubsets = 1).
%
% ----- output -----
%
% vlL
% a volume of the same size as the input V, where each voxel has the index of the class
%
% vlP
% probability maps: vlP(:,:,:,i) is a volume of the same size as the input V,
% where each voxel has the probability that such voxel belongs to class 'i'
%
% ...
%
% Marcelo Cicconet, Dec 11 2017

%% parameters

ip = inputParser;
ip.addParameter('nSubsets',100);
ip.parse(varargin{:});
p = ip.Results;

nSubsets = p.nSubsets;

%% read volume/model

sizeV = size(V);
V = imresize3(V,[round(model.vResizeFactor*size(V,1)),...
                 round(model.vResizeFactor*size(V,2)),...
                 round(model.vResizeFactor*model.zStretch*size(V,3))]);

%% compute features

tic, disp('volumeFeatures')
F = volumeFeaturesP(V,model.sigmas,model.offsets,model.osSigma,model.logSigmas,model.sfSigmas,model.sfIDs,true);
toc

%% classify

tic, disp('vlClassify')
[vlL,classProbs] = vlClassify(F,model.treeBag,nSubsets);
vlL = imresize3(vlL,sizeV,'nearest');
vlP = zeros(sizeV(1),sizeV(2),sizeV(3),size(classProbs,4));
for i = 1:size(classProbs,4)
    vlP(:,:,:,i) = imresize3(classProbs(:,:,:,i),sizeV);
end
toc

end