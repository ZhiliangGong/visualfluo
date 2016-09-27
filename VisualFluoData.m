classdef VisualFluoData < handle
    %x-ray fluorescence data class for a series of q, error is the standard
    %deviation. This program runs only for the data format of APS Sector
    %15, other beamlines would need a different algorithm reading the
    %files.
    %   Zhiliang Gong, March 19, 2015

    properties
        specFile %the spec file
        specPath %the path for the spec file
        scanFile %the mca file where the data comes from
        scanPath %the path for mca data files
        scanNumber %scan number
        
        %scalar properties
        time %time of experiment
        E %energy of the x-ray source
        wavelength %wavelength of beam in A
        s1 %the top and bottom of s1 slits
        sx %sx
        
        %vector properties
        T %programmed collection time        
        countTime %actual counting time of instrument
        q %qz range
        angle %the angle in radian
        influx %monc counts
        absorber %absorber
        
        rowNumber %the number of rows
        calibration %calibration constants for energy
        
        A %scale factor for the raw data
        element %the currently fitted element
        
        e %energy corresponding to the channels
        counts %raw data from the channels
        countsError %error of the raw data
        intensity %normalized raw data by monc and the scale factor
        intensityError %error of the normalized raw data
        
        xe %short energy axis for the calcium fluorescence        
        xCounts %raw fluorescence data for the specific element, adjusted
        netCounts %background subtracted
        xCountsError %error of the raw data for the speficied element
        xIntensity %normalized data for the speficied element
        netIntensity %background subtracted
        xIntensityError %error of the normalized data
        
        fitType %gaussian or lorentzian
        fitE %energy axis for the fitted curves
        countPara %fit parameters for counts
        countFit %fitted curve for counts
        netCountFit %background subtracted
        intensityPara %fit parameters for intensity
        intensityFit %fitted curve for intensity
        netIntensityFit %background subtracted
        signal %integrated signal
        signalError
        
    end
   
    methods
        
        %% data processing
        
        function x = VisualFluoData(specFile,specPath,scanFile,scanPath,scanNumber,A) %construct the data
            
            x.specFile = specFile;
            x.specPath = specPath;
            x.scanFile = scanFile;
            x.scanPath = scanPath;
            x.scanNumber = scanNumber;
            x.A = A;
            x.element = '';
            
            importScan(x);
            calculateIntensity(x);
            
        end
        
        function importScan(x) %import and process
                        
            %data from scan file
            fname = fullfile(x.scanPath,x.scanFile);
            [~,body] = splitScan(fname);
            readScanBody(x,body);
            
            %data from spec file
            fname = fullfile(x.specPath,x.specFile);
            body = getScanInSpec(fname,x.scanNumber);
            try
                readScanBodyInSpec(x,body);
            catch
                warning('%s %s',x.scanFile,': could not read scan in spec file. Setting sx to 0, s1 to [1 1], and absorber to 0.');
                x.sx = 0;
                x.s1 = [1 1];
                x.absorber = 0;
            end
            
            x.angle = calculateRadian(x.q,x.E);
            x.wavelength = calculateWavelength(x.E);
            
            x.e = polyval(fliplr(x.calibration),(1:x.rowNumber)')/1000;
            x.countsError = sqrt(x.counts);
            
        end
        
        function adjustScaleFactor(x,A) %adjust the scale factor to A
            
            ratio = A/x.A;
            x.A = A;
            
            if ~isempty(x.element)
                
                x.intensity = x.intensity * ratio;
                x.intensityError = x.intensityError * ratio;
                
                x.xIntensity = x.xIntensity * ratio;
                x.netIntensity = x.netIntensity * ratio;
                x.xIntensityError = x.xIntensityError * ratio;
                
                x.intensityFit = x.intensityFit * ratio;
                x.netIntensityFit = x.netIntensityFit * ratio;

                switch size(x.intensityPara,1)
                    case 5
                        x.intensityPara([1,4,5],:) = x.intensityPara([1,4,5],:) * ratio;
                    case 8
                        x.intensityPara([1,4,7,8],:) = x.intensityPara([1,4,7,8],:) * ratio;
                end
                
                x.signal = x.signal * ratio;
                x.signalError = x.signalError * ratio;
                
            end
            
        end
        
        function adjustEnergyCalibration(x) %adjust calibration to the new calibration vector
            
            x.e = polyval(fliplr(x.calibration),(1:x.rowNumber)')/1000;
            if ~isempty(x.element)
                xFit(x,x.element.name,x.fitType);
            end
            
        end
        
        function adjustFittingMethod(x) %adjust fitting method
            
            if ~isempty(x.element)
                xFit(x,x.element.name,x.fitType);
            end
            
        end
        
        %% fitting
        
        function xFit(x,element,varargin) %fit the fluorescence spectrum
            
            if nargin == 2
                type = 'gaussian';
            elseif nargin == 3
                type = varargin{1};
            else
                error('Check argument for xFit.');
            end
            x.fitType = type;
            
            element = loadElement(element);
            x.element = element;
            
            %find the energy range working on
            n1 = find(abs(x.e-element.range(1)) == min(abs(x.e-element.range(1))),1);
            n2 = find(abs(x.e-element.range(2)) == min(abs(x.e-element.range(2))),1);

            x.xe = x.e(n1:n2);
            x.xCounts = x.counts(n1:n2,:);
            x.xCountsError = x.countsError(n1:n2,:);
            x.xIntensity = x.intensity(n1:n2,:);
            x.xIntensityError = x.intensityError(n1:n2,:);
            
            [~,n] = size(x.xCounts);
            N = 500;
            x.fitE = linspace(x.xe(1),x.xe(end),N)';
            x.countFit = zeros(N,n);
            x.intensityFit = zeros(N,n);
            switch length(element.peak)
                case 1
                    x.countPara = zeros(5,n);
                    x.intensityPara = zeros(5,n);
                case 2
                    x.countPara = zeros(8,n);
                    x.intensityPara = zeros(8,n);
                otherwise
                    error('Curve type not found.');
            end
            for i = 1:n
                [x.countPara(:,i),~,x.countFit(:,i)] = fluoCurveFit(x.xe,x.xCounts(:,i),type,element.peak,element.width,N);
                [x.intensityPara(:,i),~,x.intensityFit(:,i)] = fluoCurveFit(x.xe,x.xIntensity(:,i),type,element.peak,element.width,N);
            end
            
            x.netCounts = x.xCounts - [x.xe,ones(size(x.xe))]*x.countPara(end-1:end,:);
            x.netCountFit = x.countFit - [x.fitE,ones(size(x.fitE))]*x.countPara(end-1:end,:);
            x.netIntensity = x.xIntensity - [x.xe,ones(size(x.xe))]*x.intensityPara(end-1:end,:);
            
            x.netIntensityFit = x.intensityFit - [x.fitE,ones(size(x.fitE))]*x.intensityPara(end-1:end,:);
            
            %calculate the signal and error
            x.signalError = sqrt(sum(x.xIntensityError.^2))*range(x.xe)/length(x.xe);
            switch length(element.peak)
                case 1
                    switch lower(type)
                        case {'gauss','gaussian'}
                            x.signal = x.intensityPara(1,:).*x.intensityPara(3,:)*sqrt(2*pi);
                        case {'lorentz','lorentzian'}
                            x.signal = x.intensityPara(1,:).*x.intensityPara(3,:)*2;
                    end
                case 2
                    switch lower(type)
                        case {'gauss','gaussian'}
                            x.signal = sum(x.intensityPara([1,4],:).*x.intensityPara([3,6],:)*sqrt(2*pi));
                        case {'lorentz','lorentzian'}
                            x.signal = sum(x.intensityPara([1,4],:).*x.intensityPara([3,6],:)*2);
                    end
            end
            
        end
        
        %% plotting
        
        function plotSigFit(x,what) %plot signal and fit
            
            errorbar(x.q,x.signal,x.signalError,x.signalError,'o','linewidth',1.2,'markersize',6);
            hold on;
            
            if nargin == 1
                plot(x.qFits.fits(1,:),x.qFits.fits(2,:),'linewidth',1.2,'markersize',6);
            elseif nargin == 2
                switch what
                    case 'd'
                        plot(x.para.d.fits(1,:),x.para.d.fits(2,:),'linewidth',2.4,'markersize',8);
                    case 's'
                        plot(x.para.s1.fits(1,:),x.para.s1.fits(2,:),'linewidth',2.4,'markersize',8);
                    case {'c','C'}
                        plot(x.para.C.fits(1,:),x.para.C.fits(2,:),'linewidth',2.4,'markersize',8);
                    otherwise
                        disp('parameter not found')
                end
            else
                disp('not found');
            end
            
            hold off;
            xlabel('Incidence Angle (Radian)');
            ylabel('Intensity (a.u.)');
            legend('Data','Fit');
            set(gca,'xlim',[0.016 0.032],'xtick',[0.0016 0.002 0.0024 0.0028 0.0032]);
        end
        
        function plotChi2(x,what) %plot Chi2
            switch(what)
                case 'density'
                    plot(x.qFits.s1vFits.fittingRange,x.qFits.densityFits.chi2,'lineWidth',1.2);
                    xlabel('Density (g/mL)','fontsize',14);
                case 's1v'
                    plot(x.qFits.s1vFits.fittingRange,x.qFits.s1vFits.chi2,'lineWidth',1.2);
                    xlabel('s1v (mm)','fontsize',14);
                case 'scaleFactor'
                    plot(x.qFits.s1vFits.fittingRange,x.qFits.scaleFactorFits.chi2,'lineWidth',1.2);
                    xlabel('Scale Factor','fontsize',14);
                otherwise
                    error('%s %s','cannot find the case: ','what');
            end
            ylabel('\Chi^2','fontsize',14);
        end
        
        %% utility
        
        function readScanBody(x,body) %read and save data to x
            
            [m,n] = size(body);
            
            %find where counts start
            d = 1;
            while (length(body{d,1}) < 2 || ~strcmpi(body{d,1}(1:2),'@a')) && d <= m
                d = d+1;
            end
            
            %scalar info
            for i = 1:d-1
                line = body{i,1};
                switch lower(line(1:2))
                    case '#d'
                        x.time = line(4:end);
                    case '#e'
                        C = textscan(line,'%s %s');
                        x.E = str2double(C{2});
                    case '#@'
                        if strcmpi(line(1:5),'#@cal')
                            C = textscan(line,'%s %f %f %f');
                            x.calibration = [C{2},C{3},C{4}];
                        end
                end
            end
            
            %row number
            countBlock = body(d:end,1);
            x.rowNumber = length(countsVector(countBlock));
            
            %vector info
            x.T = zeros(1,n);
            x.q = x.T;
            x.influx = x.T;
            x.countTime = x.T;
            x.counts = zeros(x.rowNumber,n);
            for i = 1:n
                for j = 1:d-1
                    line = body{j,i};
                    switch lower(line(1:2))
                        case '#t'
                            C = textscan(line,'%s %f %s');
                            x.T(i) = C{2};
                        case '#q'
                            C = textscan(line,'%s %f %f %f');
                            x.q(i) = C{end};
                        case '#m'
                            if strcmpi(line(1:5),'#monc')
                                C = textscan(line,'%s %f %f');
                                x.influx(i) = C{2};
                            end
                        case '#@'
                            if strcmpi(line(1:5),'#@cti')
                                C = textscan(line,'%s %f %f %f');
                                x.countTime(i) = C{end};
                            end
                    end
                end
                x.counts(:,i) = countsVector(body(d:end,i));
            end
            
        end
        
        function readScanBodyInSpec(x,body) %read the scan body in spec file
            
            p1 = 0; %position of sx
            p2 = 0; %position of slit size
            p3 = 0; %position of absorber
            n = 0; %number of parameters found
            i = 1;
            while n < 3 && i < length(body)                
                C = textscan(body{i},'%s %*[^\n]');
                marker = C{1}{1};
                switch lower(marker)
                    case '#p2'
                        p1 = i+1;
                        n = n+1;
                    case '#p3'
                        p2 = i+1;
                        n = n+1;
                    case '#a'
                        p3 = i;
                        n = n+1;
                end
                i = i+1;
            end
            
            C = textscan(body{p1},'%s %f %f %*[^\n]');
            x.sx = C{3};
            
            C = textscan(body{p2},'%s %f %f %f %f %f %f %*[^\n]');
            x.s1 = [C{4},C{5},C{6},C{7}];
            
            C = textscan(body{p3},'%s %s %f %*[^\n]');
            x.absorber = C{3};
            
        end
        
        function calculateIntensity(x) %calculate spectral intensity
            
            x.intensity = x.counts.*repmat(x.A./x.influx.*x.T./x.countTime,x.rowNumber,1);
            x.intensityError = x.countsError.*repmat(x.A./x.influx.*x.T./x.countTime,x.rowNumber,1);
            
        end
                
    end
    
end