function intensity_profile_GUI
    hFig = figure('Name', 'Intensity Profile Extraction', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1300, 750]);

    % Tombol untuk memuat folder
    uicontrol('Style', 'pushbutton', 'String', 'Edge Detected', ...
              'Position', [20, 700, 120, 30], 'Callback', @loadEdgeDetectedFolder);
    uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
              'Position', [160, 700, 120, 30], 'Callback', @loadRawImageFolder);
    uicontrol('Style', 'pushbutton', 'String', 'Update Profile', ...
              'Position', [300, 700, 150, 30], 'Callback', @extractProfile);
    
    % Listbox
    hEdgeList = uicontrol('Style', 'listbox', 'Position', [20, 450, 150, 200], ...
                          'Callback', @displaySelectedEdge);
    hRawList = uicontrol('Style', 'listbox', 'Position', [180, 450, 150, 200], ...
                         'Callback', @displaySelectedRaw);

    % Axes
    hEdgeAxes = axes('Units', 'pixels', 'Position', [350, 450, 300, 250]);
    hRawAxes = axes('Units', 'pixels', 'Position', [680, 450, 300, 250]);
    hProfileAxes = axes('Units', 'pixels', 'Position', [350, 100, 300, 250]);
    hPlotAxes = axes('Units', 'pixels', 'Position', [680, 100, 300, 250]);

    % Slider untuk titik tengah tumor
    uicontrol('Style', 'text', 'Position', [1020, 680, 80, 20], 'String', 'X Center');
    hXSlider = uicontrol('Style', 'slider', 'Position', [1020, 660, 150, 20], ...
                          'Min', 1, 'Max', 512, 'Value', 256, 'Callback', @updateSlider);
    hXInput = uicontrol('Style', 'edit', 'Position', [1180, 660, 50, 20], 'String', '256', 'Callback', @updateSlider);

    uicontrol('Style', 'text', 'Position', [1020, 630, 80, 20], 'String', 'Y Center');
    hYSlider = uicontrol('Style', 'slider', 'Position', [1020, 610, 150, 20], ...
                          'Min', 1, 'Max', 512, 'Value', 256, 'Callback', @updateSlider);
    hYInput = uicontrol('Style', 'edit', 'Position', [1180, 610, 50, 20], 'String', '256', 'Callback', @updateSlider);
    
    % Variabel Global
    global edgeFolder rawFolder edgeFiles rawFiles tumorX tumorY;
    edgeFolder = ''; rawFolder = ''; edgeFiles = {}; rawFiles = {};
    tumorX = 256; tumorY = 256;

    function updateSlider(~, ~)
        tumorX = round(get(hXSlider, 'Value'));
        tumorY = round(get(hYSlider, 'Value'));
        set(hXInput, 'String', num2str(tumorX));
        set(hYInput, 'String', num2str(tumorY));
        extractProfile();
    end

    function loadEdgeDetectedFolder(~, ~)
        edgeFolder = uigetdir('', 'Select Edge Detected Folder');
        if edgeFolder ~= 0
            edgeFiles = dir(fullfile(edgeFolder, '*.png'));
            edgeFiles = {edgeFiles.name};
            set(hEdgeList, 'String', edgeFiles);
        end
    end

    function loadRawImageFolder(~, ~)
        rawFolder = uigetdir('', 'Select Raw Image Folder');
        if rawFolder ~= 0
            rawFiles = dir(fullfile(rawFolder, '*.png'));
            rawFiles = {rawFiles.name};
            set(hRawList, 'String', rawFiles);
        end
    end

    function displaySelectedEdge(~, ~)
        idx = get(hEdgeList, 'Value');
        if isempty(edgeFiles), return; end
        img = imread(fullfile(edgeFolder, edgeFiles{idx}));
        axes(hEdgeAxes); imshow(img); title('Edge Detected');
    end

    function displaySelectedRaw(~, ~)
        idx = get(hRawList, 'Value');
        if isempty(rawFiles), return; end
        img = imread(fullfile(rawFolder, rawFiles{idx}));
        axes(hRawAxes); imshow(img); title('Raw Image');
    end

    function extractProfile(~, ~)
        idx = get(hRawList, 'Value');
        if isempty(rawFiles), return; end
        img = imread(fullfile(rawFolder, rawFiles{idx}));

        tumorX = round(get(hXSlider, 'Value'));
        tumorY = round(get(hYSlider, 'Value'));
        set(hXInput, 'String', num2str(tumorX));
        set(hYInput, 'String', num2str(tumorY));
        
        axes(hProfileAxes);
        imshow(img); hold on;
        radius = 50;
        numLines = 5;
        thetaValues = linspace(0, 2*pi, numLines + 1);
        thetaValues(end) = [];

        allProfiles = [];
        for i = 1:numLines
            x1 = tumorX + radius * cos(thetaValues(i));
            y1 = tumorY + radius * sin(thetaValues(i));
            x2 = tumorX - radius * cos(thetaValues(i));
            y2 = tumorY - radius * sin(thetaValues(i));
            plot([x1, x2], [y1, y2], 'r', 'LineWidth', 1.5);
            
            [~, ~, c] = improfile(img, [x1 x2], [y1 y2]);
            allProfiles = [allProfiles; c'];
            axes(hPlotAxes); hold on;
            plot(linspace(-radius, radius, length(c)), c);
        end
        title('Intensity Profiles'); xlabel('Distance (ρ)'); ylabel('Intensity');
        hold off;
    end
end
