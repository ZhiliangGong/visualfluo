function VisualFluo
%XeRay GUI for analyzing near total reflection x-ray fluorescence data for
%   all types of elements. Pre-constructured data reading routine is built
%   in for Sector 15 of APS, while other data formats need to be imported.

%% handle and shared data

%detect screen size
set(0,'units','pixels');
pix = get(0,'screensize');
if pix(4)*0.85 > 800
    height = 800;
else
    height = pix(4)*0.85;
end

handles = figure('Visible','off','Name','on','NumberTitle','off','Units','pixels',...
    'Position',[190,15,1200,height],'Resize','on');

info = {}; %stores all the necessary information
elementList = {}; %stores x-ray properties of different elements
x = {}; %stores all the data;
colors = {};
symbols = {};
initializeInfo;

%% file panel
specPanel = uipanel(handles,'Title','File','Units','normalized',...
    'Position',[0.014 0.88 0.16 0.11]);

beamLine = uicontrol(specPanel,'Style','popupmenu','String',...
    info.beamline,'Units','normalized',...
    'Position',[0.05 0.77 0.915 0.16]);

uicontrol(specPanel,'Style','pushbutton','String','Load','Units','normalized',...
    'Position',[0.08 0.32 0.25 0.32],'CallBack',@specButton_Callback);

specInput = uicontrol(specPanel,'Style','edit','Enable','inactive','Units','normalized',...
    'Position',[0.35 0.36 0.59 0.25]);

uicontrol(specPanel,'Style','pushbutton','String','Refresh','Units','normalized',...
    'Position',[0.67 0.02 0.27 0.32],'CallBack',@refreshButton_Callback);

%% data list panel
listPanel = uipanel(handles,'Title','Data','Units','normalized',...
    'Position',[0.014 0.02 0.16 0.85]);
uicontrol(listPanel,'Style','text','String','Select one or more scans','Units','normalized',...
    'Position',[0.05 0.87 0.8 0.12]);
scanList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
    'Position',[0.05 0.5 0.9 0.46],'Max',2,'CallBack',@scanList_Callback);
uicontrol(listPanel,'Style','text','String','Select the Qz range','Units','normalized',...
    'Position',[0.05 0.37 0.8 0.12]);
qzList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
    'Position',[0.05 0.015 0.9 0.44],'Max',2,'CallBack',@qzList_Callback);

%% upper plot
ax1 = axes('Parent',handles,'Units','normalized','Position',[0.215 0.52 0.45 0.44]);
ax1.XLim = [0 10];
ax1.YLim = [0 10];
ax1.XTick = [0 2 4 6 8 10];
ax1.YTick = [0 2 4 6 8 10];
ax1.XLabel.String = 'x1';
ax1.YLabel.String = 'y1';

plot1Type = uicontrol(handles,'Style','popupmenu','String',info.plot1Choices,...
    'Units','normalized',...
    'Position',[0.522 0.97 0.15 0.018],'CallBack',@plot1Type_Callback);

%% lower plot
ax2 = axes('Parent',handles,'Units','normalized','Position',[0.215 0.08 0.45 0.35]);
ax2.XLim = [0 10];
ax2.YLim = [0 10];
ax2.XTick = [0 2 4 6 8 10];
ax2.YTick = [0 2 4 6 8 10];
ax2.XLabel.String = 'x2';
ax2.YLabel.String = 'y2';

plot2Type = uicontrol(handles,'Style','popupmenu','String',info.plot2Choices,...
    'Units','normalized',...
    'Position',[0.522 0.44 0.15 0.018],'CallBack',@plot2Type_Callback);

%% before the output

rightPanel = uipanel(handles,'Units','normalized','Position',[0.68 0.02 0.31 0.97]);

elementPopup = uicontrol(rightPanel,'Style','popupmenu','String',{'Choose Element...'},'Units','normalized',...
    'Position',[0.015 0.97 0.46 0.018],'CallBack',@elementPopup_Callback);
curveType = uicontrol(rightPanel,'Style','popupmenu','String',info.curveTypes,'Units','normalized',...
    'Position',[0.49 0.97 0.46 0.018],'CallBack',@curveType_Callback);

background = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Subtract Background','Units','normalized',...
    'Position',[0.025 0.93 0.45 0.022],'CallBack',@background_Callback);
integrate = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Integrate','Units','normalized',...
    'Position',[0.5 0.93 0.45 0.022],'CallBack',@integrate_Callback);

