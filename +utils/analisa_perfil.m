function [distancias, elevacoes] = analisa_perfil(TX, vetor_intersec, A, R)
    %----------------------------------------------------------------------
    % inicializa as variaveis
    % idx, aux, indice, perfil: variáveis auxiliares
    % TX:                       classe txsite
    % vetor_intersec:           array de coordenadas (lat, lon) dos pontos
    % de intersecção entre o segmento formado pela posição do TX e do ponto
    % de interesse, os paralelos e meridianos que limitam os tiles do
    % georaster.
    % tx_coords:                coordenadas de TX para operação matricial
    % e, elevacoes:             arrays das elevações em m
    % d, distancia:             arrays das distâncias em Km

    idx = 1;
    s = size(vetor_intersec, 1);
    tx_coords = repelem([TX.Latitude, TX.Longitude], s, 1);
    
    %----------------------------------------------------------------------
    % Calculo do array de distancias dos pontos de intersecção e o TX

    d = deg2km(distance(vetor_intersec(:,2),vetor_intersec(:,1) , ...
        tx_coords(:,1), tx_coords(:,2)));
    d = transpose(d);
    
    %----------------------------------------------------------------------
    % Levantamento das elevações dos pontos de intersecção

    aux(:,1) = ceil((vetor_intersec(:,2) - R.LatitudeLimits(1))/R.CellExtentInLatitude);
    aux(:,2) = ceil((vetor_intersec(:,1) - R.LongitudeLimits(1))/R.CellExtentInLongitude);
    e = (A(sub2ind(size(A), aux(:,1), aux(:,2))))';

    %----------------------------------------------------------------------
    % Ordena o array distancia em ordem crescente

    perfil = [d; e];
    [~, indice] = sort(perfil(1,:));
    perfil = perfil(:, indice);

    e(idx) = perfil(2, 1);
    d(idx) = perfil(1, 1);
    
    %----------------------------------------------------------------------
    % Remove os valores em sequência com a mesma elevação

    if size(perfil, 2) > 1

        for n = 2:size(perfil, 2)
            if abs(perfil(2,n) - perfil(2, idx)) >= 1
                idx = idx + 1;
                e(idx) = perfil(2, n);
                d(idx) = perfil(1, n);
            end
        end
        %------------------------------------------------------------------
        
    end
    
    %----------------------------------------------------------------------
    % Retorna os array elevações e distâncias

    elevacoes = e(1:idx);
    distancias = d(1:idx);
end