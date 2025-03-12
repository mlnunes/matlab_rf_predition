% Plota o diagrama de irradiação a partir da escolha de um arquivo de 
% configuração da antena

%--------------------------------------------------------------------------
% Lista os possíveis arquivos de configuração disponíveis
aux = dir ('tests/data/*.msi');
aux = {aux.name};

arquivos = aux;

config = menu('Escolha um arquivo de configuração de antena:', arquivos);

arquivoConfig = strcat('tests/data/', arquivos{config});

ant1 = utils.readAntennaData(arquivoConfig, "Antena", "TX", 0, 0);
plotDiagramas(ant1);