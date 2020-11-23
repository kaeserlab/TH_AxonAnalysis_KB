%% paramteres

folderPath = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/DeploymentTest/KO_Blobs';

%% aggregate volumes

l = listfilesexcluding(folderPath,'.csv','_Agg.csv');

volList = cell(1,length(l));
nameList = cell(1,length(l));
maxLen = 0;
for i = 1:length(l)
    [~,name] = fileparts(l{i});
    name = strrep(name,'-','_');
    T = readtable(l{i});
    A = table2array(T);
    volList{i} = A;
    nameList{i} = name;
    maxLen = max(maxLen, length(A));
end

C = cell(maxLen,length(l));
for j = 1:length(l)
    A = volList{j};
    for i = 1:length(A)
        C{i,j} = A(i);
    end
end

T = cell2table(C,'VariableNames',nameList);

writetable(T,[folderPath filesep 'Volumes_Agg.xls']);