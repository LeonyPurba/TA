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

    % Button untuk melakukan ekstraksi profil intensitas
    uicontrol('Style', 'pushbutton', 'String', 'Profile Extraction', ...
              'Position', [300, 650, 150, 30], 'Callback', @extractProfile);

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

    % Axes untuk menampilkan gambar dengan garis intensity profile
    hProfileAxes = axes('Units', 'pixels', 'Position', [350, 100, 300, 250]);

    % Axes untuk menampilkan grafik intensity profile
    hPlotAxes = axes('Units', 'pixels', 'Position', [680, 100, 300, 250]);

    % Tambahkan slider untuk X dan Y
    uicontrol('Style', 'text', 'Position', [1020, 650, 100, 20], 'String', 'X Position');
    hXSlider = uicontrol('Style', 'slider', 'Position', [1020, 620, 100, 20], ...
        'Min', 50, 'Max', 500, 'Value', 250, 'Callback', @updateProfile);
    hXInput = uicontrol('Style', 'edit', 'Position', [1130, 620, 50, 20], ...
        'String', '250', 'Callback', @updateProfile);
 
    uicontrol('Style', 'text', 'Position', [1020, 580, 100, 20], 'String', 'Y Position');
    hYSlider = uicontrol('Style', 'slider', 'Position', [1020, 550, 100, 20], ...
        'Min', 50, 'Max', 500, 'Value', 250, 'Callback', @updateProfile);
    hYInput = uicontrol('Style', 'edit', 'Position', [1130, 550, 50, 20], ...
        'String', '250', 'Callback', @updateProfile);

    % Variabel Global untuk menyimpan path folder dan parameter
    global edgeFolder rawFolder edgeFiles rawFiles currentImg;
    edgeFolder = '';
    rawFolder = '';
    edgeFiles = {};
    rawFiles = {};
    currentImg = [];

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

    %% Fungsi Profile Extraction
    function extractProfile(~, ~)
        idx = get(hRawList, 'Value');
        if isempty(rawFiles)
            return;
        end
        imgPath = fullfile(rawFolder, rawFiles{idx});
        currentImg = imread(imgPath);
        
        % Set slider range sesuai ukuran gambar
        set(hXSlider, 'Max', size(currentImg, 2), 'Value', size(currentImg, 2)/2);
        set(hYSlider, 'Max', size(currentImg, 1), 'Value', size(currentImg, 1)/2);
        
        % Update tampilan awal
        updateProfile();
    end

    %% Fungsi Update Profile
    function updateProfile(~, ~)
        if isempty(currentImg)
            return;
        end
        
        % Bersihkan axes sebelumnya
        cla(hProfileAxes);
        cla(hPlotAxes);
        
        % Ambil posisi dari slider
        xPos = round(get(hXSlider, 'Value'));
        yPos = round(get(hYSlider, 'Value'));
        
        % Update input text
        set(hXInput, 'String', num2str(xPos));
        set(hYInput, 'String', num2str(yPos));
        
        % Tentukan panjang garis
        profileWidth = 50;
        x1 = max(1, xPos - profileWidth/2);
        x2 = min(size(currentImg, 2), xPos + profileWidth/2);
        
        % Tampilkan gambar dan garis di profile axes
        axes(hProfileAxes);
        imshow(currentImg);
        hold on;
        plot([x1, x2], [yPos, yPos], 'g', 'LineWidth', 2);  % Ganti warna menjadi hijau
        title('Image with Intensity Profile Line');
        hold off;
        
        % Ekstraksi dan plot intensity profile
        [cx, cy, c] = improfile(currentImg, [x1 x2], [yPos yPos]);
        
        axes(hPlotAxes);
        plot(linspace(-profileWidth/2, profileWidth/2, length(c)), c, 'LineWidth', 1.5);
        title('Intensity Profile');
        xlabel('Distance (pixels)');
        ylabel('Intensity');
    end
end