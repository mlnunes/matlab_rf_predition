%--------------------------------------------------------------------------
% Dados da estaçao TX
freq = 102.1e6;
movel_hrx = 1.7;
enb = txsite("Name","enb", ...
    "Latitude",-20.725683333333333, ...
    "Longitude",-42.03616666666667, ...
    "Antenna",'isotropic', ...
    "AntennaHeight",8, ...              % Unidade: metros
    "TransmitterFrequency",freq, ...    % Unidade: Hz
    "TransmitterPower",275.5);          % Unidade: W
[enbX, enbY, enbzone] = utils.deg2utm(enb.Latitude, enb.Longitude);

%--------------------------------------------------------------------------
% Carrega dados do relevo
[A,R] = readgeoraster("data/Teste_DTM_MG_copy_clip.tif");
A = double(A);

%--------------------------------------------------------------------------
% Carrega dados do clutter
[C, S] = utils.read_clutter("data/Teste_Clutter_MG_clip.tif");

%--------------------------------------------------------------------------
% Carrega CSV
csv = readmatrix("results/Comparacao_P1812_Carangola_10m.csv");
csv2 = csv( (csv(:, 1) > R.LongitudeLimits(1) & ...
    csv(:, 1) < R.LongitudeLimits(2) & ...
    csv(:, 2) > R.LatitudeLimits(1) & ...
    csv(:, 2) < R.LatitudeLimits(2)), :);

%--------------------------------------------------------------------------
% Cria variáveis de saída
Pwr_rx_csv =  zeros(size(csv2, 1), 2);
csv2 = csv( (csv(:, 1) > R.LongitudeLimits(1) & ...
    csv(:, 1) < R.LongitudeLimits(2) & ...
    csv(:, 2) > R.LatitudeLimits(1) & ...
    csv(:, 2) < R.LatitudeLimits(2)), :);
%--------------------------------------------------------------------------
% elevação da TX
[n, m] = utils.get_raster_idx(enb.Latitude, enb.Longitude, R);
elevenb = A(n, m);

%--------------------------------------------------------------------------
% Dados da estaçao RX
RX = rxsite("Latitude",latitudes(1), ...
           "Longitude", longitudes(1), ...
           "AntennaHeight",movel_hrx);

%--------------------------------------------------------------------------
% Loop de execução

idx = numel(csv2(:, 1));

for n = 1:idx
    %----------------------------------------------------------------------
    % Carrega as coordenadas da ponto de comparação
    RX.Latitude = csv2(n, 2);
    RX.Longitude = csv2(n, 1);

    %----------------------------------------------------------------------
    % Executa o modelo de predição
    run_P1812 = model.P1812(enb, RX, ...
        A, R, C, S, enbX, enbY, enbzone, elevenb);

    %----------------------------------------------------------------------
    % Calcula a intensidade de campo elétrico recebida no ponto e a
    % Atenuação
    Pwr_rx_csv(n,1) = run_P1812.PRX;
    Pwr_rx_csv(n,2) = csv2(n, 4);
    %----------------------------------------------------------------------

end

%--------------------------------------------------------------------------
% Cálculo do erro
erro = sqrt((Pwr_rx_csv(:,2) - Pwr_rx_csv(:,1)).^2);
erro_medio = sum(erro) / numel(erro);
desvio = std(erro);

fprintf("Erro médio quadrado:\t%1.f dB\n", erro_medio);
fprintf("Desvio padrão do erro:\t%1.f dB\n", desvio);

%--------------------------------------------------------------------------
% Grafico predição comparada
figure(1)
title('Valores de E RX  - HTZ vs Matlab');
plot(Pwr_rx_csv(:,2), 'b')
hold on
plot(Pwr_rx_csv(:,1), 'r')
legend('HTZ', 'Matlab')
hold off

%--------------------------------------------------------------------------
% Gráfico distribuição do erro
figure(2)
title('Distribuição do Erro - HTZ vs Matlab');
histogram(erro)


