function model = voxelClassifierTrain(trainPath,varargin)
% model = voxelClassifierTrain(trainPath,varargin)
% trains a single-layer random forest model for volume segmentation (voxel classification)
% use the 'voxelClassifier' function to apply the model
% see ...IDAC_git/common/imageSegmentation/VoxelClassifier/ReadMe.txt for more details
%
% trainPath
% path to folder where volumes and labes are;
% volumes/labels in such folder should follow a particular structure,
% which is observed when creating annotations using VolumeAnnotationBot:
% https://www.mathworks.com/matlabcentral/fileexchange/64718-volumeannotationbot
%
% ----- varargin ----- 
%
% vResizeFactor, default 1
% volume resize factor;
% a factor smaller than 1 lowers computational cost and memory requirements,
% at the expense of accuracy; but often this is a good trade-off
%
% zStretch, default 1
% 3D volumes typically have the z dimension of the voxel size different
% from the x and y dimensions;
% this factor corresponds to how much the volume should be stretched in z
% so that the voxel dimensions are the same in x, y, and z;
% the factor is computed as follows:
% zStretch = "voxel size in z" divided by "voxel size in x or y"
%
% sigmas, default 2
% volume features are simply derivatives (up to second order) in different scales;
% this parameter specifies such scales; details in volumeFeaturesP.m;
% use brackets for multiple sigmas (e.g. [1 2]);
% set to [] to ignore derivative features
%
% offsets, default platonicSolidVertices(3,2)
% offset features; see volumeFeaturesP.m and platonicSolidVertices.m for details;
% set to [] to ignore offeset features
%
% osSigma, default 2
% sigma for offset features; only one sigma allowed
%
% logSigmas, default [2 4]
% sigmas for laplacian of gaussian features; see volumeFeaturesP.m for details;
% use brackets for multiple sigmas;
% set to [] to ignore log features
%
% sfSigmas, default [1 2]
% sigmas for steerable filter features; use brackets for multiple sigmas;
% set to [] to ignore steerable filter features
%
% sfIDs, default 2
% steerable filter types; 1: curve, 2: surface, 3: volume/edge;
% use brackets for multiple types (e.g. [1 2])
%
% nTrees, default 20
% number of decision trees in the random forest ensemble
%
% minLeafSize, default 60
% minimum number of observations per tree leaf
%
% pctMaxNVoxelsPerLabel, default 1
% percentage of max number of voxels per label (w.r.t. num of voxels in volume);
% this puts a cap on the number of training samples and can improve training speed
%
% ----- output ----- 
%
% model
% structure containing model parameters
%
% ...
%
% Marcelo Cicconet, Dec 11 2017

%% parameters

ip = inputParser;
ip.addParameter('vResizeFactor',1);
ip.addParameter('zStretch',1);
ip.addParameter('sigmas',2);
ip.addParameter('offsets',platonicSolidVertices(3,2));
ip.addParameter('osSigma',2);
ip.addParameter('logSigmas',[2 4]);
ip.addParameter('sfSigmas',[1 2]);
ip.addParameter('sfIDs',2);
ip.addParameter('nTrees',20);
ip.addParameter('minLeafSize',60);
ip.addParameter('pctMaxNVoxelsPerLabel',1);
ip.parse(varargin{:});
p = ip.Results;

vResizeFactor = p.vResizeFactor;
zStretch = p.zStretch;
sigmas = p.sigmas;
offsets = p.offsets;
osSigma = p.osSigma;
logSigmas = p.logSigmas;
sfSigmas = p.sfSigmas;
sfIDs = p.sfIDs;
nTrees = p.nTrees;
minLeafSize = p.minLeafSize;
pctMaxNVoxelsPerLabel = p.pctMaxNVoxelsPerLabel;

%% read volumes/labels

[volumeList,labelList,labels] = vcParseLabelFolder(trainPath,vResizeFactor,zStretch);
nLabels = length(labels);
nVolumes = length(volumeList);

%% training samples cap

if pctMaxNVoxelsPerLabel < 100
    maxNVoxelsPerLabel = (pctMaxNVoxelsPerLabel/100)*numel(volumeList{1});
    for vlIndex = 1:nVolumes
        L = labelList{vlIndex};
        for labelIndex = 1:nLabels
            LLI = L == labelIndex;
            nVoxels = sum(LLI(:));
            rI = rand(size(L)) < maxNVoxelsPerLabel/nVoxels;
            L(LLI) = 0;
            LLI2 = rI & (LLI > 0);
            L(LLI2) = labelIndex;
        end
        labelList{vlIndex} = L;
    end
end

%% construct train matrix

flatFeats = cell(1,nVolumes);
flatLbls = cell(1,nVolumes);
nSamples = cell(1,nVolumes);
if nVolumes > 1
    parfor vlIndex = 1:nVolumes
        fprintf('computing features from example %d of %d\n', vlIndex, nVolumes);
        F = volumeFeaturesP(volumeList{vlIndex},sigmas,offsets,osSigma,logSigmas,sfSigmas,sfIDs,false);
        L = labelList{vlIndex};
        [flatFeat,flatLbl] = flattenVolFeatAndLab(F,L);
        flatFeats{vlIndex} = flatFeat;
        flatLbls{vlIndex} = flatLbl;
        nSamples{vlIndex} = length(flatLbl);
    end
else
    for vlIndex = 1:nVolumes
        fprintf('computing features from example %d of %d\n', vlIndex, nVolumes);
        F = volumeFeaturesP(volumeList{vlIndex},sigmas,offsets,osSigma,logSigmas,sfSigmas,sfIDs,true);
        L = labelList{vlIndex};
        [flatFeat,flatLbl] = flattenVolFeatAndLab(F,L);
        flatFeats{vlIndex} = flatFeat;
        flatLbls{vlIndex} = flatLbl;
        nSamples{vlIndex} = length(flatLbl);
    end
end
startEndIndices = zeros(nVolumes,2);
cumNSamples = 0;
for vlIndex = 1:nVolumes
    startEndIndices(vlIndex,1) = cumNSamples+1;
    cumNSamples = cumNSamples+nSamples{vlIndex};
    startEndIndices(vlIndex,2) = cumNSamples;
end
ft = zeros(cumNSamples,size(flatFeats{1},2));
lb = zeros(cumNSamples,1);
for vlIndex = 1:nVolumes
    rowRange = startEndIndices(vlIndex,1):startEndIndices(vlIndex,2);
    ft(rowRange,:) = flatFeats{vlIndex};
    lb(rowRange) = flatLbls{vlIndex};
end
[~,featNames] = volumeFeaturesP([],sigmas,offsets,osSigma,logSigmas,sfSigmas,sfIDs,false);

%% train

fprintf('training...'); tic
[treeBag,featImp,oobPredError] = rfTrain(ft,lb,nTrees,minLeafSize);
figureQSS
subplot(1,2,1), barh(featImp), set(gca,'yticklabel',featNames'), set(gca,'YTick',1:length(featNames)), title('feature importance')
subplot(1,2,2), plot(oobPredError), title('out-of-bag classification error')
fprintf('training time: %f s\n', toc);

%% save model

model.vResizeFactor = vResizeFactor;
model.zStretch = zStretch;
model.sigmas = sigmas;
model.offsets = offsets;
model.osSigma = osSigma;
model.logSigmas = logSigmas;
model.sfSigmas = sfSigmas;
model.sfIDs = sfIDs;
model.treeBag = treeBag;

end