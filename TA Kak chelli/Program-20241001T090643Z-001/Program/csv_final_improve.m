function csv_final_improve()
    % Define the main directory containing subfolders with masks
    main_folder = 'D:\TA\SCPM\Mask\BIRADS_2';
    subfolders = {'BIRADS_2', 'BIRADS_3', 'BIRADS_4', 'BIRADS_5'};

    results = [];
    summary = {'Subfolder', 'Mean Difference Value', 'Lowest Difference Value', 'Highest Difference Value', 'Edge Frequency'};
    all_values = [];
    interval_values_by_subfolder = cell(1, length(subfolders));

    for i = 1:length(subfolders)
        subfolder = subfolders{i};
        subfolder_path = fullfile(main_folder, subfolder);
        image_files = dir(fullfile(subfolder_path, '*.png'));
        subfolder_results = [];

        for j = 1:length(image_files)
            file_name = image_files(j).name;
            file_path = fullfile(subfolder_path, file_name);
            
            % Process the image and calculate the interval value and edge frequency
            [interval_value, edge_frequency] = process_image(file_path);
            
            % Append to results
            results = [results; {file_name, subfolder, interval_value, edge_frequency}];
            subfolder_results = [subfolder_results; interval_value];
            all_values = [all_values; i, interval_value]; % Store subfolder index and interval value
        end

        % Store interval values for box plot
        interval_values_by_subfolder{i} = subfolder_results;

        % Calculate summary statistics for the subfolder
        mean_val = mean(subfolder_results);
        min_val = min(subfolder_results);
        max_val = max(subfolder_results);
        summary = [summary; {subfolder, mean_val, min_val, max_val, edge_frequency}];
    end

    % Save the results to a CSV file
    results_table = cell2table(results, 'VariableNames', {'FileName', 'Subfolder', 'DifferenceValue', 'EdgeFrequency'});
    writetable(results_table, 'results_scpmedge500.csv');

    % Save the summary to a CSV file
    summary_table = cell2table(summary(2:end, :), 'VariableNames', summary(1, :));
    writetable(summary_table, 'summary_scpmedge500.csv');

    % Create the box plot
    data = cell2mat(interval_values_by_subfolder');
    groups = arrayfun(@(i) repmat(i, size(interval_values_by_subfolder{i})), 1:length(subfolders), 'UniformOutput', false);
    groups = cell2mat(groups');
    
    figure('Position', [100, 100, 600, 400]); % Smaller figure size
    boxplot(data, groups, 'Labels', subfolders);
    xlabel('BI-RADS Categories');
    ylabel('Difference Values');
    ylim([0 0.5]); 
    title('Difference Values by BI-RADS Categories');
    saveas(gcf, 'Box_plot_scpmedge500.png');
end

function [interval_value, edge_frequency] = process_image(file_path)
    % Read the binary image
    img = imread(file_path);
    if ndims(img) == 3
        img = rgb2gray(img);
    end
    
    % Convert image to binary if it is not already logical
    if ~islogical(img)
        binaryImage = imbinarize(img);
    else
        binaryImage = img;
    end

    % Use regionprops to get the centroid and ellipse parameters
    stats = regionprops(binaryImage, 'Centroid', 'Orientation');
    
    % Access the centroid coordinates and ellipse parameters
    centroid = stats.Centroid;
    
    % Find the boundary of the binary image
    boundary = find_boundary(binaryImage);

    % Adjust ellipse parameters based on boundary farthest points
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

    theta = linspace(0, 2 * pi, 500);
    saveMe = [];

    % Loop through possible adjustments to find the best fitting ellipse
    for majorAxis = majorAxis2 + (-150:0)
        for minorAxis = minorAxis2 + (-150:0)
            for orientation = orientation2
                x = centroid(1) + (majorAxis / 2) * cos(theta);
                y = centroid(2) + (minorAxis / 2) * sin(theta);

                % Rotate the ellipse points based on the orientation
                R = [cosd(orientation), -sind(orientation); sind(orientation), cosd(orientation)];
                ellipsePoints = R * [x - centroid(1); y - centroid(2)];

                % Calculate r1 and r2
                r1 = sqrt((ellipsePoints(1, :) + centroid(1) - centroid(1)).^2 + (ellipsePoints(2, :) + centroid(2) - centroid(2)).^2);
                boundary_x_interp = interp1(linspace(0, 1, length(boundary(:, 2))), boundary(:, 2), linspace(0, 1, 500));
                boundary_y_interp = interp1(linspace(0, 1, length(boundary(:, 1))), boundary(:, 1), linspace(0, 1, 500));
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
    boundary_x_interp = interp1(linspace(0, 1, length(boundary(:, 2))), boundary(:, 2), linspace(0, 1, 500));
    boundary_y_interp = interp1(linspace(0, 1, length(boundary(:, 1))), boundary(:, 1), linspace(0, 1, 500));
    r2 = sqrt((boundary_x_interp - centroid(1)).^2 + (boundary_y_interp - centroid(2)).^2);

    % Compute the integral value using the trapezoidal rule for the best ellipse
    interval_value = trapz(theta, ((r1 - r2) .^ 2) ./ (r1 .^ 2));

    % Calculate the edge frequency using Fourier Transform
    fft_values = fft(r2);
    edge_frequency = sum(abs(fft_values(2:end))); % Excluding the DC component
end

function boundary = find_boundary(binaryImage)
    % Find the boundary of the binary image
    boundaries = bwboundaries(binaryImage);
    boundary = boundaries{1};  % Assume the largest boundary is the region of interest
end
