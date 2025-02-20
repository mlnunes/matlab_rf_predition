function plot_perfil(fileData, latRX, lonRX)
    %----------------------------------------------------------------------
    % Traça o grafico do perfil do terreno, posiçao das estaçoes, linha de
    % visada e primeira zona de Fresnel
    % 
    % TX: classe TX
    % RX: classe RX
    % A, R: geotiff elevação
    % C, S: geotiff clutter
    %----------------------------------------------------------------------
    % validação dos argumentos

    arguments
        fileData
        latRX double
        lonRX double
    end

    %----------------------------------------------------------------------
    % Carrega os parâmetros utilizados para realizar a predição
    run(fileData)

    %----------------------------------------------------------------------
    % Carrega o modelo de predição a ser empregado
    modelo = dadosPredicao.modeloPredicao;
    
    %----------------------------------------------------------------------
    % Dados da estação TX
    TX = txsite("Name", dadosPredicao.Base.Nome,...
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
    % Dados da estaçao RX
    RX = rxsite("Latitude",latRX, ...
               "Longitude", lonRX, ...
               "AntennaHeight", dadosPredicao.Movel.Antena.Altura);

   
    %---------------------------------------------------------------------
    %levanta o perfil das elevações e clutter do terreno
    [distancias, elevacoes, clutter ] = utils.levanta_perfil(TX, RX, A, R, C, S);
    elevTX = elevacoes(1);
    elevRX = elevacoes(end);

    %----------------------------------------------------------------------
    % utiliza apenas região limitada pela mínima e máxima elevações
    min_elevacao = min(elevacoes);
    distancias_km = distancias * 1000;
    
    %-----------------------------------------------------------------------b
    % cálculo do elipsoide da primeira zona de Fresnel
    % F: vetor raio do elipsoide
    % Fl: limite inferior do elipsoide em relação a linha de visada
    % Fu: limite superior do elipsoide em relação a linha de visada

    lambda = physconst("LightSpeed") / TX.TransmitterFrequency;
    F = sqrt(lambda * distancias_km.* ...
        (distancias_km(end) - distancias_km) / (distancias_km(end)));
    
    Fl = ((elevacoes(end) + RX.AntennaHeight - elevTX)/...
        distancias_km(end)) * distancias_km + elevTX - F;

    Fu = ((elevacoes(end) + RX.AntennaHeight - elevTX)/...
        distancias_km(end)) * distancias_km + elevTX + F;

    %--------------------------------------------------------------
    % calcula o array de alturas adicional conforme a classificação
    % de clutter REC P1812.7 seção 3.2.1, tabela 2
    alturas_clutter = clutter;
    alturas_clutter(ismember(alturas_clutter, [1 2])) = 0;
    alturas_clutter(alturas_clutter == 3) = 10;
    alturas_clutter(alturas_clutter == 4) = 15;
    alturas_clutter(alturas_clutter == 5) = 20;

    %----------------------------------------------------------------------
    % cálculo da intensidade campo recebida ao longo dos enlace
    num_pts = 500;
    distancias_enlace = linspace(0, distancias(end), num_pts);
    latitudes_enlace = linspace(TX.Latitude, RX.Latitude, num_pts);
    longitudes_enlace = linspace(TX.Longitude, RX.Longitude, num_pts);
    E_enlace = zeros(1, num_pts);
    RX_enlace = RX;
    
    %--------------------------------------------------------------------------
    % Inicializas a classe de predição conforme o modelo a ser utilizado
    switch modelo
        case 'Hata'
            predicao = model.Hata(TX, RX_enlace, A, R, C, S);

        case 'P.1812'
           predicao = model.P1812(TX, RX_enlace, A, R, C, S);

        otherwise
            error("Modelo não implementado");
    end
    
    %----------------------------------------------------------------------
    % loop de varredura no pontos do enlace
    for idx = 2:num_pts
        
        %----------------------------------------------------------------------
        % Carrega as coordenadas da ponto de comparação
        RX_enlace.Latitude = latitudes_enlace(idx);
        RX_enlace.Longitude = longitudes_enlace(idx);

        %------------------------------------------------------------------
        % encontra distancia, azimute e inclinação do ponto em relação a
        % estação TX
        [distanciaPonto, azimutePonto] = utils.Propagation.Distance(TX, RX_enlace, "m");
        [x, y] = utils.get_raster_idx(RX_enlace.Latitude, RX_enlace.Longitude, R);
        inclinacaoPonto = rad2deg(atan(((RX_enlace.AntennaHeight + A(x, y)) - (TX.AntennaHeight + elevTX)) / distanciaPonto));
        
        %------------------------------------------------------------------
        % extrai os dados de ganho na direção do ponto
        [gH, gV] = antenaBase.ganhoDirecao(azimutePonto, inclinacaoPonto);
        gAnt = antenaBase.Ganho - gH - gV;

        %----------------------------------------------------------------------
        % Executa o modelo de predição
        predicao.siteRX = RX_enlace;
        calculo(predicao, gAnt);
        E_enlace(idx) = predicao.PRX;
    
    end

    %----------------------------------------------------------------------
    % Calculo da antenuação no espaço livre TX-RX
    FSL = utils.Propagation.PathLoss(TX, RX, "Free space");
    
    %----------------------------------------------------------------------
    % Cálculo da antenuação total do enlace
    Atn = predicao.Lb;

    %----------------------------------------------------------------------
    % Definições da área do gráfico

    figure('Units', 'centimeters', 'Position', [1 1 60 7])
    hold on;
    yyaxis left
    ylabel('Elevações (m)')
    xlabel('distância (Km)')

    %----------------------------------------------------------------------
    % mapeia os valores de clutter com cores representativas
    
    cores = [hex2rgb('#007cff'); hex2rgb('#0bdc0b'); hex2rgb('#ff7f7f'); hex2rgb('#4fae00'); hex2rgb('#b3263e')];
    

    %----------------------------------------------------------------------
    % Plot do clutter
    
    for n = 1:(numel(distancias) - 1)
        fill([distancias(n) distancias(n) distancias(n+1) distancias(n+1)],...
            [elevacoes(n)  (elevacoes(n) + alturas_clutter(n)) ...
            (elevacoes(n) + alturas_clutter(n)) elevacoes(n)], ...
            cores(clutter(n),:), 'EdgeColor', 'none');
    end

    %----------------------------------------------------------------------
    % Plot do perfil de elevações
    area(distancias, elevacoes, 'FaceColor', '#90a2b5', 'EdgeColor', '#101010');
    ylim([min(min_elevacao, min(Fl)) inf])

    
    %----------------------------------------------------------------------
    % desenha a linha de visada
    plot([distancias(1) distancias(end)], [(elevTX + TX.AntennaHeight) ...
        (elevRX + RX.AntennaHeight)], 'Color', '#00f9ff');

    %----------------------------------------------------------------------
    % desenha os limites da primeira zona de Fresnel
    plot(distancias, Fl,'-.', 'Color', '#007cff');
    plot(distancias, Fu,'-.', 'Color', '#007cff');

    %----------------------------------------------------------------------
    % desenha o grafico de campo E recebido
    yyaxis right
    yticks(0:15:(1.5 * max(E_enlace)));
    ylabel('E (dBuV/m)')
    plot(distancias_enlace, E_enlace, 'Color', '#00ff88');

    %----------------------------------------------------------------------
    % define a cor de fundo
    ax = gca;
    ax.Color = 'white';
    
    hold off;

    %----------------------------------------------------------------------
    % Informações da simulação
    fprintf("Dados da simulação: modelo %s\n", modelo)
    fprintf("TX:\nAltitude: %.1f m\nCoord: %.5f %.5f\n",elevTX, TX.Longitude, TX.Latitude);
    fprintf("Frequência: %.1f MHz\n", TX.TransmitterFrequency/1e6)
    fprintf("Potência: %.1f W\n",TX.TransmitterPower)
    fprintf("Antena: %.1fm\n", TX.AntennaHeight)
    fprintf("\tGanho: %.1f dBi\n", antenaBase.Ganho)
    fprintf("\tMáxima potência irradiada, %.1f dBW\n", (10*log10(TX.TransmitterPower) + antenaBase.Ganho))
    fprintf("\tAzimute: %.1f°\t/ tilt: %.1f°\n", dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico)
    fprintf("\nRX:\nAltitude: %.1f m\nCoor: %.5f %.5f\n", elevRX, RX.Latitude, RX.Longitude)
    fprintf("Antena: %.1f m\n", RX.AntennaHeight)
    fprintf("Nível de sinal recebido: %.1f dBuV\n", E_enlace(end))
    fprintf("\nEnlace:\nDistancia: %.1f Km\n", distancias(end))
    fprintf("Angulos: V: %.2f° H: %.2f°\n", inclinacaoPonto, azimutePonto)
    fprintf("Padrão de atenuação da antena: V: %.2f dB H: %.2f dB\n", gV, gH)
    fprintf("Antenução no espaço livre: %.1f dB - Atenuação total: %.1f dB\n", FSL, Atn)
    fprintf("Atenuação do modelo: %.1f dB\n", (Atn - FSL + gAnt))



end