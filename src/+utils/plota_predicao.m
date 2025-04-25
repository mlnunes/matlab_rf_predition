function plota_predicao(dadosPredicao, Z, tipoZ)
    %----------------------------------------------------------------------
    % Plota o mapa da mancha de prediçao
    %   fileData: arquivo que contém a estrutura com parâmetros da predição
    %   Z: dados de atenuação ou sinal recebido
    %   tipoZ: nome variável que Z representa, p.ex: Atenuação
    %----------------------------------------------------------------------
    arguments
        dadosPredicao struct {mustBeNonempty}
        Z (:, :) double
        tipoZ string
    end
    
    dir_app = fileparts(mfilename('fullpath'));


    %----------------------------------------------------------------------
    % Carrega os parâmetros utilizados para realizar a predição
    %run(fileData);

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

    %----------------------------------------------------------------------
    % Caracteristicas da area
    % Carrega dados do relevo
    [A, R] = utils.loadRaster(fullfile(dir_app, '..', '..', dadosPredicao.dadosRelevo), true);
    [A, R] = utils.resizeGeotiff(A, R);
    
    %--------------------------------------------------------------------------
    % elevação da estação Base
    [n, m] = utils.get_raster_idx(base.Latitude, base.Longitude, R);
    elevBase = A(n, m);

    figure
    set(gcf, 'Name', 'Predição de Cobertura', 'NumberTitle', 'off');
    axesm('MapProjection','mercator','MapLatLimit',R.LatitudeLimits+[-1 1])
    geoshow(Z, R, DisplayType="texturemap")
    geoshow(base.Latitude,base.Longitude,DisplayType="point",ZData=elevBase, ...
        MarkerEdgeColor="k",MarkerFaceColor="c",MarkerSize=10,Marker="o")
    title (sprintf('Dados de Cobertura (%s) da estação %s\nModelo: %s', tipoZ, dadosPredicao.Base.Nome, modelo));
    
    if tipoZ == "Nível de sinal"
        colormap('turbo')
    else
    % cria um colormap do branco->amarelo->vermelho 
        cmap = zeros(256, 3);
        cmap(1:128, 1:2) = repmat([1 1], 128, 1);
        cmap(1:128, 3) = linspace(0.8, 0, 128);
        cmap(129:end, 1) = 1;
        cmap(129:end, 2) = linspace(1, 0, 128);
    
        colormap(cmap)
    end
    colorbar
  
    text1 = dadosPredicao.Base.Nome;
    delta = 0.0025;
    textm(base.Latitude+delta,base.Longitude+delta,text1)
    cb = colorbar;
    cb.Label.String = tipoZ;

end

