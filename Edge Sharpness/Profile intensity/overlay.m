% Load gambar grayscale
%I = imread('D:\TA\Edge Sharpness\Profile intensity\Mask\BIRADS_2\bus_0191-r_mask.png'); 
%I = imread('D:\TA\Edge Sharpness\Profile intensity\Mask\BIRADS_2\bus_0592-l_mask.png'); 
I = imread('D:\TA\Edge Sharpness\Profile intensity\Dataset yang dipakai\BIRADS_2\bus_0191-r.png');  % pastikan grayscale


% Tentukan pusat kontur (dari hasil edge detection/mask)
xscaled_center = 142;  % ganti sesuai data kamu
yscaled_center = 93;

% Parameter
r = 60;  % panjang garis profil
num_lines = 30;
theta = linspace(0, 2*pi, num_lines + 1);  % +1 untuk 2pi

% Inisialisasi penyimpanan intensitas
profiles = cell(1, num_lines);

% Tampilkan gambar
figure(19);
imshow(I); hold on;
title('Overlay Garis Profil Intensitas Radial');
plot(xscaled_center, yscaled_center, 'ro', 'MarkerSize', 8, 'LineWidth', 2); % titik pusat

% Loop untuk setiap garis
for i = 1:num_lines
    % Hitung titik akhir garis
    x_end = xscaled_center + r * cos(theta(i));
    y_end = yscaled_center + r * sin(theta(i));
    
    % Gambar garis di gambar
    line([xscaled_center x_end], [yscaled_center y_end], 'Color', 'g', 'LineWidth', 0.5);
    
    % Ambil profil intensitas dari gambar asli sepanjang garis
    profiles{i} = improfile(I, [xscaled_center x_end], [yscaled_center y_end]);
end

hold off;

% Plot semua profil intensitas dari 180 garis
figure;
hold on;
for i = 1:num_lines
    if ~isempty(profiles{i})
        plot(profiles{i}, 'Color', [0, 0.5, 1, 0.2]);  % warna biru transparan
    end
end
hold off;

xlabel('Jarak Sepanjang Garis');
ylabel('Intensitas');
title('Semua Profil Intensitas');
grid on;

% Contoh: tampilkan 1 profil intensitas
figure(20);
subplot(3,1,1);
plot(profiles{28}, 'b', 'LineWidth', 2);
axis([0 60 20 100])
subplot(3,1,2);
plot(profiles{29}, 'b', 'LineWidth', 2);
axis([0 60 20 100])
subplot(3,1,3);
plot(profiles{3}, 'b', 'LineWidth', 2);
axis([0 60 20 100])
xlabel('Jarak Sepanjang Garis');
ylabel('Intensitas');
title('Contoh Profil Intensitas (garis ke-1)');

% Gabungkan semua nilai intensitas ke dalam satu array
%all_intensities = [];

%for i = 1:num_lines
    %if ~isempty(profiles{i})
        %all_intensities = [all_intensities; profiles{i}];  % gabung vertikal
    %end
%end

% Plot histogram
%figure;
%histogram(all_intensities, 50);  % 50 bins (bisa disesuaikan)
%xlabel('Nilai Intensitas');
%ylabel('Frekuensi');
%title('Histogram Intensitas dari Semua Profil Radial');
%grid on;

