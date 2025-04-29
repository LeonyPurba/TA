function intensity_profile_gui()
    % Global variables
    global origFolder gtFolder origFiles gtFiles hOrigList hGTList selectedOrig selectedGT;

    % Create figure
    fig = figure('Name', 'Radial Intensity Profile Extractor', 'Position', [100, 100, 800, 500]);

    % Load Original Image Button
    uicontrol('Style', 'pushbutton', 'String', 'Load Original Images', ...
        'Position', [50, 450, 150, 30], 'Callback', @loadOriginalFolder);

    % Load Ground Truth Button
    uicontrol('Style', 'pushbutton', 'String', 'Load Ground Truth', ...
        'Position', [250, 450, 150, 30], 'Callback', @loadGTFolder);

    % Overlay Button
    uicontrol('Style', 'pushbutton', 'String', 'Overlay', ...
        'Position', [650, 450, 100, 30], 'Callback', @runOverlay);

    % Listbox for Original Images
    uicontrol('Style', 'text', 'String', 'Original Images:', ...
        'Position', [50, 420, 150, 20]);
    hOrigList = uicontrol('Style', 'listbox', 'Position', [50, 200, 150, 220], ...
        'Callback', @selectOrigFile);

    % Listbox for Ground Truth
    uicontrol('Style', 'text', 'String', 'Ground Truth Masks:', ...
        'Position', [250, 420, 150, 20]);
    hGTList = uicontrol('Style', 'listbox', 'Position', [250, 200, 150, 220], ...
        'Callback', @selectGTFile);

    % Axes for Preview
    axes('Units', 'pixels', 'Position', [450, 200, 300, 200]);
    title('Preview');

    % Initialize
    selectedOrig = '';
    selectedGT = '';
end

function loadOriginalFolder(~, ~)
    global origFolder origFiles hOrigList;
    origFolder = uigetdir('', 'Select Folder with Original Images');
    if origFolder ~= 0
        origFiles = dir(fullfile(origFolder, '**', '*.png')); % <<< ini perubahannya (recursive search)
        filenames = {origFiles.name};
        set(hOrigList, 'String', filenames);
    end
end


function loadGTFolder(~, ~)
    global gtFolder gtFiles hGTList;
    gtFolder = uigetdir('', 'Select Folder with Ground Truth Masks');
    if gtFolder ~= 0
        gtFiles = dir(fullfile(gtFolder, '*.png'));
        filenames = {gtFiles.name};
        set(hGTList, 'String', filenames);
    end
end

function selectOrigFile(src, ~)
    global origFolder origFiles selectedOrig;
    idx = src.Value;
    if isempty(origFiles)
        return;
    end
    selectedOrig = fullfile(origFolder, origFiles(idx).name);
    showPreview(selectedOrig);
end

function selectGTFile(src, ~)
    global gtFolder gtFiles selectedGT;
    idx = src.Value;
    if isempty(gtFiles)
        return;
    end
    selectedGT = fullfile(gtFolder, gtFiles(idx).name);
    showPreview(selectedGT);
end

function showPreview(imgPath)
    img = imread(imgPath);
    if size(img,3) > 1
        img = rgb2gray(img);
    end
    axesObjs = findall(gcf, 'type', 'axes');
    axes(axesObjs(1));
    imshow(img, []);
end

function runOverlay(~, ~)
    global selectedOrig selectedGT;

    if isempty(selectedOrig) || isempty(selectedGT)
        errordlg('Please select both an original image and a ground truth mask.', 'Selection Error');
        return;
    end

    % ------------ Algoritma Profil Intensity Extraction--------------
    
    % Load mask binary (GROUND TRUTH) untuk cari bounding box
    mask = imread(selectedGT);
    if size(mask,3) > 1
        mask = mask(:,:,1); % pastikan grayscale
    end

    % Konversi ke binary jika belum logical
    if ~islogical(mask)
        mask = imbinarize(mask);
    end

    % Load gambar asli grayscale
    I = imread(selectedOrig);
    if size(I,3) > 1
        I = rgb2gray(I);
    end

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
    r = 40; % panjang garis profil
    num_lines = 30; % jumlah garis
    theta = linspace(0, 2*pi, num_lines + 1);
    theta = theta(1:end-1); % hapus duplikat
    selected_indices = [12, 22, 29];
    colors = {'m', 'b', 'r'};

    % Inisialisasi Profil
    profiles = cell(1, num_lines);

    % Plot Overlay di Gambar Asli
    figure;
    imshow(I); hold on;
    title('Overlay Garis Profil Intensitas Radial');

    % Tambahkan overlay dari mask
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
            color = colors{idx_in_selected};
            lw = 2.5;
        else
            color = 'g';
            lw = 0.5;
        end

        line([centroid(1), x_end], [centroid(2), y_end], 'Color', color, 'LineWidth', lw);

        if mod(i, 5) == 0 || ~isempty(idx_in_selected)
            text(x_end, y_end, sprintf('%d', i), 'Color', 'w', 'FontSize', 7, 'HorizontalAlignment', 'center');
        end

        profiles{i} = improfile(I, [centroid(1), x_end], [centroid(2), y_end], 100);
    end
    hold off;

    % Plot Semua Profil Intensitas
    figure;
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
    figure;
    for i = 1:length(selected_indices)
        subplot(3,1,i);
        idx = selected_indices(i);
        plot(profiles{idx}, colors{i}, 'LineWidth', 2);
        xlabel('Jarak Sepanjang Garis');
        ylabel('Intensitas');
        title(sprintf('Profil Intensitas Garis %d', idx));
        axis([0 length(profiles{idx}) 20 100]);
    end

  % Untuk 1 gambar:
  profile_data.theta = theta;        % 1xN array, semua sudut 
  profile_data.rho = linspace(0, r, 100);  % 1x100 array (100 titik sampling)
  profile_data.intensity = profiles; % 1xN cell, tiap cell: 100x1 array (profil intensitas tiap garis)
  
 save('namafile.mat', 'profile_data');

end
