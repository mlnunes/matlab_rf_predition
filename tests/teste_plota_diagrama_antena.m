% Plota o diagrama de irradiação a partir da escolha de um arquivo de 
% configuração da antena

arquivos = {'AIR6419_B42_NR_dlMacro_H0_V0_3500_PWR', ...
    'ISDE043407EUL'};

config = menu('Escolha um arquivo de configuração de antena:', arquivos);

arquivoConfig = strcat('tests/data/', arquivos{config}, '.msi');

ant1 = utils.readAntennaData(arquivoConfig, "Antena", "TX", 0, 0);
plotDiagramas(ant1);