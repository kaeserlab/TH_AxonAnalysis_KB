paths = {};
paths{1} = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet';
paths{2} = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet3';

%%

% output path
pathAggSet = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/TrainSet_Agg';

count = 0;
for i = 1:length(paths)
    l = listfiles(paths{i},'_Class1.tif');
    for j = 1:length(l)
        count = count+1;
        disp([count i j])
        
        p = [paths{i} filesep sprintf('V%03d.tif',j)];
        q = [pathAggSet filesep sprintf('V%03d.tif',count)];
        copyfile(p,q);
        
        p = [paths{i} filesep sprintf('V%03d_Class1.tif',j)];
        q = [pathAggSet filesep sprintf('V%03d_Class1.tif',count)];
        copyfile(p,q);
        
        p = [paths{i} filesep sprintf('V%03d_Class2.tif',j)];
        q = [pathAggSet filesep sprintf('V%03d_Class2.tif',count)];
        copyfile(p,q);
    end
end

disp(count)