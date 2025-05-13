% Path gambar
%Ori_image = '.\Raw_Image\BIRADS_2\bus_0191-r.png';
%Mask_image = '.\Resize\Resized\BIRADS_2\resized_mask_0191-r.png';

Ori_image = 'D:\TA\TA Kak chelli\Dataset yang dipakai\BIRADS_2\more 10\bus_0612-l.png';
Mask_image = 'D:\Git Repo\TA\Edge Sharpness\Profile intensity\Resize\Resized\BIRADS_2\resized_mask_0612-l.png';

% Baca gambar asli dan mask
original = imread(Ori_image);
mask = imread(Mask_image);

% Resize mask ke ukuran gambar asli jika perlu
if size(mask, 1) ~= size(original, 1) || size(mask, 2) ~= size(original, 2)
    mask = imresize(mask, [size(original, 1), size(original, 2)]);
end

% Konversi mask ke grayscale jika RGB
if size(mask, 3) > 1
    mask = rgb2gray(mask);
end

% Binarisasi mask jika belum
if max(mask(:)) > 1
    mask = imbinarize(mask);
else
    mask = logical(mask);
end

% Cari centroid tumor
stats = regionprops(mask, 'Centroid', 'Area');
if isempty(stats)
    error('Mask tidak memiliki objek.');
end

% Gunakan region dengan area terbesar
[~, idx] = max([stats.Area]);
centroid = stats(idx).Centroid;
x_centroid = round(centroid(1));
y_centroid = round(centroid(2));

% Ukuran patch hasil akhir
output_size = 384;
zoom_factor = 2;
half_crop = output_size / (2 * zoom_factor); % = 96

% Hitung koordinat crop di gambar asli
x_min = round(x_centroid - half_crop);
x_max = round(x_centroid + half_crop - 1);
y_min = round(y_centroid - half_crop);
y_max = round(y_centroid + half_crop - 1);

% Koreksi jika crop keluar batas
x_min = max(x_min, 1); x_max = min(x_max, size(original,2));
y_min = max(y_min, 1); y_max = min(y_max, size(original,1));

% Crop dan zoom
cropped = original(y_min:y_max, x_min:x_max, :);
zoomed = imresize(cropped, zoom_factor); % hasilnya 384x384

% Simpan hasil
%imwrite(zoomed, 'hasil_zoom_384A.png');

% Tampilkan
imshow(zoomed);
title('Gambar Asli Diperbesar dengan Tumor di Tengah');
