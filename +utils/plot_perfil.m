function plot_perfil(elevacoes, distancias, TX, RX, elevTX, elevRX, A, R)
    %----------------------------------------------------------------------
    % Traça o grafico do perfil do terreno, posiçao das estaçoes, linha de
    % visada e primeira zona de Fresnel
    % 
    % elevacoes: vetor de elevações à partir do TX em m
    % distancias: vetor de distancias à partir do TX em km
    % TX: classe TX
    % RX: classe RX
    % elevTX: elevação TX em m
    % elevRX: elevação RX em m
    %
    %----------------------------------------------------------------------
    % validação dos argumentos

    arguments
        elevacoes (1,:) double
        distancias (1,:) double
        TX txsite
        RX rxsite
        elevTX (1, 1) double {mustBePositive}
        elevRX (1, 1) double {mustBePositive}
        A (:, :) double
        R
    end
    
    %----------------------------------------------------------------------
    % utiliza apenas região limitada pela mínima e máxima elevações
    min_elevacao = min(elevacoes);
    distancias_km = distancias * 1000;
    
    %----------------------------------------------------------------------
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

    %----------------------------------------------------------------------
    % cálculo da intensidade campo recebida ao longo dos enlace
    num_pts = 500;
    distancias_enlace = linspace(0, distancias(end), num_pts);
    latitudes_enlace = linspace(TX.Latitude, RX.Latitude, num_pts);
    longitudes_enlace = linspace(TX.Longitude, RX.Longitude, num_pts);
    E_enlace = zeros(1, num_pts);
    RX_enlace = RX;
    [TXx, TXy, TXzone] = utils.deg2utm(TX.Latitude, TX.Longitude);
    
    for idx = 2:num_pts
        
        RX_enlace.Latitude = latitudes_enlace(idx);
        RX_enlace.Longitude = longitudes_enlace(idx);

        %----------------------------------------------------------------------
        % Executa o modelo de predição
        run_P1812 = model.P1812(TX, RX_enlace, ...
            A, R, TXx, TXy, TXzone, elevTX);
        E_enlace(idx) = run_P1812.PRX;
    
    end

    %----------------------------------------------------------------------
    % Plot do perfil de elevações

    figure('Units', 'centimeters', 'Position', [1 1 60 7])
    hold on;
    yyaxis left
    ylabel('Elevações (m)')
    xlabel('distância (Km)')

    area(distancias, elevacoes, 'FaceColor', '#90a2b5', 'EdgeColor', '#101010');
    ylim([min_elevacao inf])

    %----------------------------------------------------------------------
    % desenha a linha de visada
    plot([distancias(1) distancias(end)], [(elevTX + TX.AntennaHeight) ...
        (elevRX + RX.AntennaHeight)], 'Color', '#00f9ff');

    %----------------------------------------------------------------------
    % desenha os limites da primeira zona de Fresnel
    plot(distancias, Fl, 'Color', '#007cff');
    plot(distancias, Fu, 'Color', '#007cff');

    %----------------------------------------------------------------------
    % desenha o grafico de campo E recebido
    yyaxis right
    yticks([0:15:max(ylim)]);
    ylabel('E (dBuV/m)')
    plot(distancias_enlace, E_enlace, 'Color', '#00ff88');

    %----------------------------------------------------------------------
    % define a cor de fundo
    ax = gca;
    ax.Color = 'white';
    hold off;



end