uicontrol(rightPanel,'Style','text','String','Scaling x:','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.03 0.9 0.35 0.022]);
scaleFactor = uicontrol(rightPanel,'Style','edit','String','1e6','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.24 0.901 0.5 0.022],'CallBack',@scaleFactor_Callback);

uicontrol(rightPanel,'Style','text','String','Energy (keV) = ','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.03 0.87 0.2 0.022]);
calibration1 = uicontrol(rightPanel,'Style','edit','String','','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.24 0.871 0.13 0.022],'CallBack',@adjustCalibration);
uicontrol(rightPanel,'Style','text','String','+','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.37 0.87 0.02 0.022]);
calibration2 = uicontrol(rightPanel,'Style','edit','String','','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.39 0.871 0.13 0.022],'CallBack',@adjustCalibration);
uicontrol(rightPanel,'Style','text','String','x Chnl# + ','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.52 0.87 0.13 0.022]);
calibration3 = uicontrol(rightPanel,'Style','edit','String','','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.65 0.871 0.13 0.022],'CallBack',@adjustCalibration);
uicontrol(rightPanel,'Style','text','String','x Chnl#^2','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.78 0.87 0.15 0.022]);

%% output
output = uicontrol(rightPanel,'Style','edit','Max',2,'HorizontalAlignment','left','Units','normalized',...
    'Position',[0.03 0.07 0.935 0.79]);

uicontrol(rightPanel,'Style','pushbutton','String','Clear Output','Units','normalized',...
    'Position',[0.022 0.04 0.21 0.03],'CallBack',@clearButton_Callback);

uicontrol(rightPanel,'Style','pushbutton','String','Save Output Text','Units','normalized',...
    'Position',[0.24 0.04 0.27 0.03],'CallBack',@saveText_Callback);

uicontrol(rightPanel,'Style','text','String','Save:','HorizontalAlignment','left','Units','normalized',...
    'Position',[0.03 0.01 0.1 0.022]);

%% save buttons
uicontrol(rightPanel,'Style','pushbutton','String','Figure 1','Units','normalized',...
    'Position',[0.12 0.008 0.15 0.03],'CallBack',@saveFig1_Callback);
uicontrol(rightPanel,'Style','pushbutton','String','Figure 2','Units','normalized',...
    'Position',[0.28 0.008 0.15 0.03],'CallBack',@saveFig2_Callback);
uicontrol(rightPanel,'Style','pushbutton','String','Workspace','Units','normalized',...
    'Position',[0.44 0.008 0.17 0.03],'CallBack',@saveDataset_Callback);
uicontrol(rightPanel,'Style','pushbutton','String','Export Selected Data','Units','normalized',...
    'Position',[0.62 0.008 0.32 0.03],'CallBack',@exportData_Callback);

%% opening function

initializeVisualFluo;

%% callback functions

    function specButton_Callback(source,eventdata) %load spec file and try to load data
    %loading the spec files, and load all the data needed for subsequent
    %manipulations
    
        switch beamLine.String{beamLine.Value}
            case info.beamline{1}
                [specFile, specPath] = uigetfile('*','Select the spec file');
                try initialDataLoad(specPath,specFile)
                catch
                    warndlg('Was not able to load data.');
                end
        end
        
    end

    function refreshButton_Callback(source,eventdata) %refresh data without losing current work
        
        if ~isempty(x)
            
            oldScanNumbers = getScanNumbers(info.scanFiles);
            
            scanFiles = getScanFilesAt(info.scanPath,info.specFile);
            newScanNumbers = getScanNumbers(scanFiles);
            
            if length(newScanNumbers) > length(oldScanNumbers)
                scanFiles = scanFiles(length(oldScanNumbers)+1:end);
                A = str2double(scaleFactor.String);
                y = importData(info.specFile,info.specPath,scanFiles,info.scanPath,A);
                
                %combine the newly added data with the old data set
                info.scanFiles = {info.scanFiles{1:end},scanFiles{1:end}};
                x = {x{1:end},y{1:end}};
                scanList.String = info.scanFiles;
            end
            
        end
        
    end

    function scanList_Callback(source,eventdata)
        
        displayQz;
        VisualFluoPlot;
        displayScanInfo;
        
    end

    function qzList_Callback(source,eventdata)
        
        VisualFluoPlot;
        
    end

    function plot1Type_Callback(source,eventdata)
        
        upperPlot;
        
    end

    function plot2Type_Callback(source,eventdata) %respond to plot2Type popup menu
        
        lowerPlot;
        
    end

    function elementPopup_Callback(source,eventdata) %fits the selected data range to the element
                
        switch elementPopup.Value
            case 1
                info.element = 'none';
                switchElementFeatures('off');
                VisualFluoPlot;
            case length(elementPopup.String)
                addElement;
            otherwise
                info.element = elementPopup.String{elementPopup.Value};
                fitElement;
                switchElementFeatures('on');
                VisualFluoPlot;
        end
        
    end

    function curveType_Callback(source,eventdata) %fits the selected data range to the element
        
        fitElement;
        VisualFluoPlot;
        
    end

    function background_Callback(source,eventdata) %subtract the background of spectra
        
        upperPlot;
        
    end

    function integrate_Callback(source,eventdata) %subtract the background of spectra
        
        lowerPlot;
        
    end

    function adjustCalibration(source,eventdata) %change calibration
        
        calibration = [str2double(calibration1.String),str2double(calibration2.String),str2double(calibration3.String)];
        for i = scanList.Value(1):length(x)
            x{i}.calibration = calibration;
            adjustEnergyCalibration(x{i});
        end
        displayScanInfo;
        upperPlot;
        lowerPlot;
        
    end

    function scaleFactor_Callback(source,eventdata) %change the scale factor for the normalized data
        
        A = str2double(scaleFactor.String);
        for i = 1:length(x)
            adjustScaleFactor(x{i},A);
        end
        %displayScanInfo;
        upperPlot;
        lowerPlot;
        
    end

    function clearButton_Callback(source,eventdata) %clear the output
        
        output.String = {};
        
    end

%% saving functions

    function saveDataset_Callback(source,eventdata) %save the current data to workspace
        
        VisualFluoDataSet = x;
        save('VisualFluoDataSet','VisualFluoDataSet');
        clear VisualFluoDataSet;
        
    end

    function saveFig1_Callback(source,eventdata) %save figure one
        
        theFigure = figure;
        copyobj(ax1,theFigure);
        ax = gca;
        ax.Units = 'normalized';
        ax.Position = [.13 .11 .775 .815];
        hgsave(theFigure,'VisualFluo upper figure');
        
    end

    function saveFig2_Callback(source,eventdata) %save figure one
        
        theFigure = figure;
        copyobj(ax2,theFigure);
        ax = gca;
        ax.Units = 'normalized';
        ax.Position = [.13 .11 .775 .815];
        hgsave(theFigure,'VisualFluo lower figure');
        
    end

    function saveText_Callback(source,eventdata) %save text output
        
        [fileName,path] = uiputfile('VisualFluoOutput.txt','Save output text as');
        file = fullfile(path,fileName);
        text = output.String;
        fid = fopen(file,'a');
        fprintf(fid,strcat(datestr(datetime),'\n'));
        for i = 1:length(text)
            fprintf(fid, strcat(text{i},'\n'));
        end
        fprintf(fid,'\n');
        fclose(fid);
        
    end

    function exportData_Callback(source,eventdata) %save export selected data
        
        for i = 1:length(scanList.Value)
            y = x{scanList.Value(i)};
            scanString = num2str(y.scanNumber);
            string1 = strcat('Scan #',scanString,'.xfluo');
            string2 = sprintf('%s %s %s','Save scan #',scanString,'as');
            [fileName,path] = uiputfile(string1,string2);
            fspecFile = fullfile(path,fileName);
            
            angle = repmat(y.q(qzList.Value),2,1) * y.wavelength / 4 / pi;
            angle = reshape(angle,1,numel(angle));
            line1 = sprintf('%s %s','E(keV)\\Angle',num2str(angle));
            data = zeros(length(y.e),length(qzList.Value)*2);
            data(:,1:2:end) = y.intensity(:,qzList.Value);
            data(:,2:2:end) = y.intensityError(:,qzList.Value);
            dataMatrix = [y.e,data];
            
            try
                fid = fopen(fspecFile,'w');
                fprintf(fid,line1);
                fprintf(fid,'\n');
                dlmwrite(fspecFile,dataMatrix,'delimiter','\t','precision','%.6f','-append');
                fclose(fid);
            catch
                warning('Did not save data.');
            end
            
        end
        
    end

%% functions that make changes to the UI

    function initializeVisualFluo %initialize specfile and mca files
        
        handles.Name = 'VisualFluo';
        movegui(handles,'center')
        handles.Visible = 'on';        
        switchGui('off'); %make gui content invisible while preparing
        
        initializeInfo; %load all the initial information
        elementPopup.String = elementList;
        
        switch beamLine.String{beamLine.Value}
            
            case info.beamline{1}
                initialDataLoad(pwd);
            otherwise                
                error('Beamline not found.');                
        end
        
    end

    function VisualFluoPlot %master plot function
        
        getLineSpecAndLegend; %obtain line spec and legens for both plots
        upperPlot;
        lowerPlot;
        
    end

    function upperPlot %plot in the upper figure
        
        switch info.integrate
            case 0
                plotSpectra(ax1);
            case 1
                plotSignal(ax1);
        end
        
        normalizeXLim;
        
    end

    function lowerPlot %plot in the lower figure
        
        switch integrate.Value
            case 0
                plot2Type.Enable = 'on';
                plotParameter(ax2);
            case 1
                plot2Type.Enable = 'off';
                plotSignal(ax2);
        end
        normalizeXLim;
        
    end

    function displayQz %displays Qz in the qz list
        
        n = zeros(1,length(scanList.Value));
        for i = 1:length(scanList.Value)
            n(i) = length(x{scanList.Value(i)}.q);
        end
        ind = find(min(n)==n,1);
        qzList.String = num2cell(x{scanList.Value(ind)}.q);
        if length(qzList.String) < max(qzList.Value)
            qzList.Value = 1;
        end
        
    end

    function switchGui(status) %gray out the GUI or not
       
        set(findall(listPanel,'-property','Enable'),'Enable',status);
        set(findall(rightPanel,'-property','Enable'),'Enable',status);
        plot1Type.Enable = status;
        plot2Type.Enable = status;
        
    end

    function switchElementFeatures(status) %switch on the background subtraction and start fitting
        
        background.Enable = status;
        integrate.Enable = status;
        
    end

    function normalizeXLim %ensure the two x-axis conform to each other
        
        if strcmpi(ax1.XLabel.String,ax2.XLabel.String)
            newxlim = [min(ax1.XLim(1),ax2.XLim(1)),max(ax1.XLim(2),ax2.XLim(2))];
            set(ax1,'xlim',newxlim);
            set(ax2,'xlim',newxlim);            
        end
        
    end

    function displayScanInfo %display the important information
        
        %the text box
        oldText = output.String;
        
        outputText = cell(5,1);
        outputText{1} = '';
        outputText{2} = sprintf('%s %s','Spec file location:',x{scanList.Value(1)}.specPath);
        outputText{3} = sprintf('%s %s','Time of experiment:',x{scanList.Value(1)}.time);
        outputText{4} = sprintf('%s %s','Beam energy:',num2str(x{scanList.Value(1)}.E));
        
        theVector = zeros(1,length(scanList.Value));
        scanNumber = theVector;
        k = 1;
        for i = scanList.Value
            scanNumber(k) = x{i}.scanNumber;
            k = k+1;
        end
        outputText{5} = sprintf('%s %s','Scan number:',num2str(scanNumber));
        
        outputText = [oldText;outputText];
        output.String = outputText;
        
        %the input boxes
        scaleFactor.String = num2str(x{scanList.Value(1)}.A);
        calibration1.String = num2str(x{scanList.Value(1)}.calibration(1));
        calibration2.String = num2str(x{scanList.Value(1)}.calibration(2));
        calibration3.String = num2str(x{scanList.Value(1)}.calibration(3));
        
    end

%% data import

    function initializeInfo %initialize the starting parameters
        
        info.beamline = {'Beamline: APS 15ID','other'};
        info.specFile = '';
        info.specPath = '';
        info.scanFiles = {};
        info.scanPath = {};
        
        info.integrate = 0;
        info.element = 'none';
        
        info.curveTypes = {'Gaussian','Lorentzian'};
        info.plot1Choices = {'Counts','Counts with error','Intensity','Intensity with error'};
        info.plot2Choices = {'Influx','Count time','Live ratio','Absorber','Footprint','Slit height','Slit width','Beam position'};
        info.plot1Legend = {};
        info.plot2Legend = {};
        info.spec1 = {};
        info.spec2 = {};

        x = {}; %all the data
        
        fid = fopen(which('colorsAndSymbols.txt'));
        if fid
            text = textscan(fid,'%s %s',2);
            colors = text{2}{1};
            symbols = text{2}{2};
            fclose(fid);
        else
            colors = 'kbrgcmy';
            symbols = 'o^vsd><ph+*x.';
        end
        
        loadElementList; %cell array of element names
        
    end

    function initialDataLoad(specPath,specFile)
        
        if nargin == 1
            specFile = getSpecFileAt(specPath);
        end
        
        if loadDataAt(specPath,specFile)
            specInput.String = info.specFile;
            scanList.String = info.scanFiles;
            scanList.Value = 1;
            displayQz;
            displayScanInfo;
            VisualFluoPlot;
            switchGui('on');
            switchElementFeatures('off');
        end
        
    end
    
    function specFile = getSpecFileAt(thePath) %look for a spec file the path
        %return '' if no spec file found
        
        dirStruct = dir(thePath);
        [sortedNames,sortedIndex] = sortrows({dirStruct.name}');
        expression = '[12]\d\d\d[01][012][0123]\d';

        specFile = '';
        for i = 1:length(sortedIndex)
            if length(sortedNames{i}) == 8 && ~isempty(regexp(sortedNames{i},expression,'once'))
                specFile = sortedNames{i};
                break;
            end
        end
                
    end
    
    function scanFiles = getScanFilesAt(scanPath, specFile) %If no scan files found, return an empty cell array
        %returned scan files would be sorted
        
        % this file stores the format of spec file and scan files
        try
            expression = getExpressionOf('scan');
        catch
            expression = '[12]\d\d\d[01][012][0123]\d_(\d+)_mca';
        end
        
        dirStruct = dir(scanPath);
        [sortedNames,sortedIndex] = sortrows({dirStruct.name}');
        
        m = 0; %number of scan names
        for n = 1:length(sortedIndex)
            if ~isempty(regexp(sortedNames{n},expression,'once'))
                if ~isempty(regexp(sortedNames{n},specFile,'once'))
                    m = m+1;
                    sortedNames{m} = sortedNames{n};
                end
            end
        end
        
        if m > 1
            scanFiles = sortedNames(1:m);
            scanNumbers = getScanNumbers(scanFiles);
            [~,I] = sort(scanNumbers);
            scanFiles = scanFiles(I);
        else
            scanFiles = {};
        end

    end

    function flag = loadDataAt(thePath,specFile) %try to load data, returns 0 if not successufl, 1 if successful
        %searches for scan data files in thePath and 'vortex' folder
        
        flag = 0;
        if nargin == 1
            specFile = getSpecFileAt(thePath);
        end
        if ~isempty(specFile)
            specPath = thePath;
            scanPath = thePath;
            scanFiles = getScanFilesAt(specPath,specFile);
            if isempty(scanFiles)
                newPath = fullfile(specPath,'vortex');
                scanFiles = getScanFilesAt(newPath,specFile);
                scanPath = newPath;
            end
            
            %if found both spec files and scan files, try importing data
            if ~isempty(scanFiles)
                A = str2double(scaleFactor.String);
                try
                    x = importData(specFile,specPath,scanFiles,scanPath,A);
                    info.specFile = specFile;
                    info.specPath = specPath;
                    info.scanFiles = scanFiles;
                    info.scanPath = scanPath;
                    flag = 1;
                catch
                    warning('Was not able to import data.');
                end
            end
        end
        
    end

    function y = importData(specFile,specPath,scanFiles,scanPath,A) %return a cell array
        
        scanNumbers = getScanNumbers(scanFiles);
        
        y = cell(1,length(scanNumbers));
        for n = 1:length(scanNumbers)
            y{n} = VisualFluoData(specFile,specPath,scanFiles{n},scanPath,scanNumbers(n),A);
        end

    end

%% plot

    function plotParameter(ax) %plot the chosen parameter against qz
    
        switch plot2Type.String{plot2Type.Value}
            case info.plot2Choices{1}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.influx(qzList.Value),info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Qz');
                    ylabel(ax,'Influx Counts');
                    title(ax,'Influx - Qz Relation');
                    hold(ax,'on');
                end
            case info.plot2Choices{2}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.T(qzList.Value),info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Qz');
                    ylabel(ax,'Count Time');
                    title(ax,'Count Time - Qz Relation');
                    hold(ax,'on');
                end
            case info.plot2Choices{3}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.countTime(qzList.Value)./x{scanList.Value(i)}.T(qzList.Value),info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Qz');
                    ylabel(ax,'Detector Live Ratio');
                    title(ax,'Detector Live Ratio - Qz Relation');
                    hold(ax,'on');
                end
            case info.plot2Choices{4}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.absorber,info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Qz');
                    ylabel(ax,'Absorber');
                    title(ax,'Absorber');
                    hold(ax,'on');
                end             
            case info.plot2Choices{5}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.scanNumber,sum(x{scanList.Value(i)}.sx),info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Scan Number');
                    ylabel(ax,'Detector Footprint (mm)');
                    title(ax,'Detector Footprint');
                    hold(ax,'on');
                end
            case info.plot2Choices{6}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.scanNumber,sum(x{scanList.Value(i)}.s1(1:2)),info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Scan Number');
                    ylabel(ax,'Slit height (mm)');
                    title(ax,'Slit height');
                    hold(ax,'on');
                end
            case info.plot2Choices{7}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.scanNumber,sum(x{scanList.Value(i)}.s1(3:4)),info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Scan Number');
                    ylabel(ax,'Slit width (mm)');
                    title(ax,'Slit width');
                end
            case info.plot2Choices{8}
                for i = 1:length(scanList.Value)
                    plot(ax,x{scanList.Value(i)}.scanNumber,x{scanList.Value(i)}.sx,info.spec2{i},'markersize',8,'linewidth',2);
                    xlabel(ax,'Scan Number');
                    ylabel(ax,'Beam position (mm)');
                    title(ax,'Beam position (sx)');
                    hold(ax,'on');
                end
            otherwise
                error('type of plot not found for lower figure');                    
        end
        legend(info.plot2Legend);
        hold(ax,'off');
        
    end

    function plotSpectra(ax) %plot spectra
        
        switch plot1Type.String{plot1Type.Value}
            case info.plot1Choices{1} %counts
                k = 1;
                for i = scanList.Value                    
                    for j = qzList.Value
                        switch lower(elementPopup.String{elementPopup.Value})
                            case {'choose element...','choose element','choose'}
                                plot(ax,x{i}.e,x{i}.counts(:,j),info.spec1{k});
                            otherwise
                                switch background.Value
                                    case 0
                                        plot(ax,x{i}.xe,x{i}.xCounts(:,j),info.spec1{k});
                                    case 1
                                        plot(ax,x{i}.xe,x{i}.netCounts(:,j),info.spec1{k});
                                    otherwise
                                        error('there should only be two choices: with and without background');
                                end                                
                        end
                        hold(ax,'on');
                        k = k+1;
                    end
                end
            case info.plot1Choices{2} %counts with error
                k = 1;
                for i = scanList.Value                    
                    for j = qzList.Value
                        switch lower(elementPopup.String{elementPopup.Value})
                            case {'choose element...','choose element','choose'}
                                errorbar(ax,x{i}.e,x{i}.counts(:,j),x{i}.countsError(:,j),x{i}.countsError(:,j),info.spec1{k});
                            otherwise
                                switch background.Value
                                    case 0
                                        errorbar(ax,x{i}.xe,x{i}.xCounts(:,j),x{i}.xCountsError(:,j),x{i}.xCountsError(:,j),info.spec1{k});
                                    case 1
                                        errorbar(ax,x{i}.xe,x{i}.netCounts(:,j),x{i}.xCountsError(:,j),x{i}.xCountsError(:,j),info.spec1{k});
                                    otherwise
                                        error('there should only be two choices: with and without background');
                                end
                        end
                        hold(ax,'on');
                        k = k+1;
                    end
                end
            case info.plot1Choices{3} %normalized
                k = 1;
                for i = scanList.Value                    
                    for j = qzList.Value
                        switch lower(elementPopup.String{elementPopup.Value})
                            case {'choose element...','choose element','choose'}
                                plot(ax,x{i}.e,x{i}.intensity(:,j),info.spec1{k});
                            otherwise
                                switch background.Value
                                    case 0
                                        plot(ax,x{i}.xe,x{i}.xIntensity(:,j),info.spec1{k});
                                    case 1
                                        plot(ax,x{i}.xe,x{i}.netIntensity(:,j),info.spec1{k});
                                    otherwise
                                        error('there should only be two choices: with and without background');
                                end                                
                        end
                        hold(ax,'on');
                        k = k+1;
                    end
                end
            case info.plot1Choices{4} %normalized with error
                k = 1;
                for i = scanList.Value                    
                    for j = qzList.Value
                        switch lower(elementPopup.String{elementPopup.Value})
                            case {'choose element...','choose element','choose'}
                                errorbar(ax,x{i}.e,x{i}.intensity(:,j),x{i}.intensityError(:,j),x{i}.intensityError(:,j),info.spec1{k});
                            otherwise
                                switch background.Value
                                    case 0
                                        errorbar(ax,x{i}.xe,x{i}.xIntensity(:,j),x{i}.xIntensityError(:,j),x{i}.xIntensityError(:,j),info.spec1{k});
                                    case 1
                                        errorbar(ax,x{i}.xe,x{i}.netIntensity(:,j),x{i}.xIntensityError(:,j),x{i}.xIntensityError(:,j),info.spec1{k});
                                    otherwise
                                        error('there should only be two choices: with and without background');
                                end                                
                        end
                        hold(ax,'on');
                        k = k+1;
                    end
                end
            otherwise
                error('upper plot type not found');
        end
        
        legend(ax, info.plot1Legend);
        xlabel(ax, 'Energy (keV)');
        ylabel(ax, 'Signal');
        switch lower(elementPopup.String{elementPopup.Value})
            case {'choose element...','choose element','choose'}
                set(ax, 'xlim',[min(x{scanList.Value(1)}.e) max(x{scanList.Value(1)}.e)]);
                titleText = sprintf('%s %s','Whole Spec -',plot1Type.String{plot1Type.Value});
            otherwise
                titleText = sprintf('%s %s %s',info.element,'-',plot1Type.String{plot1Type.Value});
                switch plot1Type.String{plot1Type.Value}
                    case {info.plot1Choices{1},info.plot1Choices{2}}
                        k = 1;
                        for i = scanList.Value
                            for j = qzList.Value
                                color = info.spec1{k}(1);
                                switch background.Value
                                    case 0
                                        plot(ax,x{i}.fitE,x{i}.countFit(:,j),color);
                                    case 1
                                        plot(ax,x{i}.fitE,x{i}.netCountFit(:,j),color);
                                    otherwise
                                end                    
                                k = k+1;
                            end
                        end
                    case {info.plot1Choices{3},info.plot1Choices{4}}
                        k = 1;
                        for i = scanList.Value
                            for j = qzList.Value
                                color = info.spec1{k}(1);
                                switch background.Value
                                    case 0
                                        plot(ax,x{i}.fitE,x{i}.intensityFit(:,j),color);
                                    case 1
                                        plot(ax,x{i}.fitE,x{i}.netIntensityFit(:,j),color);
                                    otherwise
                                end                    
                                k = k+1;
                            end
                        end
                end
        end
        title(ax,titleText);
        
        hold(ax,'off');

    end

    function plotSignal(ax) %plot the integrated signal for a given element
        
        for i = 1:length(scanList.Value)
            errorbar(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.signal(qzList.Value),...
                x{scanList.Value(i)}.signalError(qzList.Value),x{scanList.Value(i)}.signalError(qzList.Value),...
                info.spec2{i},'markersize',8,'linewidth',2);
            hold(ax,'on');
        end
        hold(ax,'off');
        xlabel(ax,'Qz');
        ylabel(ax,'Fluorescence Intensity (a.u.)');
        switch lower(curveType.String{curveType.Value})
            case {'gauss','gaussian'}
                titleText = sprintf('%s %s',info.element,'Integrated Intensity (Gaussian Fit)');
            case {'lorentz','lorentzian'}
                titleText = sprintf('%s %s',info.element,'Integrated Intensity (Lorentzian Fit)');
            otherwise
                titleText = sprintf('%s %s',info.element,'Integrated Intensity (unkown curve type)');
        end
        title(ax,titleText);
        legend(ax,info.plot2Legend);
        
    end

%% utility

    function expression = getExpressionOf(type) %get the reg expression of the name of the type of files
        %type can be 'scan', or 'spec'
                
        switch lower(type)            
            case {'scan','spec'}
                fid = fopen(fullfile(getParentDir(which('XeRay.m')),'fileFormat.txt'));
                if fid > 0
                    C = textscan(fid,'%s %s','CommentStyle','%');
                    fclose(fid);
                    for i = 1:size(C{1},1)
                        if strcmpi(C{1}{i},type)
                            expression = C{2}{i};
                            break;
                        end
                    end
                else
                    switch type
                        case 'scan'
                            expression = '[12]\d\d\d[01][012][0123]\d_(\d+)_mca';
                        case 'spec'
                            expression = 'spec [12]\d\d\d[01][012][0123]\d';
                    end
                end
            otherwise
                error('type not found');            
        end
        
    end
    
    function parentDir = getParentDir(currentDir) %return the parent directory
        
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

    function scanNumbers = getScanNumbers(scanFiles) %obtain scan numbers in a vector
        
        scanNumbers = zeros(1,length(scanFiles));
        for n = 1:length(scanNumbers)
            index = regexp(scanFiles{n},'_');
            scanNumbers(n) = str2double(scanFiles{n}(index(1)+1:index(2)-1));
        end
        
    end

    function fitElement %fit the chosen element
        
        for i = 1:length(x)
            xFit(x{i},info.element,curveType.String{curveType.Value});
        end
        
    end

    function loadElementList %read the elements
        
        fid = fopen(which('elementEnergy.txt'));
        if fid
            text = textread(which('elementEnergy.txt'),'%s','delimiter','\n');
            [string,~]=stringArrayCat('',text);
            elementList = cell(1,sum(string=='#')+2);
            elementList{1} = 'Choose element...';
            j = 2;
            for i = 1:length(text)
                if strcmp(text{i}(1),'#')
                    elementList{j} = text{i}(2:end);
                    j = j+1;
                end
            end
            elementList{end} = 'Add element...';
        end
        fclose(fid);
        
    end

    function getLineSpecAndLegend %obtain line spec and legends for both plots
        
        %obtain line spec for plotting, and legends
        info.spec1 = cell(length(qzList.Value),length(scanList.Value));
        info.spec2 = cell(1,length(scanList.Value));
        info.plot1Legend = info.spec1;
        info.plot2Legend = info.spec2;
        
        for i = 1:length(qzList.Value)
            n = mod(i,length(colors));
            if n == 0
                n = length(colors);
            end
            color = colors(n);
            for j = 1:length(scanList.Value)
                m = mod(j,length(symbols));
                if m == 0
                    m = length(symbols);
                end
                symbol = symbols(m);
                info.spec1{i,j} = strcat(color,symbol);
                info.plot1Legend{i,j} = strcat('Scan #',num2str(x{scanList.Value(j)}.scanNumber),' Qz = ',num2str(x{scanList.Value(j)}.q(qzList.Value(i)),'%.3g'));
                if i == 1
                    info.spec2{j} = strcat('k',symbol);
                    info.plot2Legend{j} = strcat('Scan #',num2str(x{scanList.Value(j)}.scanNumber));
                end
            end
        end
        
        info.spec1 = reshape(info.spec1,1,numel(info.spec1));
        info.plot1Legend = reshape(info.plot1Legend,1,numel(info.plot1Legend));
        
    end

    function addElement
        
        try
            prompt = {'Element abbreviation: ','Peak(s) in keV, up to 2, separate by space: ','Peak widths in keV, optional','Lower bound energy in keV: ','Upper bound energy in keV: '};
            answer = inputdlg(prompt,'Add new element',1,{'Zn','8.64','','8.4','8.95'});
            file = which('elementEnergy.txt');
            flag = 1;

            name = answer{1};
            name(1) = upper(name(1));
            for i = 2:length(elementList)-1
                if strcmpi(name,elementList{i})
                    flag = 0;
                    warndlg(sprintf('%s %s','Element already exist in file:',file));
                    break;
                end
            end

            abbr = ' H He Li Be B C N O F Ne Na Mg Al Si P S Cl Ar K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn Fr Ra Ac Th Pa U';
            if ~regexp(abbr,name,'once')
                flag = 0;
                warndlg(sprintf('%s %s',name,'is not a valid element.'));
            end

            peak = str2num(answer{2});
            width = str2num(answer{3});
            lb = str2double(answer{4});
            ub = str2double(answer{5});

            if max(peak) > ub || min(peak) < lb
                flag = 0;
                warndlg('The upper bound should be larger than the peaks, and the lower bound should be smaller than the peaks.');
            end

            newtext = cell(3,1);
            if flag
                newtext{1} = ['#',name];
                newtext{2} = ['energies ',num2str([lb,peak,ub])];
                newtext{3} = ['peakHalfWidth ',num2str(width)];

                fid = fopen(file,'a');
                fprintf(fid,'\n');
                for i = 1:3
                    fprintf(fid,'%s\n',newtext{i});
                end
                fclose(fid);
            end
            loadElementList;
            elementPopup.String = elementList;
            elementPopup.Value = 1;
        catch
        end
        
    end

end