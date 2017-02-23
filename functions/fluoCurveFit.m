function [a,fitx,fity] = fluoCurveFit(x,y,type,peak,width,N) %fit fluorescence intensity to Gaussian or Lorentzian

    [a0,lb,ub] = getInitialValues;
    
    switch lower(type)
        case {'gauss','gaussian'}
            [a,fitx,fity] = gaussFit(a0,lb,ub);
        case {'lorentz','lorentzian'}
            [a,fitx,fity] = lorentzFit(a0,lb,ub);
        otherwise
            error('Fitting line shape for fluorescence spectra not found.');    
    end
    
    a = reshape(a,length(a),1);
    fitx = reshape(fitx,length(fitx),1);
    fity = reshape(fity,length(fity),1);
    
    function [a0,lb,ub] = getInitialValues %initial values for fitting parameters
        
        try
            baseValue = mean([mean(y(1:5)),mean(y(end-4:end))]);
        catch
            baseValue = mean(y(1),y(end));
        end
        
        switch length(peak)
            case 1
                lb = [0,peak-0.2,0,-inf,min(y)];
                ub = [range(y)*3,peak+0.2,range(x)/2,inf,mean(y)];
                a0 = zeros(1,5);
                a0(1) = range(y);
                a0(2) = peak;
                a0(4) = 0;
                a0(5) = baseValue;
                switch length(width)
                    case 0
                        a0(3) = range(x)/6;
                    case 1
                        a0(3) = width;
                    otherwise
                        error('Too many peak width parameters.')
                end
            case 2
                a0 = zeros(1,8);
                a0(1) = range(y);
                a0(4) = range(y);
                a0(2) = peak(1);
                a0(5) = peak(2);
                a0(7) = 0;
                a0(8) = baseValue;
                lb = [0,peak(1)-0.2,0,0,peak(2)-0.2,0,-inf,min(y)];
                ub = [range(y)*3,peak(1)+0.2,range(x)/2,range(y)*3,peak(2)+0.2,range(x)/2,inf,mean(y)];
                switch length(width)
                    case 0
                        a0(3) = range(x)/8;
                        a0(6) = range(x)/8;
                    case 2
                        a0(3) = width(1);
                        a0(6) = width(2);
                    otherwise
                        error('# of peak width not right.');
                end
            otherwise
                error('Only one or two peaks allowed');
        end
    
    end

    function [g,fitx,fity] = gaussFit(g0,lb,ub)
        
        fitx = linspace(x(1),x(end),N);
        OPTIONS = optimoptions('lsqnonlin','Algorithm','trust-region-reflective','Display','off');
        switch length(g0)
            case 5
                myfun = @(g) (gausslinback(g,x)-y);
                g = lsqnonlin(myfun,g0,lb,ub,OPTIONS);
                fity = gausslinback(g,fitx);
            case 8
                myfun = @(g) (gauss2linback(g,x)-y);
                g = lsqnonlin(myfun,g0,lb,ub,OPTIONS);
                fity = gauss2linback(g,fitx);
            otherwise
                error('g0 should contain either 5 or 8 elements.');
        end
        
    end

    function [l,fitx,fity] = lorentzFit(l0,lb,ub)
        
        fitx = linspace(x(1),x(end),N);
        OPTIONS = optimoptions('lsqnonlin','Algorithm','trust-region-reflective','Display','off');
        switch length(l0)
            case 5
                myfun = @(l) (lorentzlinback(l,x)-y);
                l = lsqnonlin(myfun,l0,lb,ub,OPTIONS);
                fity = lorentzlinback(l,fitx);
            case 8
                myfun = @(l) (lorentz2linback(l,x)-y);
                l = lsqnonlin(myfun,l0,lb,ub,OPTIONS);
                fity = lorentz2linback(l,fitx);
            otherwise
                error('l0 should contain either 5 or 8 elements.');
        end
        
    end

end