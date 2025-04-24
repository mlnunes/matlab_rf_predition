% Realiza a predição de cobertura de uma área a partir de um arquivo de
% configuração de uma rede SMP
%--------------------------------------------------------------------------
%raio da predição em torno da base em metros (valor default)
raio = 1000;

%--------------------------------------------------------------------------
if isunix
    bar = '/';
else
    bar = '\';
end

aux = dir (strcat(pwd, bar, 'tests', bar, 'data', bar, "*.csv"));
arquivos = {aux.name};

%--------------------------------------------------------------------------
% Caixa de diálogo para selecionar tos os arquivos da pasta ./tests/config

config = menu('Escolha o arquvio de configuração da rede:', arquivos);

arquivoConfig = strcat(pwd, bar, 'tests', bar, 'data', bar, arquivos{config});

configRede = readtable(arquivoConfig, "VariableNamingRule", "preserve");

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
        %------------------------------------------------------------------
        %inicializa as variáveis
        [A, R] = utils.loadRaster('tests/data/cuiaba_crop_dem.tif', true);
        [A , R] = utils.resizeGeotiff(A, R);
        numSites = 6;%size(configRede, 1);
        dimsA = size(A);
        lb_rede = inf(dimsA);
        prx_rede = -inf(dimsA);
        rxLat = 0;
        rxLon = 0;

        %------------------------------------------------------------------
        % Verifica e inicia o parpool automaticamente se necessário
        pool = gcp('nocreate');
        if isempty(pool)

            pool = parpool('local');

        end
        numWorkers = pool.NumWorkers;

        %------------------------------------------------------------------
        for n = 1:numWorkers:(numSites + 1)

            %--------------------------------------------------------------
            spmd
                idx = n - 1 + spmdIndex;

                %----------------------------------------------------------
                if idx <= numSites

                    disp (idx)
                    rxLat = configRede{idx, 'Lat'};
                    rxLon = configRede{idx, 'Lon'};
                    dadosPredicao = struct('modeloPredicao', 'P.526', ...
                        'frequencia', configRede{idx,'Freq_TX'} * 1e3, ...
                        'dadosRelevo', 'tests/data/cuiaba_crop_dem.tif', ...
                        'dadosClutter', 'tests/data/cuiaba_crop_clu.tif', ...
                        'Movel', struct('Antena', struct('Altura',  1.6)), ...
                        'Base', struct('Nome', configRede{n, 'Cell'}, ...
                        'Latitude', rxLat, ...
                        'Longitude', rxLon, ...
                        'Potencia', 53, ...
                        'Antena', struct('Altura', configRede{idx, 'Altura'} , ....
                        'ArquivoDados', strcat(pwd, bar, 'tests', bar, 'data', bar, 'antenas', bar, configRede{idx, 'Antenna_Model'}), ...
                        'Modelo', 'AIR6419', ...
                        'Funcao', 'TX', ...
                        'Azimute', configRede{n, 'Azimute'}, ...
                        'tiltMecanico', configRede{n, 'Tilt'}, ...
                        'Tipo', 'isotropic')));
                    [lb_local, prx_local, gAnt] = utils.predicao_area_radial(raio, dadosPredicao);

                    %----------------------------------------------------------
                else
                    %------------------------------------------------------
                    % Workers inativos criam matrizes vazias
                    lb_local = inf(dimsA);
                    prx_local = -inf(dimsA);
                    disp([int2str(n),': ocioso'])

                end

                %----------------------------------------------------------
                % Redução global após cada iteração no worker 1
                lb_reduzido = spmdReduce(@min, lb_local, 1);
                prx_reduzido = spmdReduce(@max, prx_local, 1);

                %----------------------------------------------------------
                % Apenas o primeiro worker atualiza as variáveis de
                % resultado global
                if mod(n - 1, spmdSize) + 1 == spmdIndex

                    lb_rede((lb_reduzido{1} < lb_rede) & ~isinf(lb_reduzido{1})) = lb_reduzido{1}((lb_reduzido{1} < lb_rede) & ~isinf(lb_reduzido{1}));
                    prx_rede((prx_reduzido{1} > prx_rede) & ~isinf(prx_reduzido{1})) = prx_reduzido{1}((prx_reduzido{1} > prx_rede) & ~isinf(prx_reduzido{1}));


                end
                %----------------------------------------------------------

            end
            %--------------------------------------------------------------

        end
        %------------------------------------------------------------------
        % salva os resultados de saída
        lb_rede(isinf(lb_rede)) = -inf;
        lb = lb_rede;
        prx = prx_rede;

        %------------------------------------------------------------------
        % Caixa de diálogo para plotar o resultado
        disp('Simulação concluída')
        run tests/teste_plota_area_predicao.m;

    end
    %----------------------------------------------------------------------

end
%--------------------------------------------------------------------------





