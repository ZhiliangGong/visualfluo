function parentDir = getParentDir(currentDir)
    %function to obtain the parent directory
    slashIndex = regexp(currentDir,'\');
    if isempty(slashIndex)
        slashIndex = regexp(currentDir,'/');
    end

    if slashIndex(end) ~= length(currentDir)
        parentDir = currentDir(1:slashIndex(end)-1);
    else
        parentDir = currrentDir(1:slashIndex(end-1)-1);
    end
end