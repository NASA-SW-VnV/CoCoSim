function [ lustre_code ] = getExternalLibrariesNodes( external_libraries )
[ lustre_code, open_list ] = recursive_call( external_libraries, {} );
if ~isempty(open_list)
    open_list = unique(open_list);
    open_list = cellfun(@(x) sprintf('#open <%s>\n',x), open_list, 'un', 0);
    lustre_code = [ MatlabUtils.strjoin(open_list, ''), lustre_code];
end
end

function [ lustre_code, open_list ] = recursive_call( external_libraries, already_handled )
%GETEXTERNALLIBRARIESNODES returns the lustre nodes and libraries to be add
%to the head of lustre code.
lustre_code = '';
open_list = {};
if isempty(external_libraries)
    return;
end

external_libraries = unique(external_libraries);
additional_nodes = {};
for i=1:numel(external_libraries)
    lib = external_libraries{i};
    switch lib
        %% Integer rounding modes.
        case  {'int_to_real', 'real_to_int'}
            open_list{numel(open_list) + 1} = 'conv';
            
        case '_Floor'
            open_list{numel(open_list) + 1} = 'conv';
            node = getFloor();
            lustre_code = [lustre_code, node];
            
        case '_Ceiling'
            open_list{numel(open_list) + 1} = 'conv';
            node = getCeiling();
            lustre_code = [lustre_code, node];
            
        case '_Convergent'
            [node, external_nodes_i] = getConvergent();
            lustre_code = [lustre_code, node];
            additional_nodes = [additional_nodes, external_nodes_i];
            
        case '_Nearest'
            [node, external_nodes_i] = getNearest();
            lustre_code = [lustre_code, node];
            additional_nodes = [additional_nodes, external_nodes_i];
            
        case '_Round'
            [node, external_nodes_i] = getRound();
            lustre_code = [lustre_code, node];
            additional_nodes = [additional_nodes, external_nodes_i];
            
        case 'real_to_bool'
            node = getToBool('real');
            lustre_code = [lustre_code, node];
            
        case 'int_to_bool'
            node = getToBool('int');
            lustre_code = [lustre_code, node];
            
        case 'bool_to_int'
            node = getBoolTo('int');
            lustre_code = [lustre_code, node];
            
        case 'bool_to_real'
            node = getBoolTo('real');
            lustre_code = [lustre_code, node];
            
        case {'int_to_int8','int_to_uint8',...
                'int_to_int16','int_to_uint16',...
                'int_to_int32','int_to_uint32'}
            dt = regexp(lib, 'int_to_(\w+)', 'tokens', 'once');
            if ~isempty(dt)
                dt = dt{1};
                [node, external_nodes_i] = getToInt(dt);
                additional_nodes = [additional_nodes, external_nodes_i];
                lustre_code = [lustre_code, node];
            end
       %% remaining function
        case 'fmod'
            open_list{numel(open_list) + 1} = 'simulink_math_fcn';
            
        case 'rem_int_int'
            node = getRem_int_int();
            lustre_code = [lustre_code, node];
            
            %% math functions
        case 'fabs'
            node = getFabs();
            lustre_code = [lustre_code, node];
            
            
    end
    
end

already_handled = unique([already_handled, external_libraries]);
additional_nodes = unique(additional_nodes);
additional_nodes = additional_nodes(~ismember(additional_nodes, already_handled));
[ additional_code, additional_open_list ] = recursive_call( additional_nodes, already_handled );
lustre_code = [lustre_code, additional_code];
open_list = [open_list, additional_open_list];


end

%%
function node = getToBool(dt)
format = 'node %s (x: %s)\nreturns(y:bool);\nlet\n\t y= (x > %s);\ntel\n\n';
node_name = strcat(dt, '_to_bool');
if strcmp(dt, 'int')
    zero = '0';
else
    zero = '0.0';
end
node = sprintf(format, node_name, dt, zero);

end

function node = getBoolTo(dt)
format = 'node %s (x: bool)\nreturns(y:%s);\nlet\n\t y= if x then %s else %s;\ntel\n\n';
node_name = strcat('bool_to_', dt);
if strcmp(dt, 'int')
    zero = '0';
    one = '1';
else
    zero = '0.0';
    one = '1.0';
end
node = sprintf(format, node_name, dt, one, zero);

end

%%

