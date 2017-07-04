classdef Circle < Stimulus               
    % CIRCLE - Class for circle stimuli in StimServer
    %
    % See also Stimulus

    properties ( SetAccess = immutable, GetAccess = public )
        type
    end
    
    properties ( SetAccess = public, GetAccess = public, Transient = true )
        diameter % diameter of stimulus in px
        color = [255 255 255]; % color of circle as 24-bit [r g b] value
        alpha = 255; % alpha transparency value
    end       
        
    methods
        function obj = Circle(symbolType)
            if nargin == 0
                symbolType = 1;
            end
            symbolDiameter = 200;
            StimServer.Command(0, [uint8([12, symbolType]), typecast(uint16(symbolDiameter),'uint8')]);                         
            obj = obj@Stimulus();
            obj.type = symbolType;
            obj.diameter = symbolDiameter;                        
        end
        
        function set.diameter(obj, diameter)
               StimServer.Command(obj.key, [uint8([1,1]), typecast(uint16(diameter), 'uint8')]);
               obj.diameter = diameter;
        end
        
        function set.color(obj, color)
            StimServer.Command(obj.key, [5, color, obj.alpha]); 
            obj.color = color;
        end
        
        function set.alpha(obj, alpha)
            StimServer.Command(obj.key, [5, obj.color, alpha]); 
            obj.alpha = alpha;
        end
         
    end
end