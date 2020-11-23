clear, clc

% input path
p = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet3';

%% annotate (class 1: background; class 2: axons)

index = 4;

V = volumeRead([p filesep sprintf('V%03d.tif',index)])/65535;
tool = volumeAnnotationToolZ(V,2);

%% save

for i = 1:2
    volumeWrite(uint8(255*tool.LabelMasks(:,:,:,i)),[p filesep sprintf('V%03d_Class%d.tif',index,i)]);
end
fprintf('saved annotations for volume index %d\n', index);