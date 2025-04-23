% Load gambar grayscale
%I = imread('D:\TA\Edge Sharpness\Profile intensity\Mask\BIRADS_2\bus_0191-r_mask.png'); 
%I = imread('D:\TA\Edge Sharpness\Profile intensity\Mask\BIRADS_2\bus_0592-l_mask.png'); 
I = imread('D:\TA\Edge Sharpness\Profile intensity\Dataset yang dipakai\BIRADS_2\bus_0191-r.png');  % pastikan grayscale

selected_indices = [12, 22, 29];  % indeks garis yang dipilih untuk ditampilkan di subplot
colors = {'m' 'b' 'r'};      % warna untuk masing-masing garis terpilih

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

for i = 1:num_lines
    % Hitung titik akhir garis
    x_end = xscaled_center + r * cos(theta(i));
    y_end = yscaled_center + r * sin(theta(i));
    
    % Cek apakah garis ini salah satu yang dipilih
    idx_in_selected = find(selected_indices == i);
    if ~isempty(idx_in_selected)
        color = colors{idx_in_selected};  % warna khusus
        lw = 2.5;
    else
        color = 'g';  % default: hijau
        lw = 0.5;
    end

    % Gambar garis
    line([xscaled_center x_end], [yscaled_center y_end], 'Color', color, 'LineWidth', lw);

    % Tambahkan label nomor garis
    if mod(i, 1) == 0 || ~isempty(idx_in_selected)
        text(x_end, y_end, sprintf('%d', i), 'Color', 'w', 'FontSize', 7, 'HorizontalAlignment', 'center');
    end

    % Simpan profil intensitas
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
plot(profiles{1}, 'm', 'LineWidth', 2);
xlabel('Jarak Sepanjang Garis');
ylabel('Intensitas');
%title('Contoh Profil Intensitas (garis ke-1)');
axis([0 60 20 100])
subplot(3,1,2);
plot(profiles{2}, 'b', 'LineWidth', 2);
xlabel('Jarak Sepanjang Garis');
ylabel('Intensitas');
%title('Contoh Profil Intensitas (garis ke-2)');
axis([0 60 20 100])
subplot(3,1,3);
plot(profiles{3}, 'r', 'LineWidth', 2);
xlabel('Jarak Sepanjang Garis');
ylabel('Intensitas');
%title('Contoh Profil Intensitas (garis ke-3)');
axis([0 60 20 100])



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

