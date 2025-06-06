%Ori_image  = '.\Raw_Image\BIRADS_2\bus_0191-r.png';
%Mask_image = '.\Resize\Resized\BIRADS_2\resized_mask_0191-r.png';

Ori_image = 'D:\Git Repo\TA\Edge Sharpness\Profile intensity\hasil_zoom_384.png';
Mask_image = 'D:\TA\TA Kak chelli\Mask\BIRADS_2\bus_0612-l_mask.png';

% Load mask binary (GROUND TRUTH) untuk cari bounding box
    mask = imread(Mask_image);
    if size(mask,3) > 1
        mask = mask(:,:,1); % pastikan grayscale
    end

    % Konversi ke binary jika belum logical
    if ~islogical(mask)
        mask = imbinarize(mask);
    end

    % Load gambar asli grayscale
    I = imread(Ori_image);
    if size(I,3) > 1
        I = rgb2gray(I);
    end
i
    % Pastikan ukuran mask dan gambar asli sama
    if ~isequal(size(mask), size(I))
        mask = imresize(mask, size(I));
        fprintf('Mask diubah ukurannya agar sesuai dengan gambar asli\n');
    end

    % Cari Centroid dari Mask
    props_mask = regionprops(mask, 'Centroid', 'Area');
    [~, idx] = max([props_mask.Area]);
    centroid = props_mask(idx).Centroid;
    fprintf('Centroid pada gambar penuh: [%.2f, %.2f]\n', centroid);

    % Set Parameter Garis Radial
    r = 150; % panjang garis profil
    num_lines = 30; % jumlah garis
    theta = linspace(0, 2*pi, num_lines + 1);
    theta = theta(1:end-1); 
    selected_indices = [3,15,23]; %masukin garis yg mau di ekstrak
    colors = {'m', 'c', 'b'};

    % Inisialisasi Profil
    profiles = cell(1, num_lines);
    mask_profiles = cell (1, num_lines);

    % Plot Overlay di Gambar Asli
    figure(1);
    imshow(I); hold on;
    title('Overlay Garis Profil Intensitas Radial');

    % Overlay dari mask
    h_mask = imshow(cat(3, zeros(size(mask)), mask, zeros(size(mask))));
    set(h_mask, 'AlphaData', 0.3 * double(mask));

    % Plot centroid
    plot(centroid(1), centroid(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);

    % Gambar garis radial
    for i = 1:num_lines
        x_end = centroid(1) + r * cos(theta(i));
        y_end = centroid(2) + r * sin(theta(i));

        x_end = max(1, min(size(I,2), x_end));
        y_end = max(1, min(size(I,1), y_end));

        idx_in_selected = find(selected_indices == i);
        if ~isempty(idx_in_selected)
            color = colors{mod(idx_in_selected - 1, numel(colors)) + 1};
            lw = 2.5;
        else
            color = 'g';
            lw = 0.5;
        end

        line([centroid(1), x_end], [centroid(2), y_end], 'Color', color, 'LineWidth', lw);

        if mod(i, 5) == 0 || ~isempty(idx_in_selected)
            text(x_end, y_end, sprintf('%d', i), 'Color', 'w', 'FontSize', 7, 'HorizontalAlignment', 'center');
        end

        profiles{i} = improfile(I, [centroid(1), x_end], [centroid(2), y_end], 150);
        mask_profiles{i} = improfile(double(mask), [centroid(1), x_end], [centroid(2), y_end], 150);
    end
    hold off;


    % Plot Semua Profil Intensitas
    figure(2);
    hold on;
    for i = 1:num_lines
        if ~isempty(profiles{i})
            plot(profiles{i}, 'Color', [0, 0.5, 1, 0.2]); % transparan
        end
    end
    xlabel('Jarak Sepanjang Garis');
    ylabel('Intensitas');
    title('Semua Profil Intensitas Radial');
    grid on;
    hold off;

    % Plot 3 Profil Terpilih
    figure(3);
	edge_point = zeros(1,num_lines);
    for i = 1:length(selected_indices)
        subplot(3,1,i);
        hold on;
        idx = selected_indices(i);
        plot(profiles{idx}, colors{i}, 'LineWidth', 2);

        %plot profil dari masking
        if ~isempty(mask_profiles{idx})
            plot(mask_profiles{idx} * max(profiles{idx}), 'g', 'LineWidth', 2);
        end
		edge_point(idx) = min(find(~mask_profiles{idx}));
        xlabel('Jarak Sepanjang Garis');
        ylabel('Intensitas');
        title(sprintf('Profil Intensitas Garis %d', idx));
        axis([0 150 0 130]);
        legend ('Gambar Asli', 'Masking GT');
        grid on;
        hold off;
    end


    figure(4);
	clf;

    for i = 1:length(selected_indices)
        subplot(3,1,i);
        hold on;

        idx = selected_indices(i);
		
        plot(profiles{idx}(edge_point(idx)-20:edge_point(idx)+20), colors{i}, 'LineWidth', 2);

        axis([0 40 0 130]);
        legend ('Gambar Asli', 'Masking GT');
        grid on;
        hold off;
    end

    figure(5); 
    clf;

    slopes = zeros(1, length(selected_indices)); % Menyimpan slope tiap garis
    
    for i = 1:length(selected_indices)
        subplot(3,1,i);
        hold on;
        
        idx = selected_indices(i);
        edge_idx = edge_point(idx);
        
        % Ambil profil sekitar edge
        x_range = 0:40; % 41 titik (sama seperti Figure 4)
        y_range = profiles{idx}(edge_idx-20 : edge_idx+20);
        
        % Regressi Linear (kemiringan)
        p = polyfit(x_range, y_range', 1); % y = mx + c
        y_fit = polyval(p, x_range);
        
        % Simpan slope
        slopes(i) = p(1);

        % Plot kurva asli
        plot(x_range, y_range, colors{i}, 'LineWidth', 2);

        % Plot hasil regresi   
        plot(x_range, y_fit,  'k--', 'LineWidth', 1.5);

  
        % Tampilkan slope di plot
        text(2, max(y_range)*0.9, sprintf('Slope = %.2f', p(1)), ...
            'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'w');
        
        xlabel('Pixel dari Edge (0 = -20 pixel)');
        ylabel('Intensitas');
        
        title(sprintf('Kemiringan Sekitar Edge (Garis %d)', idx));
        axis([0 40 0 130]); % Tetap seperti Figure 4
        legend('Gambar Asli', 'Regresi Linear');
        grid on;
        hold off;
    end