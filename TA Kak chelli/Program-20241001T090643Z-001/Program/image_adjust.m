function image_adjust
    % Create the main GUI figure
    hFig = figure('Name', 'Image Adjustment', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1400, 800]);

    % Create UI components
    uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
              'Position', [20, 750, 100, 30], 'Callback', @loadFolderCallback);

    % Pre-Processing Title
    uicontrol('Style', 'text', 'String', 'Pre-Processing', 'FontSize', 12, 'FontWeight', 'bold', ...
              'Position', [20, 720, 200, 30]);

    uicontrol('Style', 'text', 'String', 'Brightness', ...
              'Position', [20, 700, 60, 20]);
    hBrightnessSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                                  'Position', [90, 700, 200, 20], 'Callback', @adjustImage);
    hBrightnessValue = uicontrol('Style', 'edit', 'String', '1', ...
                                 'Position', [300, 700, 40, 20], 'Callback', @editBrightness);

    uicontrol('Style', 'text', 'String', 'Contrast', ...
              'Position', [20, 660, 60, 20]);
    hContrastSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 2, 'Value', 1, ...
                                'Position', [90, 660, 200, 20], 'Callback', @adjustImage);
    hContrastValue = uicontrol('Style', 'edit', 'String', '1', ...
                               'Position', [300, 660, 40, 20], 'Callback', @editContrast);

    % Gaussian Filtering Title
    uicontrol('Style', 'text', 'String', 'Gaussian Filtering', 'FontSize', 12, 'FontWeight', 'bold', ...
              'Position', [20, 620, 200, 30]);

    uicontrol('Style', 'text', 'String', 'Kernel Size', ...
              'Position', [20, 600, 60, 20]);
    hKernelSlider = uicontrol('Style', 'slider', 'Min', 1, 'Max', 21, 'Value', 7, ...
                              'Position', [90, 600, 200, 20], 'Callback', @applyGaussianFilter);
    hKernelValue = uicontrol('Style', 'edit', 'String', '7', ...
                             'Position', [300, 600, 40, 20], 'Callback', @editKernelSize);

    uicontrol('Style', 'text', 'String', 'Sigma', ...
              'Position', [20, 560, 60, 20]);
    hSigmaSlider = uicontrol('Style', 'slider', 'Min', 0.1, 'Max', 5, 'Value', 2.5, ...
                             'Position', [90, 560, 200, 20], 'Callback', @applyGaussianFilter);
    hSigmaValue = uicontrol('Style', 'edit', 'String', '2.5', ...
                            'Position', [300, 560, 40, 20], 'Callback', @editSigma);

    % Median Filter Title
    uicontrol('Style', 'text', 'String', 'Median Filtering', 'FontSize', 12, 'FontWeight', 'bold', ...
              'Position', [20, 520, 200, 30]);

    uicontrol('Style', 'text', 'String', 'Kernel Size', ...
              'Position', [20, 500, 60, 20]);
    hMedianKernelSlider = uicontrol('Style', 'slider', 'Min', 1, 'Max', 21, 'Value', 7, ...
                                    'Position', [90, 500, 200, 20], 'Callback', @adjustImage);
    hMedianKernelValue = uicontrol('Style', 'edit', 'String', '7', ...
                                   'Position', [300, 500, 40, 20], 'Callback', @editMedianKernelSize);

    % Threshold Title
    uicontrol('Style', 'text', 'String', 'Threshold', 'FontSize', 12, 'FontWeight', 'bold', ...
              'Position', [20, 460, 100, 20]);
    hThresholdSlider = uicontrol('Style', 'slider', 'Min', 0, 'Max', 255, 'Value', 60, ...
                                 'Position', [20, 440, 200, 20], 'Callback', @adjustImage);
    hThresholdValue = uicontrol('Style', 'edit', 'String', '60', ...
                                'Position', [230, 440, 40, 20], 'Callback', @editThreshold);

    uicontrol('Style', 'pushbutton', 'String', 'Save Image', ...
              'Position', [20, 400, 100, 30], 'Callback', @saveImageCallback);

    uicontrol('Style', 'pushbutton', 'String', 'Save All to Folder', ...
              'Position', [20, 360, 150, 30], 'Callback', @saveAllToFolderCallback);

    hImageListbox = uicontrol('Style', 'listbox', 'Position', [20, 20, 150, 320], ...
                              'Callback', @displaySelectedImage);

    hAxes = axes('Units', 'pixels', 'Position', [350, 100, 1000, 600]);

    hImageSizeText = uicontrol('Style', 'text', 'String', 'Image Size: ', ...
                               'Position', [350, 50, 200, 20]);

    % Initialize variables
    imageFiles = {};
    currentImage = [];
    filteredImage = [];
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
        filteredImage = currentImage;
        
        % Load saved parameters if they exist
        if ~isempty(imageParams{index})
            params = imageParams{index};
            set(hKernelSlider, 'Value', params.kernelSize);
            set(hSigmaSlider, 'Value', params.sigma);
            set(hBrightnessSlider, 'Value', params.brightness);
            set(hContrastSlider, 'Value', params.contrast);
            set(hMedianKernelSlider, 'Value', params.medianKernelSize);
            set(hThresholdSlider, 'Value', params.threshold);
            updateSliderTextValues();
        else
            set(hKernelSlider, 'Value', 7);
            set(hSigmaSlider, 'Value', 2.5);
            set(hBrightnessSlider, 'Value', 1);
            set(hContrastSlider, 'Value', 1);
            set(hMedianKernelSlider, 'Value', 7);
            set(hThresholdSlider, 'Value', 60);
        end
        
        applyGaussianFilter();
        imageSize = size(currentImage);
        set(hImageSizeText, 'String', sprintf('Image Size: %d x %d', imageSize(2), imageSize(1)));
    end

    function applyGaussianFilter(~, ~)
        if isempty(currentImage)
            return;
        end
        kernelSize = round(get(hKernelSlider, 'Value'));
        if mod(kernelSize, 2) == 0 % Ensure kernel size is odd
            kernelSize = kernelSize + 1;
        end
        sigma = get(hSigmaSlider, 'Value');

        % Update text values
        set(hKernelValue, 'String', num2str(kernelSize, '%d'));
        set(hSigmaValue, 'String', num2str(sigma, '%.2f'));

        % Create Gaussian kernel
        halfSize = (kernelSize - 1) / 2;
        [x, y] = meshgrid(-halfSize:halfSize, -halfSize:halfSize);
        kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
        kernel = kernel / sum(kernel(:)); % Normalize the kernel

        % Apply Gaussian filter
        filteredImage = imfilter(currentImage, kernel, 'replicate');

        % Show the filtered image
        imshow(filteredImage, 'Parent', hAxes);

        % Adjust the image after filtering
        adjustImage();
    end

    function adjustImage(~, ~)
        if isempty(filteredImage)
            return;
        end
        brightness = get(hBrightnessSlider, 'Value');
        contrast = get(hContrastSlider, 'Value');
        medianKernelSize = round(get(hMedianKernelSlider, 'Value'));
        if mod(medianKernelSize, 2) == 0 % Ensure kernel size is odd
            medianKernelSize = medianKernelSize + 1;
        end
        threshold = get(hThresholdSlider, 'Value');

        % Update text values
        set(hBrightnessValue, 'String', num2str(brightness, '%.2f'));
        set(hContrastValue, 'String', num2str(contrast, '%.2f'));
        set(hMedianKernelValue, 'String', num2str(medianKernelSize, '%d'));
        set(hThresholdValue, 'String', num2str(threshold, '%.0f'));

        % Adjust brightness and contrast
        adjustedImage = imadjust(filteredImage, stretchlim(filteredImage, [0; 1]), [0; 1], contrast);
        adjustedImage = adjustedImage * brightness;

        % Apply median filter from scratch
        adjustedImage = applyMedianFilter(adjustedImage, medianKernelSize);

        % Apply threshold after brightness and contrast adjustments
        adjustedImage(adjustedImage < threshold) = 0;
