function negative_field
    % Parent folder containing the subfolders with images
    parentFolderPath = "D:\TA\Preprocess";
    % Parent folder to save the .mat files
    outputParentFolderPath = "D:\TA\Negative field\Negative-field result";

    % List of subfolders to process
    subFolders = {'Preprocessing-result'};

    % Start the parallel pool (if not already started)
    if isempty(gcp('nocreate'))
        parpool('local'); % Use the 'local' profile to utilize all available workers
    end

    % Process each subfolder
    parfor sf = 1:length(subFolders)
        inputFolderPath = fullfile(parentFolderPath, subFolders{sf});
        outputFolderPath = fullfile(outputParentFolderPath, subFolders{sf});

        if ~exist(outputFolderPath, 'dir')
            mkdir(outputFolderPath);
        end

        imageFiles = dir(fullfile(inputFolderPath, '*.png'));f
 
        % Process each image in the subfolder
        for idx = 1:length(imageFiles)
            % Get the file name
            imageFileName = imageFiles(idx).name;
            imagePath = fullfile(inputFolderPath, imageFileName);

            % Read the image
            img = imread(imagePath);

            % Convert to grayscale
            if size(img, 3) == 3
                img = rgb2gray(img);
            end

            % Calculate gradient and magnitude
            [gx, gy] = gradient(double(img));
            CH = sqrt(gx.^2 + gy.^2);

            % Calculate external fields
            [Ex, Ey] = CMP_ExtField_L(CH);

            % Save Lorentz force components as .mat file
            [~, name, ~] = fileparts(imageFileName);
            saveFileName = fullfile(outputFolderPath, [name, '.mat']);
            parsave(saveFileName, Ex, Ey); % Use a separate function to save
        end
    end
end

% Define a separate function for saving
function parsave(saveFileName, Ex, Ey)
    save(saveFileName, 'Ex', 'Ey');
end

function [Ex, Ey] = CMP_ExtField_L(CH)
    [m, n] = size(CH);
    Ex = zeros(m, n);
    Ey = zeros(m, n);
    x = 1:n;
    y = 1:m;
    [X, Y] = meshgrid(x, y);
    for j = 1:m
        for i = 1:n
            [Ex(j, i), Ey(j, i)] = LorentzForce1(X, Y, CH, x(i), y(j), i, j);
        end
    end
end

function [Ex, Ey] = LorentzForce1(X, Y, CH, x, y, I, J)
    [m, n] = size(CH);
    Ex = 0;
    Ey = 0;
    Rx = X - x;
    Ry = Y - y;

    R = (Rx.^2 + Ry.^2).^(1.5);
    CH = double(CH);
    Rx = Rx .* CH;
    Ry = Ry .* CH;
    
    if I == 1 % Point is located in the first column
        Hx = Rx(:, 2:n) ./ R(:, 2:n);
        Hy = Ry(:, 2:n) ./ R(:, 2:n);
        Ex = sum(Hx(:));
        Ey = sum(Hy(:));
        if J == 1
            Ex = Ex + sum(Rx(2:m, I) ./ R(2:m, I));
            Ey = Ey + sum(Ry(2:m, I) ./ R(2:m, I));
        elseif J == m
            Ex = Ex + sum(Rx(1:m-1, I) ./ R(1:m-1, I));
            Ey = Ey + sum(Ry(1:m-1, I) ./ R(1:m-1, I));
        else
            Ex = Ex + sum(Rx(1:J-1, I) ./ R(1:J-1, I)) + sum(Rx(J+1:m, I) ./ R(J+1:m, I));
            Ey = Ey + sum(Ry(1:J-1, I) ./ R(1:J-1, I)) + sum(Ry(J+1:m, I) ./ R(J+1:m, I));
        end
    elseif I == n % Point is located in the last column
        Hx = Rx(:, 1:n-1) ./ R(:, 1:n-1);
        Hy = Ry(:, 1:n-1) ./ R(:, 1:n-1);
        Ex = sum(Hx(:));
        Ey = sum(Hy(:));
        if J == 1
            Ex = Ex + sum(Rx(2:m, I) ./ R(2:m, I));
            Ey = Ey + sum(Ry(2:m, I) ./ R(2:m, I));
        elseif J == m
            Ex = Ex + sum(Rx(1:m-1, I) ./ R(1:m-1, I));
            Ey = Ey + sum(Ry(1:m-1, I) ./ R(1:m-1, I));
        else
            Ex = Ex + sum(Rx(1:J-1, I) ./ R(1:J-1, I)) + sum(Rx(J+1:m, I) ./ R(J+1:m, I));
            Ey = Ey + sum(Ry(1:J-1, I) ./ R(1:J-1, I)) + sum(Ry(J+1:m, I) ./ R(J+1:m, I));
        end
    else % Elsewhere
        Hx = Rx(:, 1:I-1) ./ R(:, 1:I-1);
        Hy = Ry(:, 1:I-1) ./ R(:, 1:I-1);
        Ex = sum(Hx(:));
        Ey = sum(Hy(:));
        Hx = [];
        Hy = [];
        Hx = Rx(:, I+1:n) ./ R(:, I+1:n);
        Hy = Ry(:, I+1:n) ./ R(:, I+1:n);
        Ex = Ex + sum(Hx(:));
        Ey = Ey + sum(Hy(:));
        if J == 1
            Ex = Ex + sum(Rx(2:m, I) ./ R(2:m, I));
            Ey = Ey + sum(Ry(2:m, I) ./ R(2:m, I));
        elseif J == m
            Ex = Ex + sum(Rx(1:m-1, I) ./ R(1:m-1, I));
            Ey = Ey + sum(Ry(1:m-1, I) ./ R(1:m-1, I));
        else
            Ex = Ex + sum(Rx(1:J-1, I) ./ R(1:J-1, I)) + sum(Rx(J+1:m, I) ./ R(J+1:m, I));
            Ey = Ey + sum(Ry(1:J-1, I) ./ R(1:J-1, I)) + sum(Ry(J+1:m, I) ./ R(J+1:m, I));
        end
    end
end
