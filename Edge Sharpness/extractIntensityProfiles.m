function IntensityProfileExtraction
    % Create main figure window
    fig = figure('Name', 'Intensity Profile Extraction', ...
        'Position', [100, 100, 1200, 700], ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'NumberTitle', 'off');
    
    % Create panels
    filePanel = uipanel('Parent', fig, ...
        'Title', 'File Loader', ...
        'Position', [0.01, 0.7, 0.3, 0.25]);
    
    parametersPanel = uipanel('Parent', fig, ...
        'Title', 'Parameters', ...
        'Position', [0.01, 0.3, 0.3, 0.35]);
    
    controlsPanel = uipanel('Parent', fig, ...
        'Title', 'Simulation Controls', ...
        'Position', [0.01, 0.05, 0.3, 0.2]);
    
    % Create image axis
    axImage = axes('Parent', fig, ...
        'Position', [0.35, 0.4, 0.6, 0.55]);
    title(axImage, 'Image');
    
    % Create profile axis
    axProfile = axes('Parent', fig, ...
        'Position', [0.35, 0.05, 0.6, 0.3]);
    title(axProfile, 'Intensity Profile');
    xlabel(axProfile, 'Distance (pixels)');
    ylabel(axProfile, 'Intensity Value');
    
    % File Panel Components
    uicontrol('Parent', filePanel, ...
        'Style', 'pushbutton', ...
        'String', 'Load Image', ...
        'Position', [20, 100, 120, 30], ...
        'Callback', @loadImageCallback);
    
    uicontrol('Parent', filePanel, ...
        'Style', 'pushbutton', ...
        'String', 'Load Folder', ...
        'Position', [160, 100, 120, 30], ...
        'Callback', @loadFolderCallback);
    
    hImgInfo = uicontrol('Parent', filePanel, ...
        'Style', 'text', ...
        'String', 'No image loaded', ...
        'Position', [20, 50, 260, 40], ...
        'HorizontalAlignment', 'left');
    
    % Navigation buttons
    hPrevButton = uicontrol('Parent', filePanel, ...
        'Style', 'pushbutton', ...
        'String', 'Previous', ...
        'Position', [20, 10, 100, 30], ...
        'Callback', @previousImageCallback, ...
        'Enable', 'off');
    
    hNextButton = uicontrol('Parent', filePanel, ...
        'Style', 'pushbutton', ...
        'String', 'Next', ...
        'Position', [140, 10, 100, 30], ...
        'Callback', @nextImageCallback, ...
        'Enable', 'off');
    
    % Parameters Panel Components
    uicontrol('Parent', parametersPanel, ...
        'Style', 'text', ...
        'String', 'Profile Width (pixels):', ...
        'Position', [20, 180, 150, 20], ...
        'HorizontalAlignment', 'left');
    
    hProfileWidth = uicontrol('Parent', parametersPanel, ...
        'Style', 'edit', ...
        'String', '5', ...
        'Position', [180, 180, 70, 25]);
    
    uicontrol('Parent', parametersPanel, ...
        'Style', 'text', ...
        'String', 'Smoothing Window:', ...
        'Position', [20, 140, 150, 20], ...
        'HorizontalAlignment', 'left');
    
    hSmoothWindow = uicontrol('Parent', parametersPanel, ...
        'Style', 'edit', ...
        'String', '3', ...
        'Position', [180, 140, 70, 25]);
    
    hBackgroundSubtract = uicontrol('Parent', parametersPanel, ...
        'Style', 'checkbox', ...
        'String', 'Background Subtraction', ...
        'Value', 1, ...
        'Position', [20, 100, 200, 30]);
    
    uicontrol('Parent', parametersPanel, ...
        'Style', 'text', ...
        'String', 'Profile Direction:', ...
        'Position', [20, 70, 150, 20], ...
        'HorizontalAlignment', 'left');
    
    hDirection = uicontrol('Parent', parametersPanel, ...
        'Style', 'popupmenu', ...
        'String', {'Horizontal', 'Vertical', 'Custom Line'}, ...
        'Position', [180, 70, 100, 25], ...
        'Callback', @directionCallback);
    
    uicontrol('Parent', parametersPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Apply Parameters', ...
        'Position', [80, 20, 120, 30], ...
        'Callback', @applyParametersCallback);
    
    % Controls Panel Components
    uicontrol('Parent', controlsPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Extract Profile', ...
        'Position', [20, 80, 120, 30], ...
        'Callback', @extractProfileCallback);
    
    uicontrol('Parent', controlsPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Save Profile', ...
        'Position', [160, 80, 120, 30], ...
        'Callback', @saveProfileCallback);
    
    uicontrol('Parent', controlsPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Save Image', ...
        'Position', [20, 30, 120, 30], ...
        'Callback', @saveImageCallback);
    
    uicontrol('Parent', controlsPanel, ...
        'Style', 'pushbutton', ...
        'String', 'Reset', ...
        'Position', [160, 30, 120, 30], ...
        'Callback', @resetCallback);
    
    % Application data
    appData = struct(...
        'currentImage', [], ...
        'imageFiles', {{}}, ...
        'currentFileIndex', 1, ...
        'profileStartPoint', [], ...
        'profileEndPoint', [], ...
        'profileData', [], ...
        'profileLine', [], ...
        'profilePlot', [], ...
        'roiRect', []);
    
    % Set application data
    setappdata(fig, 'AppData', appData);
    
    % Callback functions
    function loadImageCallback(~, ~)
        [filename, pathname] = uigetfile({'*.tif;*.tiff;*.jpg;*.jpeg;*.png;*.bmp', 'Image Files'}, 'Select an Image');
        
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        end
        
        fullPath = fullfile(pathname, filename);
        appData.imageFiles = {fullPath};
        appData.currentFileIndex = 1;
        
        loadAndDisplayImage(fullPath);
        
        % Update navigation buttons
        set(hPrevButton, 'Enable', 'off');
        set(hNextButton, 'Enable', 'off');
        
        % Update app data
        setappdata(fig, 'AppData', appData);
    end

    function loadFolderCallback(~, ~)
        folderPath = uigetdir('', 'Select a folder with images');
        
        if isequal(folderPath, 0)
            return;
        end
        
        % Find all image files in the folder
        fileExtensions = {'*.tif', '*.tiff', '*.jpg', '*.jpeg', '*.png', '*.bmp'};
        imageFiles = {};
        
        for i = 1:length(fileExtensions)
            files = dir(fullfile(folderPath, fileExtensions{i}));
            for j = 1:length(files)
                imageFiles{end+1} = fullfile(folderPath, files(j).name);
            end
        end
        
        if isempty(imageFiles)
            set(hImgInfo, 'String', 'No image files found in folder');
            return;
        end
        
        % Sort the files alphabetically
        imageFiles = sort(imageFiles);
        
        % Update app data
        appData.imageFiles = imageFiles;
        appData.currentFileIndex = 1;
        
        % Load first image
        loadAndDisplayImage(imageFiles{1});
        
        % Update navigation buttons
        updateNavigationButtons();
        
        % Update app data
        setappdata(fig, 'AppData', appData);
    end

    function previousImageCallback(~, ~)
        if appData.currentFileIndex > 1
            appData.currentFileIndex = appData.currentFileIndex - 1;
            loadAndDisplayImage(appData.imageFiles{appData.currentFileIndex});
            updateNavigationButtons();
            setappdata(fig, 'AppData', appData);
        end
    end

    function nextImageCallback(~, ~)
        if appData.currentFileIndex < length(appData.imageFiles)
            appData.currentFileIndex = appData.currentFileIndex + 1;
            loadAndDisplayImage(appData.imageFiles{appData.currentFileIndex});
            updateNavigationButtons();
            setappdata(fig, 'AppData', appData);
        end
    end

    function directionCallback(src, ~)
        direction = get(src, 'Value');
        
        % Clear any existing lines or rectangles
        if ~isempty(appData.profileLine) && ishandle(appData.profileLine)
            delete(appData.profileLine);
            appData.profileLine = [];
        end
        
        if ~isempty(appData.roiRect) && ishandle(appData.roiRect)
            delete(appData.roiRect);
            appData.roiRect = [];
        end
        
        % If there's no image loaded, return
        if isempty(appData.currentImage)
            return;
        end
        
        % Set up based on direction
        axes(axImage);
        [height, width, ~] = size(appData.currentImage);
        
        switch direction
            case 1 % Horizontal
                mid_y = round(height/2);
                appData.profileStartPoint = [1, mid_y];
                appData.profileEndPoint = [width, mid_y];
                appData.profileLine = line([1, width], [mid_y, mid_y], 'Color', 'r', 'LineWidth', 2);
            case 2 % Vertical
                mid_x = round(width/2);
                appData.profileStartPoint = [mid_x, 1];
                appData.profileEndPoint = [mid_x, height];
                appData.profileLine = line([mid_x, mid_x], [1, height], 'Color', 'r', 'LineWidth', 2);
            case 3 % Custom Line
                title(axImage, 'Click and drag to define profile line');
                % Custom line will be drawn with mouse interaction
        end
        
        setappdata(fig, 'AppData', appData);
    end

    function applyParametersCallback(~, ~)
        if ~isempty(appData.profileStartPoint) && ~isempty(appData.profileEndPoint)
            extractProfile();
        else
            msgbox('Please select a profile line first', 'Warning', 'warn');
        end
    end

    function extractProfileCallback(~, ~)
        if isempty(appData.currentImage)
            msgbox('Please load an image first', 'Warning', 'warn');
            return;
        end
        
        if isempty(appData.profileStartPoint) || isempty(appData.profileEndPoint)
            msgbox('Please select a profile line first', 'Warning', 'warn');
            return;
        end
        
        extractProfile();
    end

    function saveProfileCallback(~, ~)
        if isempty(appData.profileData)
            msgbox('No profile data to save', 'Warning', 'warn');
            return;
        end
        
        [filename, pathname] = uiputfile('*.csv', 'Save Profile Data');
        
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        end
        
        fullPath = fullfile(pathname, filename);
        distance = 0:(length(appData.profileData)-1);
        data = [distance', appData.profileData'];
        
        % Create header
        header = 'Distance,Intensity';
        
        % Write data with header
        fid = fopen(fullPath, 'w');
        fprintf(fid, '%s\n', header);
        fclose(fid);
        
        % Append data
        dlmwrite(fullPath, data, '-append');
        
        msgbox(['Profile data saved to ', fullPath], 'Save Complete');
    end

    function saveImageCallback(~, ~)
        if isempty(appData.currentImage)
            msgbox('No image to save', 'Warning', 'warn');
            return;
        end
        
        [filename, pathname] = uiputfile({'*.png', 'PNG Files (*.png)'; '*.jpg', 'JPEG Files (*.jpg)'; '*.tif', 'TIFF Files (*.tif)'}, 'Save Image');
        
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        end
        
        fullPath = fullfile(pathname, filename);
        
        % Capture the current figure
        frame = getframe(fig);
        img = frame2im(frame);
        
        % Save the image
        imwrite(img, fullPath);
        
        msgbox(['Image saved to ', fullPath], 'Save Complete');
    end

    function resetCallback(~, ~)
        % Clear profile line and data
        if ~isempty(appData.profileLine) && ishandle(appData.profileLine)
            delete(appData.profileLine);
        end
        
        if ~isempty(appData.roiRect) && ishandle(appData.roiRect)
            delete(appData.roiRect);
        end
        
        appData.profileLine = [];
        appData.roiRect = [];
        appData.profileStartPoint = [];
        appData.profileEndPoint = [];
        appData.profileData = [];
        
        % Clear profile plot
        cla(axProfile);
        title(axProfile, 'Intensity Profile');
        xlabel(axProfile, 'Distance (pixels)');
        ylabel(axProfile, 'Intensity Value');
        
        % Reset direction
        set(hDirection, 'Value', 3);
        
        % Update app data
        setappdata(fig, 'AppData', appData);
        
        % Update title
        title(axImage, 'Click and drag to define profile line');
    end

    % Helper functions
    function loadAndDisplayImage(imagePath)
        try
            % Load the image
            img = imread(imagePath);
            
            % Store the image
            appData.currentImage = img;
            
            % Display image info
            [~, name, ext] = fileparts(imagePath);
            [height, width, channels] = size(img);
            
            if channels == 1
                colorType = 'Grayscale';
            else
                colorType = 'RGB';
            end
            
            infoStr = sprintf('File: %s%s\nSize: %d x %d\nType: %s', name, ext, width, height, colorType);
            set(hImgInfo, 'String', infoStr);
            
            % Display the image
            axes(axImage);
            imshow(img);
            title(axImage, 'Click and drag to define profile line');
            
            % Set up mouse callbacks for the image
            set(fig, 'WindowButtonDownFcn', @mouseDown);
            set(fig, 'WindowButtonUpFcn', @mouseUp);
            set(fig, 'WindowButtonMotionFcn', @mouseMove);
            
            % Reset profile data
            appData.profileStartPoint = [];
            appData.profileEndPoint = [];
            appData.profileData = [];
            
            % Clear profile line
            if ~isempty(appData.profileLine) && ishandle(appData.profileLine)
                delete(appData.profileLine);
                appData.profileLine = [];
            end
            
            % Clear profile plot
            cla(axProfile);
            title(axProfile, 'Intensity Profile');
            xlabel(axProfile, 'Distance (pixels)');
            ylabel(axProfile, 'Intensity Value');
            
        catch e
            errordlg(['Error loading image: ', e.message], 'Error');
        end
    end

    function updateNavigationButtons()
        % Enable/disable navigation buttons based on current index
        if appData.currentFileIndex <= 1
            set(hPrevButton, 'Enable', 'off');
        else
            set(hPrevButton, 'Enable', 'on');
        end
        
        if appData.currentFileIndex >= length(appData.imageFiles)
            set(hNextButton, 'Enable', 'off');
        else
            set(hNextButton, 'Enable', 'on');
        end
    end

    % Mouse interaction for custom line profile
    function mouseDown(~, ~)
        % Check if we're in custom line mode
        if get(hDirection, 'Value') ~= 3
            return;
        end
        
        % Get the current point
        cp = get(axImage, 'CurrentPoint');
        x = round(cp(1, 1));
        y = round(cp(1, 2));
        
        % Check if the point is within the image
        [height, width, ~] = size(appData.currentImage);
        
        if x < 1 || x > width || y < 1 || y > height
            return;
        end
        
        % Set the start point
        appData.profileStartPoint = [x, y];
        appData.profileEndPoint = [x, y];
        
        % Create a line
        if ~isempty(appData.profileLine) && ishandle(appData.profileLine)
            delete(appData.profileLine);
        end
        
        appData.profileLine = line(axImage, [x, x], [y, y], 'Color', 'r', 'LineWidth', 2);
        
        % Update app data
        setappdata(fig, 'AppData', appData);
    end

    function mouseMove(~, ~)
        % Check if we have a start point
        if isempty(appData.profileStartPoint) || get(hDirection, 'Value') ~= 3
            return;
        end
        
        % Get the current point
        cp = get(axImage, 'CurrentPoint');
        x = round(cp(1, 1));
        y = round(cp(1, 2));
        
        % Check if the point is within the image
        [height, width, ~] = size(appData.currentImage);
        
        if x < 1
            x = 1;
        elseif x > width
            x = width;
        end
        
        if y < 1
            y = 1;
        elseif y > height
            y = height;
        end
        
        % Update the end point
        appData.profileEndPoint = [x, y];
        
        % Update the line
        set(appData.profileLine, 'XData', [appData.profileStartPoint(1), x], 'YData', [appData.profileStartPoint(2), y]);
        
        % Update app data
        setappdata(fig, 'AppData', appData);
    end

    function mouseUp(~, ~)
        % Check if we have a start and end point
        if isempty(appData.profileStartPoint) || isempty(appData.profileEndPoint) || get(hDirection, 'Value') ~= 3
            return;
        end
        
        % Make sure start and end points are different
        if isequal(appData.profileStartPoint, appData.profileEndPoint)
            % Reset if the same point
            if ~isempty(appData.profileLine) && ishandle(appData.profileLine)
                delete(appData.profileLine);
                appData.profileLine = [];
            end
            
            appData.profileStartPoint = [];
            appData.profileEndPoint = [];
            
            setappdata(fig, 'AppData', appData);
            return;
        end
        
        % Extract the profile along the line
        extractProfile();
    end

    function extractProfile()
        % Get profile width
        profileWidth = str2double(get(hProfileWidth, 'String'));
        if isnan(profileWidth) || profileWidth < 1
            profileWidth = 1;
            set(hProfileWidth, 'String', '1');
        end
        
        % Get smoothing window
        smoothWindow = str2double(get(hSmoothWindow, 'String'));
        if isnan(smoothWindow) || smoothWindow < 1
            smoothWindow = 1;
            set(hSmoothWindow, 'String', '1');
        end
        
        % Convert even smoothing window to odd
        if mod(smoothWindow, 2) == 0
            smoothWindow = smoothWindow + 1;
            set(hSmoothWindow, 'String', num2str(smoothWindow));
        end
        
        % Get background subtraction flag
        bgSubtract = get(hBackgroundSubtract, 'Value');
        
        % Extract profile
        x1 = appData.profileStartPoint(1);
        y1 = appData.profileStartPoint(2);
        x2 = appData.profileEndPoint(1);
        y2 = appData.profileEndPoint(2);
        
        % Calculate length of the line
        lineLength = sqrt((x2-x1)^2 + (y2-y1)^2);
        
        % Create a vector with points along the line
        t = 0:1/lineLength:1;
        x = x1 + t * (x2 - x1);
        y = y1 + t * (y2 - y1);
        
        % Calculate normal vector to the line
        dx = x2 - x1;
        dy = y2 - y1;
        norm_x = -dy / sqrt(dx^2 + dy^2);
        norm_y = dx / sqrt(dx^2 + dy^2);
        
        % Get the image
        img = appData.currentImage;
        
        % Convert to grayscale if RGB
        if size(img, 3) > 1
            img = rgb2gray(img);
        end
        
        % Create ROI visualization
        if ~isempty(appData.roiRect) && ishandle(appData.roiRect)
            delete(appData.roiRect);
        end
        
        % Create line profile
        profile = zeros(size(t));
        
        for i = 1:length(t)
            sum_intensity = 0;
            count = 0;
            
            for w = -floor(profileWidth/2):floor(profileWidth/2)
                sample_x = round(x(i) + w * norm_x);
                sample_y = round(y(i) + w * norm_y);
                
                % Check if within image bounds
                if sample_x >= 1 && sample_x <= size(img, 2) && ...
                        sample_y >= 1 && sample_y <= size(img, 1)
                    sum_intensity = sum_intensity + double(img(sample_y, sample_x));
                    count = count + 1;
                end
            end
            
            if count > 0
                profile(i) = sum_intensity / count;
            end
        end
        
        % Background subtraction if requested
        if bgSubtract
            profile = profile - min(profile);
        end
        
        % Smoothing if requested
        if smoothWindow > 1
            profile = smooth(profile, smoothWindow);
        end
        
        % Store profile data
        appData.profileData = profile;
        
        % Plot the profile
        axes(axProfile);
        cla(axProfile);
        appData.profilePlot = plot(axProfile, 1:length(profile), profile, 'b-', 'LineWidth', 2);
        title(axProfile, 'Intensity Profile');
        xlabel(axProfile, 'Distance (pixels)');
        ylabel(axProfile, 'Intensity Value');
        grid(axProfile, 'on');
        
        % Visualize the ROI on the image
        axes(axImage);
        hold on;
        
        % Plot ROI width along the line
        roi_x = [];
        roi_y = [];
        
        for i = 1:length(t)
            for w = -floor(profileWidth/2):floor(profileWidth/2)
                roi_x(end+1) = x(i) + w * norm_x;
                roi_y(end+1) = y(i) + w * norm_y;
            end
        end
        
        appData.roiRect = plot(axImage, roi_x, roi_y, 'g.', 'MarkerSize', 1);
        hold off;
        
        % Update app data
        setappdata(fig, 'AppData', appData);
    end
end
