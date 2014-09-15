classdef CBaseOptimization < handle % handle for compatibility with C...Optimization
    %COptimization Base class with common properties for optimization
    %processes
    %   Detailed explanation goes here
    
    properties
        debug_level % Verbose level when optimizing
        maxIters    % Max number of iterations in LM optimization
        minParamChange   % Minimum change in param (norm2) to stop
        minErrorChange  % Minimum change in cost function to stop
        
        % For representation
        plot_dist_t
        plot_dist_R
        plot_res    % The number of steps in grid
    end
    
    methods
        function obj = CBaseOptimization( debug_level, maxIters, minParamChange, minErrorChange, plot_dist_R, plot_dist_t )
            % TODO: Remove this (it is in inherited class)
            if ~exist('debug_level','var')
                debug_level = 2;
            end
            obj.debug_level = debug_level;
            
            if ~exist('maxIters','var')
                maxIters = 50;
            end
            obj.maxIters = maxIters;
            
            if ~exist('minParamChange','var')
                minParamChange = 1e-8;
            end
            obj.minParamChange = minParamChange;
            
            if ~exist('minErrorChange','var')
                minErrorChange = 1e-8;
            end
            obj.minErrorChange = minErrorChange;
            
            if ~exist('plot_dist_t','var')
                plot_dist_t = 1 / 100;
            end
            obj.plot_dist_t = plot_dist_t;
            
            if ~exist('plot_dist_R','var')
                plot_dist_R = deg2rad( 0.2 );
            end
            obj.plot_dist_R = plot_dist_R;
            
            obj.plot_res = 20;
        end
        
        function x = optimize( obj, Fun, x0, space, weighted )
            % General method for optimization with LM
            [ x, ~, ~, ~ ] = LM_Man_optim(Fun,x0,...
                'space',space,'weighted',weighted,...
                'debug', obj.debug_level,...
                'maxIters', obj.maxIters,...
                'minChange', obj.minParamChange,...
                'minErrorChange', obj.minErrorChange);
        end
        
        function h = plotCostFunction( obj, gv, W, FE, Fx, x0 )
            Ngv = length(gv);
            [w_i,w_j] = meshgrid( gv );
            
            % Linearize code
            inc_eps = [ w_i(:), w_j(:), zeros(Ngv^2,1) ]';
            
            weights = W;
            
            labels = { 'x', 'y', 'z'
                       'y', 'z', 'x' };
            titles = { 'X-Y err^2', 'Y-Z err^2', 'Z-X err^2'
                       'X-Y errW' , 'Y-Z errW' , 'Z-X errW' };
            for k=1:3
                Err2 = zeros(1,Ngv^2);
                ErrW = zeros(1,Ngv^2);
                inc_eps_ = circshift( inc_eps, k-1 ); % Shift inc_eps rows
                for i=1:numel(Err2)
                    x_ = Fx( x0, inc_eps_(:,i) );
                    residual = FE( x_ );
                    Err2(i) = residual' * residual;
                    ErrW(i) = residual' * weights * residual;
                end
                Err2 = reshape(Err2,Ngv,Ngv);
                ErrW = reshape(ErrW,Ngv,Ngv);
                Err = {Err2, ErrW};
                
                res_GT = FE( x0 );
                err2_GT = { res_GT'*res_GT , res_GT'*weights*res_GT };
                for k_sub=1:2
                    subplot(2,3,k +(k_sub-1)*3 ); hold on;
                    xlabel(labels{1,k});
                    ylabel(labels{2,k});
                    title( titles{k_sub,k} );
                    surf(w_i,w_j, Err{k_sub});
                    % Plot GT point
                    plot3(0,0,err2_GT{k_sub}, '.y', 'LineWidth', 3);
                    axis([gv(1) gv(end) gv(1) gv(end)]);
                    shading interp;
                    view([90 90]);
                end
            end
            h = []; % TODO
        end
        
        function plot_gv = get_plot_gv( obj, dist )
             inc = 2*dist/obj.plot_res;
             plot_gv  = -dist:inc:+dist;
        end
    end
    
end

