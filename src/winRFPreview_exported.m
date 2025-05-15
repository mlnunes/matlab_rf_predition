classdef winRFPreview_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        popupContainerGrid             matlab.ui.container.GridLayout
        SplashScreen                   matlab.ui.control.Image
        menu_Grid                      matlab.ui.container.GridLayout
        DataHubLamp                    matlab.ui.control.Lamp
        dockModule_Close               matlab.ui.control.Image
        dockModule_Undock              matlab.ui.control.Image
        AppInfo                        matlab.ui.control.Image
        FigurePosition                 matlab.ui.control.Image
        jsBackDoor                     matlab.ui.control.HTML
        menu_Button4                   matlab.ui.control.StateButton
        menu_Button3                   matlab.ui.control.StateButton
        menu_Separator2                matlab.ui.control.Image
        menu_Button2                   matlab.ui.control.StateButton
        menu_Separator1                matlab.ui.control.Image
        menu_Button1                   matlab.ui.control.StateButton
        TabGroup                       matlab.ui.container.TabGroup
        Tab1_File                      matlab.ui.container.Tab
        file_Grid                      matlab.ui.container.GridLayout
        file_toolGrid                  matlab.ui.container.GridLayout
        file_SpecReadButton            matlab.ui.control.Button
        file_OpenFileButton            matlab.ui.control.Image
        file_Metadata                  matlab.ui.control.Label
        file_MetadataLabel             matlab.ui.control.Label
        file_Tree                      matlab.ui.container.Tree
        file_TreeLabel                 matlab.ui.control.Label
        file_TitleGridLine             matlab.ui.control.Image
        file_TitleGrid                 matlab.ui.container.GridLayout
        file_Title                     matlab.ui.control.Label
        file_TitleIcon                 matlab.ui.control.Image
        Tab2_Playback                  matlab.ui.container.Tab
        Tab5_RFDataHub                 matlab.ui.container.Tab
        Tab6_Config                    matlab.ui.container.Tab
        file_ContextMenu_Tree          matlab.ui.container.ContextMenu
        file_ContextMenu_delTree1Node  matlab.ui.container.Menu
    end

    
    properties (Access = public)
        %-----------------------------------------------------------------%
        % PROPRIEDADES COMUNS A TODOS OS APPS
        %-----------------------------------------------------------------%
        General
        General_I

        rootFolder
        entryPointFolder        

        % Essa propriedade registra o tipo de execução da aplicação, podendo
        % ser: 'built-in', 'desktopApp' ou 'webApp'.
        executionMode        

        % A função do timer é executada uma única vez após a renderização
        % da figura, lendo arquivos de configuração, iniciando modo de operação
        % paralelo etc. A ideia é deixar o MATLAB focar apenas na criação dos 
        % componentes essenciais da GUI (especificados em "createComponents"), 
        % mostrando a GUI para o usuário o mais rápido possível.
        timerObj

        % Controla a seleção da TabGroup a partir do menu.
        tabGroupController

        % Janela de progresso já criada no DOM. Dessa forma, controla-se 
        % apenas a sua visibilidade - e tornando desnecessário criá-la a
        % cada chamada (usando uiprogressdlg, por exemplo).
        progressDialog

        % Objeto que possibilita integração com o eFiscaliza.
        eFiscalizaObj

        %-----------------------------------------------------------------%
        % PROPRIEDADES ESPECÍFICAS
        %-----------------------------------------------------------------%
        projectData
        restoreView = struct('ID', {}, 'xLim', {}, 'yLim', {}, 'cLim', {})
        UIAxes1
    end


    methods
        %-----------------------------------------------------------------%
        % COMUNICAÇÃO ENTRE PROCESSOS:
        % • ipcMainJSEventsHandler
        %   Eventos recebidos do objeto app.jsBackDoor por meio de chamada 
        %   ao método "sendEventToMATLAB" do objeto "htmlComponent" (no JS).
        %
        % • ipcMainMatlabCallsHandler
        %   Eventos recebidos dos apps secundários.
        %-----------------------------------------------------------------%
        function ipcMainJSEventsHandler(app, event)
            try
                switch event.HTMLEventName
                    % JS
                    case 'renderer'
                        startup_Controller(app)
                    case 'unload'
                        closeFcn(app)

                    % MAINAPP
                    case 'mainApp.file_Tree'
                        file_ContextMenu_delTree1NodeSelected(app)

                    % DRIVETEST / RFDATAHUB
                    case {'auxApp.winDriveTest.filter_Tree', 'auxApp.winDriveTest.points_Tree', 'auxApp.winRFDataHub.filter_Tree'}
                        if contains(event.HTMLEventName, 'winDriveTest')
                            auxAppName = 'DRIVETEST';
                        elseif contains(event.HTMLEventName, 'winRFDataHub')
                            auxAppName = 'RFDATAHUB';
                        end

                        idxAuxApp = app.tabGroupController.Components.Tag == auxAppName;
                        hAuxApp   = app.tabGroupController.Components.appHandle{idxAuxApp};
                        ipcSecundaryJSEventsHandler(hAuxApp, event)

                    % JSBACKDOOR (compCustomization.js)
                    % "BackgroundColorTurnedInvisible" | "customForm" | "getURL" | "getNavigatorBasicInformation"
                    case 'BackgroundColorTurnedInvisible'
                        switch event.HTMLEventData
                            case 'SplashScreen'
                                if isvalid(app.popupContainerGrid)
                                    delete(app.popupContainerGrid)
                                end
                            otherwise
                                error('UnexpectedEvent')
                        end
                    
                    case 'customForm'
                        switch event.HTMLEventData.uuid
                            case 'eFiscalizaSignInPage'
                                report_uploadInfoController(app, event.HTMLEventData, 'uploadDocument')
                            case 'openDevTools'
                                if isequal(app.General.operationMode.DevTools, rmfield(event.HTMLEventData, 'uuid'))
                                    webWin = struct(struct(struct(app.UIFigure).Controller).PlatformHost).CEF;
                                    webWin.openDevTools();
                                end
                        end

                    otherwise
                        error('UnexpectedEvent')
                end
                drawnow

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME));
            end
        end

        %-----------------------------------------------------------------%
        function ipcMainMatlabCallsHandler(app, callingApp, operationType, varargin)
            try
                switch class(callingApp)
                    % CONFIG
                    case {'auxApp.winConfig', 'auxApp.winConfig_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "CONFIG", app.General)
                            case 'checkDataHubLampStatus'
                                DataHubWarningLamp(app)
                            case 'openDevTools'
                                dialogBox    = struct('id', 'login',    'label', 'Usuário: ', 'type', 'text');
                                dialogBox(2) = struct('id', 'password', 'label', 'Senha: ',   'type', 'password');
                                sendEventToHTMLSource(app.jsBackDoor, 'customForm', struct('UUID', 'openDevTools', 'Fields', dialogBox))
                            otherwise
                                error('UnexpectedCall')
                        end

                    % PROPAGATION
                    case {'auxApp.winPropagation', 'auxApp.winPropagation_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "PROPAGATION", app.General)
                            otherwise
                                error('UnexpectedCall')
                        end

                    % RFDATAHUB
                    case {'auxApp.winRFDataHub', 'auxApp.winRFDataHub_exported'}
                        switch operationType
                            case 'closeFcn'
                                closeModule(app.tabGroupController, "RFDATAHUB", app.General)
                            otherwise
                                error('UnexpectedCall')
                        end
    
                    otherwise
                        error('UnexpectedCall')
                end

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME));            
            end

            % Caso um app auxiliar esteja em modo DOCK, o progressDialog do
            % app auxiliar coincide com o do appAnalise. Força-se, portanto, 
            % a condição abaixo para evitar possível bloqueio da tela.
            app.progressDialog.Visible = 'hidden';
        end
    end
    
    
    methods (Access = private)
        %-----------------------------------------------------------------%
        % JSBACKDOOR
        %-----------------------------------------------------------------%
        function jsBackDoor_Initialization(app)
            app.jsBackDoor.HTMLSource           = appUtil.jsBackDoorHTMLSource();
            app.jsBackDoor.HTMLEventReceivedFcn = @(~, evt)ipcMainJSEventsHandler(app, evt);
        end

        %-----------------------------------------------------------------%
        function jsBackDoor_Customizations(app, tabIndex)
            persistent customizationStatus
            if isempty(customizationStatus)
                customizationStatus = [false, false, false, false];
            end

            switch tabIndex
                case 0
                    sendEventToHTMLSource(app.jsBackDoor, 'startup', app.executionMode);
                    app.progressDialog  = ccTools.ProgressDialog(app.jsBackDoor);
                    customizationStatus = [false, false, false, false];

                otherwise
                    if customizationStatus(tabIndex)
                        return
                    end

                    appName = class(app);

                    customizationStatus(tabIndex) = true;
                    switch tabIndex
                        case 1 % FILE
                            elToModify = {app.popupContainerGrid, ...
                                          app.file_Tree,          ...
                                          app.file_Metadata};                % ui.TextView

                            elDataTag  = ui.CustomizationBase.getElementsDataTag(elToModify);
                            if ~isempty(elDataTag)
                                sendEventToHTMLSource(app.jsBackDoor, 'initializeComponents', {                                                           ...
                                    struct('appName', appName, 'dataTag', elDataTag{1}, 'style',    struct('backgroundColor', 'rgba(255,255,255,0.65)')), ...
                                    struct('appName', appName, 'dataTag', elDataTag{2}, 'listener', struct('componentName', 'mainApp.file_Tree', 'keyEvents', {{'Delete', 'Backspace'}})), ...
                                });

                                ui.TextView.startup(app.jsBackDoor, elToModify{3}, appName);
                            end

                        otherwise
                            % Customização dos módulos que são renderizados
                            % nesta figura são controladas pelos próprios
                            % módulos.
                    end
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % INICIALIZAÇÃO DO APP
        %-----------------------------------------------------------------%
        function startup_timerCreation(app)
            app.timerObj = timer("ExecutionMode", "fixedSpacing", ...
                                 "StartDelay",    1.5,            ...
                                 "Period",        .1,             ...
                                 "TimerFcn",      @(~,~)app.startup_timerFcn);
            start(app.timerObj)
        end

        %-----------------------------------------------------------------%
        function startup_timerFcn(app)
            if ccTools.fcn.UIFigureRenderStatus(app.UIFigure)
                stop(app.timerObj)
                delete(app.timerObj)

                jsBackDoor_Initialization(app)
            end
        end

        %-----------------------------------------------------------------%
        function startup_Controller(app)
            drawnow
            
            % Essa propriedade registra o tipo de execução da aplicação, podendo
            % ser: 'built-in', 'desktopApp' ou 'webApp'.
            app.executionMode = appUtil.ExecutionMode(app.UIFigure);
            if ~strcmp(app.executionMode, 'webApp')
                app.FigurePosition.Visible = 1;
                appUtil.winMinSize(app.UIFigure, class.Constants.windowMinSize)
            end

            % Identifica o local deste arquivo .MLAPP, caso se trate das versões 
            % "built-in" ou "webapp", ou do .EXE relacionado, caso se trate da
            % versão executável (neste caso, o ctfroot indicará o local do .MLAPP).
            MFilePath = fileparts(mfilename('fullpath'));
            app.rootFolder = appUtil.RootFolder(class.Constants.appName, MFilePath);

            % Customizações...
            jsBackDoor_Customizations(app, 0)
            jsBackDoor_Customizations(app, 1)

            startup_ConfigFileRead(app, MFilePath)
            startup_AppProperties(app)
            startup_GUIComponents(app)

            sendEventToHTMLSource(app.jsBackDoor, 'turningBackgroundColorInvisible', struct('componentName', 'SplashScreen', 'componentDataTag', struct(app.SplashScreen).Controller.ViewModel.Id));
            drawnow

            % Por fim, exclui-se o splashscreen.
            if isvalid(app.popupContainerGrid)
                pause(1)
                delete(app.popupContainerGrid)
            end
        end

        %-----------------------------------------------------------------%
        function startup_ConfigFileRead(app, MFilePath)
            % "GeneralSettings.json"
            [app.General_I, msgWarning] = appUtil.generalSettingsLoad(class.Constants.appName, app.rootFolder);
            if ~isempty(msgWarning)
                appUtil.modalWindow(app.UIFigure, 'error', msgWarning);
            end

            % Para criação de arquivos temporários, cria-se uma pasta da 
            % sessão.
            tempDir = tempname;
            mkdir(tempDir)
            app.General_I.fileFolder.tempPath  = tempDir;
            app.General_I.fileFolder.MFilePath = MFilePath;

            switch app.executionMode
                case 'webApp'
                    % Força a exclusão do SplashScreen do MATLAB Web Server.
                    sendEventToHTMLSource(app.jsBackDoor, "delProgressDialog");

                    % Webapp também não suporta outras janelas, de forma que os 
                    % módulos auxiliares devem ser abertos na própria janela
                    % do appAnalise.
                    app.dockModule_Undock.Visible     = 0;

                    app.General_I.operationMode.Debug = false;
                    app.General_I.operationMode.Dock  = true;
                    
                    % A pasta do usuário não é configurável, mas obtida por 
                    % meio de chamada a uiputfile. 
                    app.General_I.fileFolder.userPath = tempDir;

                    % A renderização do plot no MATLAB WebServer, enviando-o à uma 
                    % sessão do webapp como imagem Base64, é crítica por depender 
                    % das comunicações WebServer-webapp e WebServer-BaseMapServer. 
                    % Ao configurar o Basemap como "none", entretanto, elimina-se a 
                    % necessidade de comunicação com BaseMapServer, além de tornar 
                    % mais eficiente a comunicação com webapp porque as imagens
                    % Base64 são menores (uma imagem com Basemap "sattelite" pode 
                    % ter 500 kB, enquanto uma imagem sem Basemap pode ter 25 kB).
                    app.General_I.Plot.GeographicAxes.Basemap = 'none';

                otherwise    
                    % Resgata a pasta de trabalho do usuário (configurável).
                    userPaths = appUtil.UserPaths(app.General_I.fileFolder.userPath);
                    app.General_I.fileFolder.userPath = userPaths{end};

                    switch app.executionMode
                        case 'desktopStandaloneApp'
                            app.General_I.operationMode.Debug = false;
                        case 'MATLABEnvironment'
                            app.General_I.operationMode.Debug = true;
                    end
            end

            app.General            = app.General_I;        
            app.General.AppVersion = util.getAppVersion(app.rootFolder, MFilePath, tempDir); % RFDataHub lido aqui

            % Leitura de arquivo "IBGE.mat", salvando-o em memória como 
            % variável global.
            [~, msgError] = gpsLib.checkIfIBGEIsGlobal();
            if ~isempty(msgError)
                switch app.executionMode
                    case 'MATLABEnvironment'
                        msgQuestion = sprintf(['Erro na leitura da base de dados "IBGE"\n%s\n\nEsse problema pode ' ...
                                               'ser resolvido mapeando "SupportPackages" no path do MATLAB'], msgError);
                    otherwise
                        msgQuestion = sprintf(['Erro na leitura da base de dados "IBGE"\n%s\n\nEsse problema pode ' ...
                                               'ser resolvido apagando manualmente a pasta %s'], msgError, ctfroot);
                end

                appUtil.modalWindow(app.UIFigure, 'uiconfirm', msgQuestion, {'OK'}, 1, 1);
                closeFcn(app)
            end
        end

        %-----------------------------------------------------------------%
        function startup_AppProperties(app)
            % ...
        end

        %-----------------------------------------------------------------%
        function startup_GUIComponents(app)
            % Objeto que conecta o TabGroup ao GraphicMenu.
            app.tabGroupController = tabGroupGraphicMenu(app.menu_Grid, app.TabGroup, app.progressDialog, @app.jsBackDoor_Customizations, []);
            addComponent(app.tabGroupController, "Built-in", "",                      app.menu_Button1, "AlwaysOn", struct('On', 'OpenFile_32Yellow.png', 'Off', 'OpenFile_32White.png'), matlab.graphics.GraphicsPlaceholder, 1)
            addComponent(app.tabGroupController, "External", "auxApp.winPropagation", app.menu_Button2, "AlwaysOn", struct('On', 'Playback_32Yellow.png', 'Off', 'Playback_32White.png'), app.menu_Button1,                    2)
            addComponent(app.tabGroupController, "External", "auxApp.winRFDataHub",   app.menu_Button3, "AlwaysOn", struct('On', 'mosaic_32Yellow.png',   'Off', 'mosaic_32White.png'),   app.menu_Button1,                    3)
            addComponent(app.tabGroupController, "External", "auxApp.winConfig",      app.menu_Button4, "AlwaysOn", struct('On', 'Settings_36Yellow.png', 'Off', 'Settings_36White.png'), app.menu_Button1,                    4)

            % Alerta, caso não tenha sido feito mapemanto de pasta do sharepoint.
            DataHubWarningLamp(app)
        end

        %-----------------------------------------------------------------%
        function DataHubWarningLamp(app)
            if isfolder(app.General.fileFolder.DataHub_POST)
                app.DataHubLamp.Visible = 0;
            else
                app.DataHubLamp.Visible = 1;
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % TABGROUPCONTROLLER
        %-----------------------------------------------------------------%
        function hAuxApp = auxAppHandle(app, auxAppName)
            arguments
                app
                auxAppName string {mustBeMember(auxAppName, ["PROPAGATION", "RFDATAHUB", "CONFIG"])}
            end

            hAuxApp = app.tabGroupController.Components.appHandle{app.tabGroupController.Components.Tag == auxAppName};
        end

        %-----------------------------------------------------------------%
        function inputArguments = auxAppInputArguments(app, auxAppName)
            arguments
                app
                auxAppName char {mustBeMember(auxAppName, {'FILE', 'PROPAGATION', 'RFDATAHUB', 'CONFIG'})}
            end
            
            [auxAppIsOpen, ...
             auxAppHandle] = checkStatusModule(app.tabGroupController, auxAppName);

            inputArguments = {app};

            switch auxAppName
                case {'PROPAGATION', 'RFDATAHUB'}
                    if auxAppIsOpen
                        filterTable         = auxAppHandle.filterTable;
                        rfDataHubAnnotation = auxAppHandle.rfDataHubAnnotation;
                        inputArguments      = {app, filterTable, rfDataHubAnnotation};
                    end
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)

            try
                % WARNING MESSAGES
                appUtil.disablingWarningMessages()

                % <GUI>
                app.popupContainerGrid.Layout.Row = [1,2];
                app.GridLayout.RowHeight = {44, '1x'};
                % </GUI>

                appUtil.winPosition(app.UIFigure)
                startup_timerCreation(app)

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end
            
        end

        % Close request function: UIFigure
        function closeFcn(app, event)

            % Aspectos gerais (comum em todos os apps):
            appUtil.beforeDeleteApp(app.progressDialog, app.General_I.fileFolder.tempPath, app.tabGroupController, app.executionMode)
            delete(app)
            
        end

        % Value changed function: menu_Button1, menu_Button2, 
        % ...and 2 other components
        function menu_mainButtonPushed(app, event)

            clickedButton  = event.Source;
            auxAppTag      = clickedButton.Tag;

            inputArguments = auxAppInputArguments(app, auxAppTag);
            openModule(app.tabGroupController, event.Source, event.PreviousValue, app.General, inputArguments{:})
            
        end

        % Image clicked function: dockModule_Close, dockModule_Undock
        function menu_DockButtonPushed(app, event)
            
            clickedButton = findobj(app.menu_Grid, 'Type', 'uistatebutton', 'Value', true);
            auxAppTag     = clickedButton.Tag;

            switch event.Source
                case app.dockModule_Undock
                    appGeneral = app.General;
                    appGeneral.operationMode.Dock = false;

                    inputArguments = auxAppInputArguments(app, auxAppTag);
                    closeModule(app.tabGroupController, auxAppTag, app.General)
                    openModule(app.tabGroupController, clickedButton, false, appGeneral, inputArguments{:})

                case app.dockModule_Close
                    closeModule(app.tabGroupController, auxAppTag, app.General)
            end

        end

        % Image clicked function: AppInfo, FigurePosition
        function menu_ToolbarImageCliced(app, event)

            switch event.Source
                case app.FigurePosition
                    app.UIFigure.Position(3:4) = class.Constants.windowSize;
                    appUtil.winPosition(app.UIFigure)

                case app.AppInfo
                    if isempty(app.AppInfo.Tag)
                        app.progressDialog.Visible = 'visible';
                        app.AppInfo.Tag = util.HtmlTextGenerator.AppInfo(app.General, app.rootFolder, app.executionMode, "popup");
                        app.progressDialog.Visible = 'hidden';
                    end

                    msgInfo = app.AppInfo.Tag;
                    appUtil.modalWindow(app.UIFigure, 'info', msgInfo);
            end

        end

        % Image clicked function: file_OpenFileButton
        function file_ButtonPushed_OpenFile(app, event)

            if app.General.operationMode.Simulation
                app.General.operationMode.Simulation = false;
                
                [projectFolder, ...
                 programDataFolder] = appUtil.Path(class.Constants.appName, app.rootFolder);
                simulationFolders   = {programDataFolder, projectFolder};

                for ii = 1:numel(simulationFolders)
                    filePath    = fullfile(simulationFolders{ii}, 'Simulation');    
                    listOfFiles = dir(filePath);
                    fileName    = {listOfFiles.name};
                    fileName    = fileName(endsWith(lower(fileName), '.mat'));

                    if ~isempty(fileName)
                        break
                    end
                end

            else
                [fileName, filePath] = uigetfile({'*.bin;*.dbm;*.mat', 'Binários (*.bin,*.dbm,*.mat)'; ...
                                                  '*.csv;*.sm1809',    'Textuais (*.csv,*.sm1809)'},   ...
                                                  '', app.General.fileFolder.lastVisited, 'MultiSelect', 'on');
                figure(app.UIFigure)
    
                if isequal(fileName, 0)
                    return
                elseif ~iscell(fileName)
                    fileName = {fileName};
                end
                misc_updateLastVisitedFolder(app, filePath)
            end

            file_OpenSelectedFiles(app, filePath, fileName)

        end

        % Button pushed function: file_SpecReadButton
        function file_ButtonPushed_SpecRead(app, event)
                        
            % <ReviewNote> EMD - 22/08/2024</ReviewNote>
            % Verificar se há ao menos um fluxo a ser lido...
            flag = false;
            for ii = 1:numel(app.metaData)
                if any([app.metaData(ii).Data.Enable])
                    flag = true;
                    break
                end
            end

            if ~flag
                appUtil.modalWindow(app.UIFigure, 'warning', 'Não há fluxo de informação a ser lido...');
                return
            end

            % Verifica se os módulos auxiliares abaixo descritos estão abertos.
            % - auxiliarWin1: winSignalAnalysis
            % - auxiliarWin2: winDriveTest
            if strcmp(auxAppStatus(app, 'RELER INFORMAÇÃO ESPECTRAL'), 'Não')
                return
            end

            % Reinicia a variável, caso não vazia...
            if ~isempty(app.specData)
                delete(app.specData)
                app.specData = model.SpecData.empty;
            end
           
            d = [];
            try
                d = appUtil.modalWindow(app.UIFigure, 'progressdlg', 'Em andamento...');
                app.specData = spectrumRead(app.specData, app.metaData, app, d);

                if isempty(app.UIAxes1)
                    startup_Axes(app)
                end
    
                % Habilita botões do menu principal - PLAYBACK, REPORT e MISC -
                % abrindo programaticamente o modo PLAYBACK.
                set(app.menu_Button2, 'Enable', 1, 'Value', 1)
                app.menu_Button3.Enable = 1;
                app.menu_Button4.Enable = 1;
                app.menu_Button5.Enable = 1;
                app.menu_Button6.Enable = 1;

                menu_mainButtonPushed(app, struct('Source', app.menu_Button2, 'PreviousValue', false))

                % Constroi a árvore de fluxos espectrais, deixando selecionado
                % o primeiro dos fluxos. E constroi a árvore de fluxos espectrais
                % que eventualmente foram incluídos em um projeto.
                play_TreeBuilding(app)
                app.play_Tree.SelectedNodes = app.play_Tree.Children(1).Children(1);
                report_TreeBuilding(app)
    
                % Desabilita botão, inviabilizando leitura do mesmo conjunto de
                % dados.
                app.file_SpecReadButton.Visible = 0;

            catch ME
                appUtil.modalWindow(app.UIFigure, 'error', getReport(ME));
                file_DataReaderError(app)
            end

            delete(d)

        end

        % Selection changed function: file_Tree
        function file_TreeSelectionChanged(app, event)
            
            currentSelectedFileIndex = [];

            if ~isempty(app.file_Tree.SelectedNodes)
                % Caso sejam selecionados nós de apenas um único arquivo,
                % apresentam-se os metadados relacionados à informação 
                % espectral, além de habilitar os botões do toolbar.

                idxFileList   = arrayfun(@(x) x.NodeData.idx1, app.file_Tree.SelectedNodes, "UniformOutput", false);
                idxFile       = unique(horzcat(idxFileList{:}));

                if isscalar(idxFile)
                    idxThreadList = arrayfun(@(x) x.NodeData.idx2, app.file_Tree.SelectedNodes, "UniformOutput", false);
                    idxThread     = idxThreadList{1};

                    for ii = 2:numel(idxThreadList)
                        idxThread = intersect(idxThread, idxThreadList{ii});
                    end

                    if ~isempty(idxThread)
                        currentSelectedFileIndex = struct('previousSelectedFileIndex',  idxFile, ...
                                                          'previousSelectedFileThread', idxThread);
                    end
                end
            end

            if isequal(app.file_Tree.UserData, currentSelectedFileIndex)
                % Não faz nada...

            elseif ~isempty(currentSelectedFileIndex)
                app.file_Tree.UserData = currentSelectedFileIndex;

                collapse(app.file_Tree)                        
                expand(app.file_Tree.Children(idxFile), 'all')
                scroll(app.file_Tree, app.file_Tree.SelectedNodes(end))

                ui.TextView.update(app.file_Metadata, util.HtmlTextGenerator.Thread(app.metaData, idxFile, idxThread));

            else
                app.file_Tree.UserData = struct('previousSelectedFileIndex', [], 'previousSelectedFileThread', []);
                ui.TextView.update(app.file_Metadata, '');
            end
            
        end

        % Menu selected function: file_ContextMenu_delTree1Node
        function file_ContextMenu_delTree1NodeSelected(app, event)
            % <ReviewNote>EMD - 14/08/2024</ReviewNote>
            idxTable = table('Size', [0, 3],                                ...
                             'VariableTypes', {'double', 'double', 'cell'}, ...
                             'VariableNames', {'level', 'idx1', 'idx2'});

            for ii = 1:numel(app.file_Tree.SelectedNodes)
                idx = find(idxTable.idx1 == app.file_Tree.SelectedNodes(ii).NodeData.idx1, 1);
                if isempty(idx)
                    idxTable(end+1,:)   = {app.file_Tree.SelectedNodes(ii).NodeData.level, app.file_Tree.SelectedNodes(ii).NodeData.idx1, {app.file_Tree.SelectedNodes(ii).NodeData.idx2}};
                else
                    idxTable(idx,[1,3]) = {min([idxTable{idx,1}, app.file_Tree.SelectedNodes(ii).NodeData.level]), {unique([cell2mat(idxTable{idx,3}), app.file_Tree.SelectedNodes(ii).NodeData.idx2])}};
                end
            end

            idxTable = sortrows(idxTable, 'idx1')

            for kk = height(idxTable):-1:1
                idx1 = idxTable.idx1(kk);
                idx2 = idxTable.idx2{kk};

                switch idxTable.level(kk)
                    case 1
                        delete(app.metaData(idx1))
                        app.metaData(idx1) = [];

                    otherwise
                        if isequal(idxTable.idx2{kk}, 1:numel(app.metaData(idx1).Data))
                            delete(app.metaData(idx1))
                            app.metaData(idx1) = [];
                        else
                            delete(app.metaData(idx1).Data(idx2))
                            app.metaData(idx1).Data(idx2)    = [];
                            app.metaData(idx1).Samples(idx2) = [];
                            app.metaData(idx1).Memory        = EstimatedMemory(app.metaData, idx1);
                        end
                end
            end
            
            file_TreeBuilding(app)

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Color = [0.9412 0.9412 0.9412];
            app.UIFigure.Position = [100 100 1244 660];
            app.UIFigure.Name = 'rfPreview';
            app.UIFigure.Icon = 'D:\InovaFiscaliza\matlab_rf_predition\src\resources\Icons\icon_48.png';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);
            app.UIFigure.HandleVisibility = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {44, '1x', 44};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Tooltip = {''};
            app.GridLayout.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = [1 2];
            app.TabGroup.Layout.Column = 1;

            % Create Tab1_File
            app.Tab1_File = uitab(app.TabGroup);
            app.Tab1_File.Title = 'FILE';

            % Create file_Grid
            app.file_Grid = uigridlayout(app.Tab1_File);
            app.file_Grid.ColumnWidth = {5, 320, '1x', 10, 304, 16, 5};
            app.file_Grid.RowHeight = {23, 3, 5, 22, 5, '1x', 5, 34};
            app.file_Grid.ColumnSpacing = 0;
            app.file_Grid.RowSpacing = 0;
            app.file_Grid.Padding = [0 0 0 24];
            app.file_Grid.BackgroundColor = [1 1 1];

            % Create file_TitleGrid
            app.file_TitleGrid = uigridlayout(app.file_Grid);
            app.file_TitleGrid.ColumnWidth = {18, '1x'};
            app.file_TitleGrid.RowHeight = {23};
            app.file_TitleGrid.ColumnSpacing = 3;
            app.file_TitleGrid.RowSpacing = 0;
            app.file_TitleGrid.Padding = [2 0 0 0];
            app.file_TitleGrid.Tag = 'COLORLOCKED';
            app.file_TitleGrid.Layout.Row = 1;
            app.file_TitleGrid.Layout.Column = 2;
            app.file_TitleGrid.BackgroundColor = [0.749 0.749 0.749];

            % Create file_TitleIcon
            app.file_TitleIcon = uiimage(app.file_TitleGrid);
            app.file_TitleIcon.ScaleMethod = 'none';
            app.file_TitleIcon.Layout.Row = 1;
            app.file_TitleIcon.Layout.Column = 1;
            app.file_TitleIcon.HorizontalAlignment = 'left';
            app.file_TitleIcon.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'addFiles_18.png');

            % Create file_Title
            app.file_Title = uilabel(app.file_TitleGrid);
            app.file_Title.FontSize = 11;
            app.file_Title.Layout.Row = 1;
            app.file_Title.Layout.Column = 2;
            app.file_Title.Text = 'ARQUIVOS';

            % Create file_TitleGridLine
            app.file_TitleGridLine = uiimage(app.file_Grid);
            app.file_TitleGridLine.ScaleMethod = 'none';
            app.file_TitleGridLine.Layout.Row = 2;
            app.file_TitleGridLine.Layout.Column = 2;
            app.file_TitleGridLine.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineH.svg');

            % Create file_TreeLabel
            app.file_TreeLabel = uilabel(app.file_Grid);
            app.file_TreeLabel.VerticalAlignment = 'bottom';
            app.file_TreeLabel.FontSize = 10;
            app.file_TreeLabel.Layout.Row = 4;
            app.file_TreeLabel.Layout.Column = 2;
            app.file_TreeLabel.Text = 'LISTA DE ARQUIVOS';

            % Create file_Tree
            app.file_Tree = uitree(app.file_Grid);
            app.file_Tree.Multiselect = 'on';
            app.file_Tree.SelectionChangedFcn = createCallbackFcn(app, @file_TreeSelectionChanged, true);
            app.file_Tree.FontSize = 10;
            app.file_Tree.Layout.Row = 6;
            app.file_Tree.Layout.Column = [2 3];

            % Create file_MetadataLabel
            app.file_MetadataLabel = uilabel(app.file_Grid);
            app.file_MetadataLabel.VerticalAlignment = 'bottom';
            app.file_MetadataLabel.FontSize = 10;
            app.file_MetadataLabel.Layout.Row = 4;
            app.file_MetadataLabel.Layout.Column = 5;
            app.file_MetadataLabel.Text = 'METADADOS';

            % Create file_Metadata
            app.file_Metadata = uilabel(app.file_Grid);
            app.file_Metadata.VerticalAlignment = 'top';
            app.file_Metadata.WordWrap = 'on';
            app.file_Metadata.FontSize = 11;
            app.file_Metadata.Layout.Row = 6;
            app.file_Metadata.Layout.Column = [5 6];
            app.file_Metadata.Interpreter = 'html';
            app.file_Metadata.Text = '';

            % Create file_toolGrid
            app.file_toolGrid = uigridlayout(app.file_Grid);
            app.file_toolGrid.ColumnWidth = {22, 110, '1x', 110};
            app.file_toolGrid.RowHeight = {3, 17, 2};
            app.file_toolGrid.ColumnSpacing = 5;
            app.file_toolGrid.RowSpacing = 0;
            app.file_toolGrid.Padding = [5 6 5 6];
            app.file_toolGrid.Layout.Row = 8;
            app.file_toolGrid.Layout.Column = [1 7];

            % Create file_OpenFileButton
            app.file_OpenFileButton = uiimage(app.file_toolGrid);
            app.file_OpenFileButton.ScaleMethod = 'none';
            app.file_OpenFileButton.ImageClickedFcn = createCallbackFcn(app, @file_ButtonPushed_OpenFile, true);
            app.file_OpenFileButton.Tooltip = {'Seleciona arquivos'};
            app.file_OpenFileButton.Layout.Row = 2;
            app.file_OpenFileButton.Layout.Column = 1;
            app.file_OpenFileButton.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Import_16.png');

            % Create file_SpecReadButton
            app.file_SpecReadButton = uibutton(app.file_toolGrid, 'push');
            app.file_SpecReadButton.ButtonPushedFcn = createCallbackFcn(app, @file_ButtonPushed_SpecRead, true);
            app.file_SpecReadButton.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Run_24.png');
            app.file_SpecReadButton.IconAlignment = 'right';
            app.file_SpecReadButton.HorizontalAlignment = 'right';
            app.file_SpecReadButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.file_SpecReadButton.FontSize = 11;
            app.file_SpecReadButton.Visible = 'off';
            app.file_SpecReadButton.Layout.Row = [1 3];
            app.file_SpecReadButton.Layout.Column = 4;
            app.file_SpecReadButton.Text = 'Inicia análise';

            % Create Tab2_Playback
            app.Tab2_Playback = uitab(app.TabGroup);
            app.Tab2_Playback.AutoResizeChildren = 'off';
            app.Tab2_Playback.Title = 'PREDICTION';

            % Create Tab5_RFDataHub
            app.Tab5_RFDataHub = uitab(app.TabGroup);
            app.Tab5_RFDataHub.Title = 'RFDATAHUB';

            % Create Tab6_Config
            app.Tab6_Config = uitab(app.TabGroup);
            app.Tab6_Config.Title = 'CONFIG';

            % Create menu_Grid
            app.menu_Grid = uigridlayout(app.GridLayout);
            app.menu_Grid.ColumnWidth = {28, 5, 28, 5, 28, 28, '1x', 20, 20, 20, 20, 0, 0};
            app.menu_Grid.RowHeight = {7, 20, 7};
            app.menu_Grid.ColumnSpacing = 5;
            app.menu_Grid.RowSpacing = 0;
            app.menu_Grid.Padding = [5 5 5 5];
            app.menu_Grid.Tag = 'COLORLOCKED';
            app.menu_Grid.Layout.Row = 1;
            app.menu_Grid.Layout.Column = 1;
            app.menu_Grid.BackgroundColor = [0.2 0.2 0.2];

            % Create menu_Button1
            app.menu_Button1 = uibutton(app.menu_Grid, 'state');
            app.menu_Button1.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button1.Tag = 'FILE';
            app.menu_Button1.Tooltip = {'Leitura de arquivos'};
            app.menu_Button1.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'OpenFile_32Yellow.png');
            app.menu_Button1.IconAlignment = 'top';
            app.menu_Button1.Text = '';
            app.menu_Button1.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button1.FontSize = 11;
            app.menu_Button1.Layout.Row = [1 3];
            app.menu_Button1.Layout.Column = 1;
            app.menu_Button1.Value = true;

            % Create menu_Separator1
            app.menu_Separator1 = uiimage(app.menu_Grid);
            app.menu_Separator1.ScaleMethod = 'none';
            app.menu_Separator1.Enable = 'off';
            app.menu_Separator1.Layout.Row = [1 3];
            app.menu_Separator1.Layout.Column = 2;
            app.menu_Separator1.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create menu_Button2
            app.menu_Button2 = uibutton(app.menu_Grid, 'state');
            app.menu_Button2.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button2.Tag = 'PROPAGATION';
            app.menu_Button2.Tooltip = {'Propagação'};
            app.menu_Button2.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Playback_32White.png');
            app.menu_Button2.IconAlignment = 'top';
            app.menu_Button2.Text = '';
            app.menu_Button2.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button2.FontSize = 11;
            app.menu_Button2.Layout.Row = [1 3];
            app.menu_Button2.Layout.Column = 3;

            % Create menu_Separator2
            app.menu_Separator2 = uiimage(app.menu_Grid);
            app.menu_Separator2.ScaleMethod = 'none';
            app.menu_Separator2.Enable = 'off';
            app.menu_Separator2.Layout.Row = [1 3];
            app.menu_Separator2.Layout.Column = 4;
            app.menu_Separator2.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'LineV_White.svg');

            % Create menu_Button3
            app.menu_Button3 = uibutton(app.menu_Grid, 'state');
            app.menu_Button3.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button3.Tag = 'RFDATAHUB';
            app.menu_Button3.Tooltip = {'RFDataHub'};
            app.menu_Button3.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'mosaic_32White.png');
            app.menu_Button3.IconAlignment = 'top';
            app.menu_Button3.Text = '';
            app.menu_Button3.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button3.FontSize = 11;
            app.menu_Button3.Layout.Row = [1 3];
            app.menu_Button3.Layout.Column = 5;

            % Create menu_Button4
            app.menu_Button4 = uibutton(app.menu_Grid, 'state');
            app.menu_Button4.ValueChangedFcn = createCallbackFcn(app, @menu_mainButtonPushed, true);
            app.menu_Button4.Tag = 'CONFIG';
            app.menu_Button4.Tooltip = {'Configurações gerais'};
            app.menu_Button4.Icon = fullfile(pathToMLAPP, 'resources', 'Icons', 'Settings_36White.png');
            app.menu_Button4.IconAlignment = 'top';
            app.menu_Button4.Text = '';
            app.menu_Button4.BackgroundColor = [0.2 0.2 0.2];
            app.menu_Button4.FontSize = 11;
            app.menu_Button4.Layout.Row = [1 3];
            app.menu_Button4.Layout.Column = 6;

            % Create jsBackDoor
            app.jsBackDoor = uihtml(app.menu_Grid);
            app.jsBackDoor.Layout.Row = [1 3];
            app.jsBackDoor.Layout.Column = 8;

            % Create FigurePosition
            app.FigurePosition = uiimage(app.menu_Grid);
            app.FigurePosition.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.FigurePosition.Visible = 'off';
            app.FigurePosition.Tooltip = {'Reposiciona janela'};
            app.FigurePosition.Layout.Row = 2;
            app.FigurePosition.Layout.Column = 10;
            app.FigurePosition.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'layout1_32White.png');

            % Create AppInfo
            app.AppInfo = uiimage(app.menu_Grid);
            app.AppInfo.ImageClickedFcn = createCallbackFcn(app, @menu_ToolbarImageCliced, true);
            app.AppInfo.Tooltip = {'Informações gerais'};
            app.AppInfo.Layout.Row = 2;
            app.AppInfo.Layout.Column = 11;
            app.AppInfo.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Dots_32White.png');

            % Create dockModule_Undock
            app.dockModule_Undock = uiimage(app.menu_Grid);
            app.dockModule_Undock.ScaleMethod = 'none';
            app.dockModule_Undock.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Undock.Tag = 'DRIVETEST';
            app.dockModule_Undock.Tooltip = {'Reabre módulo em outra janela'};
            app.dockModule_Undock.Layout.Row = 2;
            app.dockModule_Undock.Layout.Column = 12;
            app.dockModule_Undock.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Undock_18White.png');

            % Create dockModule_Close
            app.dockModule_Close = uiimage(app.menu_Grid);
            app.dockModule_Close.ScaleMethod = 'none';
            app.dockModule_Close.ImageClickedFcn = createCallbackFcn(app, @menu_DockButtonPushed, true);
            app.dockModule_Close.Tag = 'DRIVETEST';
            app.dockModule_Close.Tooltip = {'Fecha módulo'};
            app.dockModule_Close.Layout.Row = 2;
            app.dockModule_Close.Layout.Column = 13;
            app.dockModule_Close.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'Delete_12SVG_white.svg');

            % Create DataHubLamp
            app.DataHubLamp = uilamp(app.menu_Grid);
            app.DataHubLamp.Enable = 'off';
            app.DataHubLamp.Visible = 'off';
            app.DataHubLamp.Tooltip = {'Pendente mapear pasta do Sharepoint'};
            app.DataHubLamp.Layout.Row = 2;
            app.DataHubLamp.Layout.Column = 9;
            app.DataHubLamp.Color = [1 0 0];

            % Create popupContainerGrid
            app.popupContainerGrid = uigridlayout(app.GridLayout);
            app.popupContainerGrid.ColumnWidth = {'1x', 880, '1x'};
            app.popupContainerGrid.RowHeight = {'1x', 300, '1x'};
            app.popupContainerGrid.Layout.Row = 3;
            app.popupContainerGrid.Layout.Column = 1;
            app.popupContainerGrid.BackgroundColor = [1 1 1];

            % Create SplashScreen
            app.SplashScreen = uiimage(app.popupContainerGrid);
            app.SplashScreen.Layout.Row = 2;
            app.SplashScreen.Layout.Column = 2;
            app.SplashScreen.ImageSource = fullfile(pathToMLAPP, 'resources', 'Icons', 'SplashScreen.gif');

            % Create file_ContextMenu_Tree
            app.file_ContextMenu_Tree = uicontextmenu(app.UIFigure);

            % Create file_ContextMenu_delTree1Node
            app.file_ContextMenu_delTree1Node = uimenu(app.file_ContextMenu_Tree);
            app.file_ContextMenu_delTree1Node.MenuSelectedFcn = createCallbackFcn(app, @file_ContextMenu_delTree1NodeSelected, true);
            app.file_ContextMenu_delTree1Node.ForegroundColor = [1 0 0];
            app.file_ContextMenu_delTree1Node.Text = 'Excluir';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = winRFPreview_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
