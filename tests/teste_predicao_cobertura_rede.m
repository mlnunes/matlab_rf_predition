% Realiza a predição de cobertura de uma área a partir de um arquivo de
% configuração de uma rede SMP

%raio da predição em torno da base em metros (valor default)
raio = 1000;

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
        [A , R] = utils.resizeGeotiff(A, R);
        lb_rede = inf(size(A));
        prx_rede = -inf(size(A));
        rxLat = 0;
        rxLon = 0;
        for n = 1 : size(configRede, 1)
            disp (n)
            if ((configRede{n, 'Lat'} == rxLat) && (configRede{n, 'Lon'} == rxLon))
                dadosPredicao.Base.Antena.Azimute = configRede{n, 'Azimute'};
                dadosPredicao.Base.Antena.tiltMecanico = configRede{n, 'Tilt'};
                dadosPredicao.Base.Antena.ArquivoDados = strcat(pwd, bar, 'tests', bar, 'data', bar, 'antenas', bar, string(configRede{n, 'Antenna_Model'}));


                antenaBase = utils.readAntennaData(dadosPredicao.Base.Antena.ArquivoDados, dadosPredicao.Base.Antena.Modelo,...
                    dadosPredicao.Base.Antena.Funcao, dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico);

                RX = rxsite();
                TX = txsite(Latitude=configRede{n, 'Lat'}, Longitude=configRede{n, 'Lon'});
                for p = 1 : size(gAnt, 1)
                    for q = 1 : size(gAnt, 2)
                        if ~isinf(lb(p, q))
                            RX.Latitude = R.intrinsicYToLatitude(p);
                            RX.Longitude= R.intrinsicXToLongitude(q);
                            [distancia, azimute] = utils.Propagation.Distance(TX, RX, "m");
                            inclinacao = rad2deg(atan((dadosPredicao.Movel.Antena.Altura + A(p, q) - ...
                                configRede{n, 'Altura'}) / distancia));
                            [gH, gV] = antenaBase.ganhoDirecao(azimute, inclinacao);
                            gAntAux = antenaBase.Ganho - gH - gV;
                            lb(p, q) = lb(p, q) - gAnt(p, q) + gAntAux;
                            prx(p, q) = prx(p, q) - gAnt(p, q) + gAntAux;
                            gAnt(p, q) = gAntAux;
                        end

                    end
                end

            else
                rxLat = configRede{n, 'Lat'};
                rxLon = configRede{n, 'Lon'};

                dadosPredicao = struct('modeloPredicao', 'P.526', ...
                    'frequencia', configRede{n,'Freq_TX'} * 1e3, ...
                    'dadosRelevo', 'tests/data/cuiaba_crop_dem.tif', ...
                    'dadosClutter', 'tests/data/cuiaba_crop_clu.tif', ...
                    'Movel', struct('Antena', struct('Altura',  1.6)), ...
                    'Base', struct('Nome', configRede{n, 'Cell'}, ...
                    'Latitude', rxLat, ...
                    'Longitude', rxLon, ...
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
                [lb, prx, gAnt] = utils.predicao_area_radial(raio, dadosPredicao);
            end
            
            
            lb_rede((lb < lb_rede) & (~isinf(lb))) = lb ((lb < lb_rede) & (~isinf(lb)));
            prx_rede ((prx > prx_rede) & (~isinf(prx))) = prx ((prx > prx_rede) & (~isinf(prx)));
        end
      %------------------------------------------------------------------
      % Caixa de diálogo para plotar o resultado
      lb_rede(isinf(lb_rede)) = -inf;
      lb = lb_rede;
      prx = prx_rede;
      disp('Simulação concluída')
      run tests/teste_plota_area_predicao.m;
    
      %------------------------------------------------------------------

    end
    %----------------------------------------------------------------------  

end
%--------------------------------------------------------------------------





