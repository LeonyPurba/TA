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

    % Button untuk menggambar manual
    uicontrol('Style', 'pushbutton', 'String', 'Draw Line', ...
              'Position', [300, 650, 120, 30], 'Callback', @drawProfileLine);

    % Button untuk simpan hasil
    uicontrol('Style', 'pushbutton', 'String', 'Save Profile', ...
              'Position', [440, 650, 120, 30], 'Callback', @saveProfile);

    % Button otomatis berdasarkan theta
    uicontrol('Style', 'pushbutton', 'String', 'Auto Profile', ...
              'Position', [580, 650, 120, 30], 'Callback', @autoProfile);

    % Listbox gambar edge
    hEdgeList = uicontrol('Style', 'listbox', 'Position', [20, 400, 150, 200], ...
                          'Callback', @displaySelectedEdge);

    % Listbox gambar raw
    hRawList = uicontrol('Style', 'listbox', 'Position', [180, 400, 150, 200], ...
                         'Callback', @displaySelectedRaw);

    % Axes edge, raw, plot
    hEdgeAxes = axes('Units', 'pixels', 'Position', [350, 400, 250, 250]);
    hRawAxes  = axes('Units', 'pixels', 'Position', [620, 400, 250, 250]);
    hPlotAxes = axes('Units', 'pixels', 'Position', [350, 100, 520, 250]);

    % Variabel Global
    global edgeFolder rawFolder edgeFiles rawFiles currentImg profileData thetaData;
    edgeFolder = ''; rawFolder = ''; edgeFiles = {}; rawFiles = {};
    currentImg = []; profileData = []; thetaData = [];

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
        imgPath = fullfile(edgeFolder, edgeFiles{idx});
        img = imread(imgPath);
        axes(hEdgeAxes); imshow(img); title('Edge Detected');
    end

    function displaySelectedRaw(~, ~)
        idx = get(hRawList, 'Value');
        if isempty(rawFiles), return; end
        imgPath = fullfile(rawFolder, rawFiles{idx});
        currentImg = imread(imgPath);
        axes(hRawAxes); imshow(currentImg); title('Raw Image');
    end

    function drawProfileLine(~, ~)
        if isempty(currentImg)
            errordlg('Please select a raw image first', 'Error'); return;
        end
        axes(hRawAxes); title('Select two points for intensity profile');
        [x, y] = ginput(2);
        hold on; plot(x, y, 'r-', 'LineWidth', 2); hold off;

        if size(currentImg, 3) == 3
            grayImg = rgb2gray(currentImg);
        else
            grayImg = currentImg;
        end

        numSamples = 100;
        [cx, cy, c] = improfile(grayImg, x, y, numSamples);
        pixelDist = sqrt(diff(cx).^2 + diff(cy).^2);
        dist = [0; cumsum(pixelDist)];

        theta = calculateTheta(x, y, cx, cy);
        thetaData = theta;

        axes(hPlotAxes); cla;
        if size(c, 2) > 1
            plot(dist, c, 'LineWidth', 1.5); legend('R','G','B');
        else
            plot(dist, c, 'b-', 'LineWidth', 1.5);
        end
        title('Intensity Profile'); xlabel('Distance'); ylabel('Intensity'); grid on;
        text(0.8*max(dist), 0.8*max(c), ['\theta = ', num2str(theta, '%.2f'), '°'], ...
             'FontSize', 12, 'Color', 'red', 'FontWeight', 'bold');
        profileData = [dist, c];
    end

    function theta = calculateTheta(x, y, cx, cy)
        dx = cx(2) - cx(1);
        dy = cy(2) - cy(1);
        alpha = atan2(dy, dx) * (180 / pi);
        theta = mod(alpha + 90, 360);
    end

    function autoProfile(~, ~)
        if isempty(currentImg) || isempty(edgeFiles)
            errordlg('Load both raw and edge images first', 'Error'); return;
        end
        idx = get(hEdgeList, 'Value');
        edgeImgPath = fullfile(edgeFolder, edgeFiles{idx});
        edgeImg = imread(edgeImgPath);
        if size(edgeImg,3) == 3, edgeImg = rgb2gray(edgeImg); end
        edgeBin = imbinarize(edgeImg);

        boundaries = bwboundaries(edgeBin);
        if isempty(boundaries)
            errordlg('No boundary found in edge image', 'Error'); return;
        end
        boundary = boundaries{1};
        xBoundary = boundary(:,2); yBoundary = boundary(:,1);
        centerX = mean(xBoundary); centerY = mean(yBoundary);

        nLines = 12; % 30 derajat
        thetaData = linspace(0, 2*pi, nLines+1); thetaData(end) = [];

        axes(hRawAxes); imshow(currentImg); hold on;
        plot(centerX, centerY, 'r+', 'MarkerSize', 10, 'LineWidth', 2);

        if size(currentImg, 3) == 3
            grayImg = rgb2gray(currentImg);
        else
            grayImg = currentImg;
        end

        maxRadius = max([size(grayImg,1), size(grayImg,2)]) / 2;
        profileData = [];
        cla(hPlotAxes);

        for i = 1:length(thetaData)
            angle = thetaData(i);
            xEnd = centerX + maxRadius * cos(angle);
            yEnd = centerY + maxRadius * sin(angle);
            line([centerX xEnd], [centerY yEnd], 'Color', 'g', 'LineWidth', 1.5);

            numSamples = 100;
            [cx, cy, c] = improfile(grayImg, [centerX xEnd], [centerY yEnd], numSamples);
            pixelDist = sqrt(diff(cx).^2 + diff(cy).^2);
            dist = [0; cumsum(pixelDist)];
            if size(c, 2) > 1
                meanIntensity = mean(c, 2);
            else
                meanIntensity = c;
            end
            profileData = [profileData; [repmat(thetaData(i)*180/pi, numSamples, 1), dist, meanIntensity]];
            axes(hPlotAxes); hold on;
            plot(dist, meanIntensity, 'DisplayName', ['\theta = ', num2str(thetaData(i)*180/pi, '%.1f'), '°']);
        end

        hold off; title('Intensity Profiles per \theta');
        xlabel('Distance (pixels)'); ylabel('Intensity'); legend('show'); grid on;
    end

    function saveProfile(~, ~)
        if isempty(profileData)
            errordlg('No profile data to save', 'Error'); return;
        end
        [file, path] = uiputfile('profile_data.csv', 'Save Profile Data');
        if file
            writematrix(profileData, fullfile(path, file));
            msgbox('Profile data saved successfully', 'Success');
        end
    end
end
