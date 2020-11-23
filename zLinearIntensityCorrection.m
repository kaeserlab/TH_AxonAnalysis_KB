function W = zLinearIntensityCorrection(V)

y = zeros(size(V,3),1);
for i = 1:size(V,3)
    Vi = V(:,:,i);
%     y(i) = mean(Vi(:));
    y(i) = prctile(Vi(:), 95);
end

x = (1:length(y))';
X = [ones(length(x),1) x];
b = X\y;

W = zeros(size(V));
for i = 1:size(W,3)
    W(:,:,i) = V(:,:,i)-b(2)*x(i);
end

end