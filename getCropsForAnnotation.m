%% find minimum volume size for crop

path1 = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/WT';
path2 = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/KO';
zStretch = 3.1250;

l1 = listfiles(path1,'.tif');
l2 = listfiles(path2,'.tif');
ls = {l1,l2};
sizes = [];
for j = 1:length(ls)
    lj = ls{j};
    for i = 1:length(lj)
        disp([j i])
        V = volumeRead(lj{i})/65535;
        V = imresize3(V,[size(V,1) size(V,2) zStretch*size(V,3)]);
        sizes = [sizes; size(V)];
    end
end

minSizes = min(sizes);
disp('min size')
disp(minSizes)

%% generate crops for annotation

% output path
q = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet2EqZ';


halfMinSizeZ = floor(minSizes(3)/2);
count = 0;
for j = 1:length(ls)
    lj = ls{j};
    for i = 1:length(lj)
        disp([j i])
        V = volumeRead(lj{i})/65535;
        V = imresize3(V,[size(V,1) size(V,2) 3.1250*size(V,3)]);
        V = zLinearIntensityCorrection(V);
        
        r0 = round(size(V,1)/2);
        c0 = round(size(V,2)/2);
        r1 = r0-halfMinSizeZ*2+1;
        r2 = r0+halfMinSizeZ*2;
        c1 = c0-halfMinSizeZ*2+1;
        c2 = c0+halfMinSizeZ*2;
        p2 = size(V,3);
        p1 = p2-2*halfMinSizeZ+1;
        W = V(r1:r2,c1:c2,p1:p2);
%         size(W)
%         tlvt(W)
%         return
        count = count+1;
        volumeWrite(uint16(65535*W),[q filesep sprintf('V%03d.tif',count)]);
    end
end