function predicao_area(fileData)
    arguments
        fileData {mustBeFile}
    end
    
    load(fileData, 'dadosPredicao');

    modelo = dadosPredicao.modeloPredicao;

    %----------------------------------------------------------------------
    % Dados da estação base
    freq = dadosPredicao.frequencia;
    base = txsite("Name", dadosPredicao.Base.Nome,...
        "Latitude", dadosPredicao.Base.Latitude,...
        "Longitude", dadosPredicao.Base.Longitude,...
        "Antenna", dadosPredicao.Base.Antena.Tipo,...
        "AntennaHeight", dadosPredicao.Base.Antena.Altura,...
        "TransmitterFrequency", dadosPredicao.frequencia,...
        "TransmitterPower", dadosPredicao.Base.Potencia);
    [baseX, baseY, baseZone] = utils.deg2utm(base.Latitude, base.Longitude);

    % Carrega os dados da antena
    antenaBase = utils.readAntennaData(dadosPredicao.Base.Antena.ArquivoDados, dadosPredicao.Base.Antena.Modelo,...
        dadosPredicao.Base.Antena.Funcao, dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico);

    %----------------------------------------------------------------------
    % Dados estaçao movel
    movel_hrx = dadosPredicao.Movel.Antena.Altura;

    %----------------------------------------------------------------------
    % Caracteristicas da area
    % Carrega dados do relevo
    [A, R] = readgeoraster(dadosPredicao.dadosRelevo);
    A = double(A);

    %--------------------------------------------------------------------------
    % Carrega dados do clutter, se não houver arqivo de clutter uma matriz
    % default com representação área aberta/rural
    if ~isempty(dadosPredicao.dadosClutter)
    
        [C, S] = utils.read_clutter(dadosPredicao.dadosClutter);
    
    else
       
        C = 2 * ones(size(A));
        S = R;
    
    end
    
    C = double(C);
    
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
               "AntennaHeight",movel_hrx);
    
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
            % eNB
            [distanciaPonto, azimutePonto] = utils.Propagation.Distance(base, RX, "m");
            inclinacaoPonto = rad2deg(atan(((RX.AntennaHeight + A(n, m)) - (base.AntennaHeight + elevBase)) / distanciaPonto));
            
            %------------------------------------------------------------------
            % extrai os dados de ganho na direção do ponto
            gMax = antenaBase.Ganho;
            [gH, gV] = antenaBase.ganhoDirecao(azimutePonto, inclinacaoPonto);
            
            %------------------------------------------------------------------
            % calcula a atenuação e nível de sinal recebido
            
            switch modelo
                case 'Hata'
                    elevRX = A(n, m);
                    predicao = model.Hata(base.TransmitterFrequency /1e6, ...
                        base.AntennaHeight, elevBase, movel_hrx, elevRX, distanciaPonto/1000);
                    Lb(n, m) = predicao.Lb;
                    Pwr_rx(n, m) = predicao.PRX;
                
                case 'P.1812'
                   predicao = model.P1812(base, RX, ...
                   A, R, C, S, baseX, baseY, baseZone, elevBase, 1, 50, 0, gH, gV, gMax);
                   Pwr_rx(n, m) = predicao.PRX; % + 11.97; converte dBuV/m p/ dBm
                   Lb(n ,m) = predicao.Lb;
                otherwise
                    break
            end
        end
            
    end

    %--------------------------------------------------------------------------
    % Mapa da mancha de prediçao
    figure
    axesm('MapProjection','mercator','MapLatLimit',R.LatitudeLimits+[-1 1])
    geoshow(Pwr_rx, R, DisplayType="texturemap")
    geoshow(base.Latitude,base.Longitude,DisplayType="point",ZData=elevBase, ...
        MarkerEdgeColor="k",MarkerFaceColor="c",MarkerSize=10,Marker="o")
    
    % cria um colormap do branco->amarelo->vermelho 
    cmap = zeros(256, 3);
    cmap(1:128, 1:2) = repmat([1 1], 128, 1);
    cmap(1:128, 3) = linspace(1, 0, 128);
    cmap(129:end, 1) = 1;
    cmap(129:end, 2) = linspace(1, 0, 128);

    colormap(cmap)
    colorbar
  
    text1 = dadosPredicao.Base.Nome;
    delta = 0.0005;
    textm(base.Latitude+delta,base.Longitude+delta,text1)
    cb = colorbar;
    cb.Label.String = "Intensidade de Campo (V/m)";

end