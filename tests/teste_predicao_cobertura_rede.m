% Realiza a predição de cobertura de uma área a partir de um arquivo de
% configuração de uma rede SMP

%raio da predição em torno da base em metros (valor default)
raio = 8000;

if isunix
    bar = '/';
else
    bar = '\';
end

aux = dir (strcat(pwd, bar, 'tests', bar, 'data', bar, "*.csv"));
arquivos = {aux.name};

%arquivos = aux(3:end);

%configRede = readtable("tests/data/Nextim_5G_MT 1.csv", "VariableNamingRule", "preserve");

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
        [A, R] = utils.loadRaster('tests/data/cuiaba_crop_dem.tif', true);
        [C, S] = utils.read_clutter('tests/data/cuiaba_crop_clu.tif');
        [A , R] = utils.resizeGeotiff(A, R);
        [C, S] = utils.resizeGeotiff(C , S);
        A = A + C;
        R.GeographicCRS = [];
        lb_rede = inf(size(A));
        prx_rede = -inf(size(A));
        rxLat = 0;
        rxLon = 0;
        numSites = 1;%size(configRede, 1);

        p = utils.parpoolCheck();
        numWorkers = p.NumWorkers;

        prx_rede_cell = repmat({prx_rede}, numWorkers, 1);
        lb_rede_cell = repmat({lb_rede}, numWorkers, 1);

        idxsCells = zeros(1, numSites);
        aux = 0;
        txLat = 0;
        txLon = 0;

        for ii = 1 : numSites
            if ((configRede{ii, 'Lat'} ~= txLat) && (configRede{ii, 'Lon'} ~= txLon))
                aux = aux + 1;
                idxsCells(aux) = ii;
            end
            txLat = configRede{ii, 'Lat'};
            txLon = configRede{ii, 'Lon'};
        end

        idxsCells = idxsCells(1:aux);

        for m = 1 : numWorkers : numel(idxsCells)
            
            if (m + numWorkers - 1) <= numel(idxsCells)
                idxsPar = idxsCells(m : m + numWorkers - 1);
            else
                idxsPar = idxsCells(m : end);
            end

            parfor x = 1:numel(idxsPar)
                lb_rede_cell{x} = inf(size(A));
                prx_rede_cell{x} = -inf(size(A));
                n = idxsPar(x);
                disp (n)
                txLat = configRede{n, 'Lat'};
                txLon = configRede{n, 'Lon'};

                

                dadosPredicao = struct('modeloPredicao', 'P.526', ...
                    'frequencia', configRede{n,'Freq_TX'} * 1e6, ...
                    'dadosRelevo', 'tests/data/cuiaba_crop_dem.tif', ...
                    'dadosClutter', 'tests/data/cuiaba_crop_clu.tif', ...
                    'Movel', struct('Antena', struct('Altura',  1.6)), ...
                    'Base', struct('Nome', configRede{n, 'Cell'}, ...
                    'Latitude', txLat, ...
                    'Longitude', txLon, ...
                    'Potencia',53, ...
                    'Antena', struct('Altura', configRede{n, 'Altura'} , ....
                    'ArquivoDados', strcat(pwd, bar, 'tests', bar, 'data', bar, 'antenas', bar, configRede{n, 'Antenna_Model'}), ...
                    'Modelo', 'AIR6419', ...
                    'Funcao', 'TX', ...
                    'Azimute', configRede{n, 'Azimute'}, ...
                    'tiltMecanico', configRede{n, 'Tilt'}, ...
                    'Tipo', 'isotropic')));

 
                %--------------------------------------------------------------------
                % Executa o cálculo de predição com o parâmetros selecionados
                [lb_local, prx_local, gAnt_local] = utils.predicao_area_radial(raio, dadosPredicao, A , R);
                lb_rede_cell{x} = lb_local;
                prx_rede_cell{x} =  prx_local;

                nn = n + 1;
                
                while (nn <= numSites)

                    if ((txLat ~= configRede{nn, 'Lat'}) || (txLon ~= configRede{nn, 'Lon'}))
                        break
                    end

                    dadosPredicao.Base.Antena.Azimute = configRede{nn, 'Azimute'};
                    dadosPredicao.Base.Antena.tiltMecanico = configRede{nn, 'Tilt'};
                    dadosPredicao.Base.Antena.ArquivoDados = strcat(pwd, bar, 'tests', bar, 'data', bar, 'antenas', bar, string(configRede{nn, 'Antenna_Model'}));

                    antenaBase = utils.readAntennaData(dadosPredicao.Base.Antena.ArquivoDados, dadosPredicao.Base.Antena.Modelo,...
                        dadosPredicao.Base.Antena.Funcao, dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico);

                    RX = rxsite();
                    TX = txsite(Latitude=configRede{nn, 'Lat'}, Longitude=configRede{nn, 'Lon'});

                    for t = 1 : size(gAnt_local, 1)
                        for q = 1 : size( gAnt_local, 2)
                            if ~isinf(lb_local(t, q))
                                RX.Latitude = R.intrinsicYToLatitude(t);
                                RX.Longitude= R.intrinsicXToLongitude(q);
                                [distancia, azimute] = utils.Propagation.Distance(TX, RX, "m");
                                inclinacao = rad2deg(atan((dadosPredicao.Movel.Antena.Altura + A(t, q) - ...
                                    configRede{nn, 'Altura'}) / distancia));
                                [gH, gV] = antenaBase.ganhoDirecao(azimute, inclinacao);
                                gAntAux = antenaBase.Ganho - gH - gV;
                                lbAux = lb_local(t, q) - gAnt_local(t, q) + gAntAux;
                                prxAux = prx_local(t, q) - gAnt_local(t, q) + gAntAux
                                if lbAux < lb_rede_cell{x}(t, q)
                                    lb_rede_cell{x}(t, q) = lbAux;
                                end

                                if prxAux > prx_rede_cell{x}(t, q)
                                    prx_rede_cell{x}(t, q) = prxAux;
                                end

                            end
                        end
                    end

                    nn = nn + 1;


                end

            end
            
            for k = 1 : numWorkers
                mascara_local = ~isinf(lb_rede_cell{k});
                mascara_lb = (lb_rede_cell{k} < lb_rede) & mascara_local;
                mascara_prx = (prx_rede_cell{k} > prx_rede) & mascara_local;
                lb_rede(mascara_lb) = lb_rede_cell{k}(mascara_lb);
                prx_rede (mascara_prx) = prx_rede_cell{k}(mascara_prx);
            end

        end



        %------------------------------------------------------------------
        % Caixa de diálogo para plotar o resultado
        lb_rede(isinf(lb_rede)) = -inf;
        lb = lb_rede;
        prx_rede(isinf(prx_rede)) = nan;
        prx = prx_rede;
        disp('Simulação concluída')
        run tests/teste_plota_area_predicao.m;

        %------------------------------------------------------------------

    end
    %----------------------------------------------------------------------

end
%--------------------------------------------------------------------------





