function [Lb, Pwr_rx] = predicao_area_radial(raio_m, fileData)
    %----------------------------------------------------------------------
    % Calcula a predição e cobertura de uma área
    %
    % fileData: arquivo que contém a estrutura com parâmetros da predição
    %       dadosPredicao: nome da struct
    %               modelo de predição: ['Hata', 'P.1812']
    %               frequencia: frequência da análise (Hz)
    %               dadosRelevo: arquivo geotif com dados de elevação em metros da
    %                   área de análise 
    %               dadosClutter: arquivo geotif com dados de classificação
    %                   da cobertura do terreno na área de análise
    %               Movel:
    %                   Antena:
    %                       Altura: altura da antena (m)
    %               Base:
    %                   Nome: nome da estação
    %                   Latitude: latitude da estação (graus decimais)
    %                   Longitude: longitude da estação (graus decimais)
    %                   Potencia: potência do transmissor (W)
    %                   Antena:
    %                       Altura: altura da antena (m)
    %                       ArquivoDados: arquivo de informações e diagrama
    %                       de irradiação da antena
    %                       Modelo: nome do modelo da antena
    %                       Funcao: ['TX', 'RX']
    %                       Azimute: azimute a antena
    %                       tiltMecanico: inclinação da antena
    %                       Tipo: ['isotropic', 'array']
    %
    %   Lb: matriz de valores de atenuação calculada para cada célula do
    %       geotif da área de análise (dB)
    %   Pwr_rx: matriz de valores de nível de sinal recebido calculado para
    %           cada célula do geotif da área de análise
    %----------------------------------------------------------------------
   
    arguments
        raio_m  
        fileData {mustBeFile}
    end
    
    %----------------------------------------------------------------------
    % Carrega os parâmetros utilizados para realizar a predição
    run(fileData);

    modelo = dadosPredicao.modeloPredicao;

    %----------------------------------------------------------------------
    % Dados da estação base
    base = txsite("Name", dadosPredicao.Base.Nome,...
        "Latitude", dadosPredicao.Base.Latitude,...
        "Longitude", dadosPredicao.Base.Longitude,...
        "Antenna", dadosPredicao.Base.Antena.Tipo,...
        "AntennaHeight", dadosPredicao.Base.Antena.Altura,...
        "TransmitterFrequency", dadosPredicao.frequencia,...
        "TransmitterPower", dadosPredicao.Base.Potencia);
    
    % Carrega os dados da antena
    
    antenaBase = utils.readAntennaData(dadosPredicao.Base.Antena.ArquivoDados, dadosPredicao.Base.Antena.Modelo,...
        dadosPredicao.Base.Antena.Funcao, dadosPredicao.Base.Antena.Azimute, dadosPredicao.Base.Antena.tiltMecanico);

    %----------------------------------------------------------------------
    % Caracteristicas da area
    % Carrega dados do relevo
    [A, R] = utils.loadRaster(dadosPredicao.dadosRelevo, true);

    %--------------------------------------------------------------------------
    % Carrega dados do clutter, se não houver arqivo de clutter uma matriz
    % default com representação área aberta/rural
    if ~isempty(dadosPredicao.dadosClutter)
    
        [C, S] = utils.read_clutter(dadosPredicao.dadosClutter);
    
    else
       
        C = 2 * ones(size(A));
        S = R;
    
    end
    
    % C = double(C);
    
    %--------------------------------------------------------------------------
    % Cria variáveis de saída
    %Pwr_rx = -Inf * ones(size(A));
    Pwr_rx = nan(size(A));
    Lb = Pwr_rx;
    
    %--------------------------------------------------------------------------
    % elevação da estação Base
    [n, m] = utils.get_raster_idx(base.Latitude, base.Longitude, R);
    elevBase = A(n, m);


    %--------------------------------------------------------------------------
    % clutter da estação Base
    clutBase = C(n,m);


    %----------------------------------------------------------------------
    % Cria um elipsoide de referência para os cálculos de distância
    wgs84 = wgs84Ellipsoid("meter");
    

    %----------------------------------------------------------------------
    % Calcula as células que compõem a borda da area de predição
    % raio em número de células
    raioC = round(raio_m/((R.CellExtentInLatitude * 111320)));
    
    % indices da celula que abriga a estação base
    txN = n;
    txM = m;

    % matriz de indices únicos que descrevem um circulo de raio raioC em
    % torno das célula A(txM, txN)
    borda = utils.calc_idxs_borda(txM, txN , raioC);


    %--------------------------------------------------------------------------
    % Incializa a variavel RX instanciando a classe rxsite() preparando
    % para loop
    RX = rxsite();

    %--------------------------------------------------------------------------
    % Inicializas a classe de predição conforme o modelo a ser utilizado
    switch modelo
        case 'Hata'
            predicao = model.Hata(base, RX, A, R, C, S);

        case 'P.1812'
           predicao = model.P1812(base, RX, A, R, C, S);

        otherwise
            error("Modelo não implementado");
    end

    %--------------------------------------------------------------------------
    % Cria barra de progresso
    barExec = uiprogressdlg(uifigure);
    
    %--------------------------------------------------------------------------
    % Loop de execução

    for i = 1:size(borda,1)

        %------------------------------------------------------------------
        % atualiza barra de status de execução
        if ~mod(i, 10)
            percent_exec = i /(size(borda,1));
            barExec.Message = sprintf('Executado: %.1f %%', (percent_exec * 100));
            barExec.Value = percent_exec;
        end
        
        %------------------------------------------------------------------
        % Atualiza o ponto externo da radial
        RX.Latitude = R.intrinsicYToLatitude(borda(i, 2));
        RX.Longitude = R.intrinsicXToLongitude(borda(i, 1));

        %------------------------------------------------------------------
        % encontra distancia, azimute da radial
        [~, azimuteRadial] = utils.Propagation.Distance(base, RX, "m"); 
        
        %------------------------------------------------------------------
        % Levanta o perfil e clutter da radial
        % Encontra as células que estão na radial
        pontos_radial = utils.vetor_intersecao(base, RX, R);
        celulas_radial = zeros(size(pontos_radial));
        celulas_radial(:, 1) = (arrayfun(@(idx) utils.get_raster_idx(pontos_radial(idx, 2), ...
							        pontos_radial(idx, 1), R), 1:size(pontos_radial,1)))';
        [~, aux] = arrayfun(@(idx) utils.get_raster_idx(pontos_radial(idx, 2), ...
			        pontos_radial(idx, 1), R), 1:size(pontos_radial,1));
        celulas_radial(:, 2) = aux';

        %------------------------------------------------------------------
        % Remove células/pontos repetidas
        [celulas_radial, idxs] = unique(celulas_radial, "rows");
        pontos_radial = pontos_radial(idxs, :);


        % armazena a elevação e clutter das células da radial
        elevacoes_radial = (arrayfun(@(fix)A(celulas_radial(fix, 1), ...
                           celulas_radial(fix, 2)), ...
                           1:size(celulas_radial,1)))';

        clutter_radial = (arrayfun(@(fix)C(celulas_radial(fix, 1), ...
                         celulas_radial(fix, 2)), ...
                         1:size(celulas_radial,1)))'; 


        % levanta as distâncias das células da radial até a estação base
        distancias_radial = (arrayfun(@(idx) distance(...
                            base.Latitude, base.Longitude, ...
                            pontos_radial(idx, 2), pontos_radial(idx, 1), ...
                            wgs84), 1:size(celulas_radial, 1)))';

        % ordena os arrays
        perfil_radial_ordenado = utils.ordena_perfil(distancias_radial', ...
                                                     elevacoes_radial', ...
                                                     clutter_radial');
        
        celulas_radial_ordenadas = utils.ordena_perfil(distancias_radial', ...
                                                       celulas_radial(:,1)', ...
                                                       celulas_radial(:,2)');
        
        pontos_radial_ordenados = utils.ordena_perfil(distancias_radial', ...
                                                       pontos_radial(:,1)', ...
                                                       pontos_radial(:,2)');


        distancias_radial = perfil_radial_ordenado(1,:)';
        elevacoes_radial = perfil_radial_ordenado(2,:)';
        clutter_radial = perfil_radial_ordenado(3,:)';
        celulas_radial = celulas_radial_ordenadas(2:3,:)';
        pontos_radial = pontos_radial_ordenados(2:3, :)';

        %------------------------------------------------------------------
        % calcula as inclinações de cada ponto em relação a estação base

        alturaAntenaRx = RX.AntennaHeight;
        alturaAntenaBase = base.AntennaHeight + elevBase;
        inclinacoes = (arrayfun(@(idx) rad2deg(atan(((alturaAntenaRx + elevacoes_radial(idx)) - ...
           alturaAntenaBase)) / distancias_radial(idx)), 1:size(pontos_radial,1)))';

        %------------------------------------------------------------------
        % calcula os ganhos da antena na direção dos pontos da radial
        ganhoMaxAntenaBase = antenaBase.Ganho;
        gAnt = zeros(3, numel(inclinacoes));
        [gAnt(1,:), gAnt(2,:)] = (arrayfun(@(idx) (antenaBase.ganhoDirecao(azimuteRadial, ...
            inclinacoes(idx))), 1:size(pontos_radial,1)));
        gAnt(3,:) = ganhoMaxAntenaBase - gAnt(1,:) - gAnt(2,:);


        %------------------------------------------------------------------
        % iniciar o loop sobre as celulas_radial passando o perfil,
        % clutter e distancia para calculo(predicao, gAnt)
        for k = 1:size(celulas_radial,1)
            
            %--------------------------------------------------------------
            % Verifica se a célula já foi computada anteriormente
            if ~isnan(Lb(celulas_radial(k, 1), celulas_radial(k, 2)))
                continue
            end

            %----------------------------------------------------------
            % Atualiza as coordenadas do ponto de RX
            RX.Latitude = pontos_radial(k, 2);
            RX.Longitude = pontos_radial(k, 1);

            %----------------------------------------------------------
            % Adapta os arrays de distancia, clutter e elevações para
            % execução no modelo
            [d, e, c] = utils.remove_sequencias(perfil_radial_ordenado(:, 1:k));
            elevsiteRX = elevacoes_radial(k);
            distanciaRX = distancias_radial(k)/1000;
            clutterRX = clutter_radial(k);
            d = [0, d/1000, distanciaRX];
            e = [elevBase, e, elevsiteRX];
            c = [clutBase, c, clutterRX];
                          
            %------------------------------------------------------------------
            % calcula a atenuação e nível de sinal recebido
            predicao.siteRX = RX;
            calculo(predicao, gAnt(3, k), 'perfil_distancia', d, 'perfil_elevacao', e, ...
                    'perfil_clutter', c);
            Lb(celulas_radial(k, 1), celulas_radial(k, 2)) = predicao.Lb;
            Pwr_rx(celulas_radial(k, 1), celulas_radial(k, 2)) = predicao.PRX; %executar a partir da linha 36 do P1812
        
            %--------------------------------------------------------------
            
        end
        %-------------------------------------------------------------------


    end
    
    %----------------------------------------------------------------------
    % Interpola os valores não calculados à partir das células vizinhas
    [M, N] = meshgrid(1:size(Lb, 2), 1:size(Lb, 1));
    mascaraDentro = (M - txM).^2 + (N - txN).^2 < raioC^2;
    Lb(find(~mascaraDentro)) = -Inf;
    Lb = fillmissing(Lb, 'linear');
    % Lb(Lb(find(mascaraDentro)) == Inf) = NaN;
    %Lb =fillmissing(Lb, 'linear');

    close(barExec)
end