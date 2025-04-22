function intensity_profile_extraction
    % Membuat GUI utama
    hFig = figure('Name', 'Intensity Profile Extraction', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1200, 700]);

    % Tombol untuk memuat folder edge-detected images
    uicontrol('Style', 'pushbutton', 'String', 'Edge Detected', ...
              'Position', [20, 650, 120, 30], 'Callback', @loadEdgeFolder);

    % Tombol untuk memuat folder raw images
    uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
              'Position', [150, 650, 120, 30], 'Callback', @loadRawFolder);

    % Tombol untuk melakukan profile extraction
    uicontrol('Style', 'pushbutton', 'String', 'Profile Extraction', ...
              'Position', [280, 650, 150, 30], 'Callback', @profileExtraction);

    % Listbox untuk menampilkan daftar gambar edge-detection
    hEdgeList = uicontrol('Style', 'listbox', 'Position', [20, 400, 120, 200], ...
                          'Callback', @displayEdgeImage);

    % Listbox untuk menampilkan daftar gambar raw images
    hRawList = uicontrol('Style', 'listbox', 'Position', [150, 400, 120, 200], ...
                         'Callback', @displayRawImage);

    % Axes untuk menampilkan gambar edge detected
    hEdgeAxes = axes('Units', 'pixels', 'Position', [300, 400, 250, 250]);

    % Axes untuk menampilkan gambar raw image
    hRawAxes = axes('Units', 'pixels', 'Position', [600, 400, 250, 250]);

    % Axes untuk menampilkan hasil profile extraction
    hProfileAxes = axes('Units', 'pixels', 'Position', [300, 50, 800, 300]);

    % Variabel untuk menyimpan data gambar
    edgeImages = {};
    rawImages = {};
    edgeFolder = '';
    rawFolder = '';

    % Fungsi untuk memuat folder edge-detection
    function loadEdgeFolder(~, ~)
        edgeFolder = uigetdir;
        if edgeFolder ~= 0
            edgeImages = dir(fullfile(edgeFolder, '*.png'));  % Sesuaikan format file jika berbeda
            edgeListNames = {edgeImages.name};
            set(hEdgeList, 'String', edgeListNames);
        end
    end

    % Fungsi untuk memuat folder raw images
    function loadRawFolder(~, ~)
        rawFolder = uigetdir;
        if rawFolder ~= 0
            rawImages = dir(fullfile(rawFolder, '*.png'));  % Sesuaikan format file jika berbeda
            rawListNames = {rawImages.name};
            set(hRawList, 'String', rawListNames);
        end
    end

    % Fungsi untuk menampilkan gambar edge detection
    function displayEdgeImage(~, ~)
        idx = get(hEdgeList, 'Value');
        if ~isempty(edgeImages)
            img = imread(fullfile(edgeFolder, edgeImages(idx).name));
            axes(hEdgeAxes);
            imshow(img);
        end
    end

    % Fungsi untuk menampilkan gambar raw image
    function displayRawImage(~, ~)
        idx = get(hRawList, 'Value');
        if ~isempty(rawImages)
            img = imread(fullfile(rawFolder, rawImages(idx).name));
            axes(hRawAxes);
            imshow(img);
        end
    end

    % Fungsi untuk profile extraction (nanti ditambahkan fitur manual click)
    function profileExtraction(~, ~)
        % Menampilkan raw image yang dipilih untuk ditarik garis
        idx = get(hRawList, 'Value');
        if ~isempty(rawImages)
            img = imread(fullfile(rawFolder, rawImages(idx).name));
            axes(hProfileAxes);
            imshow(img);
            hold on;

            % Klik titik manual untuk menggambar garis
            title('Klik titik tengah lalu titik luar tumor');
            [x, y] = ginput(2);
            plot([x(1), x(2)], [y(1), y(2)], 'r-', 'LineWidth', 2);
            hold off;
        end
    end
end
