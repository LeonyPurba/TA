% === INPUT ===
img = imread('D:\Git Repo\TA\Edge Sharpness\Profile intensity\hasil_zoom_384.png');  % Gambar asli
centroid = [192.91, 191.30];  % Misal data centroid-nya (x, y)
crop_size = 950;        % Ukuran crop persegi (bisa kamu sesuaikan)

% === Proses Crop di Sekitar Centroid ===
half_crop = crop_size / 2;

% Ambil koordinat crop
x_c = round(centroid(1));
y_c = round(centroid(2));
x_min = max(x_c - half_crop, 1);
y_min = max(y_c - half_crop, 1);
x_max = min(x_min + crop_size - 1, size(img,2));
y_max = min(y_min + crop_size - 1, size(img,1));

% Penyesuaian bila crop melewati batas kanan/bawah
if x_max - x_min + 1 < crop_size
    x_min = max(x_max - crop_size + 1, 1);
end
if y_max - y_min + 1 < crop_size
    y_min = max(y_max - crop_size + 1, 1);
end

% Crop dan resize
cropped_img = img(y_min:y_max, x_min:x_max, :);
zoomed_img = imresize(cropped_img, [384 384]);

% === Tampilkan & Simpan Hasil ===
imshow(zoomed_img);
title('Tumor Dipusatkan dan Diperbesar (384x384)');
%imwrite(zoomed_img, 'tumor_dari_centroid1.png');
