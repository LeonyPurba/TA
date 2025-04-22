function image_adjust
    % Create the main GUI figure
    hFig = figure('Name', 'Image Brightness and Contrast Adjustment', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1200, 700]);

    % Create UI components
    uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
              'Position', [20, 650, 100, 30], 'Callback', @loadFolderCallback);

    % Pre-Processing Title
    uicontrol('Style', 'text', 'String', 'Image Adjustment', 'FontSize', 12, 'FontWeight', 'bold', ...
              'Position', [20, 620, 200, 30]);

    uicontrol('Style', 'text', 'String', 'Brightness', ...
              'Position', [20, 590, 60, 20]);
    hBrightnessSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                                  'Position', [90, 590, 200, 20], 'Callback', @adjustImage);
    hBrightnessValue = uicontrol('Style', 'edit', 'String', '1', ...
                                 'Position', [300, 590, 40, 20], 'Callback', @editBrightness);

    uicontrol('Style', 'text', 'String', 'Contrast', ...
              'Position', [20, 550, 60, 20]);
    hContrastSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                                'Position', [90, 550, 200, 20], 'Callback', @adjustImage);
    hContrastValue = uicontrol('Style', 'edit', 'String', '1', ...
                               'Position', [300, 550, 40, 20], 'Callback', @editContrast);

    uicontrol('Style', 'pushbutton', 'String', 'Save Image', ...
              'Position', [20, 510, 100, 30], 'Callback', @saveImageCallback);

    uicontrol('Style', 'pushbutton', 'String', 'Save All to Folder', ...
              'Position', [20, 470, 150, 30], 'Callback', @saveAllToFolderCallback);
              
    uicontrol('Style', 'pushbutton', 'String', 'Close', ...
              'Position', [20, 430, 100, 30], 'Callback', @closeCallback);

    hImageListbox = uicontrol('Style', 'listbox', 'Position', [20, 20, 150, 400], ...
                              'Callback', @displaySelectedImage);

    hAxes = axes('Units', 'pixels', 'Position', [350, 100, 800, 550]);

    hImageSizeText = uicontrol('Style', 'text', 'String', 'Image Size: ', ...
                               'Position', [350, 50, 200, 20]);

    % Initialize variables
    imageFiles = {};
    currentImage = [];
    adjustedImage = [];
    adjustedImages = {};
    imageParams = {};

    function loadFolderCallback(~, ~)
        folderName = uigetdir;
        if folderName == 0
            return;
        end
        imageFiles = getAllImages(folderName);
        set(hImageListbox, 'String', {imageFiles.name});
        adjustedImages = cell(length(imageFiles), 1);
        imageParams = cell(length(imageFiles), 1);
    end

    function files = getAllImages(folderName)
        files = [];
        imageTypes = {'*.jpg', '*.png', '*.bmp', '*.tiff'};
        for i = 1:length(imageTypes)
            newFiles = dir(fullfile(folderName, '**', imageTypes{i}));
            files = [files; newFiles];
        end
    end

    function displaySelectedImage(~, ~)
        index = get(hImageListbox, 'Value');
        if isempty(index) || index == 0
            return;
        end
        imgPath = fullfile(imageFiles(index).folder, imageFiles(index).name);
        currentImage = imread(imgPath);
        
        % Load saved parameters if they exist
        if ~isempty(imageParams{index})
            params = imageParams{index};
            set(hBrightnessSlider, 'Value', params.brightness);
            set(hContrastSlider, 'Value', params.contrast);
            updateSliderTextValues();
        else
            set(hBrightnessSlider, 'Value', 1);
            set(hContrastSlider, 'Value', 1);
            updateSliderTextValues();
        end
        
        % Show the original image first
        imshow(currentImage, 'Parent', hAxes);
        
        % Apply adjustments
        adjustImage();
        
        % Update image size text
        imageSize = size(currentImage);
        set(hImageSizeText, 'String', sprintf('Image Size: %d x %d', imageSize(2), imageSize(1)));
    end

    function adjustImage(~, ~)
        if isempty(currentImage)
            return;
        end
        brightness = get(hBrightnessSlider, 'Value');
        contrast = get(hContrastSlider, 'Value');

        % Update text values
        set(hBrightnessValue, 'String', num2str(brightness, '%.2f'));
        set(hContrastValue, 'String', num2str(contrast, '%.2f'));

        % Adjust brightness and contrast
        adjustedImage = imadjust(currentImage, stretchlim(currentImage, [0; 1]), [0; 1], contrast);
        adjustedImage = adjustedImage * brightness;

        imshow(adjustedImage, 'Parent', hAxes);

        % Store the adjusted image and parameters
        index = get(hImageListbox, 'Value');
        if ~isempty(index) && index > 0
            adjustedImages{index} = adjustedImage;
            imageParams{index} = struct('brightness', get(hBrightnessSlider, 'Value'), ...
                                        'contrast', get(hContrastSlider, 'Value'));
        end
    end

    function saveImageCallback(~, ~)
        index = get(hImageListbox, 'Value');
        if isempty(index) || isempty(adjustedImages{index})
            return;
        end
        
        [fileName, pathName] = uiputfile({'*.png;*.jpg;*.bmp;*.tiff'}, 'Save Image As');
        if fileName == 0
            return;
        end
        imwrite(adjustedImages{index}, fullfile(pathName, fileName));
    end
    
    function saveAllToFolderCallback(~, ~)
        if isempty(adjustedImages)
            return;
        end
        folderName = uigetdir;
        if folderName == 0
            return;
        end
        for i = 1:length(adjustedImages)
            if ~isempty(adjustedImages{i})
                [~, name, ext] = fileparts(imageFiles(i).name);
                outputPath = fullfile(folderName, [name, '_adjusted', ext]);
                imwrite(adjustedImages{i}, outputPath);
            end
        end
        msgbox('All adjusted images have been saved.', 'Success');
    end

    function editBrightness(~, ~)
        val = str2double(get(hBrightnessValue, 'String'));
        if isnan(val) || val < 0 || val > 2
            set(hBrightnessValue, 'String', num2str(get(hBrightnessSlider, 'Value')));
        else
            set(hBrightnessSlider, 'Value', val);
            adjustImage();
        end
    end

    function editContrast(~, ~)
        val = str2double(get(hContrastValue, 'String'));
        if isnan(val) || val < 0 || val > 2
            set(hContrastValue, 'String', num2str(get(hContrastSlider, 'Value')));
        else
            set(hContrastSlider, 'Value', val);
            adjustImage();
        end
    end

    function updateSliderTextValues()
        % Update slider text values
        set(hBrightnessValue, 'String', num2str(get(hBrightnessSlider, 'Value'), '%.2f'));
        set(hContrastValue, 'String', num2str(get(hContrastSlider, 'Value'), '%.2f'));
    end
    
    function closeCallback(~, ~)
        % Close the figure
        close(hFig);
    end
end