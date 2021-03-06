function obj = filterRotationRANSAC_Automated( C_Rtri, C_segs )

% Generate all possible correspondences
% for i=1:length(C_segs)
%     segs = C_segs{i};
%     C = combnk( 1:length(segs), 3 )';
% end

R0 = [-0.5046   -0.8623    0.0428
   -0.0921    0.0045   -0.9957
    0.8584   -0.5064   -0.0817];

Nobs = length(C_Rtri);
S_corresps = struct( 'N', [],...
                     'V', [],...
                     'X', [],...
                   'idx', [] );
% decimation = 10;
decimation = floor( Nobs/5 );
for i=1:Nobs % Decimation is used to reduce the number of correspondences
    N = C_Rtri{i};
    segs = C_segs{i};
    Nsegs = length(segs);
    V = [segs.v];
    S_corresps(i).idx = [ kron([1 2 3],ones(1,Nsegs))
                        kron(ones(1,3),1:Nsegs)    ];
	S_corresps(i).N = reshape( repmat(N,Nsegs,1), 3,[] );
    S_corresps(i).V = repmat( V, 1, 3 );
	S_corresps(i).X = [ reshape( repmat(N,Nsegs,1), 3,[] ) ;
                      repmat( V, 1, 3 ) ];
end

corresps = [S_corresps(1:decimation:Nobs).X];
feedback = true;
RANSAC_Rotation_threshold = 0.02;
[R, inliers, dist] = ransacFitTransNormals(corresps, RANSAC_Rotation_threshold, feedback);
% R can be used as initial estimate for optimization process

% Find within each observation the possible matches:
C_corresps = cell(3,Nobs);
for i=1:Nobs
    d = dot(S_corresps(i).N, R(:,1:2)*S_corresps(i).V,1);
    mask = abs(d) < RANSAC_Rotation_threshold;
    matches = S_corresps(i).idx(:,mask);
    for j=1:size(matches,2);
        C_corresps{matches(1,j),i} = ...
            [C_corresps{matches(1,j),i}, matches(2,j)];
    end
    
    % Reorder C_segs elements giving image label to them
    segs = C_segs{i};
end
hold on,
h_(1) = plot(segs(4).pts(1,:),segs(4).pts(2,:),'.r');
h_(2) = plot(segs(6).pts(1,:),segs(6).pts(2,:),'.g');
h_(3) = plot(segs(1).pts(1,:),segs(1).pts(2,:),'.b');
h_(3) = plot(segs(5).pts(1,:),segs(5).pts(2,:),'.b');

% Find indexes of outliers in complete set of 3xN correspondences
idxs_inliers  = idxs_exist( inliers );
idxs_outliers = setdiff( idxs_exist, idxs_inliers );

%% Assign outlier tag to each observation obs(i)
Nobs = length( obj.obs );
map = reshape( 1:3*Nobs, 3,Nobs );

% Assign 1 to elements which are outliers
mask_RANSAC_R_outliers = false(1,length(mask_exist));
mask_RANSAC_R_outliers( idxs_outliers ) = true;
for i=1:Nobs
    obj.obs(i).is_R_outlier = mask_RANSAC_R_outliers( map(:,i) );
end

end