function [node, external_nodes] = getToInt(dt)
format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
format = [format, 'y= if x > %d then %d + rem_int_int((x - %d - 1),%d) \n\t'];
format = [format, 'else if x < %d then %d + rem_int_int((x - (%d) + 1),%d) \n\telse x;\ntel\n\n'];
v_max = double(intmax(dt));
v_min = double(intmin(dt));
nb_int = (v_max - v_min + 1);
node_name = strcat('int_to_', dt);

node = sprintf(format, node_name, v_max, v_min, v_max, nb_int,...
    v_min, v_max, v_min, nb_int);
external_nodes = {'rem_int_int'};

end

%%
function node = getFloor()
% Round towards minus infinity.
format = '--Round towards minus infinity..\n ';
format = [ 'node _Floor (x: real)\nreturns(y:int);\nlet\n\t'];
format = [format, 'y= if x < 0.0 then real_to_int(x) - 1 \n\t'];
format = [format, 'else real_to_int(x);\ntel\n\n'];
node = sprintf(format);
end

%%
function node = getCeiling()
% Round towards plus infinity.
format = '--Round towards plus infinity.\n ';
format = [ format ,'node _Ceiling (x: real)\nreturns(y:int);\nlet\n\t'];
format = [format, 'y= if x < 0.0 then real_to_int(x) \n\t'];
format = [format, 'else real_to_int(x) + 1;\ntel\n\n'];
node = sprintf(format);
end

%%
function [node, external_nodes] = getConvergent()
%Rounds number to the nearest representable value.
%If a tie occurs, rounds to the nearest even integer.
%Equivalent to the Fixed-Point Designer? convergent function.
format = '--Rounds number to the nearest representable value.\n ';
format = [ format ,'node _Convergent (x: real)\nreturns(y:int);\nlet\n\t'];
format = [ format , 'y = if (x > 0.5) then\n\t\t\t'];
format = [ format , 'if (fmod(x, 2.0) = 0.5) '];
format = [ format , ' then _Floor(x)\n\t\t\t'];
format = [ format , ' else _Floor(x + 0.5)\n\t\t'];
format = [ format , ' else\n\t\t'];
format = [ format , ' if (x >= -0.5) then 0 \n\t\t'];
format = [ format , ' else \n\t\t\t'];
format = [ format , ' if (fmod(x, 2.0) = -0.5) then _Ceiling(x)\n\t\t\t'];
format = [ format , ' else _Ceiling(x - 0.5);'];
format = [ format , '\ntel\n\n'];


node = sprintf(format);
external_nodes = {'fmod', '_Floor', '_Ceiling'};

end

%% Nearest Rounds number to the nearest representable value.
%If a tie occurs, rounds toward positive infinity. Equivalent to the Fixed-Point Designer nearest function.
function [node, external_nodes] = getNearest()
format = '--Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity\n ';
format = [ format ,'node _Nearest (x: real)\nreturns(y:int);\nlet\n\t'];
format = [ format , 'y = if (fabs(x) >= 0.5) then _Floor(x + 0.5)\n\t'];
format = [ format , ' else 0;'];
format = [ format , '\ntel\n\n'];


node = sprintf(format);
external_nodes = { '_Floor', '_Ceiling', 'fabs'};
end

%% Round Rounds number to the nearest representable value. 
%If a tie occurs, rounds positive numbers toward positive infinity and rounds negative numbers toward negative infinity. Equivalent to the Fixed-Point Designer round function.
function [node, external_nodes] = getRound()
format = '--Rounds number to the nearest representable value.\n';
format = [format , '--If a tie occurs,rounds positive numbers toward positive infinity and rounds negative numbers toward negative infinity\n '];
format = [ format ,'node _Round (x: real)\nreturns(y:int);\nlet\n\t'];
format = [ format , 'y = if (x >= 0.5) then _Floor(x + 0.5)\n\t\t'];
format = [ format , ' else if (x > -0.5) then 0 \n\t\t'];
format = [ format , ' else _Ceiling(x - 0.5);'];
format = [ format , '\ntel\n\n'];


node = sprintf(format);
external_nodes = {'_Floor', '_Ceiling'};
end
%%
function rem_node = getRem_int_int()
format = 'node rem_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
format = [format, 'z= if (x < 0) and (y > 0) then (x mod -y) \n\t'];
format = [format, 'else (x mod y);\ntel\n\n'];

rem_node = sprintf(format);
end

%%
function fabs_node = getFabs()
format = 'node fabs (x:real)\nreturns(z:real);\nlet\n\t';
format = [format, 'z= if (x >= 0.0)  then x \n\t'];
format = [format, 'else -x;\ntel\n\n'];

fabs_node = sprintf(format);
end