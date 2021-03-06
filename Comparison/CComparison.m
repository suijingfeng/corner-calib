classdef CComparison < handle & CStaticComp
    %CComparison class to grab data from several simulations(TODO: comment)
    
    % Constructor is object-dependent

    properties 
        Trihedron       % Trihedron methods
        Corner          % Corner methods
        Checkerboard    % Checkerboard methods
    end
    
    properties %(Access = protected)
        cam_sd_vals        % Camera noise levels
        scan_sd_vals       % Lidar noise levels
        Nobs_vals          % Number of correspondences levels
        
        Rt_gt           % Store groundtruth Rt for this specific comparison
        N_sim
    end
    
    methods
               
        % Constructor TODO: add property GTComp if the GT change every it
        function obj = CComparison( Rt_gt, N_sim, cam_sd_vals, scan_sd_vals, Nobs_vals )
            
            obj.dim_cam_sd( size(cam_sd_vals,2) );
            obj.dim_scan_sd( size(scan_sd_vals,2) );
            obj.dim_N_co( size(Nobs_vals,2) );
            obj.dim_N_sim( N_sim );
            obj.N_sim = N_sim;
            
            obj.Trihedron    = CTrihedronComp;
            obj.Corner       = CCornerComp;
            obj.Checkerboard = CCheckerboardComp;
            
            obj.Rt_gt = Rt_gt; % Store groundtruth transformation
            
            obj.cam_sd_vals        = cam_sd_vals;
            obj.scan_sd_vals       = scan_sd_vals;
            obj.Nobs_vals          = Nobs_vals;
        end
        
        % Show object information
        function dispAvailable( obj )
            fprintf('==========================================\n');
            fprintf('Object data:\n')
            fprintf('==========================================\n');
            fprintf('Simulated methods:')
            patterns = obj.getPatterns;
            for i = 1:length(patterns)
                disp( patterns{i} );
                disp('-----------------');
                disp( obj.getMethods(patterns{i}) );
            end
            fprintf('Number of simulations for each tuple: %d\n', obj.N_sim);
            fprintf('Vector of camera noises (pixels):\n');
            disp(obj.cam_sd_vals);
            fprintf('Vector of LRF noises (m):\n');
            disp(obj.scan_sd_vals);
            fprintf('Vector of N of observations:\n');
            disp(obj.Nobs_vals);
            fprintf('Complete lines for .ini\n');
            fprintf('cam_sd_vals  = [ ');
            fprintf('%f ',obj.cam_sd_vals); fprintf(']\n');
            fprintf('scan_sd_vals = [ ');
            fprintf('%f ',obj.scan_sd_vals); fprintf(']\n');
            fprintf('Nobs_vals    = [ ');
            fprintf('%f ',obj.Nobs_vals); fprintf(']\n');
            fprintf('==========================================\n\n');
        end
        function patterns = getPatterns( obj )
            patterns = fieldnames( obj );
        end
        function methods = getMethods( obj, pattern )
            methods = fieldnames( obj.(pattern) );
            methods(end) = []; % Remove mem
        end
        
        function checkValue( obj, field, v )
            for val = v
                if isempty(find(val==obj.(field),1))
                    fprintf('%s available values:\n',field);
                    disp(obj.(field));
                    error('Non existent value %f for field %s',val,field);
                end
            end            
        end
        
        function indexes = getIndexes( obj, field, v )
            indexes = [];
            for val = v
                idx = find(val==obj.(field),1);
                if isempty(idx)
                    fprintf('%s available values:\n',field);
                    disp(obj.(field));
                    error('Non existent value %f for field %s',val,field);
                else
                    indexes(end+1) = idx;
                end
            end            
        end
        
        function obj = plotDataOld( obj, cam_sd_vals, scan_sd_vals, Nobs_vals )           
            % Plot options
            plot_sim_file = fullfile( pwd, 'plotBoxplot.ini' );
            plotOpts = readConfigFile( plot_sim_file );
            extractStructFields( plotOpts );
            clear plotOpts;
            
            % Check size of inputs (only one should be > 1)
            s = [ length(cam_sd_vals), length(scan_sd_vals), length(Nobs_vals) ];
            if length(find(s>1)) > 1
                error('Currently only one variable can be a vector')
            end
            [Nx,imax] = max(s); % The number of groups (one for each X value)
            % Get label
            vals = {cam_sd_vals, scan_sd_vals, Nobs_vals};
            xlabels = {'Cam noise','LRF noise','Nobs'};
            val_label = {};
            for val = vals{imax};
                val_label{end+1} = num2str(val);
            end
            xlab = xlabels{imax};
            
            % Check if the scan_sd value is correct
            cam_idxs  = obj.getIndexes('cam_sd_vals',cam_sd_vals);
            scan_idxs = obj.getIndexes('scan_sd_vals',scan_sd_vals);
            Nobs_idxs = obj.getIndexes('Nobs_vals',Nobs_vals);

            % Extract dim x Nsim matrices for representation
            all_R_err = [];
            all_t_err = [];
            Cval = cell(1,0);
            Ctag = cell(1,0);
            N_met = 0;
            for idx_pattern = 1:size(patterns,1)
                pat = patterns{idx_pattern,1};
                methods = patterns{idx_pattern,2};
                for idx_method = 1:length(methods)
                    met = methods{idx_method};
