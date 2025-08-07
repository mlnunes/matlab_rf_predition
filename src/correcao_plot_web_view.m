cla(axesHandle);
geobasemap(axesHandle,'satellite')

pasta = fileparts(mfilename('fullpath'));
pastaCache = fullfile(pasta, '..', '..', 'cache');
arquivosCache = dir (fullfile(pastaCache, '*.mbtiles'));

if (size({arquivosCache.name}, 2) > 0)
    [~,ultimoArquivo, ~] = fileparts(fullfile(pastaCache, arquivosCache(end).name));
    ultimoArquivo = str2double(ultimoArquivo);
    if ultimoArquivo < 9
        string1 = '0';
    else
        string1 = '';
    end
    
    arquivoTile = strcat(string1, num2str(ultimoArquivo + 1));
else
    arquivoTile = '01';
end
arquivoTile = fullfile(pastaCache, strcat(arquivoTile, '.mbtiles'));


margin = 0.5;
lat_span = max(latGrid(:)) - min(latGrid(:));
lon_span = max(lonGrid(:)) - min(lonGrid(:));
geolimits(axesHandle, ...
    [min(latGrid(:)) - margin * lat_span, max(latGrid(:)) + margin * lat_span], ...
    [min(lonGrid(:)) - margin * lon_span, max(lonGrid(:)) + margin * lon_span]);
pause(2);
exportgraphics(axesHandle, fullfile(pastaCache, 'mapa_satelite.tif'));

geoData = Z;
geoData(isnan(geoData)) = -999999;
mask = geoData ~= -999999;
vmin = min(min(geoData(mask)));
vmax = max(max(geoData(mask)));
geoDataClamped = min(max(geoData, vmin), vmax);
geoDataNorm = (geoDataClamped - vmin) / (vmax - vmin);
nColors = 256;
cmap = turbo(nColors);
idx = round(geoDataNorm * (nColors - 1)) + 1;
idx(~mask) = 1;
geoDataRGB = ind2rgb(idx, cmap);


imgBase = imread(fullfile(pastaCache, 'mapa_satelite.tif'));
geoResized = imresize(geoDataRGB, [size(imgBase,1), size(imgBase,2)]);
imgBase = im2double(imgBase);
fused_img = (1 - alfa) * imgBase + alfa * geoResized;
R_fused = R;
R_fused.RasterSize = [size(imgBase, 1), size(imgBase, 2)];
geotiffwrite(fullfile(pastaCache, 'fused_basemap.tif'), im2uint8(fused_img), R_fused);

% comandos no gdal
path_gdal = fullfile('\', 'OSGeo4W', 'bin');
gdal_translate = fullfile(path_gdal, 'gdal_translate');
cmd = sprintf('"%s" "%s" "%s" -of MBTILES', gdal_translate, (fullfile(pastaCache, 'fused_basemap.tif')),  arquivoTile);
system(cmd);
gdaladdo = fullfile(path_gdal, 'gdaladdo');
cmd = sprintf('"%s" -r average "%s"', gdaladdo, arquivoTile);
system(cmd);

removeCustomBasemap PredicaoPropagRF
addCustomBasemap('PredicaoPropagRF', arquivoTile, 'Attribution', 'Anatel')
geobasemap(axesHandle, 'PredicaoPropagRF')



% maketiles('tests/results/fused_basemap.tif', ...
%           'TileDirectory', 'tests/results/tiles_fusion', ...
%           'ZoomLevel', [10 12]); 