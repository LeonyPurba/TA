% Load gambar grayscale
I = imread('D:\TA\Edge Sharpness\Profile intensity\Dataset yang dipakai\BIRADS_2\bus_0191-r.png');  % pastikan grayscale

% Tentukan pusat kontur (dari hasil edge detection/mask)
xscaled_center = 142;  % ganti sesuai data kamu
yscaled_center = 93;

% Parameter
r = 60;  % panjang garis profil
num_lines = 30;
theta = linspace(0, 2*pi, num_lines + 1);  % +1 agar mencakup 360 derajat
theta(end) = [];  % hapus titik duplikat di akhir

% Indeks garis yang dipilih dan warnanya
selected_indices = [1, 2, 3];  % bisa diganti sesuai kebutuhan
colors = {'m', 'b', 'r'};      % warna untuk masing-masing garis terpilih

% Inisialisasi penyimpanan intensitas
profiles = cell(1, num_lines);

% Tampilkan gambar dan garis radial
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

% Plot semua profil intensitas dari semua garis
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

% Tampilkan profil intensitas untuk garis yang dipilih
figure(20);
for k = 1:length(selected_indices)
    subplot(length(selected_indices), 1, k);
    idx = selected_indices(k);
    plot(profiles{idx}, 'Color', colors{k}, 'LineWidth', 2);
    xlabel('Jarak Sepanjang Garis');
    ylabel('Intensitas');
    title(sprintf('Contoh Profil Intensitas (garis ke-%d)', idx));
    axis([0 60 20 100]);
end
