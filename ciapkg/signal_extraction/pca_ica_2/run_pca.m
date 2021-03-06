function [PcaOutputSpatial PcaOutputTemporal PcaOutputSingularValues PcaInfo] = run_pca(inputMatrix, num_PCs, varargin)
    % runs PCA on an input 3D matrix aiming to output number of PCs specified in input
    % inputs
        % inputMatrix: input movie (give a character string pointing to the movie file) or matrix ([x y frames]) to run PCA on.
        % num_PCs: scalar value with initial guess as to number of principal components, e.g. 100.
    %options:
        % frameList: vector of frames to use, blank = all frames, e.g. 1:500 or [].
        % movie_dataset_name: string indicating HDF5 dataset name, e.g. '/movie'
        % convert_to_double: 0 = don't convert input movie to double, 1 = convert input movie to double.convert the input vector to double.
    % outputs
        % PcaOutputSpatial - [x y nPCs] where nPCs does not necessarily need to equal the number of PCs from the initial guess nPCs.
        % PcaOutputTemporal - [nPCs frames] output traces from
        % PcaOutputSingularValues - PCA singular values.
        % PcaInfo - structure with information about this PCA run.
    % changelog
    	% 2019.11.10 [18:35:33] - Make sure M and mean_M are of the same class. - Biafra
    %========================
    options.frameList = [];
    options.convert_to_double = 0;
    options.movie_dataset_name = '/Data/Images';
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %     eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    % get the movie if a string input
    if strcmp(class(inputMatrix),'char')|strcmp(class(inputMatrix),'cell')
        display('loading matrix inside PCA function.')
        M = loadMovieList(inputMatrix,'convertToDouble',options.convert_to_double,'frameList',options.frameList,'inputDatasetName',options.movie_dataset_name);

    else
        M = inputMatrix;
        clear inputMatrix;
        % do nothing
    end

    % replace any NaNs with zero
    display('removing NaNs...');drawnow
    M(isnan(M)) = 0;

    %Perform mean subtraction for optimal PCA performance
    display('performing mean subtraction...');drawnow
    inputMean = nanmean(M(:));
    inputMean = cast(inputMean,class(M));
    M = bsxfun(@minus,M,inputMean);

    [height, width, num_frames] = size(M);

    % Reshape movie into [space x time] matrix
    num_pixels = height * width;
    M = reshape(M, num_pixels, num_frames);

    % Make each frame zero-mean in place
    mean_M = mean(M,1);
    M = bsxfun(@minus, cast(M,class(mean_M)), mean_M);

    % PCA
    %------------------------------------------------------------
    [PcaOutputSpatial, PcaOutputTemporal, PcaOutputSingularValues] = compute_pca(M, num_PCs); %#ok<*NASGU,*ASGLU>
    PcaOutputSingularValues = diag(PcaOutputSingularValues); % Save only the diagonal of S

    % savename = sprintf('pca_n%d.mat', num_PCs);

    PcaInfo.movie_height = height;
    PcaInfo.movie_width  = width;
    PcaInfo.movie_frames = num_frames;
    PcaInfo.num_PCs = num_PCs;

    % save(savename, 'info', 'spatial', 'temporal', 'S');

    fprintf('%s: All done!\n', datestr(now));
end