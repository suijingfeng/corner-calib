classdef Cxi < Manifold.Dyn
    %Cxi Class for storage of Trihedron Observation image, structure formed
    %by one point (center) and three directions (one per line)
    %   Detailed explanation goes here
    
    properties (Dependent)
%         c   % 2x1 R2 vector
%         v   % 1x3 array with S1 directions of lines
    end
    
    methods % Not compulsory
        function obj = Cxi( c, v1, v2, v3 )
            % obj = Cxi( c, v1, v2, v3 )
            if isnumeric(c)
                c = Manifold.Rn( c );
            end
            if isnumeric(v1)
                v1 = Manifold.S1( v1 );
            end
            if isnumeric(v2)
                v2 = Manifold.S1( v2 );
            end
            if isnumeric(v3)
                v3 = Manifold.S1( v3 );
            end
            
            % obj = Cxi( c_R2, v1_S1, v2_S1, v3_S1 )
            obj = obj@Manifold.Dyn( c, v1, v2, v3 );
        end
        
        % Function to simplify interface
        function c = c( obj )
            c = obj.vars{1};
        end
        function v = v( obj, ind )
            v = obj.vars{1+ind};
        end
    end
end
