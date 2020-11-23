%% parameters

filePathWT = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/Scratch/WT_TubularAnalysis.xls';
filePathKO = '/home/mc457/files/CellBiology/IDAC/Marcelo/Kaeser/Balakrishnan/Scratch/KO_TubularAnalysis.xls';

%% plot

filePaths = {filePathWT,filePathKO};
quantArrays = cell(1,2);

for index = 1:2
    T = readtable(filePaths{index});
    C = table2cell(T);
    C = C(:,2:end-1);
    A = zeros(size(C));
    for i = 1:size(C,1)
        for j = 1:size(C,2)
            A(i,j) = C{i,j};
        end
    end
    quantArrays{index} = A;
end

figure, hold on
% colors = {'g','r'};
colors = {[0 0.5 0], [0.5 0 0]};
averages = zeros(2,size(C,2));
for index = 1:2
    for i = 1:size(quantArrays{index},1)
        averages(index,:) = averages(index,:)+quantArrays{index}(i,:);
        plot(quantArrays{index}(i,:),'Color',colors{index},'LineWidth',1);
    end
    averages(index,:) = averages(index,:)/size(quantArrays{index},1);
end
colors = {[0 1 0], [1 0 0]};
for index = 1:2
    plot(averages(index,:),'Color',colors{index},'LineWidth',2);
end
hold off
xlabel('distance from medial axis')
ylabel('proportion of surface area')
title('green: WT | red: KO')