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

    % Variabel Global untuk menyimpan path folder
    global edgeFolder rawFolder edgeFiles rawFiles;
    edgeFolder = '';
    rawFolder = '';
    edgeFiles = {};
    rawFiles = {};

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
        img = imread(imgPath);
        axes(hRawAxes);
        imshow(img);
        title('Raw Image');
    end

    %% Fungsi Profile Extraction
    function extractProfile(~, ~)
        idx = get(hRawList, 'Value');
        if isempty(rawFiles)
            return;
        end
        imgPath = fullfile(rawFolder, rawFiles{idx});
        img = imread(imgPath);
        
        % Menampilkan gambar raw di box bawah
        axes(hProfileAxes);
        imshow(img);
        title('Image with Intensity Profile Lines');
        
        % Menentukan titik tengah tumor (sementara manual)
        tumorCenter = [size(img,2)/2, size(img,1)/2];  
        radius = 50; % Jarak dari pusat tumor
        numLines = 5; % Jumlah garis
        
        hold on;
        thetaValues = linspace(0, 2*pi, numLines + 1); % Menentukan sudut garis
        thetaValues(end) = []; % Buang nilai 2π agar tidak duplikat

        % Menyimpan semua profil intensitas
        allProfiles = [];

        for i = 1:numLines
            x1 = tumorCenter(1) + radius * cos(thetaValues(i));
            y1 = tumorCenter(2) + radius * sin(thetaValues(i));
            x2 = tumorCenter(1) - radius * cos(thetaValues(i));
            y2 = tumorCenter(2) - radius * sin(thetaValues(i));

            plot([x1, x2], [y1, y2], 'r', 'LineWidth', 1.5); % Plot garis
            
            % Ambil intensity profile sepanjang garis
            [cx, cy, c] = improfile(img, [x1 x2], [y1 y2]); 

            % Simpan hasil ke array
            allProfiles = [allProfiles; c'];

            % Plot intensity profile di axes sebelahnya
            axes(hPlotAxes);
            hold on;
            plot(linspace(-radius, radius, length(c)), c);
        end

        % Set judul grafik
        title('Intensity Profiles');
        xlabel('Distance (ρ)');
        ylabel('Intensity');
        hold off;
    end
end
