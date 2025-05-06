function intensity_profile_gui()
    % Global variables
    global origFolder gtFolder origFiles gtFiles hOrigList hGTList selectedOrig selectedGT profile_data slope_data gui_fig hProfileInput hPreviewAxes;

    % Create figure
    gui_fig = figure('Name', 'Radial Intensity Profile Extractor', 'Position', [100, 100, 800, 500]);

    % Load Original Image Button
    uicontrol('Style', 'pushbutton', 'String', 'Load Original Images', ...
        'Position', [50, 450, 150, 30], 'Callback', @loadOriginalFolder);

    % Load Ground Truth Button
    uicontrol('Style', 'pushbutton', 'String', 'Load Ground Truth', ...
        'Position', [250, 450, 150, 30], 'Callback', @loadGTFolder);

    % Overlay Button
    uicontrol('Style', 'pushbutton', 'String', 'Overlay', ...
        'Position', [650, 450, 100, 30], 'Callback', @runOverlay);

    % Save profile data
    uicontrol('Style', 'pushbutton', 'String', 'Save Profile Data', ...
        'Position', [650, 100, 100, 30], 'Callback', @saveProfileData);
    
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

    % Manual Input for Profile Indices
    uicontrol('Style', 'text', 'String', 'Profile Indices (e.g., 3,15,23):', ...
        'Position', [450, 450, 180, 20]);
    hProfileInput = uicontrol('Style', 'edit', 'Position', [450, 420, 180, 25], ...
        'String', '3,15,23');

    % Axes for Preview
    axes('Units', 'pixels', 'Position', [450, 200, 300, 200]);
    title('Preview');

    hPreviewAxes = axes('Units', 'pixels', 'Position', [450, 200, 300, 200]);
    title(hPreviewAxes, 'Preview');


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
        
        % Gabungkan folder + nama untuk path lengkap
        fileNames = {origFiles.name};
        set(hOrigList, 'String', fileNames);
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
    global origFiles selectedOrig;
    idx = src.Value;
    if isempty(origFiles)
        return;
    end

    % Ambil file path langsung dari listbox
    allPaths = get(src, 'UserData');
        if isempty(allPaths)
        return;
    end

    selectedOrig = items{idx};
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
    global hPreviewAxes;

    if isempty(hPreviewAxes) || ~isvalid(hPreviewAxes)
        warning('Preview axes not valid.');
        return;
    end

    img = imread(imgPath);
    if size(img,3) > 1
        img = rgb2gray(img);
    end

    axes(hPreviewAxes);  % arahkan ke preview axes
    imshow(img, [], 'Parent', hPreviewAxes);
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
    
    % Inform user
    msgbox('All data and plots have been cleared.', 'Clear Complete');
end

