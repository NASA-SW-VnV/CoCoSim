
%% Get unique short name
function unique_name = getUniqueName(object, id)
    global SF_STATES_PATH_MAP SF_JUNCTIONS_PATH_MAP;
    if ischar(object)
        name = object;
        if nargin == 1
            if isKey(SF_STATES_PATH_MAP, name)
                id = SF_STATES_PATH_MAP(name).Id;
            elseif isKey(SF_JUNCTIONS_PATH_MAP, name)
                id = SF_JUNCTIONS_PATH_MAP(name).Id;
            else
                error('%s not found in SF_STATES_PATH_MAP', name);
            end
        end
    else
        name = object.Name;
        id = object.Id;
    end
    [~, name, ~] = fileparts(name);
    id_str = sprintf('%.0f', id);
    unique_name = sprintf('%s_%s',...
        nasa_toLustre.utils.SLX2LusUtils.name_format(name),id_str );
end
