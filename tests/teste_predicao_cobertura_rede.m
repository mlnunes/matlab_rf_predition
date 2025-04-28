% Realiza a predição de cobertura de uma área a partir de um arquivo de
% configuração de uma rede SMP

%raio da predição em torno da base em metros (valor default)
raio = 8000;

fileFolder = fileparts(mfilename('fullpath'));

aux = dir (fullfile( fileFolder, 'data', "*.csv"));
arquivos = {aux.name};

%--------------------------------------------------------------------------
% Caixa de diálogo para selecionar tos os arquivos da pasta ./tests/config

% config = listdlg('Escolha o arquvio de configuração da rede:', arquivos);

[config, configStatus] = listdlg('PromptString', {'Escolha o arquvio de', 'configuração da rede:'},...
                                 'ListString', arquivos,...
                                 'SelectionMode','single',...
                                 'ListSize',[250,150]);

if ~configStatus
    return
end

arquivoConfig = fullfile(fileFolder, 'data', arquivos{config});

configRede = readtable(arquivoConfig, "VariableNamingRule", "preserve");
configRede.("_LatLonHash") = string(round(configRede.Lat, 6)) + "," + string(round(configRede.Lon, 6));


%base64

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
        numSites = 1; %height(configRede);

        p = utils.parpoolCheck();
        numWorkers = p.NumWorkers;

        prx_rede_cell = repmat({prx_rede}, numWorkers, 1);
        lb_rede_cell = repmat({lb_rede}, numWorkers, 1);
        gAnt_cell = repmat({lb_rede}, numWorkers, 1);


        [C, idxsCells, ic] = unique(configRede(1:numSites, :).("_LatLonHash"), "stable");


        for m = 1 : numWorkers : numel(idxsCells)

            if (m + numWorkers - 1) <= numel(idxsCells)
                idxsPar = idxsCells(m : m + numWorkers - 1);
            else
                idxsPar = idxsCells(m : end);
            end

            parfor x = 1:numel(idxsPar)

                n = idxsPar(x);
                disp (n)
                txLat = configRede.Lat(n);
                txLon = configRede.Lon(n);


                dadosPredicao = struct('modeloPredicao', 'P.526', ...
                    'frequencia', configRede{n,'Freq_TX'} * 1e6, ...
                    'dadosRelevo', 'tests/data/cuialb_localba_crop_dem.tif', ...
                    'dadosClutter', 'tests/data/cuiaba_crop_clu.tif', ...
                    'Movel', struct('Antena', struct('Altura',  1.6)), ...
                    'Base', struct('Nome', configRede{n, 'Cell'}, ...
                    'Latitude', txLat, ...
                    'Longitude', txLon, ...
                    'Potencia',53.15, ...
                    'Antena', struct('Altura', configRede{n, 'Altura'} , ....
                    'ArquivoDados', fullfile(fileFolder, 'data', 'antenas', configRede.Antenna_Model{n}), ...
                    'Modelo', 'AIR6419', ...
                    'Funcao', 'TX', ...
                    'Azimute', configRede{n, 'Azimute'}, ...
                    'tiltMecanico', configRede{n, 'Tilt'}, ...
                    'Tipo', 'isotropic')));


                %--------------------------------------------------------------------
                % Executa o cálculo de predição com o parâmetros selecionados
                [lb_rede_cell{x}, prx_rede_cell{x}, gAnt_cell{x}] = utils.predicao_area_radial(raio, dadosPredicao, A , R, lb_rede_cell{x}, gAnt_cell{x});
                lb_local = lb_rede_cell{x};
                prx_local = prx_rede_cell{x};

                idxSetores = find(n==ic)';

                if numel(idxSetores) > 1
                    TX = txsite(Latitude=configRede{n, 'Lat'}, Longitude=configRede{n, 'Lon'});
                    RX = rxsite();

                    for nn = idxSetores(2 : end)

                        dadosPredicao.Base.Antena.Azimute = configRede{nn, 'Azimute'};
                        dadosPredicao.Base.Antena.tiltMecanico = configRede{nn, 'Tilt'};
                        dadosPredicao.Base.Antena.ArquivoDados = fullfile( fileFolder, 'data', 'antenas', configRede.Antenna_Model{nn});

                        antenaBase = utils.readAntennaData(dadosPredicao.Base.Antena.ArquivoDados, dadosPredicao.Base.Antena.Modelo,...
                            dadosPredicao.Base.Antena.Funcao, dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico);

                        % validar se infino antes e remover o aninhamento com um loop
                        % gAnt_cell{x}(t, q) -> gAnt_cell{x} ll -> ll vem
                        % da linha anterior
                        for t = 1 : height(gAnt_cell{x})
                            for q = 1 : width(gAnt_cell{x})
                                if ~isinf(lb_rede_cell{x}(t, q))
                                    RX.Latitude = R.intrinsicYToLatitude(t);
                                    RX.Longitude= R.intrinsicXToLongitude(q);
                                    [distancia, azimute] = utils.Propagation.Distance(TX, RX, "m");
                                    inclinacao = rad2deg(atan((dadosPredicao.Movel.Antena.Altura + A(t, q) - ...
                                        configRede{nn, 'Altura'}) / distancia));
                                    [gH, gV] = antenaBase.ganhoDirecao(azimute, inclinacao);
                                    gAntAux = antenaBase.Ganho - gH - gV;
                                    lbAux = lb_local(t, q) - gAnt_cell{x}(t, q) + gAntAux;
                                    prxAux = prx_local(t, q) - gAnt_cell{x}(t, q) + gAntAux;

                                    if lbAux < lb_rede_cell{x}(t, q)
                                        lb_rede_cell{x}(t, q) = lbAux;
                                    end

                                    if prxAux > prx_rede_cell{x}(t, q)
                                        prx_rede_cell{x}(t, q) = prxAux;
                                    end

                                end
                            end
                        end

                    end
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





