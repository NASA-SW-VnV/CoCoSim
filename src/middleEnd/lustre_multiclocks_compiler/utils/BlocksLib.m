classdef BlocksLib
    %BlocksLib This class is a set of Simulink blocks as Lustre libraries.
    
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens] = template()
            opens = {};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes_i, opens] = get__DigitalClock()
            opens = {};
            external_nodes_i = {'_round', '_fabs'};
            format = 'node _DigitalClock (simulationTime, SampleTime:real)\nreturns(q:real);\n';
            format = [format, 'var b:bool;\n'];
            format = [format, 'let\n\t'];
            format = [format, 'b = _fabs(simulationTime - _round(simulationTime/SampleTime) * SampleTime) <= 0.000000001; \n\t'];
            format = [format, 'q = if b then simulationTime else pre q; \n'];
            format = [format, 'tel\n\n'];
            node = sprintf(format);
        end
    end
    
end

