% Realiza a predição de cobertura de uma área a partir da escolha de um
% arquivo de configuração

%raio da predição em torno da base em metros
raio = 4000;

aux = dir ('tests/config/');
aux = {aux.name};

arquivos = aux(3:end);

config = menu('Escolha uma configuração para rodar a predição:', arquivos);

arquivoConfig = strcat('tests/config/', arquivos{config});
[lb, prx] = utils.predicao_area_radial(raio, arquivoConfig);

graf = {'Atenuação', 'Nível de sinal', 'Não'};
grafico = menu('Deseja ver o gráfico do resultado?', graf);

if grafico == 1
    utils.plota_predicao(arquivoConfig, lb, graf{grafico})

elseif grafico == 2
    utils.plota_predicao(arquivoConfig, prx, graf{grafico})

end

