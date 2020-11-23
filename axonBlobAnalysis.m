clear, clc

%% parameters

folderPath = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/DeploymentTest/WT';
sigma = 5;
threshold = 0.75;
pcts = [10,30,50,70,90];

%% blob analysis

% create output folder for blobs if non existent
outFolderPathBlobs = [folderPath '_Blobs'];
if ~exist(outFolderPathBlobs,'dir')
    mkdir(outFolderPathBlobs);
end

pmFolderPath = [folderPath '_PM'];
l = listfiles(pmFolderPath,'.tif');
vs = [];
for index = 1:length(l)
    fprintf('processing volume %d of %d\n', index, length(l));
    V = volumeRead(l{index})/255;
    
    sV = imgaussfilt3(V,sigma);
    tV = sV > threshold;
    
    [~,name] = fileparts(l{index});
    volumeWrite(255*uint8(tV),[outFolderPathBlobs filesep name '.tif']);
    
    vTable = regionprops3(tV,'Volume');
    writetable(vTable,[outFolderPathBlobs filesep name '.csv']);
    
    v = table2array(vTable);

    vs = [vs; v];
end

%%

quants = zeros(1,length(pcts));
varNames = cell(1,length(pcts));
for i = 1:length(pcts)
    quants(i) = prctile(vs,pcts(i));
    varNames{i} = sprintf('pct%d',pcts(i));
end

T = array2table(quants,'VariableNames',varNames);
writetable(T,[folderPath '_BlobAnalysis.csv']);
disp('done')