classdef VisualFluo < handle
    
    properties
        
        data
        gui
        
        guiFigure
        
        config
        
        ElementProfiles
        
    end
    
    methods
        
        function this = VisualFluo()
            
            initializeGui();
            
            function initializeGui()
                
                configFile = which('visualfluo.config.json');
                this.config = loadjson(configFile);
                this.ElementProfiles = loadjson(fullfile(getParentDir(which('VisualFluo.m')), 'support-files/element-profiles.json'));
                
                createView();
                createController();
                
                this.control('initial-load');
                
            end
            
            function createView()
                
                createFigure();
                createBeamlinePanel();
                createDataListPanel();
                createPlot1();
                createPlot2();
                createMenus();
                createBasicInfoTable();
                createCalibrationTable();
                createOutputRegion();
                createSaveButtons();
                
                function createFigure()
                    
                   set(0,'units','pixels');
                   screenSize = get(0,'screensize');
                   if screenSize(4) * 0.85 > 800
                       height = 800;
                   else
                       height = screenSize(4) * 0.85;
                   end
                   
                   this.guiFigure = figure('Visible','off','Name','VisualFluo','NumberTitle','off','Units','pixels',...
                       'Position',[190,15,1200,height],'Resize','on');
                   
                   movegui(this.guiFigure, 'center');
                   
                   this.guiFigure.Visible = 'on';
                    
                end
                
                function createBeamlinePanel()
                    
                    this.gui.specPanel = uipanel(this.guiFigure,'Title','File','Units','normalized',...
                        'Position',[0.014 0.88 0.16 0.11]);
                    
                    specPanel = this.gui.specPanel;
                    
                    this.gui.beamlineMenu = uicontrol(specPanel, 'Style', 'popupmenu', 'String',...
                        this.config.beamLines, 'Units','normalized', 'Position',[0.05 0.77 0.915 0.16]);
                    
                    this.gui.loadButton = uicontrol(specPanel, 'Style', 'pushbutton', 'String','Load','Units','normalized',...
                        'Position',[0.08 0.32 0.25 0.32]);
                    
                    this.gui.specInput = uicontrol(specPanel,'Style','edit','Enable','inactive','Units','normalized',...
                        'Position',[0.35 0.36 0.59 0.25]);
                    
                    this.gui.refreshButton = uicontrol(specPanel,'Style','pushbutton','String','Refresh','Units','normalized',...
                        'Position',[0.67 0.02 0.27 0.32]);
                    
                end
                
                function createDataListPanel()
                    
                    this.gui.listPanel = uipanel(this.guiFigure,'Title','Data','Units','normalized',...
                        'Position',[0.014 0.02 0.16 0.85]);
                    
                    listPanel = this.gui.listPanel;
                    
                    this.gui.scanText = uicontrol(listPanel,'Style','text','String','Select one or more scans','Units','normalized',...
                        'Position',[0.05 0.87 0.8 0.12]);
                    
                    this.gui.scanList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
                        'Position',[0.05 0.5 0.9 0.46],'Max',2);
                    
                    this.gui.qzText = uicontrol(listPanel,'Style','text','String','Select the Qz range','Units','normalized',...
                        'Position',[0.05 0.37 0.8 0.12]);
                    
                    this.gui.qzList = uicontrol(listPanel,'Style','listbox','Units','normalized',...
                        'Position',[0.05 0.015 0.9 0.44],'Max',2);
                    
                end
                
                function createPlot1()
                    
                    ax1 = axes('Parent', this.guiFigure, 'Units','normalized','Position',[0.215 0.52 0.45 0.44]);
                    ax1.XLim = [0 10];
                    ax1.YLim = [0 10];
                    ax1.XTick = [0 2 4 6 8 10];
                    ax1.YTick = [0 2 4 6 8 10];
                    ax1.XLabel.String = 'x1';
                    ax1.YLabel.String = 'y1';
                    
                    this.gui.ax1 = ax1;
                    
                    this.gui.plot1Type = uicontrol(this.guiFigure,'Style','popupmenu','String', this.config.plot1Choices,...
                        'Units','normalized', 'Position',[0.522 0.97 0.15 0.018]);
                    
                end
                
                function createPlot2()
                    
                    ax2 = axes('Parent',this.guiFigure,'Units','normalized','Position',[0.215 0.08 0.45 0.35]);
                    ax2.XLim = [0 10];
                    ax2.YLim = [0 10];
                    ax2.XTick = [0 2 4 6 8 10];
                    ax2.YTick = [0 2 4 6 8 10];
                    ax2.XLabel.String = 'x2';
                    ax2.YLabel.String = 'y2';
                    
                    this.gui.ax2 = ax2;
                    
                    this.gui.plot2Type = uicontrol(this.guiFigure,'Style','popupmenu','String',this.config.plot2Choices,...
                        'Units','normalized', 'Position',[0.522 0.44 0.15 0.018]);
                    
                end
                
                function createMenus()
                    
                    this.gui.rightPanel = uipanel(this.guiFigure,'Units','normalized','Position',[0.68 0.02 0.31 0.97]);
                    
                    rightPanel = this.gui.rightPanel;
                    
                    this.gui.elementMenu = uicontrol(rightPanel,'Style','popupmenu','String',{'Choose Element...'},'Units','normalized',...
                        'Position',[0.015 0.97 0.46 0.018]);
                    
                    this.gui.lineShape = uicontrol(rightPanel,'Style','popupmenu','String', {'Gaussian','Lorentzian'},'Units','normalized',...
                        'Position',[0.49 0.97 0.46 0.018], 'Enable', 'off');
                    
                    this.gui.background = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Subtract Background','Units','normalized',...
                        'Position',[0.025 0.93 0.45 0.022]);
                    
                    this.gui.integrate = uicontrol(rightPanel,'Style','radiobutton','Enable','off','String','Integrate','Units','normalized',...
                        'Position',[0.5 0.93 0.45 0.022]);
                    
                end
                
                function createBasicInfoTable()
                    
                    rowName = {'Energy (keV)', 'Slit Height (mm)', 'Scaling (x)'};
                    colName = {};
                    columnFormat = {'numeric'};
                    columnWidth = {120};
                    basicInfoData = {0; 0; 1e6};
                    
                    this.gui.basicInfoTable = uitable(this.gui.rightPanel,'Data', basicInfoData,...
                        'ColumnFormat', columnFormat,'ColumnEditable', true, 'Units', 'normalized',...
                        'ColumnWidth',columnWidth,'ColumnName', colName, 'RowName',rowName,'RowStriping','off',...
                        'Position', [.03 .82 .9 .1]);
                    
                end
                
                function createCalibrationTable()
                    
                    this.gui.calibractionText = uicontrol(this.gui.rightPanel, 'Style', 'text',...
                        'String', 'Vortex Calibration', 'Units', 'normalized', 'Position', [0.03 0.795 0.9 0.02],...
                        'HorizontalAlignment', 'left');
                    
                    rowName = {'Constant', 'Linear Term', 'Quadratic Term', 'Cubic Term'};
                    colName = {};
                    columnFormat = {'numeric', 'numeric', 'numeric', 'numeric'};
                    columnWidth = {140};
                    tableData = {0; 0; 0; 0};
                    
                    this.gui.calibrationTable = uitable(this.gui.rightPanel, 'Data', tableData, ...
                        'ColumnName', colName, 'RowName', rowName, 'RowStriping', 'off', ...
                        'ColumnFormat', columnFormat, 'ColumnWidth', columnWidth, 'ColumnEditable', true, ...
                        'Units', 'normalized', 'Position', [0.03 0.67 0.9 0.12]);
                    
                end
                
                function createOutputRegion()
                    
                    this.gui.systemLogText = uicontrol(this.gui.rightPanel, 'Style', 'text',...
                        'String', 'Sysem Log', 'Units', 'normalized', 'Position', [0.03 0.645 0.9 0.02],...
                        'HorizontalAlignment', 'left');
                    
                    rightPanel = this.gui.rightPanel;
                    
                    this.gui.output = uicontrol(rightPanel,'Style','edit','Max',2,'HorizontalAlignment','left','Units','normalized',...
                        'Position',[0.03 0.07 0.935 0.57]);
                    
                    this.gui.clearOutputButton = uicontrol(rightPanel,'Style','pushbutton','String','Clear Output','Units','normalized',...
                        'Position',[0.022 0.04 0.21 0.03]);
                    
                    this.gui.saveOutputButton = uicontrol(rightPanel,'Style','pushbutton','String','Save Output Text','Units','normalized',...
                        'Position',[0.24 0.04 0.27 0.03]);
                    
                    this.gui.saveText = uicontrol(rightPanel,'Style','text','String','Save:','HorizontalAlignment','left','Units','normalized',...
                        'Position',[0.03 0.01 0.1 0.022]);
                    
                end
                
                function createSaveButtons()
                    
                    rightPanel = this.gui.rightPanel;
                    
                    this.gui.saveFigure1Button = uicontrol(rightPanel,'Style','pushbutton','String','Figure 1','Units','normalized',...
                        'Position',[0.12 0.008 0.15 0.03]);
                    
                    this.gui.saveFigure2Button = uicontrol(rightPanel,'Style','pushbutton','String','Figure 2','Units','normalized',...
                        'Position',[0.28 0.008 0.15 0.03]);
                    
                    this.gui.saveWorkspaceButton = uicontrol(rightPanel,'Style','pushbutton','String','Workspace','Units','normalized',...
                        'Position',[0.44 0.008 0.17 0.03]);
                    
                    this.gui.exportDataButton = uicontrol(rightPanel,'Style','pushbutton','String','Export Selected Data','Units','normalized',...
                        'Position',[0.62 0.008 0.32 0.03]);
                    
                end
                
            end
            
            function createController()
                
                % left panel
                this.gui.loadButton.Callback = @(varargin) this.control('load');
                this.gui.refreshButton.Callback = @(varargin) this.control('refresh');
                this.gui.scanList.Callback = @(varargin) this.control('scan');
                this.gui.qzList.Callback = @(varargin) this.control('qz');
                
                % central panel
                this.gui.plot1Type.Callback = @(varargin) this.control('plot1-type');
                this.gui.plot2Type.Callback = @(varargin) this.control('plot2-type');
                
                % right panel before the output
                this.gui.elementMenu.Callback = @(varargin) this.control('element');
                this.gui.lineShape.Callback = @(varargin) this.control('line-shape');
                this.gui.background.Callback = @(varargin) this.control('background');
                this.gui.integrate.Callback = @(varargin) this.control('integrate');
                
                % tables
                this.gui.basicInfoTable.CellEditCallback = @(source, eventdata) this.control('basic-info', eventdata);
                this.gui.calibrationTable.CellEditCallback = @(source, eventdata) this.control('calibration', eventdata);
                
                % buttons below the output
                this.gui.clearOutputButton.Callback = @(varargin) this.control('clear-output');
                this.gui.saveOutputButton.Callback = @(varargin) this.control('save-output');
                this.gui.saveFigure1Button.Callback = @(varargin) this.control('save-figure-1');
                this.gui.saveFigure2Button.Callback = @(varargin) this.control('save-figure-2');
                this.gui.saveWorkspaceButton.Callback = @(varargin) this.control('save-workspace');
                this.gui.exportDataButton.Callback = @(varargin) this.control('export-data');
                
            end
            
        end
        
        function model(this, state, trigger, varargin)
            
            switch state
                case 'element'
                    switch trigger
                        case {'element', 'line-shape'}
                            elementProfile = varargin{1};
                            lineShape = varargin{2};
                            fitElement(elementProfile, lineShape);
                        otherwise
                            warning(['case not found for model, with state = ', state, ' and trigger = ', trigger]);
                    end
                otherwise
                    warning(['case not found for model, with state = ', state]);
            end
            
            function fitElement(elementProfile, lineShape)
                
                x = this.data;
                for i = 1:length(x)
                    xFit(x{i}, elementProfile, lineShape);
                end
                
            end
            
        end
        
        function view(this, state, trigger, varargin)
            
            switch state
                case 'empty'
                    switch trigger
                        case 'initial-load'
                            this.gui.elementMenu.String = getElementMenuItems();
                            this.gui.specInput.String = this.data{1}.specFile;
                            this.gui.scanList.String = getScanListString();
                            this.gui.qzList.String = getQzList();
                            displayTableInfo();
                            displayScanInfo();
                            upperPlot();
                            plotParameter();
                        otherwise
                            warning(['case not found for view, with state = ', state, ' and trigger = ', trigger]);
                    end
                case 'whole'
                    turnElementFeatures('off');
                    switch trigger
                        case 'scan'
                            this.gui.qzList.String = getQzList();
                            displayTableInfo();
                            displayScanInfo();
                            upperPlot();
                            plotParameter();
                        case 'qz'
                            upperPlot();
                            plotParameter();
                        case {'plot1-type', 'element', 'basic-info', 'calibration'}
                            upperPlot();
                        case 'plot2-type'
                            plotParameter();
                        case 'clear-output'
                            this.gui.output.String = {};
                        otherwise
                            warning(['case not found for view, with state = ', state, ' and trigger = ', trigger]);
                    end
                case 'element'
                    turnElementFeatures('on');
                    switch trigger
                        case {'element', 'line-shape', 'plot1-type', 'background', 'basic-info', 'calibration'}
                            upperPlot();
                        case 'qz'
                            upperPlot();
                            plotParameter();
                        case 'scan'
                            displayTableInfo();
                            displayScanInfo();
                            upperPlot();
                        case 'integrate'
                            upperPlot();
                        case 'plot2-type'
                            plotParameter();
                        case 'clear-output'
                            this.gui.output.String = {};
                        otherwise
                            warning(['case not found for view, with state = ', state, ' and trigger = ', trigger]);
                    end
            end
            
            function scanList = getScanListString()
                
                n = length(this.data);
                scanList = cell(n, 1);
                
                for i = 1 : n
                    scanList{i} = ['Scan #', num2str(this.data{i}.scanNumber)];
                end
                
            end
            
            function qzList = getQzList()
                
                indices = this.gui.scanList.Value;
                m = length(indices);
                n = zeros(1, m);
                for i = 1 : m
                    n(i) = length(this.data{indices(i)}.q);
                end
                ind = find(min(n)==n,1);
                qzList = num2cell(this.data{indices(ind)}.q);
                
            end
            
            function items = getElementMenuItems()
                items = ['Choose Element...'; fieldnames(this.ElementProfiles); 'Add Element'];
            end
            
            function plotParameter()
                
                ax = this.gui.ax2;
                plot2Type = this.gui.plot2Type;
                scanList = this.gui.scanList;
                qzList = this.gui.qzList;
                x = this.data;
                
                switch plot2Type.String{plot2Type.Value}
                    case this.config.plot2Choices{1}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.influx(qzList.Value),this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Qz');
                            ylabel(ax,'Influx Counts');
                            title(ax,'Influx - Qz Relation');
                            hold(ax,'on');
                        end
                    case this.config.plot2Choices{2}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.T(qzList.Value),this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Qz');
                            ylabel(ax,'Count Time');
                            title(ax,'Count Time - Qz Relation');
                            hold(ax,'on');
                        end
                    case this.config.plot2Choices{3}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.countTime(qzList.Value)./x{scanList.Value(i)}.T(qzList.Value),this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Qz');
                            ylabel(ax,'Detector Live Ratio');
                            title(ax,'Detector Live Ratio - Qz Relation');
                            hold(ax,'on');
                        end
                    case this.config.plot2Choices{4}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.q(qzList.Value),x{scanList.Value(i)}.absorber,this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Qz');
                            ylabel(ax,'Absorber');
                            title(ax,'Absorber');
                            hold(ax,'on');
                        end
                    case this.config.plot2Choices{5}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.scanNumber,sum(x{scanList.Value(i)}.sx),this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Scan Number');
                            ylabel(ax,'Detector Footprint (mm)');
                            title(ax,'Detector Footprint');
                            hold(ax,'on');
                        end
                    case this.config.plot2Choices{6}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.scanNumber,sum(x{scanList.Value(i)}.s1(1:2)),this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Scan Number');
                            ylabel(ax,'Slit height (mm)');
                            title(ax,'Slit height');
                            hold(ax,'on');
                        end
                    case this.config.plot2Choices{7}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.scanNumber,sum(x{scanList.Value(i)}.s1(3:4)),this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Scan Number');
                            ylabel(ax,'Slit width (mm)');
                            title(ax,'Slit width');
                        end
                    case this.config.plot2Choices{8}
                        for i = 1:length(scanList.Value)
                            plot(ax,x{scanList.Value(i)}.scanNumber,x{scanList.Value(i)}.sx,this.config.spec2{i},'markersize',8,'linewidth',2);
                            xlabel(ax,'Scan Number');
                            ylabel(ax,'Beam position (mm)');
                            title(ax,'Beam position (sx)');
                            hold(ax,'on');
                        end
                    otherwise
                        error('type of plot not found for lower figure');
                end
                legend(this.config.plot2Legend);
                hold(ax,'off');
                
            end
            
            function plotSpectra()
                
                scanList = this.gui.scanList;
                qzList = this.gui.qzList;
                elementMenu = this.gui.elementMenu;
                plot1Type = this.gui.plot1Type;
                background = this.gui.background;
                ax = this.gui.ax1;
                x = this.data;
                
                switch this.gui.plot1Type.String{this.gui.plot1Type.Value}
                    case this.config.plot1Choices{1}
                        k = 1;
                        for i = scanList.Value
                            for j = qzList.Value
                                switch lower(elementMenu.String{elementMenu.Value})
                                    case {'choose element...','choose element','choose'}
                                        plot(ax, x{i}.e,x{i}.counts(:,j), this.config.spec1{k});
                                    otherwise
                                        switch background.Value
                                            case 0
                                                plot(ax,x{i}.xe,x{i}.xCounts(:,j),this.config.spec1{k});
                                            case 1
                                                plot(ax,x{i}.xe,x{i}.netCounts(:,j),this.config.spec1{k});
                                            otherwise
                                                error('there should only be two choices: with and without background');
                                        end
                                end
                                hold(ax,'on');
                                k = k+1;
                            end
                        end
                    case this.config.plot1Choices{2} %counts with error
                        k = 1;
                        for i = scanList.Value
                            for j = qzList.Value
                                switch lower(elementMenu.String{elementMenu.Value})
                                    case {'choose element...','choose element','choose'}
                                        errorbar(ax,x{i}.e,x{i}.counts(:,j),x{i}.countsError(:,j),x{i}.countsError(:,j),this.config.spec1{k});
                                    otherwise
                                        switch background.Value
                                            case 0
                                                errorbar(ax,x{i}.xe,x{i}.xCounts(:,j),x{i}.xCountsError(:,j),x{i}.xCountsError(:,j),this.config.spec1{k});
                                            case 1
                                                errorbar(ax,x{i}.xe,x{i}.netCounts(:,j),x{i}.xCountsError(:,j),x{i}.xCountsError(:,j),this.config.spec1{k});
                                            otherwise
                                                error('there should only be two choices: with and without background');
                                        end
                                end
                                hold(ax,'on');
                                k = k+1;
                            end
                        end
                    case this.config.plot1Choices{3} %normalized
                        k = 1;
                        for i = scanList.Value
                            for j = qzList.Value
                                switch lower(elementMenu.String{elementMenu.Value})
                                    case {'choose element...','choose element','choose'}
                                        plot(ax,x{i}.e,x{i}.intensity(:,j),this.config.spec1{k});
                                    otherwise
                                        switch background.Value
                                            case 0
                                                plot(ax,x{i}.xe,x{i}.xIntensity(:,j),this.config.spec1{k});
                                            case 1
                                                plot(ax,x{i}.xe,x{i}.netIntensity(:,j),this.config.spec1{k});
                                            otherwise
                                                error('there should only be two choices: with and without background');
                                        end
                                end
                                hold(ax,'on');
                                k = k+1;
                            end
                        end
                    case this.config.plot1Choices{4} %normalized with error
                        k = 1;
                        for i = scanList.Value
                            for j = qzList.Value
                                switch lower(elementMenu.String{elementMenu.Value})
                                    case {'choose element...','choose element','choose'}
                                        errorbar(ax,x{i}.e,x{i}.intensity(:,j),x{i}.intensityError(:,j),x{i}.intensityError(:,j),this.config.spec1{k});
                                    otherwise
                                        switch background.Value
                                            case 0
                                                errorbar(ax,x{i}.xe,x{i}.xIntensity(:,j),x{i}.xIntensityError(:,j),x{i}.xIntensityError(:,j),this.config.spec1{k});
                                            case 1
                                                errorbar(ax,x{i}.xe,x{i}.netIntensity(:,j),x{i}.xIntensityError(:,j),x{i}.xIntensityError(:,j),this.config.spec1{k});
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
                
                legend(ax, this.config.plot1Legend);
                xlabel(ax, 'Energy (keV)');
                ylabel(ax, 'Signal');
                switch lower(elementMenu.String{elementMenu.Value})
                    case {'choose element...','choose element','choose'}
                        set(ax, 'xlim',[min(x{scanList.Value(1)}.e) max(x{scanList.Value(1)}.e)]);
                        titleText = sprintf('%s %s','Whole Spec -',plot1Type.String{plot1Type.Value});
                    otherwise
                        titleText = sprintf('%s %s %s',this.config.element,'-',plot1Type.String{plot1Type.Value});
                        switch plot1Type.String{plot1Type.Value}
                            case {this.config.plot1Choices{1},this.config.plot1Choices{2}}
                                k = 1;
                                for i = scanList.Value
                                    for j = qzList.Value
                                        color = this.config.spec1{k}(1);
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
                            case {this.config.plot1Choices{3},this.config.plot1Choices{4}}
                                k = 1;
                                for i = scanList.Value
                                    for j = qzList.Value
                                        color = this.config.spec1{k}(1);
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
            
            function plotSignal()
                % plot the integrated signal for a given element
                
                ax = this.gui.ax1;
                scanList = this.gui.scanList;
                qzList = this.gui.qzList;
                lineShape = this.gui.lineShape;
                x = this.data;
                
                for i = 1:length(scanList.Value)
                    errorbar(ax,x{scanList.Value(i)}.angle(qzList.Value),x{scanList.Value(i)}.signal(qzList.Value),...
                        x{scanList.Value(i)}.signalError(qzList.Value),x{scanList.Value(i)}.signalError(qzList.Value),...
                        this.config.spec2{i},'markersize',8,'linewidth',2);
                    hold(ax,'on');
                end
                hold(ax,'off');
                xlabel(ax,'Angle (radian)');
                ylabel(ax,'Fluorescence Intensity (a.u.)');
                switch lower(lineShape.String{lineShape.Value})
                    case {'gauss','gaussian'}
                        titleText = sprintf('%s %s',this.config.element,'Integrated Intensity (Gaussian Fit)');
                    case {'lorentz','lorentzian'}
                        titleText = sprintf('%s %s',this.config.element,'Integrated Intensity (Lorentzian Fit)');
                    otherwise
                        titleText = sprintf('%s %s',this.config.element,'Integrated Intensity (unkown curve type)');
                end
                title(ax,titleText);
                legend(ax,this.config.plot2Legend);
                
            end
            
            function upperPlot()
                switch this.gui.elementMenu.Value
                    case 1
                        plotSpectra();
                    case length(this.gui.elementMenu.String)
                    otherwise
                        switch this.gui.integrate.Value
                            case 0
                                plotSpectra();
                            case 1
                                plotSignal();
                        end
                end
            end
            
            function turnElementFeatures(mode)
                this.gui.lineShape.Enable = mode;
                this.gui.background.Enable = mode;
                this.gui.integrate.Enable = mode;
            end
            
            function displayTableInfo()
                this.gui.calibrationTable.Data = getCalibarationTableData();
                this.gui.basicInfoTable.Data = getBasicInfoTableData();
                
                function dat = getCalibarationTableData()
                    calibration = this.data{this.gui.scanList.Value(1)}.calibration;
                    dat = zeros(1, 4);
                    dat(1:length(calibration)) = calibration;
                    dat = dat';
                end
                
                function dat = getBasicInfoTableData()
                    dat = cell(3, 1);
                    n = this.gui.scanList.Value(1);
                    dat{1} = this.data{n}.E;
                    dat{2} = sum(this.data{n}.s1(1:2));
                    dat{3} = this.data{n}.A;
                end
                
            end
            
            function displayScanInfo()
                %display the important information
                
                scanList = this.gui.scanList;
                output = this.gui.output;
                x = this.data;
                
                %the text box
                oldText = output.String;
                
                
                outputText = cell(6,1);
                outputText{1} = '';
                outputText{2} = repmat('-',1,68);
                outputText{3} = sprintf('%s %s','Spec file location:',x{scanList.Value(1)}.specPath);
                outputText{4} = sprintf('%s %s','Time of experiment:',x{scanList.Value(1)}.time);
                outputText{5} = sprintf('%s %s','Beam energy:',num2str(x{scanList.Value(1)}.E));
                
                theVector = zeros(1,length(scanList.Value));
                scanNumber = theVector;
                k = 1;
                for i = scanList.Value
                    scanNumber(k) = x{i}.scanNumber;
                    k = k+1;
                end
                outputText{6} = sprintf('%s %s','Scan number:',num2str(scanNumber));
                
                outputText = [oldText;outputText];
                output.String = outputText;
            end
            
        end
        
        function control(this, trigger, varargin)
            
            state = getGuiState();
            
            switch state
                case 'empty'
                    switch trigger
                        case 'initial-load'
                            specFile = getSpecFileAt(pwd);
                            if loadDataAt(pwd, specFile)
                                getLineSpecAndLegendFirstTime();
                                this.view(state, trigger);
                            end
                        otherwise
                            warning(['case not found for view, with state = ', state, ' and trigger = ', trigger]);
                    end
                case 'whole'
                    switch trigger
                        case 'load'
                            [specFile, specFilePath] = uigetfile('*', 'Select the spec file');
                            if specFile ~= 0
                               if loadDataAt(specFile, specFilePath)
                                   getLineSpecAndLegendFirstTime();
                                   this.view(state, trigger);
                               end
                            end
                        case 'refresh'
                            refreshScans();
                        case {'scan', 'qz'}
                            getLineSpecAndLegend();
                            this.view(state, trigger);
                        case {'plot1-type', 'plot2-type', 'element', 'clear-output'}
                            this.view(state, trigger);
                        case 'basic-info'
                            eventdata = varargin{1};
                            updateViewNeeded = processBasicInfoTable(eventdata);
                            if updateViewNeeded
                                this.view(state, trigger);
                            end
                        case 'calibration'
                            eventdata = varargin{1};
                            updateViewNeeded = processCalibrationTable(eventdata);
                            if updateViewNeeded
                                this.view(state, trigger);
                            end
                        case 'save-output'
                            saveOutputText();
                        case 'save-figure-1'
                            saveFigure1();
                        case 'save-figure-2'
                            saveFigure2();
                        case 'save-workspace'
                            saveDataset();
                        case 'export-data'
                            exportSelectedData();
                        otherwise
                            warning(['case not found for view, with state = ', state, ' and trigger = ', trigger]);
                    end
                case 'element'
                    switch trigger
                        case 'load'
                            disp('will build up the loading');
                        case 'refresh'
                            refreshScans();
                        case {'scan', 'qz'}
                            getLineSpecAndLegend();
                            this.view(state, trigger);
                        case 'element'
                            this.config.element = this.gui.elementMenu.String{this.gui.elementMenu.Value};
                            lineShape = this.gui.lineShape.String{this.gui.lineShape.Value};
                            elementProfile = this.ElementProfiles.(this.config.element);
                            this.model(state, trigger, elementProfile, lineShape);
                            this.view(state, trigger);
                        case 'line-shape'
                            lineShape = this.gui.lineShape.String{this.gui.lineShape.Value};
                            elementProfile = this.ElementProfiles.(this.config.element);
                            this.model(state, trigger, elementProfile, lineShape);
                            this.view(state, trigger);
                        case {'plot1-type', 'plot2-type', 'background', 'integrate', 'clear-output'}
                            this.view(state, trigger);
                        case 'basic-info'
                            eventdata = varargin{1};
                            updateViewNeeded = processBasicInfoTable(eventdata);
                            if updateViewNeeded
                                this.view(state, trigger);
                            end
                        case 'calibration'
                            eventdata = varargin{1};
                            updateViewNeeded = processCalibrationTable(eventdata);
                            if updateViewNeeded
                                this.view(state, trigger);
                            end
                        case 'save-output'
                            saveOutputText();
                        case 'save-figure-1'
                            saveFigure1();
                        case 'save-figure-2'
                            saveFigure2();
                        case 'save-workspace'
                            saveDataset();
                        case 'export-data'
                            exportSelectedData();
                        otherwise
                            warning(['case not found for view, with state = ', state, ' and trigger = ', trigger]);
                    end
                otherwise
                    warning(['case not found for control, with state = ', state]);
            end
            
            function state = getGuiState()
                if isempty(this.gui.scanList.String)
                    state = 'empty';
                else
                    if this.gui.elementMenu.Value == 1
                        state = 'whole';
                    else
                        state = 'element';
                    end
                end
            end
            
            function flag = loadDataAt(thePath, specFile)
                %try to load data, returns 0 if not successufl, 1 if successful
                %searches for scan data files in thePath and 'vortex' folder
                
                flag = 0;
                if nargin == 1
                    specFile = getSpecFileAt(thePath);
                end
                if ~isempty(specFile)
                    specPath = thePath;
                    scanPath = thePath;
                    scanFiles = getScanFilesAt(specPath, specFile);
                    if isempty(scanFiles)
                        newPath = fullfile(specPath, 'vortex');
                        scanFiles = getScanFilesAt(newPath, specFile);
                        scanPath = newPath;
                    end
                    
                    %if found both spec files and scan files, try importing data
                    if ~isempty(scanFiles)
                        A = this.gui.basicInfoTable.Data{3};
                        try
                            this.data = importData(specFile, specPath, scanFiles, scanPath, A);
                            this.config.specFile = specFile;
                            this.config.specPath = specPath;
                            this.config.scanFiles = scanFiles;
                            this.config.scanPath = scanPath;
                            flag = 1;
                        catch
                            warning('Was not able to import data.');
                        end
                    end
                end
            end
            
            function refreshScans()
                % refresh data without losing current work
                
                x = this.data;
                
                if ~isempty(x)
                    
                    n = length(x);
                    scanFiles = cell(1, n);
                    for i = 1 : length(x)
                        scanFiles{i} = x{i}.scanFile;
                        if i == 1
                            scanPath = x{i}.scanPath;
                            currentSpecFile = x{i}.specFile;
                            specPath = x{i}.specPath;
                        end
                    end
                    
                    oldScanNumbers = getScanNumbers(scanFiles);
                    
                    newScanFiles = getScanFilesAt(scanPath, currentSpecFile);
                    newScanNumbers = getScanNumbers(newScanFiles);
                    
                    if length(newScanNumbers) > length(oldScanNumbers)
                        newScanFiles = newScanFiles(length(oldScanNumbers)+1 : end);
                        A = str2double(this.gui.basicInfoTable.Data{3});
                        y = importData(currentSpecFile, specPath, newScanFiles, scanPath, A);
                        
                        %combine the newly added data with the old data set
                        this.data = {x{1:end},y{1:end}};
                        this.gui.scanList.String = {scanFiles{1:end}, newScanFiles{1:end}};
                    end
                    
                end
                
            end
            
            function updateViewNeeded = processBasicInfoTable(eventdata)
                
                updateViewNeeded = false;
                
                indices = eventdata.Indices;
                table = this.gui.basicInfoTable;
                if ~isnumeric(eventdata.NewData) || indices(1) == 2
                    table.Data{indices(1), indices(2)} = eventdata.PreviousData;
                else
                    selected = this.gui.scanList.Value;
                    switch indices(1)
                        case 1
                            for i = selected
                                this.data{i}.E = table.Data{1};
                            end
                        case 3
                            updateViewNeeded = true;
                            for i = selected
                                adjustScaleFactor(this.data{i}, table.Data{3});
                            end
                    end
                end
            end
            
            function updateViewNeeded = processCalibrationTable(eventdata)
                
                updateViewNeeded = false;
                
                indices = eventdata.Indices;
                table = this.gui.calibrationTable;
                if ~isnumeric(eventdata.NewData)
                    table.Data{indices(1), indices(2)} = eventdata.PreviousData;
                else
                    updateViewNeeded = true;
                    selected = this.gui.scanList.Value;
                    for i = selected
                        this.data{i}.calibration = table.Data';
                        adjustEnergyCalibration(this.data{i});
                    end
                end
                
            end
            
            function saveOutputText()
                
                [fileName, path] = uiputfile('visualfluo-output.txt','Save output text as');
                file = fullfile(path, fileName);
                text = this.gui.output.String;
                fid = fopen(file, 'a');
                fprintf(fid, strcat(datestr(datetime), '\n'));
                for i = 1:length(text)
                    fprintf(fid, strcat(text{i}, '\n'));
                end
                fprintf(fid,'\n');
                fclose(fid);
                
                message = {'Output text save at:'; path; 'File name is:'; fileName};
                prependOutput(message);
                
            end
            
            function saveFigure1()
                
                theFigure = figure;
                copyobj(this.gui.ax1, theFigure);
                ax = gca;
                ax.Units = 'normalized';
                ax.Position = [.13 .11 .775 .815];
                hgsave(theFigure,'VisualFluo upper figure');
                
                prependOutput('Figure 1 is produced.');
                
            end
            
            function saveFigure2()
                
                theFigure = figure;
                copyobj(this.gui.ax2, theFigure);
                ax = gca;
                ax.Units = 'normalized';
                ax.Position = [.13 .11 .775 .815];
                hgsave(theFigure, 'VisualFluo lower figure');
                
                prependOutput('Figure 2 is produced.');
                
            end
            
            function saveDataset()
                
                VisualFluoDataSet = this.data;
                save('VisualFluoDataSet','VisualFluoDataSet');
                clear VisualFluoDataSet;
                
                prependOutput('Dataset is saved to current folder.');
                
            end
            
            function exportSelectedData()
                
                x = this.data;
                scanList = this.gui.scanList;
                qzList = this.gui.qzList;
                
                for i = 1:length(scanList.Value)
                    y = x{scanList.Value(i)};
                    scanString = num2str(y.scanNumber);
                    string1 = strcat('scan-', scanString, '.xfluo');
                    string2 = sprintf('%s %s %s', 'Save scan #', scanString, 'as');
                    [fileName, path] = uiputfile(string1, string2);
                    fspecFile = fullfile(path, fileName);
                    
                    angle = repmat(y.angle(qzList.Value), 2, 1);
                    angle = reshape(angle, 1, numel(angle));
                    line1 = sprintf('%s %s', 'E(keV)\\Angle', num2str(angle, 10));
                    dat = zeros(length(y.e), length(qzList.Value)*2);
                    dat(:, 1:2:end) = y.intensity(:, qzList.Value);
                    dat(:, 2:2:end) = y.intensityError(:, qzList.Value);
                    dataMatrix = [y.e, dat];
                    
                    try
                        fid = fopen(fspecFile, 'w');
                        fprintf(fid, line1);
                        fprintf(fid, '\n');
                        dlmwrite(fspecFile, dataMatrix, 'delimiter', '\t', 'precision', '%.6f', '-append');
                        fclose(fid);
                        prependOutput({'Data file saved at:'; path; 'File name is:'; fileName});
                    catch
                        prependOutput('Did not save data.');
                    end
                    
                end
                
            end
            
            function prependOutput(message)
                
                text = this.gui.output.String;
                if ischar(message)
                    newText = {' '; repmat('-', 1, 68); ['Time stamp: ', datestr(datetime)]; message};
                else
                    newText = [' '; repmat('-', 1, 68); ['Time stamp: ', datestr(datetime)]; message];
                end
                
                if isempty(text)
                    this.gui.output.String = newText;
                else
                    this.gui.output.String = [newText; text];
                end
                
            end
            
            % utility
            
            function specFile = getSpecFileAt(thePath)
                %look for a spec file the path
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
            
            function scanFiles = getScanFilesAt(scanPath, specFile)
                %If no scan files found, return an empty cell array
                %returned scan files would be sorted
                
                % this file stores the format of spec file and scan files
                try
                    expression = getExpressionOf('scan');
                catch
                    expression = '[12]\d\d\d[01][012][0123]\d_(\d+)_mca';
                end
                
                try
                    dirStruct = dir(scanPath);
                    [sortedNames, sortedIndex] = sortrows({dirStruct.name}');
                    
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
                catch
                    
                end
                
            end
            
            function scanNumbers = getScanNumbers(scanFiles)
                %obtain scan numbers in a vector
                
                scanNumbers = zeros(1,length(scanFiles));
                for n = 1:length(scanNumbers)
                    index = regexp(scanFiles{n},'_');
                    scanNumbers(n) = str2double(scanFiles{n}(index(1)+1:index(2)-1));
                end
                
            end
            
            function y = importData(specFile, specPath, scanFiles, scanPath, A)
                %return a cell array
        
                scanNumbers = getScanNumbers(scanFiles);
                
                y = cell(1, length(scanNumbers));
                for n = 1:length(scanNumbers)
                    y{n} = VisualFluoData(specFile, specPath, scanFiles{n}, scanPath, scanNumbers(n), A);
                end
                
            end
            
            function getLineSpecAndLegend()
                
                qzList = this.gui.qzList;
                scanList = this.gui.scanList;
                x = this.data;
                colors = this.config.colors;
                symbols = this.config.symbols;
                
                this.config.spec1 = cell(length(qzList.Value),length(scanList.Value));
                this.config.spec2 = cell(1,length(scanList.Value));
                this.config.plot1Legend = this.config.spec1;
                this.config.plot2Legend = this.config.spec2;
                
                for i = 1:length(qzList.Value)
                    n = mod(i, length(colors));
                    if n == 0
                        n = length(colors);
                    end
                    color = colors(n);
                    for j = 1 : length(scanList.Value)
                        m = mod(j, length(symbols));
                        if m == 0
                            m = length(symbols);
                        end
                        symbol = symbols(m);
                        this.config.spec1{i, j} = strcat(color, symbol);
                        this.config.plot1Legend{i, j} = strcat('Scan #', num2str(x{scanList.Value(j)}.scanNumber),' Qz=',num2str(x{scanList.Value(j)}.q(qzList.Value(i)),'%.3g'));
                        if i == 1
                            this.config.spec2{j} = strcat('k', symbol);
                            this.config.plot2Legend{j} = strcat('Scan #', num2str(x{scanList.Value(j)}.scanNumber));
                        end
                    end
                end
                
                this.config.spec1 = reshape(this.config.spec1,1,numel(this.config.spec1));
                this.config.plot1Legend = reshape(this.config.plot1Legend,1,numel(this.config.plot1Legend));
                
            end
            
            function getLineSpecAndLegendFirstTime()
                
                this.config.spec1 = {'ko'};
                this.config.plot1Legend = {['Scan #', num2str(this.data{1}.scanNumber)]};
                this.config.spec2 = {'ko'};
                this.config.plot2Legend = {['Scan #', num2str(this.data{1}.scanNumber), ' @ Qz=', num2str(this.data{1}.q(1))]};
                
            end
            
        end
        
    end
    
end