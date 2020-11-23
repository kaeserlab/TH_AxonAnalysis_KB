clear, clc

%% parameters

folderPath = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/DeploymentTest/WT';
maxRadius = 20;

%% measurements

% create output folder for DistMaps if non existent
outFolderPath = [folderPath '_DistMaps'];
if ~exist(outFolderPath,'dir')
    mkdir(outFolderPath);
end

segFolderPath = [folderPath '_Seg'];
l = listfiles(segFolderPath,'.tif');

C = cell(length(l),maxRadius+2);
for index = 1:length(l)
    [~,name] = fileparts(l{index});
    C{index,1} = name;
    
    V = volumeRead(l{index})/255;
    V0 = V > 0;

    skel = Skeleton3DForBalakrishnan(V0);

    V00 = V0 & not(imerode(V0,strel('sphere',1)));
    sV00 = sum(V00(:));

%     DistMap = zeros(size(V,1),size(V,2),size(V,3),maxRadius);
    DistMap = zeros(size(V));
    
    s0 = skel;
    quant = zeros(1,maxRadius);
    for i = 1:maxRadius
        fprintf('processing image %d, radius %d\n', index, i);
        s00 = s0;
        s0 = imdilate(s0,strel('sphere',1));
        s00 = s0 & not(s00);

        maskI = s00 & V00;
%         DistMap(:,:,:,i) = maskI;
        DistMap(maskI) = 50+200*(i-1)/(maxRadius-1);
        
        V00S = V00(s00);
        quant(i) = sum(V00S)/sV00;
        C{index,i+1} = quant(i);
        
%         disp([sum(maskI(:)) sum(V00S)])
        
        V00(s0) = 0;
    end
    C{index,maxRadius+2} = sum(quant);
    
%     tiffwriteimj(255*uint8(DistMap),[outFolderPath filesep name '.tif']);
    volumeWrite(uint8(imgaussfilt3(DistMap,1)),[outFolderPath filesep name '.tif']);
end

%% save results

varNames = cell(1,maxRadius+2);
varNames{1,1} = 'file';
for i = 1:maxRadius
    varNames{1,i+1} = sprintf('r%d',i);
end
varNames{1,maxRadius+2} = 'total';

T = cell2table(C,'VariableNames',varNames);
writetable(T,[folderPath '_TubularAnalysis.xls']);
disp('done')