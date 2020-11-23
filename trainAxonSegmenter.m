%% balance class labels

% input path
p = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet2EqZ';

% output path
q = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet2EqZ_ClassBalanced';

% foreground/background ratio
fbr = 0.5;


nFiles = length(listfiles(p,'_Class1.tif'));
for i = 1:nFiles
    disp(i)
    C1 = volumeRead([p filesep sprintf('V%03d_Class1.tif',i)]) > 0;
    C2 = volumeRead([p filesep sprintf('V%03d_Class2.tif',i)]) > 0;
    n1 = sum(C1(:));
    n2 = sum(C2(:));
    disp([sum(C1(:)) sum(C2(:))])
    if n1 > n2
        f = n2/n1;
        C1 = C1 & rand(size(C1)) < f;
    else
        f = n1/n2;
        C2 = C2 & rand(size(C2)) < f;
    end
    disp([sum(C1(:)) sum(C2(:))])
    
    C2 = C2 & rand(size(C2)) < fbr;
    disp([sum(C1(:)) sum(C2(:))])
    
    copyfile([p filesep sprintf('V%03d.tif',i)],[q filesep sprintf('V%03d.tif',i)]);
    volumeWrite(255*uint8(C1),[q filesep sprintf('V%03d_Class1.tif',i)]);
    volumeWrite(255*uint8(C2),[q filesep sprintf('V%03d_Class2.tif',i)]);
end


%% train segmentation model

% class balanced dataset path
q = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet2EqZ_ClassBalanced';

model = voxelClassifierTrain(q,'sigmas',[2 4],'offsets',[],'logSigmas',[],'sfSigmas',[2],'sfIDs',[1],'pctMaxNVoxelsPerLabel',100);

%% save model

save('/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/model2EqZ.mat','model');
disp('model saved')

%% test on training data

index = 5;
V = volumeRead([q filesep sprintf('V%03d.tif',index)])/65535;
[vlL,vlP] = voxelClassifier(V,model);
tlvt([V vlP(:,:,:,2)])

%% test on data

pathIn = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/DeploymentTest2/Sample';
pathOut = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/DeploymentTest2/Sample_PM';
zStretch = 3.1250;

l = listfiles(pathIn,'.tif');

for i = 1:length(l)
    disp(i)
    V = volumeRead(l{i})/65535;
    V = imresize3(V,[size(V,1) size(V,2) zStretch*size(V,3)]);
    [vlL,vlP] = voxelClassifier(V,model);
    [~,name] = fileparts(l{i});
    p = [pathOut filesep sprintf('%s_2.tif',name)];
    volumeWrite(uint8(255*vlP(:,:,:,2)),p);
    p = [pathOut filesep sprintf('%s_2_ImRs.tif',name)];
    volumeWrite(uint8(255*normalize(V)),p);
end
disp('done')

%% post process prob. maps

% i = 1;
% [~,name] = fileparts(l{i});
% p = sprintf('/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/WT_PM/%s_2.tif',name);
% V = volumeRead(p)/255;
% W = imerode(V,strel('sphere',2));
% p = sprintf('/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/WT_PM/%s_2_PostProc.tif',name);
% volumeWrite(uint8(255*W),p);
% disp('done')