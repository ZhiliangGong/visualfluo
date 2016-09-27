function [head,body] = splitScan(fname) %split the scan into header portion, and body portions
    %split the head part into a cell array, and the body part into
    %a cell matrix

    mtext = textread(fname,'%s','delimiter','\n');

    n = length(mtext);
    k = zeros(1,n);
    for i = 1:n
        k(i) = ~isempty(mtext{i});
    end
    k = k(2:end)-k(1:end-1);
    k = [1,k];

    m = find(k);
    m = [m(1:2:end-1);m(2:2:end)];
    l = m(2,:)-m(1,:); %length of each block

    ns = sum(l>30); %# of qz
    nl = length(l);
    body = cell(l(end),ns);
    for i = (nl-ns+1):nl
        body(:,i-nl+ns) = mtext(m(1,i):m(2,i)-1);
    end

    head = cell(sum(l(1:nl-ns)),1);
    j = 1;
    for i = 1:nl-ns
        head(j:j+l(i)-1) = mtext(m(1,i):m(2,i)-1);
        j = j+l(i);
    end

end