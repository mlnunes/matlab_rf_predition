% Plota o gráfico de predição considerando as variaveis lp para antenuação 
% prx para nível recebido

if ~exist('arquivoConfig', 'var')
    aux = dir ('tests/config/');
    aux = {aux.name};

    arquivos = aux(3:end);

    config = menu('Escolha uma configuração para rodar a predição:', arquivos);

    arquivoConfig = strcat('tests/config/', arquivos{config});
end


graf = {'Atenuação', 'Nível de sinal', 'Não'};
grafico = menu('Deseja ver o gráfico do resultado?', graf);

if grafico < 3
    dimensoes = menu('Qual visualização?', {'2D', '3D'});

    if dimensoes == 1
    
        if grafico == 1
            utils.plota_predicao(arquivoConfig, lb, graf{grafico})
        
        elseif grafico == 2
            utils.plota_predicao(arquivoConfig, prx, graf{grafico})
        end
    else
        if grafico == 1
            utils.plota_predicao3D(arquivoConfig, lb, graf{grafico})
        
        elseif grafico == 2
            utils.plota_predicao3D(arquivoConfig, prx, graf{grafico})
        end

    end
end

clear arquivoConfig;