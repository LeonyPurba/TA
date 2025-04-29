function resize_images_gui_simple()
    % Global variables
    global imgFolder imgFiles outputFolder hOriginal hResized;

    % Create GUI window
    fig = figure('Name', 'Image Resizer 256x256', 'Position', [100, 100, 600, 400]);
    
    % Buttons
    uicontrol('Style', 'pushbutton', 'String', 'Select Input Folder', ...
        'Position', [50, 340, 150, 30], 'Callback', @selectInputFolder);
    
    uicontrol('Style', 'pushbutton', 'String', 'Select Output Folder', ...
        'Position', [225, 340, 150, 30], 'Callback', @selectOutputFolder);
    
    uicontrol('Style', 'pushbutton', 'String', 'Resize Images', ...
        'Position', [400, 340, 150, 30], 'Callback', @resizeImages);
    
    uicontrol('Style', 'pushbutton', 'String', 'Exit', ...
        'Position', [250, 30, 100, 30], 'Callback', @(~,~) close(fig), ...
        'ForegroundColor', [0.8, 0, 0]);
    
    % Listbox for Original Image Sizes
    uicontrol('Style', 'text', 'String', 'Original Sizes:', ...
        'Position', [50, 310, 120, 20]);
    hOriginal = uicontrol('Style', 'listbox', 'Position', [50, 100, 200, 200]);
    
    % Listbox for Resized Image Sizes
    uicontrol('Style', 'text', 'String', 'Resized Sizes:', ...
        'Position', [350, 310, 120, 20]);
    hResized = uicontrol('Style', 'listbox', 'Position', [350, 100, 200, 200]);
    
    % Status Text
    uicontrol('Style', 'text', 'String', 'Input Folder: Not Selected', ...
        'Tag', 'inputStatus', 'Position', [50, 70, 500, 15], 'HorizontalAlignment', 'left');
    uicontrol('Style', 'text', 'String', 'Output Folder: Not Selected', ...
        'Tag', 'outputStatus', 'Position', [50, 85, 500, 15], 'HorizontalAlignment', 'left');
end

function selectInputFolder(~, ~)
    global imgFolder imgFiles hOriginal;
    
    imgFolder = uigetdir('', 'Select Input Folder');
    if imgFolder ~= 0
        imgFiles = dir(fullfile(imgFolder, '*.png'));
        if isempty(imgFiles)
            errordlg('No PNG images found in the selected folder.');
            return;
        end
        
        % Update status
        set(findobj('Tag', 'inputStatus'), 'String', ['Input Folder: ', imgFolder]);
        
        % Show original sizes
        sizes = cell(1, numel(imgFiles));
        for i = 1:numel(imgFiles)
            info = imfinfo(fullfile(imgFolder, imgFiles(i).name));
            sizes{i} = sprintf('%s: %dx%d', imgFiles(i).name, info.Width, info.Height);
        end
        set(hOriginal, 'String', sizes);
        
        % Clear resized list
        set(findobj('Tag', 'outputStatus'), 'String', 'Output Folder: Not Selected');
        global outputFolder hResized;
        outputFolder = '';
        set(hResized, 'String', {});
    end
end

function selectOutputFolder(~, ~)
    global outputFolder;
    
    outputFolder = uigetdir('', 'Select Output Folder');
    if outputFolder ~= 0
        set(findobj('Tag', 'outputStatus'), 'String', ['Output Folder: ', outputFolder]);
    end
end

function resizeImages(~, ~)
    global imgFolder imgFiles outputFolder hResized;
    
    if isempty(imgFiles)
        errordlg('Please select input folder first.');
        return;
    end
    
    if isempty(outputFolder)
        errordlg('Please select output folder first.');
        return;
    end
    
    % Start resizing
    hWait = waitbar(0, 'Resizing images...');
    for i = 1:numel(imgFiles)
        imgPath = fullfile(imgFolder, imgFiles(i).name);
        img = imread(imgPath);
        img_resized = imresize(img, [256 256]);
        
        outputName = fullfile(outputFolder, ['resized_' imgFiles(i).name]);
        imwrite(img_resized, outputName);
        
        waitbar(i/numel(imgFiles), hWait);
    end
    close(hWait);
    
    % Show resized image sizes
    resizedFiles = dir(fullfile(outputFolder, 'resized_*.png'));
    resizedSizes = cell(1, numel(resizedFiles));
    for i = 1:numel(resizedFiles)
        info = imfinfo(fullfile(outputFolder, resizedFiles(i).name));
        resizedSizes{i} = sprintf('%s: %dx%d', resizedFiles(i).name, info.Width, info.Height);
    end
    set(hResized, 'String', resizedSizes);
    
    msgbox(sprintf('Successfully resized %d images.', numel(imgFiles)), 'Done');
end
