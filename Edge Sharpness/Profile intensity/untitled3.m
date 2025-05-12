% Kode untuk zoom area tumor berdasarkan mask pada gambar asli
% Load gambar
mask = imread('D:\TA\TA Kak chelli\Mask\BIRADS_2\bus_0191-r_mask.png');
gambar_asli = imread('D:\TA\TA Kak chelli\Dataset yang dipakai\BIRADS_2\bus_0191-r.png');

% Membuat gambar mask menjadi grayscale jika belum
if size(mask, 3) > 1  % Jika gambar berwarna, konversi ke grayscale dahulu
    mask_gray = rgb2gray(mask);
else
    mask_gray = mask;
end

% Konversi gambar asli ke grayscale jika perlu
if size(gambar_asli, 3) > 1
    gambar_asli_gray = rgb2gray(gambar_asli);
else
    gambar_asli_gray = gambar_asli;
end

% LANGKAH 1: PROSES PADA MASK
% Terapkan Canny edge detector pada mask untuk mendapatkan tepi yang lebih jelas
edge_mask = edge(mask_gray, 'Canny', 'nothinning');

% Isi lubang yang mungkin terdapat pada hasil edge detection
edge_mask_filled = imfill(edge_mask, 'holes');

% Bersihkan noise kecil dengan operasi morfologi
se = strel('disk', 2);
edge_mask_cleaned = imclose(edge_mask_filled, se);
edge_mask_cleaned = imopen(edge_mask_cleaned, se);

% Deteksi boundaries dari hasil Canny edge detection pada mask
[B, L, N] = bwboundaries(edge_mask_cleaned, 'noholes');

% Jika ada lebih dari satu objek, pilih yang terbesar
if length(B) > 1
    areas = cellfun(@length, B);
    [~, idx] = max(areas);
    boundary = B{idx};
elseif length(B) >= 1
    boundary = B{1};
else
    % Jika Canny gagal menemukan objek, kembali ke metode thresholding
    threshold = graythresh(mask_gray);
    mask_binary = imbinarize(mask_gray, threshold);
    [B, ~, ~] = bwboundaries(mask_binary, 'noholes');
    if length(B) >= 1
        areas = cellfun(@length, B);
        [~, idx] = max(areas);
        boundary = B{idx};
    else
        error('Tidak dapat mendeteksi tumor pada mask');
    end
end

% Ekstrak boundary koordinat
boundary_x = boundary(:, 1);
boundary_y = boundary(:, 2);

% LANGKAH 2: PROSES PADA GAMBAR ASLI
% Buat mask baru dari boundary yang didapatkan pada gambar mask
tumor_mask = false(size(mask_gray));
for i = 1:length(boundary_x)
    tumor_mask(boundary_x(i), boundary_y(i)) = true;
end

% Isi area boundary untuk mendapatkan mask penuh
tumor_mask_filled = imfill(tumor_mask, 'holes');

% Buat mask untuk gambar asli (dengan ukuran yang mungkin berbeda)
if size(tumor_mask_filled) ~= size(gambar_asli_gray)
    % Jika ukuran berbeda, resize mask
    tumor_mask_resized = imresize(tumor_mask_filled, size(gambar_asli_gray));
else
    tumor_mask_resized = tumor_mask_filled;
end

% Terapkan mask pada gambar asli untuk mendapatkan hanya area tumor
tumor_region_gray = gambar_asli_gray .* uint8(tumor_mask_resized);

% Jika gambar asli berwarna, terapkan mask pada setiap channel
if size(gambar_asli, 3) > 1
    tumor_region = gambar_asli;
    for channel = 1:size(gambar_asli, 3)
        tumor_region(:,:,channel) = gambar_asli(:,:,channel) .* uint8(tumor_mask_resized);
    end
else
    tumor_region = tumor_region_gray;
end

% LANGKAH 3: HITUNG BOUNDING BOX DAN PADDING
% =========================================
% Hitung bounding box berdasarkan boundary dari mask
min_x = min(boundary_x);
min_y = min(boundary_y);
max_x = max(boundary_x);
max_y = max(boundary_y);
width = max_y - min_y;
height = max_x - min_x;

% Tentukan padding untuk cropping
padding_factor = 1.5; % Faktor padding
padding_x = round(height * (padding_factor - 1) / 2);
padding_y = round(width * (padding_factor - 1) / 2);

% Hitung koordinat untuk cropping pada gambar asli dengan padding
crop_min_x = max(1, min_x - padding_x);
crop_min_y = max(1, min_y - padding_y);
crop_max_x = min(size(gambar_asli, 1), max_x + padding_x);
crop_max_y = min(size(gambar_asli, 2), max_y + padding_y);

% Hitung dimensi cropping
crop_width = crop_max_y - crop_min_y;
crop_height = crop_max_x - crop_min_x;

% LANGKAH 4: PROSES ZOOMING/CROPPING
% =================================
% Cropping pada gambar asli berdasarkan bounding box
cropped_region = [crop_min_y, crop_min_x, crop_width, crop_height];
zoomed_image = imcrop(gambar_asli, cropped_region);

