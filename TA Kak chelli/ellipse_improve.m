function ellipse_improve()
    % Create and hide the GUI as it is being constructed.
    f = figure('Visible', 'off', 'Position', [360, 500, 1000, 500]);

    % Construct the components.
    hloadfolder = uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
        'Position', [750, 450, 100, 30], 'Callback', @loadfolder_Callback);
    hlistbox = uicontrol('Style', 'listbox', 'Position', [750, 100, 200, 300], 'Callback', @listbox_Callback);
    hauto = uicontrol('Style', 'pushbutton', 'String', 'Auto Ellipse', ...
        'Position', [750, 50, 100, 30], 'Callback', @autobutton_Callback, 'Enable', 'off');
    haxes1 = axes('Units', 'pixels', 'Position', [50, 50, 300, 400]);
    haxes2 = axes('Units', 'pixels', 'Position', [400, 50, 300, 400]);
    hintegral = uicontrol('Style', 'text', 'String', 'Difference Value: ', ...
        'Position', [50, 450, 200, 30], 'HorizontalAlignment', 'left');
  
    % Initialize the GUI.
    set(f, 'Name', 'Ellipse Fitting GUI');
    movegui(f, 'center');
    set(f, 'Visible', 'on');

    % Store the handles in the GUI.
    handles.haxes1 = haxes1;
    handles.haxes2 = haxes2;
    handles.hintegral = hintegral;
    handles.hlistbox = hlistbox;
    handles.hauto = hauto;
    handles.image = [];
    handles.boundary = [];
    handles.ellipse = [];
    handles.image_files = {};
    guidata(f, handles);

    function loadfolder_Callback(~, ~)
        % Select the folder
        folder_path = uigetdir();
        if folder_path == 0
            return;
        end
        
        % Get list of image files in the folder
        image_files = dir(fullfile(folder_path, '*.png'));
        image_files = [image_files; dir(fullfile(folder_path, '*.jpg'))];
        image_files = [image_files; dir(fullfile(folder_path, '*.jpeg'))];
        image_files = [image_files; dir(fullfile(folder_path, '*.tif'))];

        % Update handles
        handles.image_files = image_files;
        guidata(f, handles);

        % Display the image files in the listbox
        set(handles.hlistbox, 'String', {image_files.name});
    end

    function listbox_Callback(hObject, ~)
        % Get the handles
        handles = guidata(hObject);
        selected_index = get(hObject, 'Value');
        if isempty(selected_index) || selected_index > length(handles.image_files)
            return;
        end
        selected_file = handles.image_files(selected_index);
        img_path = fullfile(selected_file.folder, selected_file.name);
        
        % Load the selected image
        img = imread(img_path);
    
        % Convert to grayscale if it is not already
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
    
        % Binarize the image if it is not logical
        if ~islogical(img)
            bw = imbinarize(img);
        else
            bw = img;
        end
    
        % Fill holes and extract the boundary of the region
        bw = imfill(bw, 'holes');
        boundaries = bwboundaries(bw);
        boundary = boundaries{1};  % Assume the largest boundary is the region of interest
    
        % Update handles
        handles.image = img;
        handles.boundary = boundary;
        guidata(hObject, handles);
    
        % Display the image and boundary
        axes(handles.haxes1);
        imshow(img, []);
        hold on;
        plot(boundary(:, 2), boundary(:, 1), 'g', 'LineWidth', 2);
        hold off;
    
        % Enable the ellipse button
        set(handles.hauto, 'Enable', 'on');
    end

    function autobutton_Callback(hObject, ~)
        % Get the handles
        handles = guidata(hObject);
        img = handles.image;
        
        % Ensure the image is binary
        if ~islogical(img)
            binaryImage = imbinarize(img);
        else
            binaryImage = img;
        end
        
        % Use regionprops to get the centroid and ellipse parameters
        stats = regionprops(binaryImage, 'Centroid', 'Orientation');
        
        % Access the centroid coordinates and ellipse parameters
        centroid = stats.Centroid;
        
        % Adjust ellipse parameters based on boundary farthest points
        boundary = handles.boundary;
        leftmost = min(boundary(:, 2));
        rightmost = max(boundary(:, 2));
        topmost = min(boundary(:, 1));
        bottommost = max(boundary(:, 1));
        
        % Calculate distances to find the longest span
        distance_leftmost = abs(centroid(1) - leftmost);
        distance_rightmost = abs(rightmost - centroid(1));
        distance_topmost = abs(centroid(2) - topmost);
        distance_bottommost = abs(bottommost - centroid(2));
        
        % Determine major and minor axes
        majorAxis2 = 2 * max(distance_leftmost, distance_rightmost);
        minorAxis2 = 2 * max(distance_topmost, distance_bottommost);
        orientation2 = -stats.Orientation;
        
        % Initialize theta and saveMe variable
        theta = linspace(0, 2 * pi, 100);
        saveMe = [];
        
        % Loop through possible adjustments to find the best fitting ellipse
        for majorAxis = majorAxis2 + (-200:0)
            for minorAxis = minorAxis2 + (-200:0)
                for orientation = orientation2
                    x = centroid(1) + (majorAxis / 2) * cos(theta);
                    y = centroid(2) + (minorAxis / 2) * sin(theta);

                    % Rotate the ellipse points based on the orientation
                    R = [cosd(orientation), -sind(orientation); sind(orientation), cosd(orientation)];
                    ellipsePoints = R * [x - centroid(1); y - centroid(2)];

                    % Calculate r1 and r2
                    r1 = sqrt((ellipsePoints(1, :) + centroid(1) - centroid(1)).^2 + (ellipsePoints(2, :) + centroid(2) - centroid(2)).^2);
                    boundary_x_interp = interp1(linspace(0, 1, length(handles.boundary(:, 2))), handles.boundary(:, 2), linspace(0, 1, 100));
                    boundary_y_interp = interp1(linspace(0, 1, length(handles.boundary(:, 1))), handles.boundary(:, 1), linspace(0, 1, 100));
                    r2 = sqrt((boundary_x_interp - centroid(1)).^2 + (boundary_y_interp - centroid(2)).^2);

                    % Compute the integral value using the trapezoidal rule
                    integral_value = trapz(theta, ((r1 - r2) .^ 2) ./ (r1 .^ 2));

                    saveMe = [saveMe, [majorAxis; minorAxis; orientation; integral_value]];
                end
            end
        end

        % Find the best fitting ellipse parameters
        [~, aIdx] = min(saveMe(4, :));
        bestParams = saveMe(:, aIdx);

        % Extract best parameters
        majorAxis = bestParams(1);
        minorAxis = bestParams(2);
        orientation = bestParams(3);

        x = centroid(1) + (majorAxis / 2) * cos(theta);
        y = centroid(2) + (minorAxis / 2) * sin(theta);

        % Rotate the ellipse points based on the best orientation
        R = [cosd(orientation), -sind(orientation); sind(orientation), cosd(orientation)];
        ellipsePoints = R * [x - centroid(1); y - centroid(2)];

        % Calculate r1 and r2 for the best ellipse
        r1 = sqrt((ellipsePoints(1, :) + centroid(1) - centroid(1)).^2 + (ellipsePoints(2, :) + centroid(2) - centroid(2)).^2);
        boundary_x_interp = interp1(linspace(0, 1, length(handles.boundary(:, 2))), handles.boundary(:, 2), linspace(0, 1, 100));
        boundary_y_interp = interp1(linspace(0, 1, length(handles.boundary(:, 1))), handles.boundary(:, 1), linspace(0, 1, 100));
        r2 = sqrt((boundary_x_interp - centroid(1)).^2 + (boundary_y_interp - centroid(2)).^2);

        % Compute the integral value using the trapezoidal rule for the best ellipse
        integral_value = trapz(theta, ((r1 - r2) .^ 2) ./ (r1 .^ 2));

        % Display the results
        axes(handles.haxes1);
        imshow(binaryImage, []);
        hold on;
        plot(handles.boundary(:, 2), handles.boundary(:, 1), 'g', 'LineWidth', 2);
        plot(ellipsePoints(1, :) + centroid(1), ellipsePoints(2, :) + centroid(2), 'r', 'LineWidth', 2);
        hold off;
        
        axes(handles.haxes2);
        plot(theta, r1, 'r', 'LineWidth', 2);
        hold on;
        plot(theta, r2, 'g', 'LineWidth', 2);
        hold off;
        legend('r1 (Ellipse)', 'r2 (Boundary)');
        title('r1 & r2 on \theta');
        
        % Update the integral value text
        set(handles.hintegral, 'String', sprintf('Difference Value: %.4f', integral_value));
        
        % Create a mask for the ellipse
        ellipseMask = poly2mask(ellipsePoints(1, :) + centroid(1), ellipsePoints(2, :) + centroid(2), size(binaryImage, 1), size(binaryImage, 2));
        
%         % Plot differences for the best fitting ellipse
%         figure;
%         plot(abs(r1 - r2));
%         title('Absolute Difference between r1 and r2');
    end
end
