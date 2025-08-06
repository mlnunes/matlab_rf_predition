% Realiza a predição de cobertura de uma área a partir da escolha de um
% arquivo de configuração

fileFolder = fileparts(mfilename('fullpath'));
aux = dir(fullfile(fileFolder, 'config'));
aux = {aux.name};

arquivos = aux(3:end);

config = menu('Escolha uma configuração para rodar a predição:', arquivos);
arquivoConfig = fullfile(fileFolder, 'config', arquivos{config});

raio_metros   = 1000;
run(arquivoConfig);

[lb, prx] = utils.predicao_area(raio_metros, dadosPredicao);

graf = {'Atenuação', 'Nível de sinal', 'Não'};
grafico = menu('Deseja ver o gráfico do resultado?', graf);

f = uifigure;
ax = uiaxes(f, 'Units', 'normalized', 'Position', [0,0,1,1]);

if grafico == 1
    utils.plota_predicao(dadosPredicao, lb, graf{grafico}, ax)
elseif grafico == 2
    utils.plota_predicao(dadosPredicao, prx, graf{grafico}, ax)
end

