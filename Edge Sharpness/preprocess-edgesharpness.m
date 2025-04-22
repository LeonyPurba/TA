function image_adjust_brightness_contrast
    % Create the main GUI figure
    hFig = figure('Name', 'Image Adjustment', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 800, 600]);

    % Create UI components
    uicontrol('Style', 'pushbutton', 'String', 'Load Image', ...
              'Position', [20, 550, 100, 30], 'Callback', @loadImageCallback);

    uicontrol('Style', 'text', 'String', 'Brightness', ...
              'Position', [20, 500, 60, 20]);
    hBrightnessSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                                  'Position', [90, 500, 200, 20], 'Callback', @adjustImage);
    hBrightnessValue = uicontrol('Style', 'edit', 'String', '1', ...
                                 'Position', [300, 500, 40, 20], 'Callback', @editBrightness);

    uicontrol('Style', 'text', 'String', 'Contrast', ...
              'Position', [20, 460, 60, 20]);
    hContrastSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                                'Position', [90, 460, 200, 20], 'Callback', @adjustImage);
    hContrastValue = uicontrol('Style', 'edit', 'String', '1', ...
                               'Position', [300, 460, 40, 20], 'Callback', @editContrast);

    uicontrol('Style', 'pushbutton', 'String', 'Save Image', ...
              'Position', [20, 400, 100, 30], 'Callback', @saveImageCallback);

    hAxes = axes('Units', 'pixels', 'Position', [350, 100, 400, 400]);

    % Initialize variables
    currentImage = [];
    adjustedImage = [];

    function loadImageCallback(~, ~)
        [fileName, pathName] = uigetfile({'*.jpg;*.png;*.bmp;*.tiff'}, 'Select an Image');
        if fileName == 0
            return;
        end
        imgPath = fullfile(pathName, fileName);
        currentImage = imread(imgPath);
        imshow(currentImage, 'Parent', hAxes);
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

        % Show adjusted image
        imshow(adjustedImage, 'Parent', hAxes);
    end

    function saveImageCallback(~, ~)
        if isempty(adjustedImage)
            return;
        end
        [fileName, pathName] = uiputfile({'*.png'}, 'Save Image As');
        if fileName == 0
            return;
        end
        imwrite(adjustedImage, fullfile(pathName, fileName));
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
end
