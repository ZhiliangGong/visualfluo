function elementStruct = loadElement(element) %load the elementEnergies file
        
    %read the whole elementEnergy file
    fname = which('elementEnergy.txt');
    text = textread(fname, '%s', 'delimiter', '\n');

    n = length(text);
    for i = 1:n
        if strcmp(text{i}(1),'#')
            if strcmpi(text{i}(2:end),element)
                break;
            end
        end
    end

    elementStruct.name = text{i}(2:end);

    energy = str2num(text{i+1}(9:end));
    elementStruct.peak = energy(2:end-1);
    elementStruct.range = [energy(1),energy(end)];

    elementStruct.width = str2num(text{i+2}(15:end));

end