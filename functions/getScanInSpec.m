function body = getScanInSpec(fname,scanNumber)

    feature = sprintf('%s %s','#s',num2str(scanNumber));
    n = length(feature);
    text = textread(fname,'%s','delimiter','\n');
    
    n1 = 0;
    for i = 1:length(text)
        if length(text{i}) >= n && strcmpi(text{i}(1:n), feature)
            n1 = i;
        end
        if n1 > 0 && isempty(text{i})
            n2 = i-1;
            break;
        end
    end
    
    body = text(n1:n2);

end