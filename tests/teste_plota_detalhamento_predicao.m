% Plota o detalhamento do cálculo de predição e o gráfico do perfil do
% relevo


%--------------------------------------------------------------------------
% Lista os possíveis arquivos de configuração disponíveis
aux = dir ('tests/config/');
aux = {aux.name};

dadosPredicao = aux(3:end);


%--------------------------------------------------------------------------
% Cria a caixa de diálogo para receber a opção de arquivo de configuração
config = menu('Escolha uma configuração de predição:', dadosPredicao);



%--------------------------------------------------------------------------
% salva o nome do arquivo selecionado pelo usuário
arquivoDadosPredicao = strcat('tests/config/', dadosPredicao{config});

%--------------------------------------------------------------------------
% Formulário para receber as coordenadas
prompt = {'Latitude:', 'Longitude:'}; 
title = 'Coordenadas';
num_lines = [1 50];
defaultInput = {'', ''}; 

%--------------------------------------------------------------------------
% Exibe a caixa de diálogo para entrada das coordenadas
coordenadas = inputdlg(prompt, title, num_lines, defaultInput);

%--------------------------------------------------------------------------
% Verifica se o usuário não cancelou a entrada
if ~isempty(coordenadas)
    latRX = str2double(coordenadas{1});
    lonRX = str2double(coordenadas{2});

    utils.plot_perfil(arquivoDadosPredicao, latRX, lonRX)
end