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
            return;
        end
        
        axes(hRawAxes);
        title('Select two points for intensity profile');
        [x, y] = ginput(2); % Pilih dua titik secara interaktif
        
        hold on;
        plot(x, y, 'r-', 'LineWidth', 2);
        hold off;
        
        [c, cx, cy] = improfile(currentImg, x, y);
        
        axes(hPlotAxes);
        plot(1:length(c), c, 'b', 'LineWidth', 1.5);
        title('Intensity Profile');
        xlabel('Pixel Distance');
        ylabel('Intensity');
        grid on;
        
        profileData = [cx cy c];
    end

    %% Fungsi untuk Menyimpan Profil Intensitas
    function saveProfile(~, ~)
        if isempty(profileData)
            return;
        end
        [file, path] = uiputfile('profile_data.csv', 'Save Profile Data');
        if file
            csvwrite(fullfile(path, file), profileData);
        end
    end
end
