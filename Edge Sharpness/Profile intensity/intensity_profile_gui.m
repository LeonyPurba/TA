function intensity_profile_gui()
    % Global variables
    global origFolder gtFolder origFiles gtFiles hOrigList hGTList selectedOrig selectedGT profile_data slope_data gui_fig;

    % Create figure
    gui_fig = figure('Name', 'Radial Intensity Profile Extractor', 'Position', [100, 100, 800, 500]);

    % Load Original Image Button
    uicontrol('Style', 'pushbutton', 'String', 'Load Original Images', ...
        'Position', [50, 450, 150, 30], 'Callback', @loadOriginalFolder);

    % Load Ground Truth Button
    uicontrol('Style', 'pushbutton', 'String', 'Load Ground Truth', ...
        'Position', [250, 450, 150, 30], 'Callback', @loadGTFolder);

    % Overlay Button
    uicontrol('Style', 'pushbutton', 'String', 'Overlay & Save', ...
        'Position', [650, 450, 100, 30], 'Callback', @runOverlay);

    % CLEAR Button
    uicontrol('Style', 'pushbutton', 'String', 'CLEAR', ...
        'Position', [650, 50, 100, 30], 'Callback', @clearData);

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
    profile_data = [];
    slope_data = [];
end

function loadOriginalFolder(~, ~)
    global origFolder origFiles hOrigList;
    origFolder = uigetdir('', 'Select Folder with Original Images');
    if origFolder ~= 0
        origFiles = dir(fullfile(origFolder, '**', '*.png'));
        % Store the full paths in filenames for display
        filenames = {origFiles.name};
        set(hOrigList, 'String', filenames);
    end
end

function loadGTFolder(~, ~)
    global gtFolder gtFiles hGTList;
    gtFolder = uigetdir('', 'Select Folder with Ground Truth Masks');
    if gtFolder ~= 0
        gtFiles = dir(fullfile(gtFolder, '**', '*.png'));
        filenames = {gtFiles.name};
        set(hGTList, 'String', filenames);
    end
end

function selectOrigFile(src, ~)
    global origFolder origFiles selectedOrig;
    idx = src.Value;
    if isempty(origFiles) || idx < 1 || idx > length(origFiles)
        return;
    end
    % Use fullfile with folder and full path to ensure correct path
    selectedOrig = fullfile(origFiles(idx).folder, origFiles(idx).name);
    showPreview(selectedOrig);
end

function selectGTFile(src, ~)
    global gtFolder gtFiles selectedGT;
    idx = src.Value;
    if isempty(gtFiles) || idx < 1 || idx > length(gtFiles)
        return;
    end
    selectedGT = fullfile(gtFiles(idx).folder, gtFiles(idx).name);
    showPreview(selectedGT);
end

function showPreview(imgPath)
    try
        img = imread(imgPath);
        if size(img,3) > 1
            img = rgb2gray(img);
        end
        axesObjs = findall(gcf, 'type', 'axes');
        axes(axesObjs(1));
        imshow(img, []);
    catch e
        fprintf('Error loading image: %s\n', imgPath);
        fprintf('Error message: %s\n', e.message);
    end
end

function clearData(~, ~)
    % Close any existing figures except the main GUI
    global gui_fig profile_data slope_data;
    
    % Get all open figures
    all_figs = findall(0, 'Type', 'figure');
    
    % Close all figures except the main GUI
    for i = 1:length(all_figs)
        if all_figs(i) ~= gui_fig
            close(all_figs(i));
        end
    end
    
    % Clear data variables
    profile_data = [];
    slope_data = [];
end

