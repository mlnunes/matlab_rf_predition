function [Lb, Pwr_rx] = predicao_area(fileData)
    %----------------------------------------------------------------------
    % Calcula a predição e cobertura de uma área
    %
    % fileData: arquivo que contém a estrutura com parâmetros da predição
    %       dadosPredicao: nome da struct
    %               modelo de predição: ['Hata', 'P.1812']
    %               frequencia: frequência da análise (Hz)
    %               dadosRelevo: arquivo geotif com dados de elevação em metros da
    %                   área de análise 
    %               dadosClutter: arquivo geotif com dados de classificação
    %                   da cobertura do terreno na área de análise
    %               Movel:
    %                   Antena:
    %                       Altura: altura da antena (m)
    %               Base:
    %                   Nome: nome da estação
    %                   Latitude: latitude da estação (graus decimais)
    %                   Longitude: longitude da estação (graus decimais)
    %                   Potencia: potência do transmissor (W)
    %                   Antena:
    %                       Altura: altura da antena (m)
    %                       ArquivoDados: arquivo de informações e diagrama
    %                       de irradiação da antena
    %                       Modelo: nome do modelo da antena
    %                       Funcao: ['TX', 'RX']
    %                       Azimute: azimute a antena
    %                       tiltMecanico: inclinação da antena
    %                       Tipo: ['isotropic', 'array']
    %
    %   Lb: matriz de valores de atenuação calculada para cada célula do
    %       geotif da área de análise (dB)
    %   Pwr_rx: matriz de valores de nível de sinal recebido calculado para
    %           cada célula do geotif da área de análise
    %----------------------------------------------------------------------
   
    arguments
        fileData {mustBeFile}
    end
    
    %----------------------------------------------------------------------
    % Carrega os parâmetros utilizados para realizar a predição
    run(fileData);

    modelo = dadosPredicao.modeloPredicao;

    %----------------------------------------------------------------------
    % Dados da estação base
    base = txsite("Name", dadosPredicao.Base.Nome,...
        "Latitude", dadosPredicao.Base.Latitude,...
        "Longitude", dadosPredicao.Base.Longitude,...
        "Antenna", dadosPredicao.Base.Antena.Tipo,...
        "AntennaHeight", dadosPredicao.Base.Antena.Altura,...
        "TransmitterFrequency", dadosPredicao.frequencia,...
        "TransmitterPower", dadosPredicao.Base.Potencia);
    
    % Carrega os dados da antena
    
    antenaBase = utils.readAntennaData(dadosPredicao.Base.Antena.ArquivoDados, dadosPredicao.Base.Antena.Modelo,...
        dadosPredicao.Base.Antena.Funcao, dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico);

    %----------------------------------------------------------------------
    % Caracteristicas da area
    % Carrega dados do relevo
    [A, R] = utils.loadRaster(dadosPredicao.dadosRelevo, true);

    %--------------------------------------------------------------------------
    % Carrega dados do clutter, se não houver arqivo de clutter uma matriz
    % default com representação área aberta/rural
    if ~isempty(dadosPredicao.dadosClutter)
    
        [C, S] = utils.read_clutter(dadosPredicao.dadosClutter);
    
    else
       
        C = 2 * ones(size(A));
        S = R;
    
    end
    
    % C = double(C);
    
    %--------------------------------------------------------------------------
    % Cria variáveis de saída
    Pwr_rx = zeros(size(A));
    Lb = zeros(size(A));
    
    %--------------------------------------------------------------------------
    % elevação da estação Base
    [n, m] = utils.get_raster_idx(base.Latitude, base.Longitude, R);
    elevBase = A(n, m);
    
    %--------------------------------------------------------------------------
    % Prepara loop de execução para carregar as coordenadas do centro de todas 
    % as células
    centro_i =  -R.CellExtentInLatitude / 2;
    centro_j =  R.CellExtentInLongitude / 2;
    latitudes = R.LatitudeLimits(2):...
        -R.CellExtentInLatitude:...
        R.LatitudeLimits(1);
    latitudes = latitudes + centro_i;
    longitudes = R.LongitudeLimits(1):...
        R.CellExtentInLongitude:...
        R.LongitudeLimits(2);
    longitudes = longitudes + centro_j;
    Llat = numel(latitudes) - 1;
    Llon = numel(longitudes) - 1;

    %--------------------------------------------------------------------------
    % Inicializa o loop com dados da primeira célula 
    RX = rxsite("Latitude",latitudes(1), ...
               "Longitude", longitudes(1), ...
               "AntennaHeight",dadosPredicao.Movel.Antena.Altura);

    %--------------------------------------------------------------------------
    % Inicializas a classe de predição conforme o modelo a ser utilizado
    switch modelo
        case 'Hata'
            predicao = model.Hata(base, RX, A, R, C, S);

        case 'P.1812'
           predicao = model.P1812(base, RX, A, R, C, S);

        otherwise
            error("Modelo não implementado");
    end
    %--------------------------------------------------------------------------
    % Cria barra de progresso
    d = uiprogressdlg(uifigure);
    
    %--------------------------------------------------------------------------
    % Loop de execução
    
    m = 1;


    for n = 1:Llat
 
        percent_exec = ((n - 1) * Llon + m)/(Llat * Llon);
        d.Message = sprintf('Executado: %.1f %%', (percent_exec * 100));
        d.Value = percent_exec;
        
        for m = 1:Llon
        
            RX.Latitude = latitudes(n);
            RX.Longitude = longitudes(m);
            
            %------------------------------------------------------------------
            % encontra distancia, azimute e inclinação do ponto em relação a
            % estação TX
            [distanciaPonto, azimutePonto] = utils.Propagation.Distance(base, RX, "m");
            inclinacaoPonto = rad2deg(atan(((RX.AntennaHeight + A(n, m)) - (base.AntennaHeight + elevBase)) / distanciaPonto));
            
            %------------------------------------------------------------------
            % extrai os dados de ganho na direção do ponto
            [gH, gV] = antenaBase.ganhoDirecao(azimutePonto, inclinacaoPonto);
            gAnt = antenaBase.Ganho - gH - gV;
            
            %------------------------------------------------------------------
            % calcula a atenuação e nível de sinal recebido
            predicao.siteRX = RX;
            calculo(predicao, gAnt);
            Lb(n, m) = predicao.Lb;
            Pwr_rx(n, m) = predicao.PRX;
            
        end
            
    end
    close(d)
end