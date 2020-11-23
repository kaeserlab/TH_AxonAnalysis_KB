clear, clc

folderPath = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/DeploymentTest/WT';
modelPath = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/model2EqZ.mat';
zStretch = 3.1250;
segErosionRad = 2;

%% load model

load(modelPath); % loads 'model'

%% compute probability maps

l = listfiles(folderPath,'.tif');

% create output folder for PMs if non existent
outFolderPathPM = [folderPath '_PM'];
if ~exist(outFolderPathPM,'dir')
    mkdir(outFolderPathPM);
end

% create output folder for PMs (original size) if non existent
outFolderPathPMOS = [folderPath '_PMOS'];
if ~exist(outFolderPathPMOS,'dir')
    mkdir(outFolderPathPMOS);
end

% create output folder for resized images if non existent
outFolderPathRsIm = [folderPath '_RsIm'];
if ~exist(outFolderPathRsIm,'dir')
    mkdir(outFolderPathRsIm);
end

% compute and save PMs
for i = 1:length(l)
    fprintf('computing prob. map %d of %d\n', i, length(l));
    V = volumeRead(l{i})/65535;
    origSizeV = size(V);
    V = imresize3(V,[size(V,1) size(V,2) zStretch*size(V,3)]);
    V = zLinearIntensityCorrection(V);
    [vlL,vlP] = voxelClassifier(V,model);
    [~,name] = fileparts(l{i});
    p = [outFolderPathPM filesep name '.tif'];
    volumeWrite(uint8(255*vlP(:,:,:,2)),p);
    p = [outFolderPathPMOS filesep name '.tif'];
    volumeWrite(uint16(65535*imresize3(vlP(:,:,:,2),origSizeV)),p);
    
    [~,name] = fileparts(l{i});
    volumeWrite(uint8(255*V),[outFolderPathRsIm filesep name '.tif']);
end

%% segment

m = listfiles(outFolderPathPM,'.tif');

% create output folder for segmentation masks if non existent
outFolderPathSeg = [folderPath '_Seg'];
if ~exist(outFolderPathSeg,'dir')
    mkdir(outFolderPathSeg);
end

% compute segmentation masks
for i = 1:length(l)
    fprintf('computing segm. mask %d of %d\n', i, length(l));
    
    V = volumeRead(m{i})/255;
    V = imgaussfilt3(V,3);
    B = V > 0.5;

    % https://www.mathworks.com/matlabcentral/fileexchange/43400-skeleton3d
%     skel = Skeleton3DForBalakrishnan(B);
%     dskel = imdilate(skel,strel('sphere',axonMinRad+segErosionRad));
% 
%     BW = B | dskel;
    BW = imerode(B,strel('sphere',segErosionRad));

    [~,name] = fileparts(l{i});
    volumeWrite(255*uint8(BW),[outFolderPathSeg filesep name '.tif']);
end
disp('done')
