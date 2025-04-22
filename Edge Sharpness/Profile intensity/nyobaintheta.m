% --- Step 1: Load image dan mask
original_img = imread('D:\TA\Edge Sharpness\Profile intensity\Dataset yang dipakai\BIRADS_2\bus_0191-r.png'); % <- sesuaikan
if size(original_img, 3) == 3
    original_gray = rgb2gray(original_img);
else
    original_gray = original_img;
end

mask = imbinarize(original_gray);  % atau load segmentasi lesi kamu

% --- Step 2: Deteksi centroid
stats = regionprops(mask, 'Centroid');
centroid = stats.Centroid;
x_center = centroid(1);
y_center = centroid(2);

% --- Step 3: Inisialisasi parameter garis radial
num_lines = 12; % misal tiap 30 derajat
theta = linspace(0, 2*pi, num_lines + 1);
theta(end) = [];  % hapus titik ganda di akhir

r_max = 100;
%r_max = max(size(original_gray));  % panjang maksimum garis
profiles = cell(1, num_lines);  % simpan hasil improfile

% --- Step 4: Plot semua garis di gambar asli
figure;
imshow(original_gray, []);
hold on;
for i = 1:num_lines
    x_end = x_center + r_max * cos(theta(i));
    y_end = y_center + r_max * sin(theta(i));

    % Tampilkan garis di gambar
    plot([x_center, x_end], [y_center, y_end], 'g');

    % Ambil intensitas dengan improfile
    profiles{i} = improfile(original_gray, [x_center x_end], [y_center y_end]);
end
plot(x_center, y_center, 'ro', 'MarkerFaceColor', 'r');  % plot titik pusat

% --- Step 5: Tampilkan semua kurva intensitas
figure;
hold on;
for i = 1:num_lines
    if ~isempty(profiles{i})
        plot(profiles{i});
    end
end
title('Profil Intensitas Sepanjang Garis Radial');
xlabel('Jarak Sepanjang Garis');
ylabel('Intensitas');
grid on;