%                     Rt = squeeze(obj.(pat).(met).mem(:,scan_sd_it,N_co_it,:));
                    Rt = squeeze(obj.(pat).(met).mem(cam_idxs,scan_idxs,Nobs_idxs,:));
                    if size(Rt,2)==1
                        warning('Check squeeze changed dimension order if too many singletons');
                        keyboard
                        Rt = Rt';
                    end
                    R_err = cell2mat( cellfun(@(x)obj.R_err(x), Rt, 'UniformOutput',false) );
                    t_err = cell2mat( cellfun(@(x)obj.t_err(x), Rt, 'UniformOutput',false) );
                    err.(pat).(met).R = R_err;
                    err.(pat).(met).t = t_err;
                    all_R_err = [ all_R_err , R_err' ];
                    all_t_err = [ all_t_err , t_err' ];
                    
                    met_label = repmat({met},1,Nx);
                    Cval = {Cval{:},val_label{:}};
                    Ctag = {Ctag{:},met_label{:}};
                    
                    N_met = N_met+1;
                end
            end
            err.xtick = num2str( obj.cam_sd_vals );
            
            % TODO: Complete options (color, grouping, etc.)
            color = repmat(rand(N_met,3),Nx,1);
            Rlab = 'Rotation error (deg)';
            tlab = 'Translation error (m)';
            figure
            subplot(211)
            boxplot(all_R_err,{Cval,Ctag},'position',pos_,'colors', color, 'factorgap',0,'whisker',0,'plotstyle','compact');
            set(gca,'YScale','log')
            xlabel(xlab)
            ylabel(Rlab)
            subplot(212)
            boxplot(all_t_err,{Cval,Ctag},'colors', color, 'factorgap',[5 0.05],'plotstyle','compact');
            set(gca,'YScale','log')
            xlabel(xlab)
            ylabel(tlab)
            set(gcf,'units','normalized','position',[0 0 1 1]);
        end
        
        function obj = plotData( obj, cam_sd_vals, scan_sd_vals, Nobs_vals )           
            % Plot options
            plot_sim_file = fullfile( pwd, 'plotBoxplot.ini' );
            plotOpts = readConfigFile( plot_sim_file );
            extractStructFields( plotOpts );
            clear plotOpts;
            
            % Check size of inputs (only one should be > 1)
            s = [ length(cam_sd_vals), length(scan_sd_vals), length(Nobs_vals) ];
            if length(find(s>1)) > 1
                error('Currently only one variable can be a vector')
            end
            [Nx,imax] = max(s); % The number of groups (one for each X value)
            % Get label
            vals = {cam_sd_vals, scan_sd_vals, Nobs_vals};
            xlabels = {'Cam noise','LRF noise','Nobs'};
            val_label = {};
            for val = vals{imax};
                val_label{end+1} = num2str(val);
            end
            xlab = xlabels{imax};
            
            % Check if the scan_sd value is correct
            cam_idxs  = obj.getIndexes('cam_sd_vals',cam_sd_vals);
            scan_idxs = obj.getIndexes('scan_sd_vals',scan_sd_vals);
            Nobs_idxs = obj.getIndexes('Nobs_vals',Nobs_vals);

            % Extract dim x Nsim matrices for representation
            all_R_err = [];
            all_t_err = [];
            Cval = cell(1,0);
            Ctag = cell(1,0);
            Cleg = cell(1,0);
            Clab = cell(1,0);
            N_met = 0;
            for idx_pattern = 1:size(patterns,1)
                pat = patterns{idx_pattern,1};
                methods = patterns{idx_pattern,2};
                for idx_method = 1:length(methods)
                    met = methods{idx_method};
%                     Rt = squeeze(obj.(pat).(met).mem(:,scan_sd_it,N_co_it,:));
                    Rt = squeeze(obj.(pat).(met).mem(cam_idxs,scan_idxs,Nobs_idxs,:));
                    if size(Rt,2)==1
                        warning('Check squeeze changed dimension order if too many singletons');
                        keyboard
                        Rt = Rt';
                    end
                    R_err = cell2mat( cellfun(@(x)obj.R_err(x), Rt, 'UniformOutput',false) );
                    t_err = cell2mat( cellfun(@(x)obj.t_err(x), Rt, 'UniformOutput',false) );
                    err.(pat).(met).R = R_err;
                    err.(pat).(met).t = t_err;
                    all_R_err = [ all_R_err , R_err' ];
                    all_t_err = [ all_t_err , t_err' ];
                    
                    met_label = repmat({met},1,Nx);
                    Cval = {Cval{:},val_label{:}};
                    Ctag = {Ctag{:},met_label{:}};
                                       
                    N_met = N_met+1;
                end
            end
            err.xtick = num2str( obj.cam_sd_vals );
            
            % Parameters to control the position in X label
            Npos    = 5;    % gap between samples in X label
            pos_ini = 1;    % initial value in X label
            Nsep    = 0.5;  % gap between methods in X label
            % Load the vector of positions
            pos_aux = pos_ini:Npos:Npos*Nx;
            pos_    = pos_aux
            pos_1   = [];
            for i = 1:N_met-1
                pos_ = [pos_ pos_aux+i*Nsep];
            end
            
            color_ = [0.2980392156862745 0.4470588235294118 0.6901960784313725;
              0.3333333333333333 0.6588235294117647 0.40784313725490196;
              0.7686274509803922 0.3058823529411765 0.3215686274509804;
              %0.5058823529411764 0.4470588235294118 0.6980392156862745;];
              0.8                0.7254901960784313 0.4549019607843137];
            color = repmat(color_,Nx,1);           
%             color = repmat(rand(N_met,3),Nx,1);
            Rlab = 'Rotation error (deg)';
            tlab = 'Translation error (m)';
            Cleg = {'Trihedron','Kwak et al.','Wasielewski et al.','Vasconcelos et al.'};
            
            % Boxplot for R
            h = figure; hold on;
            boxplot(all_R_err,{Cval,Ctag},'position',sort(pos_),'colors', color, 'factorgap',0,'whisker',0,'plotstyle','compact');
            bp_ = findobj(h, 'tag', 'Outliers');
            set(bp_,'Visible','Off');   % Remove the outliers           
            xlabel(xlab); ylabel(Rlab);
            % Plot the lines
            median_ = median(all_R_err);
            for i = 1:N_met
                x_ = pos_(1, Nx*(i-1)+1:Nx*i);
                y_ = median_(1, Nx*(i-1)+1:Nx*i);               
                plot(x_,y_,'Color',color(i,:),'LineWidth',1.5);
                %Cleg = {Cleg{:}, Ctag{1,Nx*(i-1)+1} };
            end
            Clab = {Cval{1,1:Nx}};
            set(gca,'YScale','log');
            set(gca,'XTickLabel',{' '});  
            [legh,objh,outh,outm] = legend(Cleg);
            set(objh,'linewidth',3);   
            set(gca,'XTick',pos_aux);
            set(gca,'XTickLabel',Clab);
            
            % Boxplot for t
            h = figure; hold on;
            boxplot(all_t_err,{Cval,Ctag},'position',sort(pos_),'colors', color, 'factorgap',0,'whisker',0,'plotstyle','compact');
            bp_ = findobj(h, 'tag', 'Outliers');
            set(bp_,'Visible','Off');   % Remove the outliers           
            xlabel(xlab); ylabel(tlab);
            % Plot the lines
            median_ = median(all_t_err);
            for i = 1:N_met
                x_ = pos_(1, Nx*(i-1)+1:Nx*i);
                y_ = median_(1, Nx*(i-1)+1:Nx*i);               
                plot(x_,y_,'Color',color(i,:),'LineWidth',1.5);
            end
            set(gca,'YScale','log');
            set(gca,'XTickLabel',{' '});  
            [legh,objh,outh,outm] = legend(Cleg);
            set(objh,'linewidth',3);   
            set(gca,'XTick',pos_aux);
            set(gca,'XTickLabel',Clab);           
        end        
        
        function obj = plot( obj, field, cam_sd_vals, scan_sd_vals, Nobs_vals )
            % Plot options
            plot_sim_file = fullfile( pwd, 'plotBoxplot.ini' );
            plotOpts = readConfigFile( plot_sim_file );
            extractStructFields( plotOpts );
            clear plotOpts;
            
            % Check size of inputs (only one should be > 1)
            s = [ length(cam_sd_vals), length(scan_sd_vals), length(Nobs_vals) ];
            if length(find(s>1)) > 1
                error('Currently only one variable can be a vector')
            end
            [Nx,imax] = max(s); % The number of groups (one for each X value)
            % Get label
            vals = {cam_sd_vals, scan_sd_vals, Nobs_vals};
            xlabels = {'Cam noise','LRF noise','Nobs'};
            val_label = {};
            for val = vals{imax};
                val_label{end+1} = num2str(val);
            end
            xlab = xlabels{imax};
            
            % Check if the scan_sd value is correct
            cam_idxs  = obj.getIndexes('cam_sd_vals',cam_sd_vals);
            scan_idxs = obj.getIndexes('scan_sd_vals',scan_sd_vals);
            Nobs_idxs = obj.getIndexes('Nobs_vals',Nobs_vals);

            % Extract dim x Nsim matrices for representation
            all_val_plot = [];
            Cval = cell(1,0);
            Ctag = cell(1,0);
            N_met = 0;
            for idx_pattern = 1:size(patterns,1)
                pat = patterns{idx_pattern,1};
                methods = patterns{idx_pattern,2};
                for idx_method = 1:length(methods)
                    met = methods{idx_method};
%                     Rt = squeeze(obj.(pat).(met).mem(:,scan_sd_it,N_co_it,:));
                    val = squeeze(obj.(pat).(met).(field)(cam_idxs,scan_idxs,Nobs_idxs,:));
                    if size(val,2)==1
                        warning('Check squeeze changed dimension order if too many singletons');
                        keyboard
                        val = val';
                    end
                    val_plot = cell2mat( cellfun(@(x)obj.(field)(x), val, 'UniformOutput',false) );
%                     err.(pat).(met).R = R_err;
%                     err.(pat).(met).t = t_err;
                    values.(pat).(met).(field) = val_plot;
                    all_val_plot = [ all_val_plot , val_plot' ];
                    
                    met_label = repmat({met},1,Nx);
                    Cval = {Cval{:},val_label{:}};
                    Ctag = {Ctag{:},met_label{:}};
                    
                    N_met = N_met+1;
                end
            end
%             err.xtick = num2str( obj.cam_sd_vals );
            
            % TODO: Complete options (color, grouping, etc.)
            color = repmat(rand(N_met,3),Nx,1);
            medians{1} = median( values.Trihedron.Weighted3D.cov_t' );
%             medians{2} = median( values.Trihedron.NonWeighted3D.cov_R' );
            medians{2} = median( values.Trihedron.Global.cov_t' );
            figure, hold on
            plot( [5 10 20 50], medians{1}, '-o' )
            plot( [5 10 20 50], medians{2}, '-o' )
            
            val_lab = field;
            figure
            boxplot(all_val_plot,{Cval,Ctag},'colors', color, 'factorgap',10,'plotstyle','compact');
%             set(gca,'YScale','log')
            xlabel(xlab)
            ylabel(val_lab)
%             set(gcf,'units','normalized','position',[0 0 1 1]);
        end
        
        function [R_err] = R_err( obj, Rt )
            R_err = angularDistance( Rt(1:3,1:3), obj.Rt_gt(1:3,1:3) );
        end
        function [t_err] = t_err( obj, Rt )
            t_err = norm( Rt(1:3,4) - obj.Rt_gt(1:3,4) );
        end
        function [max_eig] = cov_R( obj, cov )
            s = svd( cov );
            max_eig = s(1);
        end
        function [max_eig] = cov_t( obj, cov )
            s = svd( cov );
            max_eig = s(1);
        end
        
        function obj = plotCamNoise( obj )
            %TODO            
        end
        function obj = plotLidarNoise( obj )
            %TODO            
        end
        
        
        
    end
    
end