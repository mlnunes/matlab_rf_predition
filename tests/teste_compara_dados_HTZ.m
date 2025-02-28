% Realiza a comparação de dados de predição do HTZ

%--------------------------------------------------------------------------
% Lista os possíveis arquivos de configuração disponíveis
aux = dir ('tests/config/');
aux = {aux.name};

dadosPredicao = aux(3:end);


%--------------------------------------------------------------------------
% Lista os possíveis arquivos de dados do HTZ disponíveis
aux = dir ('tests/results/htz/*.csv');
aux = {aux.name};

predicaoHTZ = aux;

config = menu('Escolha uma configuração de predição:', dadosPredicao);

arquivoDadosPredicao = strcat('tests/config/', dadosPredicao{config});

config = menu('Escolha um conjunto de dados gerados pelo HTZ:', predicaoHTZ);
arquivoDadosHTZ = strcat('tests/results/htz/', predicaoHTZ{config});

compara = utils.compara_HTZ(arquivoDadosPredicao, arquivoDadosHTZ);

disp("Os dados de comparação estão disponiveis na variável compara.")