%         adjustedImage(adjustedImage >= threshold) = 255;

        imshow(adjustedImage, 'Parent', hAxes);

        % Store the adjusted image and parameters
        index = get(hImageListbox, 'Value');
        if ~isempty(index) && index > 0
            adjustedImages{index} = adjustedImage;
            imageParams{index} = struct('kernelSize', get(hKernelSlider, 'Value'), ...
                                        'sigma', get(hSigmaSlider, 'Value'), ...
                                        'brightness', get(hBrightnessSlider, 'Value'), ...
                                        'contrast', get(hContrastSlider, 'Value'), ...
                                        'medianKernelSize', get(hMedianKernelSlider, 'Value'), ...
                                        'threshold', get(hThresholdSlider, 'Value'));
        end
    end

    function saveImageCallback(~, ~)
        index = get(hImageListbox, 'Value');
        if isempty(adjustedImages{index})
            return;
        end
        
        % Convert the adjusted image to binary with 0 and 255 values
        binaryImage = adjustedImages{index};
        binaryImage = uint8(binaryImage) * 255;
        
        [fileName, pathName] = uiputfile({'*.png'}, 'Save Image As');
        if fileName == 0
            return;
        end
        imwrite(binaryImage, fullfile(pathName, fileName));
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
                % Convert the adjusted image to binary with 0 and 255 values
                binaryImage = adjustedImages{i};
                binaryImage = uint8(binaryImage) * 255;
                
                [~, name, ext] = fileparts(imageFiles(i).name);
                outputPath = fullfile(folderName, [name, '_threshold', ext]);
                imwrite(binaryImage, outputPath);
            end
        end
        msgbox('All adjusted images have been saved.', 'Success');
    end


    function editKernelSize(~, ~)
        val = str2double(get(hKernelValue, 'String'));
        if isnan(val) || val < 1 || val > 21 || mod(val, 2) == 0
            set(hKernelValue, 'String', num2str(get(hKernelSlider, 'Value')));
        else
            set(hKernelSlider, 'Value', val);
            applyGaussianFilter();
        end
    end

    function editSigma(~, ~)
        val = str2double(get(hSigmaValue, 'String'));
        if isnan(val) || val < 0.1 || val > 5
            set(hSigmaValue, 'String', num2str(get(hSigmaSlider, 'Value')));
        else
            set(hSigmaSlider, 'Value', val);
            applyGaussianFilter();
        end
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

    function editMedianKernelSize(~, ~)
        val = str2double(get(hMedianKernelValue, 'String'));
        if isnan(val) || val < 1 || val > 21 || mod(val, 2) == 0
            set(hMedianKernelValue, 'String', num2str(get(hMedianKernelSlider, 'Value')));
        else
            set(hMedianKernelSlider, 'Value', val);
            adjustImage();
        end
    end

    function editThreshold(~, ~)
        val = str2double(get(hThresholdValue, 'String'));
        if isnan(val) || val < 0 || val > 255
            set(hThresholdValue, 'String', num2str(get(hThresholdSlider, 'Value')));
        else
            set(hThresholdSlider, 'Value', val);
            adjustImage();
        end
    end

    function updateSliderTextValues()
        % Update slider text values
        set(hKernelValue, 'String', num2str(get(hKernelSlider, 'Value'), '%d'));
        set(hSigmaValue, 'String', num2str(get(hSigmaSlider, 'Value'), '%.2f'));
        set(hBrightnessValue, 'String', num2str(get(hBrightnessSlider, 'Value'), '%.2f'));
        set(hContrastValue, 'String', num2str(get(hContrastSlider, 'Value'), '%.2f'));
        set(hMedianKernelValue, 'String', num2str(get(hMedianKernelSlider, 'Value'), '%d'));
        set(hThresholdValue, 'String', num2str(get(hThresholdSlider, 'Value'), '%.0f'));
    end

    function outputImage = applyMedianFilter(inputImage, kernelSize)
        % Apply a median filter from scratch
        paddedImage = padarray(inputImage, [floor(kernelSize/2), floor(kernelSize/2)], 'symmetric');
        outputImage = zeros(size(inputImage), 'like', inputImage);

        for i = 1:size(inputImage, 1)
            for j = 1:size(inputImage, 2)
                neighborhood = paddedImage(i:i+kernelSize-1, j:j+kernelSize-1);
                outputImage(i, j) = median(neighborhood(:));
            end
        end
    end
end
