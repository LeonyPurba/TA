% === Cek Centroid dari Citra ===
% Pastikan input image adalah citra biner (misalnya hasil segmentasi/mask)

% Baca gambar (ganti 'mask.png' dengan path file Anda)
mask = imread('D:\TA\TA Kak chelli\Mask\BIRADS_2\bus_0612-l_mask.png');

% Jika gambar RGB, konversi ke grayscale
if size(mask,3) == 3
    mask = rgb2gray(mask);
end

% Threshold jika bukan biner
if ~islogical(mask)
    mask = imbinarize(mask);
end

% Hitung properti region
stats = regionprops(mask, 'Centroid', 'Area');

% Ambil centroid dari area terbesar (jika ada beberapa region)
if length(stats) > 1
    [~, idx] = max([stats.Area]);
    centroid = stats(idx).Centroid;
else
    centroid = stats.Centroid;
end

% Tampilkan gambar dan centroid
imshow(mask);
hold on;
plot(centroid(1), centroid(2), 'r+', 'MarkerSize', 15, 'LineWidth', 2);
title(sprintf('Centroid: (%.2f, %.2f)', centroid(1), centroid(2)));
hold off;

% Tampilkan nilai koordinat centroid di command window
fprintf('Centroid koordinat: X = %.2f, Y = %.2f\n', centroid(1), centroid(2));
