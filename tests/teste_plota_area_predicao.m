% Plota o gráfico de predição considerando as variaveis lp para antenuação
% prx para nível recebido

fileFolder = fileparts(mfilename('fullpath'));

if ~exist('dadosPredicao', 'var')
    aux = dir (fullfile(fileFolder, 'config'));
    aux = {aux.name};

    arquivos = aux(3:end);

    [config, configStatus] = listdlg('PromptString', {'Escolha uma configuração',  'para rodar a predição:'},...
        'ListString', arquivos,...
        'SelectionMode','single',...
        'ListSize',[250,250]);

    if ~configStatus
        return
    end

    arquivoConfig = fullfile(fileFolder, 'config', arquivos{config});
    run(arquivoConfig);
end


grafico = questdlg('Deseja ver o gráfico do resultado?', '', ...
    "Atenuação", "Nível de sinal", "Não", "Não");

if grafico == "Não"
    return
end

%dimensoes = menu('Qual visualização?', {'2D', '3D'});

dimensoes = questdlg('Qual visualização', '',...
            "2D", "3D", "Cancela", "2D");


if dimensoes == "2D"

    if grafico == "Atenuação"
        utils.plota_predicao(dadosPredicao, lb, grafico)

    elseif grafico == "Nível de sinal"
        utils.plota_predicao(dadosPredicao, prx, grafico)
    end

elseif dimensoes == "3D"
    if grafico == "Atenuação"
        utils.plota_predicao3D(dadosPredicao, lb, grafico)

    elseif grafico == "Nível de sinal"
        utils.plota_predicao3D(dadosPredicao, prx, grafico)
    end
    
end


clear dadosPredicao;