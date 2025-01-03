function [distancias, elevacoes] = levanta_perfil(TX, RX, A, R)
    %----------------------------------------------------------------------
    % Funçao que levanta o perfil do enlace TX e RX
    % distancias:       array de distancias entre os pontos de alteraçao da
    % elevaçao no terreno e o TX em km
    % elevacoes:        array do perfil de elevaçoes do terreno em m
    % TX:               classe txsite
    % RX:               classe rxsite
    % A, R:             matriz de elevações A e lista de atributos do georaster
    % vetor_intersec:   array de pontos de intersecção (lat, lon) entre o segmento de
    % reta definido pelas coordenadas de TX e de RX com os meridianos e
    % paralelos que limitam os tiles do geroraster
    % distancias:       array ordenado de distancias entre os pontos de
    % transição das elevações do terreno e o ponto TX em km
    % elevacoes:        perfil de elevações do terreno em m
    
    
    %----------------------------------------------------------------------
    % inicializa as variaáveis

    distancias = [];
    elevacoes = [];
    
    %----------------------------------------------------------------------
    % calcula o array de intersecções
    
    vetor_intersec = utils.vetor_intersecao(TX, RX, R);

    %----------------------------------------------------------------------
    
    if ~isempty(vetor_intersec)
        
        %------------------------------------------------------------------
        % levanta o perfil do terreno removendo as ambiguidades

        [distancias, elevacoes] = utils.analisa_perfil(TX, vetor_intersec, A, R);
        
        %------------------------------------------------------------------
        % Preenche as posições iniciais e finais dos arrays distancias e
        % elevacoes

        [n, m] = utils.get_raster_idx(RX.Latitude, RX.Longitude, R);
        elevsiteRX = A(n, m);
        distanciaRX = utils.Propagation.Distance(TX, RX, 'km');
        [n, m] = utils.get_raster_idx(TX.Latitude, TX.Longitude, R);
        elevsiteTX = A(n, m);
        distancias = [0, distancias, distanciaRX];
        elevacoes = [elevsiteTX, elevacoes, elevsiteRX];
    
    end

    %----------------------------------------------------------------------
end