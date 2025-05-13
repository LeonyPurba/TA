% Path gambar
Ori_image_path = '.\Raw_Image\BIRADS_2\bus_0191-r.png';
mask_image_path = 'D:\TA\TA Kak chelli\Mask\BIRADS_2\bus_0191-r_mask.png';

% 1. Load gambar
ori_img = imread(Ori_image_path);
mask_img = imread(mask_image_path);

% 2. Convert ke grayscale jika perlu
if size(ori_img, 3) == 3
    ori_img = rgb2gray(ori_img);
end

if size(mask_img, 3) == 3
    mask_img = rgb2gray(mask_img);
end

% 3. Resize original image ke ukuran masking
ori_resized = imresize(ori_img, size(mask_img), 'bicubic');  % jadi 384x384

% 4. Cari centroid dari area tumor di mask
mask_binary = imbinarize(mask_img);
stats = regionprops(mask_binary, 'Centroid');

% Validasi: pastikan objek terdeteksi
if isempty(stats)
    error('Tidak ditemukan area tumor pada gambar masking.');
end

% Ambil titik centroid (x, y)
centroid = stats(1).Centroid;
cx = round(centroid(1));
cy = round(centroid(2));

% 5. Crop area sekitar centroid untuk memperbesar fokus
zoom_factor = 2;  % Zoom 2x
crop_size = round(size(mask_img) / zoom_factor); % [192 192]
half_crop = floor(crop_size / 2);

% Hitung koordinat cropping
x1 = max(cx - half_crop(2), 1);
y1 = max(cy - half_crop(1), 1);
x2 = min(cx + half_crop(2) - 1, size(ori_resized, 2));
y2 = min(cy + half_crop(1) - 1, size(ori_resized, 1));

cropped_ori = ori_resized(y1:y2, x1:x2);
cropped_mask = mask_binary(y1:y2, x1:x2);

% Resize crop jadi sama ukuran dengan aslinya agar bisa di-overlay
final_ori = imresize(cropped_ori, [size(mask_img, 1), size(mask_img, 2)]);
final_mask = imresize(cropped_mask, [size(mask_img, 1), size(mask_img, 2)]);

% 6. Overlay hasilnya (warna merah untuk mask)
overlay_img = cat(3, final_ori, final_ori, final_ori);  % Convert ke RGB
red = uint8(255);
green = uint8(0);
blue = uint8(0);

% Buat saluran merah transparan di area mask
for i = 1:3
    channel = overlay_img(:, :, i);
    if i == 1
        channel(final_mask) = red;
    else
        channel(final_mask) = channel(final_mask) * 0.3;
    end
    overlay_img(:, :, i) = channel;
end

% 7. Tampilkan hasil
figure;
subplot(1,3,1); imshow(ori_img); title('Original Image');
subplot(1,3,2); imshow(mask_img); title('Mask Image');
subplot(1,3,3); imshow(overlay_img); title('Overlay Result');
