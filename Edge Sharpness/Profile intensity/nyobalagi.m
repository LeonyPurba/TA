function intensity_profile_GUI
    % Create the main GUI figure
    hFig = figure('Name', 'Intensity Profile Extraction', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1200, 700]);

    % Button untuk memuat folder hasil edge detection
    uicontrol('Style', 'pushbutton', 'String', 'Edge Detected', ...
              'Position', [20, 650, 120, 30], 'Callback', @loadEdgeDetectedFolder);

    % Button untuk memuat folder gambar mentah (raw image)
    uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
              'Position', [160, 650, 120, 30], 'Callback', @loadRawImageFolder);

    % Button untuk ekstraksi profil intensitas manual
    uicontrol('Style', 'pushbutton', 'String', 'Draw Line', ...
              'Position', [300, 650, 120, 30], 'Callback', @drawProfileLine);
    
    % Button untuk menyimpan data profil intensitas
    uicontrol('Style', 'pushbutton', 'String', 'Save Profile', ...
              'Position', [440, 650, 120, 30], 'Callback', @saveProfile);

    % Listbox untuk menampilkan daftar gambar hasil edge detection
    hEdgeList = uicontrol('Style', 'listbox', 'Position', [20, 400, 150, 200], ...
                          'Callback', @displaySelectedEdge);

    % Listbox untuk menampilkan daftar gambar mentah (raw image)
    hRawList = uicontrol('Style', 'listbox', 'Position', [180, 400, 150, 200], ...
                         'Callback', @displaySelectedRaw);

    % Axes untuk menampilkan hasil edge detection
    hEdgeAxes = axes('Units', 'pixels', 'Position', [350, 400, 300, 250]);

    % Axes untuk menampilkan gambar raw yang dipilih
    hRawAxes = axes('Units', 'pixels', 'Position', [680, 400, 300, 250]);

    % Axes untuk menampilkan grafik intensity profile
    hPlotAxes = axes('Units', 'pixels', 'Position', [350, 100, 630, 250]);

    % Variabel Global untuk menyimpan path folder dan parameter
    global edgeFolder rawFolder edgeFiles rawFiles currentImg profileData;
    edgeFolder = '';
    rawFolder = '';
    edgeFiles = {};
    rawFiles = {};
    currentImg = [];
    profileData = [];

    %% Fungsi Load Folder Edge Detected
    function loadEdgeDetectedFolder(~, ~)
        edgeFolder = uigetdir('', 'Select Edge Detected Folder');
        if edgeFolder ~= 0
            edgeFiles = dir(fullfile(edgeFolder, '*.png'));
            edgeFiles = {edgeFiles.name};
            set(hEdgeList, 'String', edgeFiles);
        end
    end

    %% Fungsi Load Folder Raw Image
    function loadRawImageFolder(~, ~)
        rawFolder = uigetdir('', 'Select Raw Image Folder');
        if rawFolder ~= 0
            rawFiles = dir(fullfile(rawFolder, '*.png'));
            rawFiles = {rawFiles.name};
            set(hRawList, 'String', rawFiles);
        end
    end

    %% Fungsi Menampilkan Gambar Edge Detection
    function displaySelectedEdge(~, ~)
        idx = get(hEdgeList, 'Value');
        if isempty(edgeFiles)
            return;
        end
        imgPath = fullfile(edgeFolder, edgeFiles{idx});
        img = imread(imgPath);
        axes(hEdgeAxes);
        imshow(img);
        title('Edge Detected');
    end

    %% Fungsi Menampilkan Gambar Raw Image
    function displaySelectedRaw(~, ~)
        idx = get(hRawList, 'Value');
        if isempty(rawFiles)
            return;
        end
        imgPath = fullfile(rawFolder, rawFiles{idx});
        currentImg = imread(imgPath);
        axes(hRawAxes);
        imshow(currentImg);
        title('Raw Image');
    end

    %% Fungsi untuk Menggambar Garis dan Menggunakan improfile
    function drawProfileLine(~, ~)
        if isempty(currentImg)
            errordlg('Please select a raw image first', 'Error');
            return;
        end
        
        axes(hRawAxes);
        title('Select two points for intensity profile');
        [x, y] = ginput(2); % Pilih dua titik secara interaktif
        
        hold on;
        plot(x, y, 'r-', 'LineWidth', 2);
        hold off;
        
        % Ekstrak profil intensitas
        % Jika citra RGB, konversi ke grayscale jika diperlukan
        if size(currentImg, 3) == 3
            grayImg = rgb2gray(currentImg);
        else
            grayImg = currentImg;
        end
        
        % Menggunakan improfile dengan 100 sampel untuk hasil yang lebih detail
        numSamples = 100;
        [cx, cy, c] = improfile(grayImg, x, y, numSamples);
        
        % Hitung jarak pixel yang sebenarnya
        pixelDist = sqrt(diff(cx).^2 + diff(cy).^2);
        dist = [0; cumsum(pixelDist)];
        
        % Plot profil intensitas terhadap jarak fisik
        axes(hPlotAxes);
        cla; % Bersihkan axes
        
        % Jika c adalah matriks (untuk gambar RGB), plot semua channel
        if size(c, 2) > 1
            plot(dist, c, 'LineWidth', 1.5);
            legend('Red', 'Green', 'Blue');
        else
            plot(dist, c, 'b-', 'LineWidth', 1.5);
        end
        
        title('Intensity Profile');
        xlabel('Distance along line (pixels)');
        ylabel('Intensity');
        grid on;
        
        % Simpan data untuk ekspor
        profileData = [dist, c];
    end

    %% Fungsi untuk Menyimpan Profil Intensitas
    function saveProfile(~, ~)
        if isempty(profileData)
            errordlg('No profile data to save', 'Error');
            return;
        end
        [file, path] = uiputfile('profile_data.csv', 'Save Profile Data');
        if file
            csvwrite(fullfile(path, file), profileData);
            msgbox('Profile data saved successfully', 'Success');
        end
    end
end