% Hitung pusat tumor
x_center = (min_x + max_x) / 2;
y_center = (min_y + max_y) / 2;

% LANGKAH 5: DETEKSI TUMOR PADA GAMBAR ASLI DENGAN MENGGUNAKAN EDGE DETECTION
% =========================================================================
% Terapkan Canny edge detection pada gambar asli
edge_asli = edge(gambar_asli_gray, 'Canny', 'nothinning');

% Gunakan mask tumor untuk mendapatkan edge yang hanya pada area tumor
edge_tumor = edge_asli .* tumor_mask_resized;

% Terapkan boundary yang didapatkan pada gambar asli
tumor_boundary_asli = zeros(size(gambar_asli_gray));
for i = 1:length(boundary_x)
    if boundary_x(i) <= size(tumor_boundary_asli, 1) && boundary_y(i) <= size(tumor_boundary_asli, 2)
        tumor_boundary_asli(boundary_x(i), boundary_y(i)) = 1;
    end
end

% LANGKAH 6: TAMPILKAN HASIL
% =========================
% Buat figure baru untuk hasil deteksi
figure('Name', 'Hasil Deteksi Tumor pada Gambar Asli', 'Position', [100, 100, 1200, 600]);

% Panel 1: Tampilkan proses pada mask
subplot(2, 4, 1);
imshow(mask_gray);
title('Mask Original');

subplot(2, 4, 2);
imshow(edge_mask);
title('Canny Edge Detection pada Mask');

subplot(2, 4, 3);
imshow(edge_mask_cleaned);
hold on;
plot(boundary_y, boundary_x, 'r', 'LineWidth', 2);
title('Edge dengan Boundary Tumor pada Mask');
hold off;

subplot(2, 4, 4);
imshow(tumor_mask_filled);
title('Mask Area Tumor');

% Panel 2: Tampilkan proses pada gambar asli
subplot(2, 4, 5);
imshow(gambar_asli);
hold on;
% Gambar boundary pada gambar asli
plot(boundary_y, boundary_x, 'g', 'LineWidth', 1);
% Gambar bounding box pada gambar asli
rectangle('Position', cropped_region, 'EdgeColor', 'r', 'LineWidth', 2);
title('Gambar Asli dengan ROI');
hold off;

subplot(2, 4, 6);
imshow(tumor_region);
title('Area Tumor pada Gambar Asli');

subplot(2, 4, 7);
imshow(edge_tumor);
title('Edge Tumor pada Gambar Asli');

subplot(2, 4, 8);
imshow(zoomed_image);
title('Hasil Zoom pada Area Tumor');

% Buat figure untuk perbandingan
figure('Name', 'Perbandingan Hasil', 'Position', [200, 200, 800, 400]);

% Tampilkan perbandingan antara mask original dan hasil zoom
subplot(1, 2, 1);
imshow(mask);
title('Mask Original');

subplot(1, 2, 2);
imshow(zoomed_image);
title('Hasil Zoom pada Area Tumor');

% Buat figure khusus untuk hasil zoom
figure('Name', 'Hasil Zoom Final', 'Position', [300, 300, 500, 500]);
set(gcf, 'Color', 'w'); % Set background putih

ax_zoom = axes('Position', [0, 0, 1, 1]);
imshow(zoomed_image, 'Parent', ax_zoom);

% Menerapkan aspek ratio untuk figure zoom
[zoom_height, zoom_width, ~] = size(zoomed_image);
aspect_ratio = zoom_width / zoom_height;

% Sesuaikan ukuran figure berdasarkan aspek ratio
if aspect_ratio > 1
    new_height = 400;
    new_width = round(new_height * aspect_ratio);
else
    new_width = 400;
    new_height = round(new_width / aspect_ratio);
end

set(gcf, 'Position', [300, 300, new_width, new_height]);
axis equal tight;
title('Hasil Zoom Akhir');

% Simpan hasil zoom
imwrite(zoomed_image, 'tumor_zoom_final.png');

% Buat figure tambahan untuk memperlihatkan detail edge pada hasil zoom
figure('Name', 'Edge pada Hasil Zoom', 'Position', [400, 400, 500, 500]);
zoomed_image_gray = rgb2gray(zoomed_image);
edge_zoomed = edge(zoomed_image_gray, 'Canny', 'nothinning');
imshow(edge_zoomed);
title('Edge Detection pada Hasil Zoom');

% Tampilkan informasi
fprintf('\n===== HASIL DETEKSI TUMOR =====\n');
fprintf('Boundary tumor terdeteksi dengan %d titik.\n', length(boundary));
fprintf('Area tumor: Min X=%d, Min Y=%d, Width=%d, Height=%d\n', min_x, min_y, width, height);
fprintf('ROI pada gambar asli: X=%d, Y=%d, Width=%d, Height=%d\n', crop_min_y, crop_min_x, crop_width, crop_height);
fprintf('Pusat tumor berada pada koordinat X=%d, Y=%d\n', round(x_center), round(y_center));
fprintf('Hasil zoom telah disimpan sebagai "tumor_zoom_final.png".\n');
fprintf('===============================\n');