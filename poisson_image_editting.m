% 清理环境
close all;
clear;
clc;

%添加图像路径
addpath img

% 用户设定
% 设定源图、目标图像、mask的路径，设定目标图像paste区域的起始坐标点
% TargetImgPath = 'poolTarget.jpg';
% SourceImgPath = 'bear.jpg';
% SourceMaskPath = 'bearMask.jpg';
TargetImgPath = 'femaleTarget.png';
SourceImgPath = 'femaleSource.png';
SourceMaskPath = 'femaleMask1.png';

% 设定要将source中轮廓内的图像粘贴到target图中具体哪个位置
% position_in_target = [10, 225];%狗熊
position_in_target = [42, 220];%蒙娜丽莎  

% 读入三张图片
TargetImg = imread(TargetImgPath);
SourceImg = imread(SourceImgPath);
SourceMask = im2bw(imread(SourceMaskPath));

% 获取mask的二值图的对象轮廓
[SrcBoundary,L] = bwboundaries(SourceMask, 8);

% 绘制裁剪的轮廓
figure, imshow(SourceImg), axis image  
hold on  
for k = 1:length(SrcBoundary)  
    boundary = SrcBoundary{k};  
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2)  
end  
title('Source image intended area for cutting from');  
 

% 获取目标图像大小
[TargetRows, TargetCols, ~] = size(TargetImg);  
% SourceMask中非零的部分
[row, col] = find(SourceMask);

% mask框在source图中的大小
start_pos = [min(col), min(row)];  
end_pos   = [max(col), max(row)];  
frame_size  = end_pos - start_pos;  

% 判断是否出现越界，若出现越界，则调整position_in_target
if (frame_size(1) + position_in_target(1) > TargetCols)  
    position_in_target(1) = TargetCols - frame_size(1);  
end  
  
if (frame_size(2) + position_in_target(2) > TargetRows)  
    position_in_target(2) = TargetRows - frame_size(2);  
end  

% 构建一个与Target图相等的新的mask
MaskTarget = zeros(TargetRows, TargetCols);  

% ind = sub2ind(sz,row,col) 针对大小为 sz 的矩阵返回由 row 和 col 指定的行列下标的对应线性索引 ind。
% 此处，sz 是包含两个元素的向量，其中 sz(1) 指定行数，sz(2) 指定列数。
% 利用线性索引，把TargetImg中对应位置的值赋值为1。
MaskTarget( sub2ind( [TargetRows, TargetCols], row - start_pos(2) + position_in_target(2), ...  
col - start_pos(1) + position_in_target(1) ) ) = 1; 

% 获取二值图像中对象的轮廓，把这个轮廓在TargetImg上绘制出来
TargBoundry = bwboundaries(MaskTarget, 8);  
figure, imshow(TargetImg), axis image  
hold on  
for k = 1:length(TargBoundry)  
    boundary = TargBoundry{k};  
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 1)  
end  
title('Target Image with intended place for pasting Source');  

templt = [0 1 0; 1 -4 1; 0 1 0];  % 拉普拉斯算子
LaplacianSource = imfilter(double(SourceImg), templt, 'replicate');  % 对源图像执行拉普拉斯算子
VR = LaplacianSource(:, :, 1);  
VG = LaplacianSource(:, :, 2);  
VB = LaplacianSource(:, :, 3);  

% 取出目标图像的R、G、B
TargetImgR = double(TargetImg(:, :, 1));  
TargetImgG = double(TargetImg(:, :, 2));  
TargetImgB = double(TargetImg(:, :, 3));  

% 给mask区域赋值，R,G,B需要分开赋值
% 注意MaskTarget是double类型，SourceMask已经是logical类型
TargetImgR(logical(MaskTarget(:))) = VR(SourceMask(:));  
TargetImgG(logical(MaskTarget(:))) = VG(SourceMask(:));  
TargetImgB(logical(MaskTarget(:))) = VB(SourceMask(:));  

% 合并3通道，形成新的图像
TargetImgNew = cat(3, TargetImgR, TargetImgG, TargetImgB);  
% 绘制新的图像
figure, imagesc(uint8(TargetImgNew)), axis image, title('Target image with laplacian of source inserted');  

% 计算邻接矩阵A和b2
[A,b] = calcAdjancency( MaskTarget, TargetImgR, TargetImgG, TargetImgB );  

% 计算b
b1 = b(:,1) + VR(SourceMask(:));
b2 = b(:,2) + VG(SourceMask(:));
b3 = b(:,3) + VB(SourceMask(:));

% 求解Ax = b中的x
RX = cgs(A,b1,1e-4,100);
GX = cgs(A,b2,1e-4,100);
BX = cgs(A,b3,1e-4,100);
% RX = A\b1;
% GX = A\b2;
% BX = A\b3;

% 取出目标图像的R、G、B
FinalImgR = double(TargetImg(:, :, 1));  
FinalImgG = double(TargetImg(:, :, 2));  
FinalImgB = double(TargetImg(:, :, 3));  

% 给mask区域赋值，R,G,B需要分开赋值
% 注意MaskTarget是double类型，SourceMask已经是logical类型
FinalImgR(logical(MaskTarget(:))) = RX;  
FinalImgG(logical(MaskTarget(:))) = GX;  
FinalImgB(logical(MaskTarget(:))) = BX;  

% 合并RGB三分量
ResultImg = cat(3, FinalImgR, FinalImgG, FinalImgB);  

% 显示最终融合效果
figure;  
imshow(uint8(ResultImg));  