function runOverlay(~, ~)
    global selectedOrig selectedGT profile_data slope_data gui_fig hProfileInput;

    if isempty(selectedOrig) || isempty(selectedGT)
        errordlg('Please select both an original image and a ground truth mask.', 'Selection Error');
        return;
    end

    % Get selected profile indices from input field
    profile_indices_str = get(hProfileInput, 'String');
    selected_indices = str2num(profile_indices_str); % Convert string to array
    
    if isempty(selected_indices) || length(selected_indices) ~= 3
        errordlg('Please enter exactly 3 profile indices separated by commas.', 'Input Error');
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
    r = 45; % panjang garis profil
    num_lines = 30; % jumlah garis
    theta = linspace(0, 2*pi, num_lines + 1);
    theta = theta(1:end-1); % hapus duplikat
    colors = {'m', 'c', 'b'};

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

    % Gambar garis radial
    edge_point = zeros(1, num_lines);
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
        
        % Temukan titik edge
        if any(mask_profiles{i} == 0)
            edge_point(i) = min(find(mask_profiles{i} == 0));
        else
            % Jika tidak ada titik 0, gunakan akhir profil sebagai edge
            edge_point(i) = length(mask_profiles{i});
        end
    end
    hold off;

    % Skip the "All Profiles" figure and "Selected Profiles" figure
    % Only generate the slope figure as requested

    % Hitung dan plot kemiringan - Only Figure to Keep
    fig_slope = figure('Name', ['Slope Analysis - ' filename], 'NumberTitle', 'off', 'Position', [660, 50, 500, 500]);
    
    slopes = zeros(1, length(selected_indices));
    for i = 1:length(selected_indices)
        subplot(3,1,i);
        hold on;
        
        idx = selected_indices(i);
        edge_idx = edge_point(idx);
        
        % Pastikan edge_idx valid dan array tidak keluar batas
        if edge_idx > 20 && edge_idx + 20 <= length(profiles{idx})
            % Ambil profil sekitar edge
            x_range = 0:40; % 41 titik
            y_range = profiles{idx}(edge_idx-20:edge_idx+20);
            
            % Regresi Linear (kemiringan)
            p = polyfit(x_range, y_range', 1); % y = mx + c
            y_fit = polyval(p, x_range);
            
            % Simpan slope
            slopes(i) = p(1);
            
            % Plot kurva asli
            plot(x_range, y_range, colors{i}, 'LineWidth', 2);
            
            % Plot hasil regresi
            plot(x_range, y_fit, 'k--', 'LineWidth', 1.5);
            
            % Tampilkan slope di plot
            text(2, max(y_range)*0.9, sprintf('Slope = %.2f', p(1)), ...
                'FontSize', 10, 'Color', 'k', 'BackgroundColor', 'w');
            
            xlabel('Pixel dari Edge (0 = -20 pixel)');
            ylabel('Intensitas');
            title(sprintf('Kemiringan Sekitar Edge (Garis %d)', idx));
            axis([0 40 0 130]);
            legend('Gambar Asli', 'Regresi Linear');
            grid on;
        else
            text(0.5, 0.5, 'Edge point tidak valid', 'Units', 'normalized');
        end
        hold off;
    end
    
    % Removed the radar plot figure
    
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
        end
    end
    
    % Persiapkan data untuk disimpan
    profile_data = struct();
    profile_data.theta = theta;
    profile_data.rho = linspace(0, r, 150);
    profile_data.intensity = profiles;
    profile_data.mask_profiles = mask_profiles;
    
    slope_data = struct();
    slope_data.selected_indices = selected_indices;
    slope_data.edge_points = edge_point;
    slope_data.slopes = slopes;
    slope_data.all_slopes = all_slopes;
    
    % Fokus kembali ke GUI
    figure(gui_fig);
    
    msgbox('Analysis complete! You can now save the data.', 'Analysis Complete');
end

function saveProfileData(~, ~)
    global selectedOrig profile_data slope_data;

    if isempty(profile_data)
        errordlg('No profile data to save. Please run overlay first.', 'Save Error');
        return;
    end

    % Pilih folder penyimpanan
    outputFolder = uigetdir('', 'Select Folder to Save Profile Data');
    if outputFolder == 0
        return;
    end

    % Buat nama file berdasarkan nama gambar
    [~, filename, ~] = fileparts(selectedOrig);
    
    % Simpan profile data dan slope data dalam file yang sama
    if ~isempty(slope_data)
        % Gabungkan semua data ke dalam satu struct untuk memudahkan akses
        data_to_save = struct();
        data_to_save.profile_data = profile_data;
        data_to_save.slope_data = slope_data;
        
        % Tambahkan informasi tambahan untuk referensi
        data_to_save.filename = filename;
        data_to_save.analysis_date = datestr(now);
        
        % Simpan semua data dengan format nama gambar
        %save(fullfile(outputFolder, [filename '_profile.mat']), 'data_to_save');
        
        % Simpan juga file CSV dengan slope values untuk mudah dianalisis
        %selected_indices = slope_data.selected_indices;
        %slopes = slope_data.slopes;
        all_slopes = slope_data.all_slopes;
        
        % Buat file CSV untuk slope yang dipilih
        selected_slopes_file = fullfile(outputFolder, [filename '_selected_slopes.csv']);
        fid = fopen(selected_slopes_file, 'w');
        fprintf(fid, 'Line Index,Slope Value\n');
        for i = 1:length(selected_indices)
            fprintf(fid, '%d,%.4f\n', selected_indices(i), slopes(i));
        end
        fclose(fid);
        
        % Buat file CSV untuk semua slope
        all_slopes_file = fullfile(outputFolder, [filename '_all_slopes.csv']);
        fid = fopen(all_slopes_file, 'w');
        fprintf(fid, 'Line Index,Slope Value\n');
        for i = 1:length(all_slopes)
            fprintf(fid, '%d,%.4f\n', i, all_slopes(i));
        end
        fclose(fid);
        
        msgbox('Profile and slope data saved successfully!', 'Success');
    else
        % Fallback ke cara lama jika slope_data kosong
        save(fullfile(outputFolder, [filename '_profile.mat']), 'profile_data');
        msgbox('Only profile data saved (no slope data).', 'Warning');
    end
end