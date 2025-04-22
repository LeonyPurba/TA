% === STEP 1: Buka file .fig ===
fig = openfig('C:\Users\Leony\Downloads\BIRADS5Nyobain.fig'); 
%fig = openfig('D:\TA\Ellips\BIRADS 2\bus_0191-r_maskdif.fig'); 
ax = gca;  % ambil axis aktif
lines = findall(ax, 'Type', 'Line');  % ambil semua data line di plot

% === STEP 2: Ekstrak data X dan Y ===
x = get(lines(1), 'XData');  % theta
y = get(lines(1), 'YData');  % r1 - r2

% === STEP 3: Lakukan FFT ===
Y = fft(y);  % hasil FFT kompleks
N = length(y);  % jumlah sampel
f = (0:N-1)*(1/N);  % sumbu frekuensi (normalized)
magnitude = abs(Y);  % ambil magnitudo (tanpa fase)

% === STEP 4: Plot hasil spektrum frekuensi ===
figure;
plot(f(1:floor(N/2)), magnitude(1:floor(N/2)));
xlabel('Frekuensi (relatif)');
ylabel('|FFT|');
title('Spektrum Frekuensi dari r_1 - r_2');
grid on;

% === STEP 5: Opsional - Hitung energi frekuensi tinggi ===
low_cutoff = 20;  % indeks frekuensi rendah dilewati
energy_high = sum(magnitude(low_cutoff:end).^2);
energy_total = sum(magnitude.^2);
ratio = energy_high / energy_total;

fprintf('Rasio energi frekuensi tinggi: %.4f\n', ratio);
