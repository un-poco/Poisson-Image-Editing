function [neighbors,b] = calcAdjancency( Mask, TargetImgR, TargetImgG, TargetImgB ) 
% 计算稀疏的邻接矩阵A & b的一部分(b2)
%b分为两部分，第一部分是div(定义为b1)，第二部分是已知邻接点的相反数(定义为b2)
[height, width]      = size(Mask);  
[row_mask, col_mask] = find(Mask);  

% length(row_mask)代表有多少个待解像素点
% neighbors = zeros(length(row_mask), length(row_mask));  
neighbors = sparse(length(row_mask), length(row_mask), 0);  
b = zeros(length(row_mask),3); 

%下标转线性索引  
roi_idxs = sub2ind([height, width], row_mask, col_mask);  

%求A
for k = 1:size(row_mask, 1)
    neighbors(k, k) = -4;
    %4 邻接点  
    connected_4 = [row_mask(k), col_mask(k)-1;%left  
                   row_mask(k), col_mask(k)+1;%right  
                   row_mask(k)-1, col_mask(k);%top  
                   row_mask(k)+1, col_mask(k)];%bottom  
  
    ind_neighbors = sub2ind([height, width], connected_4(:, 1), connected_4(:, 2));  
       
    for neighbor_idx = 1: 4 %number of neighbors,  
        adjacent_pixel_idx =  ismembc2(ind_neighbors(neighbor_idx), roi_idxs);  %判断临接点是否是待解的未知点
        % 注：ismembc2是matlab的二分查找函数，i = ismembc2(t, X)，
        % 注：返回 t 在 X 中的位置，其中 X 必须为递增的的数值向量
        if (adjacent_pixel_idx ~= 0)  % 该临接点是待解的未知点
            neighbors(k, adjacent_pixel_idx) = 1;  %若待解的点两者相邻，则赋值为1
        else % 该临接点不是待解的未知点
            %首先判断这个邻接点在Mask中的线性索引位置
            %再求出它在TargetImg中的线性索引位置
            b(k, 1) = b(k, 1) - TargetImgR(connected_4(neighbor_idx, 1),connected_4(neighbor_idx, 2));
            b(k, 2) = b(k, 2) - TargetImgG(connected_4(neighbor_idx, 1),connected_4(neighbor_idx, 2));
            b(k, 3) = b(k, 3) - TargetImgB(connected_4(neighbor_idx, 1),connected_4(neighbor_idx, 2));
        end  
    end   
end  


end

