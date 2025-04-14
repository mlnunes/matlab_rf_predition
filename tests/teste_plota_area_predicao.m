% Plota o gráfico de predição considerando as variaveis lp para antenuação 
% prx para nível recebido

if isunix
    bar = '/';
else
    bar = '\';
end

if ~exist('dadosPredicao', 'var')
    aux = dir (strcat('tests', bar, 'config', bar));
    aux = {aux.name};

    arquivos = aux(3:end);

    config = menu('Escolha uma configuração para rodar a predição:', arquivos);

    arquivoConfig = strcat('tests', bar, 'config', bar, arquivos{config});
    run(arquivoConfig);
end


graf = {'Atenuação', 'Nível de sinal', 'Não'};
grafico = menu('Deseja ver o gráfico do resultado?', graf);

if grafico < 3
    dimensoes = menu('Qual visualização?', {'2D', '3D'});

    if dimensoes == 1
    
        if grafico == 1
            utils.plota_predicao(dadosPredicao, lb, graf{grafico})
        
        elseif grafico == 2
            utils.plota_predicao(dadosPredicao, prx, graf{grafico})
        end
    else
        if grafico == 1
            utils.plota_predicao3D(dadosPredicao, lb, graf{grafico})
        
        elseif grafico == 2
            utils.plota_predicao3D(dadosPredicao, prx, graf{grafico})
        end

    end
end

clear dadosPredicao;