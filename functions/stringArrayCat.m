function [string, stringArray] = stringArrayCat(string,stringArray) %concatenate string array
    if ~isempty(stringArray)
        string = sprintf('%s%s',string,stringArray{1});
        stringArray = stringArray(2:end);
        [string, stringArray] = stringArrayCat(string, stringArray);
    end
end