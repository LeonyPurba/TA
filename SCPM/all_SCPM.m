function all_SCPM
    % Create the main figure
    fig = figure('Name', 'SCPM GUI', 'Position', [100, 100, 1200, 700], 'MenuBar', 'none', 'NumberTitle', 'off');

    % Create the panel for file loading
    panelFileLoader = uipanel('Parent', fig, 'Title', 'File Loader', 'Position', [0.05, 0.75, 0.4, 0.2]);

    % Create the load folder button inside the File Loader panel
    uicontrol('Parent', panelFileLoader, 'Style', 'pushbutton', 'String', 'Load Folder', 'Position', [10, 50, 100, 30], 'Callback', @loadFolderCallback);

    % Create the listbox for displaying files inside the File Loader panel
    uicontrol('Parent', panelFileLoader, 'Style', 'listbox', 'Position', [120, 10, 200, 100], 'Tag', 'fileListBox');

    % Create the panel for parameter inputs
    panelParameters = uipanel('Parent', fig, 'Title', 'Parameters', 'Position', [0.05, 0.4, 0.4, 0.35]);

    % Create parameter input fields in 4 rows and 2 columns inside the Parameters panel
    paramNames = {'N', 'Ncycle', 'beta', 'dT', 'L', 'w1', 'w2', 'w3', 'xCosAmp', 'xCosOffset', 'ySinAmp', 'ySinOffset'};
    defaultValues = {'60', '1000', '0.7', '0.065', '2', '2.5', '0.01', '1.55', '15', '-15', '15', '20'};
    xPos = [50, 220];  % Adjusted the x position to give more space on the left
    yPos = [180, 150, 120, 90, 60, 30, 0, -30];

    for i = 1:length(paramNames)
        col = mod(i-1, 2) + 1;
        row = floor((i-1) / 2) + 1;
        createParameterInput(paramNames{i}, xPos(col), yPos(row), defaultValues{i}, panelParameters);
    end

    % Create the panel for simulation controls
    panelSimControls = uipanel('Parent', fig, 'Title', 'Simulation Controls', 'Position', [0.05, 0.05, 0.4, 0.25]);

    % Create start simulation button inside the Simulation Controls panel
    uicontrol('Parent', panelSimControls, 'Style', 'pushbutton', 'String', 'Start Simulation', 'Position', [10, 150, 100, 30], 'Callback', @startSimulationCallback);
    
    % Create stop simulation button inside the Simulation Controls panel
    uicontrol('Parent', panelSimControls, 'Style', 'pushbutton', 'String', 'Stop Simulation', 'Position', [10, 100, 100, 30], 'Callback', @stopSimulationCallback);

    % Create save button inside the Simulation Controls panel
    uicontrol('Parent', panelSimControls, 'Style', 'pushbutton', 'String', 'Save', 'Position', [10, 50, 100, 30], 'Callback', @saveImageCallback);

    % Create zoom toggle button inside the Simulation Controls panel
    uicontrol('Parent', panelSimControls, 'Style', 'togglebutton', 'String', 'Zoom', 'Position', [120, 150, 100, 30], 'Callback', @toggleZoomCallback, 'Tag', 'zoomToggle');

    % Create axes for plotting
    ax = axes('Parent', fig, 'Position', [0.5, 0.1, 0.45, 0.8]);

    % Variable to control the simulation loop
    running = false;

    % Variables to store the final x and y positions
    finalX = [];
    finalY = [];
    adjustedImage = [];

    function loadFolderCallback(~, ~)
        folderPath = uigetdir;
        if folderPath
            files = dir(fullfile(folderPath, '*.mat'));
            fileNames = {files.name};
            fileListBox = findobj('Tag', 'fileListBox');
            set(fileListBox, 'String', fileNames, 'UserData', {files.folder});
        end
    end

    function createParameterInput(name, x, y, defaultValue, parent)
        uicontrol('Parent', parent, 'Style', 'text', 'Position', [x-60, y, 60, 20], 'String', name, 'HorizontalAlignment', 'right');
        uicontrol('Parent', parent, 'Style', 'edit', 'Position', [x+10, y, 100, 20], 'Tag', name, 'String', defaultValue);
    end

    function startSimulationCallback(~, ~)
        fileListBox = findobj('Tag', 'fileListBox');
        selectedFileIndex = get(fileListBox, 'Value');
        if isempty(selectedFileIndex)
            errordlg('Please select a file from the list.', 'File Selection Error');
            return;
        end
        folderPath = get(fileListBox, 'UserData');
        fileName = get(fileListBox, 'String');
        filePath = fullfile(folderPath{1}, fileName{selectedFileIndex});

        % Load the selected file
        data = load(filePath);

        % Retrieve parameters from GUI
        N = str2double(get(findobj('Tag', 'N'), 'String'));
        Ncycle = str2double(get(findobj('Tag', 'Ncycle'), 'String'));
        beta = str2double(get(findobj('Tag', 'beta'), 'String'));
        dT = str2double(get(findobj('Tag', 'dT'), 'String'));
        L = str2double(get(findobj('Tag', 'L'), 'String'));
        w1 = str2double(get(findobj('Tag', 'w1'), 'String'));
        w2 = str2double(get(findobj('Tag', 'w2'), 'String'));
        w3 = str2double(get(findobj('Tag', 'w3'), 'String'));
        xCosAmp = str2double(get(findobj('Tag', 'xCosAmp'), 'String'));
        xCosOffset = str2double(get(findobj('Tag', 'xCosOffset'), 'String'));
        ySinAmp = str2double(get(findobj('Tag', 'ySinAmp'), 'String'));
        ySinOffset = str2double(get(findobj('Tag', 'ySinOffset'), 'String'));

        dT2 = (dT^2)/2;
        dT3 = (dT^3)/6;
        Fs = 1/(2*dT);

        % Initialize shape
        mode_flag = 'circle';
        if strcmp(mode_flag, 'random')
            x = 1 * randn(1, N);
            y = 1 * randn(1, N);
        elseif strcmp(mode_flag, 'circle')
            h = 2 * pi / N;
            t = -pi + (1:N)' * h;
            x = (xCosAmp * cos(t)) + xCosOffset;
            y = (ySinAmp * sin(t)) + ySinOffset;
            x = x(:)';
            y = y(:)';
        elseif strcmp(mode_flag, 'line')
            y(1:N) = -15:(N - 16);
            x(1:N) = 30;
            x = x(:)';
            y = y(:)';
        else
            error('not proper mode')
        end

        % Initialize velocity vectors
        vx = zeros(1, N);
        vy = zeros(1, N);

        % Initialize graphics
        axes(ax); % Set the current axes to ax
        cla(ax); % Clear the axes
        [X, Y] = meshgrid(-128:127, -128:127);

        Ex = data.Ex; % Load Ex from data
        Ey = data.Ey; % Load Ey from data

        quiver(X, Y, Ex, Ey, 'Parent', ax);

        px = Ex;
        py = Ey;
        hLine1 = line('XData', x, 'YData', y, 'LineStyle', 'none', 'Marker', '.', 'Color', 'k', 'Parent', ax);

        axis(ax, 'off');
        axis(ax, 'equal');
        set(ax, 'YDir', 'reverse'); % Equivalent to 'axis ij'

        title(ax, 'Status: Not Active');
        pause(1);
        title(ax, 'Status: Active');

        running = true;
        dAx = zeros(3, N); % Initialize dAx
        dAy = zeros(3, N); % Initialize dAy

        for i = 1:3 % Build first 3 steps using simple euler implicit method
            if ~running
                break;
            end
            [Fcx, Fcy] = CoulombForce(x, y);
            [Fsx, Fsy] = SpringForce_L(x, y, L);

            Ex = interp2(X, Y, px, x, y);
            Ey = interp2(X, Y, py, x, y);

            dAx(i, :) = w1 * Fcx + w2 * Ex - beta * vx + w3 * Fsx;
            dAy(i, :) = w1 * Fcy + w2 * Ey - beta * vy + w3 * Fsy;
            x = x + vx * dT;
            y = y + vy * dT;
            vx = vx + dAx(i, :) * dT;
            vy = vy + dAy(i, :) * dT;
        end

        for i = 1:Ncycle
            if ~running
                break;
            end
            [Fcx, Fcy] = CoulombForce(x, y);
            [Fsx, Fsy] = SpringForce_L(x, y, L);

            Ex = interp2(X, Y, px, x, y);
            Ey = interp2(X, Y, py, x, y);

            dAx(1:2, :) = dAx(2:3, :);
            dAy(1:2, :) = dAy(2:3, :);
            dAx(3, :) = w1 * Fcx + w2 * Ex - beta * vx + w3 * Fsx;
            dAy(3, :) = w1 * Fcy + w2 * Ey - beta * vy + w3 * Fsy;

            DAx = Fs * (3 * dAx(3, :) - 4 * dAx(2, :) + dAx(1, :));
            DAy = Fs * (3 * dAy(3, :) - 4 * dAy(2, :) + dAy(1, :));
            x = max(-128, min(128, x + vx * dT + dT2 * dAx(3, :) + dT3 * DAx));
            y = max(-128, min(128, y + vy * dT + dT2 * dAy(3, :) + dT3 * DAy));
            vx = vx + dT * dAx(3, :) + dT2 * DAx;
            vy = vy + dT * dAy(3, :) + dT2 * DAy;

            xa(1) = x(1);
            xa(2) = x(N);
            ya(1) = y(1);
            ya(2) = y(N);
            set(hLine1, 'XData', x, 'YData', y);
            drawnow;
        end

        % Store the final x and y positions
        finalX = x;
        finalY = y;

        % Scale the coordinates to make the object 2x bigger
        x_scaled = (finalX - mean(finalX)) * 1 + mean(finalX);
        y_scaled = (finalY - mean(finalY)) * 1 + mean(finalY);

        % Create a new figure for saving
        figure(101)
        clf
        set(gcf, 'Color', 'k') % Set the figure background to black
        ax2 = axes('Color', 'k', 'XColor', 'k', 'YColor', 'k'); % Set the axis background to black
        hold on

        % Draw filled polygons between the final positions of the particles
        fill(x_scaled, y_scaled, 'w', 'EdgeColor', 'w'); % White filled polygon

        % Draw lines between the final positions of the particles
        for i = 1:N-1
            line([x_scaled(i) x_scaled(i+1)], [y_scaled(i) y_scaled(i+1)], 'Color', 'w'); % White lines
        end

        % Draw a line from the last particle to the first to close the loop
        line([x_scaled(N) x_scaled(1)], [y_scaled(N) y_scaled(1)], 'Color', 'w');

        axis off; 
        axis equal; 
        set(ax2, 'YDir', 'reverse'); % 'axis ij' equivalent

        % Calculate the range of the scaled object
        x_range = max(x_scaled) - min(x_scaled);
        y_range = max(y_scaled) - min(y_scaled);

        % Calculate the center of the scaled object
        x_center = (max(x_scaled) + min(x_scaled)) / 2;
        y_center = (max(y_scaled) + min(y_scaled)) / 2;

        % Calculate the limits to center the scaled object within a 256x256 canvas
        xlim([x_center - x_range/2 - (256 - x_range)/2, x_center + x_range/2 + (256 - x_range)/2]);
        ylim([y_center - y_range/2 - (256 - y_range)/2, y_center + y_range/2 + (256 - y_range)/2]);

        % Set the figure size to 256x256
        set(gcf, 'Position', [100, 100, 256, 256]);
        set(ax2, 'Position', [0 0 1 1]); % Make the axis fill the entire figure

        % Save the current image to the variable
        frame = getframe(ax2);
        adjustedImage = frame.cdata;

        title(ax, 'Status: Not Active');
    end

    function stopSimulationCallback(~, ~)
        running = false;
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
        figure(101); % Show the figure after saving
    end

    function toggleZoomCallback(hObject, ~)
        if get(hObject, 'Value')
            zoom on;
        else
            zoom off;
        end
    end

    % Nested functions
    function [Fsx, Fsy] = SpringForce_L(x, y, L)
        % Function to calculate Spring Force based on L (Length of spring)
        n = length(x);
        k = 0.9;

        % First particle
        diff_x_12 = (x(2) - x(1));
        diff_y_12 = (y(2) - y(1));
        diff_L_12 = sqrt(diff_x_12 * diff_x_12 + diff_y_12 * diff_y_12);

        Fsx_12 = -k * (L - diff_L_12) * diff_x_12 / diff_L_12;
        Fsy_12 = -k * (L - diff_L_12) * diff_y_12 / diff_L_12;

        diff_x_1n = (x(n) - x(1));
        diff_y_1n = (y(n) - y(1));
        diff_L_1n = sqrt(diff_x_1n * diff_x_1n + diff_y_1n * diff_y_1n);

        Fsx_1n = -k * (L - diff_L_1n) * diff_x_1n / diff_L_1n;
        Fsy_1n = -k * (L - diff_L_1n) * diff_y_1n / diff_L_1n;

        Fsx(1) = Fsx_12 + Fsx_1n;
        Fsy(1) = Fsy_12 + Fsy_1n;

        % Second particle to (n-1) particle
        for i = 2:(n - 1)
            diff_x_a = (x(i - 1) - x(i));
            diff_y_a = (y(i - 1) - y(i));
            diff_L_a = sqrt(diff_x_a * diff_x_a + diff_y_a * diff_y_a);

            Fsx_a = -k * (L - diff_L_a) * diff_x_a / diff_L_a;
            Fsy_a = -k * (L - diff_L_a) * diff_y_a / diff_L_a;

            diff_x_b = (x(i + 1) - x(i));
            diff_y_b = (y(i + 1) - y(i));
            diff_L_b = sqrt(diff_x_b * diff_x_b + diff_y_b * diff_y_b);

            Fsx_b = -k * (L - diff_L_b) * diff_x_b / diff_L_b;
            Fsy_b = -k * (L - diff_L_b) * diff_y_b / diff_L_b;

            Fsx(i) = Fsx_a + Fsx_b;
            Fsy(i) = Fsy_a + Fsy_b;
        end

        % Last particle
        diff_x_n = (x(n - 1) - x(n));
        diff_y_n = (y(n - 1) - y(n));
        diff_L_n = sqrt(diff_x_n * diff_x_n + diff_y_n * diff_y_n);

        Fsx_n = -k * (L - diff_L_n) * diff_x_n / diff_L_n;
        Fsy_n = -k * (L - diff_L_n) * diff_y_n / diff_L_n;

        diff_x_n1 = (x(1) - x(n));
        diff_y_n1 = (y(1) - y(n));
        diff_L_n1 = sqrt(diff_x_n1 * diff_x_n1 + diff_y_n1 * diff_y_n1);

        Fsx_n1 = -k * (L - diff_L_n1) * diff_x_n1 / diff_L_n1;
        Fsy_n1 = -k * (L - diff_L_n1) * diff_y_n1 / diff_L_n1;

        Fsx(n) = Fsx_n + Fsx_n1;
        Fsy(n) = Fsy_n + Fsy_n1;
    end

    function [Fx, Fy] = CoulombForce(x, y)
        % Function to calculate Coulomb force
        L = length(x);
        Fx = zeros(1, L);
        Fy = zeros(1, L);

        % First point
        X = x(2:L);
        Y = y(2:L);
        Xd = x(1) - X;
        Yd = y(1) - Y;
        R = (Xd.^2 + Yd.^2).^(1.5);
        Fx(1) = sum(Xd ./ R);
        Fy(1) = sum(Yd ./ R);

        % Intermediate points
        for i = 2:(L - 1)
            X = [x(1:(i - 1)) x((i + 1):L)];
            Y = [y(1:(i - 1)) y((i + 1):L)];
            Xd = x(i) - X;
            Yd = y(i) - Y;
            R = (Xd.^2 + Yd.^2).^(1.5);
            Fx(i) = sum(Xd ./ R);
            Fy(i) = sum(Yd ./ R);
        end

        % Last point
        X = x(1:L - 1);
        Y = y(1:L - 1);
        Xd = x(L) - X;
        Yd = y(L) - Y;
        R = (Xd.^2 + Yd.^2).^(1.5);
        Fx(L) = sum(Xd ./ R);
        Fy(L) = sum(Yd ./ R);
    end
end


