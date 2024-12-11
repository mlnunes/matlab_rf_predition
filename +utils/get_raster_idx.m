function [idx] = get_raster_idx(coord, limit, delta, maxdim)
% recebe a latitude ou longitude e retorna a linha ou coluna da 
% matriz do raster
% idx: linha ou coluna
% coord: latitude ou longitude em graus decimais
% limit: latitude ou longitude mínima do tile do raster
% delta: a extenção da célula do raster na dimensão em questão
% maxdim: número de colunas da matriz do raster na dimensão
%----------------------------------------------------------------------
    idx = ceil((coord - limit(1))/delta);

    %----------------------------------------------------------------------
    % ajusta os limites inferior e superior
    if idx < 1

        idx = 1;

    elseif idx > maxdim

        idx = maxdim;
        
    end
    %----------------------------------------------------------------------

end