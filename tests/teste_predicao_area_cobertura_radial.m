% Realiza a predição de cobertura de uma área a partir da escolha de um
% arquivo de configuração

%raio da predição em torno da base em metros (valor default)
raio = 4800;

aux = dir ('tests/config/');
aux = {aux.name};

arquivos = aux(3:end);

%--------------------------------------------------------------------------
% Caixa de diálogo para selecionar tos os arquivos da pasta ./tests/config

config = menu('Escolha uma configuração para rodar a predição:', arquivos);

arquivoConfig = strcat('tests/config/', arquivos{config});


%--------------------------------------------------------------------------
% Caixa de diálogo para entrar com o raio da predição
raio_user = inputdlg({'Entre com raio da cobertura (m):'}, ...
                     "Raio", ...
                     [1, 50], ...
                     {int2str(raio)});

%--------------------------------------------------------------------------
% Testa se o valor do raio é válido ou se não foi abortado o cálculo
if ~isempty(raio_user)
    raio = str2double(raio_user{1});
    if isnan(raio)
        error("Entrada inválida! Insira um número inteiro.")
    else

      %--------------------------------------------------------------------
      % Executa o cálculo de predição com o parâmetros selecionados  
      [lb, prx] = utils.predicao_area_radial(raio, arquivoConfig);

        %------------------------------------------------------------------
        % Caixa de diálogo para plotar o resultado
        graf = {'Atenuação', 'Nível de sinal', 'Não'};
        grafico = menu('Deseja ver o gráfico do resultado?', graf);
        
        if grafico == 1
            utils.plota_predicao(arquivoConfig, lb, graf{grafico})
        
        elseif grafico == 2
            utils.plota_predicao(arquivoConfig, prx, graf{grafico})
        
        end
        %------------------------------------------------------------------

    end
    %----------------------------------------------------------------------  

end
%--------------------------------------------------------------------------





