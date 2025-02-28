% Realiza a predição de cobertura de uma área a partir da escolha de um
% arquivo de configuração
arquivos = {'Radio_FM_Carangola_Hata_30m', ...
    'Radio_FM_Carangola_1812_10m', ...
    'Radio_FM_Carangola_1812_30m', ...
    'Testset_1812_10m', ...
     'TVD_Anhanguera_1812_30m'};

config = menu('Escolha uma configuração para rodar a predição:', arquivos);

arquivoConfig = strcat('tests/config/', arquivos{config}, '.m');
[lb, prx] = utils.predicao_area(arquivoConfig);

graf = {'Atenuação', 'Nível de sinal', 'Não'};
grafico = menu('Deseja ver o gráfico do resultado?', graf);

if grafico == 1
    utils.plota_predicao(arquivoConfig, lb, graf{grafico})

elseif graffico == 2
    utils.plota_predicao(arquivoConfig, prx, graf{grafico})

end