function runOverlay(~, ~)
    global selectedOrig selectedGT profile_data slope_data gui_fig;

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
    end

    % Cari Centroid dari Mask
    props_mask = regionprops(mask, 'Centroid', 'Area');
    [~, idx] = max([props_mask.Area]);
    centroid = props_mask(idx).Centroid;

    % Set Parameter Garis Radial
    r = 45; % panjang garis profil
    num_lines = 30; % jumlah garis
    theta = linspace(0, 2*pi, num_lines + 1);
    theta = theta(1:end-1); % hapus duplikat

    % Inisialisasi Profil
    profiles = cell(1, num_lines);
    mask_profiles = cell(1, num_lines);
    
    % Dapatkan nama file untuk judul figure
    [~, filename, ~] = fileparts(selectedOrig);

    % Plot Overlay di Gambar Asli - Separate Figure
    fig_overlay = figure('Name', ['Overlay - ' filename], 'NumberTitle', 'off', 'Position', [50, 50, 600, 500]);
    imshow(I); hold on;
    title('Overlay Garis Profil Intensitas Radial');

    % Tambahkan overlay dari mask
    h_mask = imshow(cat(3, zeros(size(mask)), mask, zeros(size(mask))));
    set(h_mask, 'AlphaData', 0.3 * double(mask));

    % Plot centroid
    plot(centroid(1), centroid(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);

    % Gambar garis radial dan ekstrak profil untuk semua garis
    edge_point = zeros(1, num_lines);
    for i = 1:num_lines
        x_end = centroid(1) + r * cos(theta(i));
        y_end = centroid(2) + r * sin(theta(i));

        x_end = max(1, min(size(I,2), x_end));
        y_end = max(1, min(size(I,1), y_end));

        line([centroid(1), x_end], [centroid(2), y_end], 'Color', 'g', 'LineWidth', 0.5);

        if mod(i, 5) == 0
            text(x_end, y_end, sprintf('%d', i), 'Color', 'w', 'FontSize', 7, 'HorizontalAlignment', 'center');
        end

        profiles{i} = improfile(I, [centroid(1), x_end], [centroid(2), y_end], 150);
        mask_profiles{i} = improfile(double(mask), [centroid(1), x_end], [centroid(2), y_end], 150);
        
        % Temukan titik edge
        if any(mask_profiles{i} == 0)
            edge_point(i) = min(find(mask_profiles{i} == 0));
        else
            % Jika tidak ada titik 0, gunakan akhir profil sebagai edge
            edge_point(i) = length(mask_profiles{i});
        end
    end
    hold off;

    % Hitung kemiringan untuk semua garis
    all_slopes = zeros(1, num_lines);
    valid_slopes = true(1, num_lines);
    
    for i = 1:num_lines
        if edge_point(i) > 20 && edge_point(i) + 20 <= length(profiles{i})
            y_range = profiles{i}(edge_point(i)-20:edge_point(i)+20);
            x_range = 0:40;
            p = polyfit(x_range, y_range', 1);
            all_slopes(i) = p(1);
        else
            valid_slopes(i) = false;
            all_slopes(i) = NaN; % Mark invalid slopes with NaN
        end
    end
    
    % Persiapkan data untuk disimpan
    profile_data = struct();
    profile_data.theta = theta;
    profile_data.rho = linspace(0, r, 150);
    profile_data.intensity = profiles;
    profile_data.mask_profiles = mask_profiles;
    
    slope_data = struct();
    slope_data.edge_points = edge_point;
    slope_data.all_slopes = all_slopes;
    
    % Simpan data ke Excel
    saveToExcel(filename, all_slopes);
   
    figure(gui_fig);
end

function saveToExcel(filename, all_slopes)
    % Meminta folder untuk menyimpan
    outputFolder = uigetdir('', 'Select Folder to Save Excel Data');
    if outputFolder == 0
        return;
    end
    
    % Buat table untuk disimpan ke Excel
    profile_indices = (1:length(all_slopes))';
    slope_values = all_slopes';
    
    % Buat table dengan 2 kolom
    T = table(profile_indices, slope_values, 'VariableNames', {'Profile', 'Slope'});
    
    % Simpan ke Excel
    excel_filename = fullfile(outputFolder, [filename '.xlsx']);
    writetable(T, excel_filename);
end