clear;
%parpool('local', 4)

%--------------------------------------------------------------------------
% Dados da estaçao TX
freq = 102.1e6;
movel_hrx = 1.6;
enb = txsite("Name","enb", ...
    "Latitude",-20.725683333333333, ...
    "Longitude",-42.03616666666667, ...
    "Antenna",'isotropic', ...
    "AntennaHeight",8, ...              % Unidade: metros
    "TransmitterFrequency",freq, ...    % Unidade: Hz
    "TransmitterPower",275.5);          % Unidade: W
[enbX, enbY, enbzone] = utils.deg2utm(enb.Latitude, enb.Longitude);

%--------------------------------------------------------------------------
% Carrega dados do relevo
[A,R] = readgeoraster("data/Teste_DTM_MG_copy_clip.tif");
A = double(A);

%--------------------------------------------------------------------------
% Cria variáveis de saída
Pwr_rx = zeros(size(A));
Lb = zeros(size(A));

%--------------------------------------------------------------------------
% elevação da TX
[n, m] = utils.get_raster_idx(enb.Latitude, enb.Longitude, R);
elevenb = A(n, m);

%--------------------------------------------------------------------------
% Prepara loop de execução para carregar as coordenadas do centro de todas 
% as células
centro_i =  -R.CellExtentInLatitude / 2;
centro_j =  R.CellExtentInLongitude / 2;
latitudes = R.LatitudeLimits(2):...
    -R.CellExtentInLatitude:...
    R.LatitudeLimits(1);
latitudes = latitudes + centro_i;
longitudes = R.LongitudeLimits(1):...
    R.CellExtentInLongitude:...
    R.LongitudeLimits(2);
longitudes = longitudes + centro_j;
Llat = numel(latitudes)-1;
Llon = numel(longitudes)-1;

%--------------------------------------------------------------------------
% Dados da estaçao RX
RX = rxsite("Latitude",latitudes(1), ...
           "Longitude", longitudes(1), ...
           "AntennaHeight",movel_hrx);

%--------------------------------------------------------------------------
% Habilita paralelismo
%p = gcp("nocreate");
%    if isempty(p)
%        parpool("Threads");
%    end

%--------------------------------------------------------------------------
% Cria barra de progresso
d = uiprogressdlg(uifigure);

%--------------------------------------------------------------------------
% Loop de execução

m = 1;
%parfor n = 1:Llat

for n = 1:Llat
 
    percent_exec = ((n - 1) * Llon + m)/(Llat * Llon);
    d.Message = sprintf('Executado: %.1f %%', (percent_exec * 100));
    d.Value = percent_exec;
    
    for m = 1:Llon
    
        RX.Latitude = latitudes(n);
        RX.Longitude = longitudes(m);
        run_P1812 = model.P1812(enb, RX, ...
           A, R, enbX, enbY, enbzone, elevenb);
        Pwr_rx(n, m) = run_P1812.PRX; % + 11.97; converte dBuV/m p/ dBm
        Lb(n ,m) = run_P1812.Lb;
    
    end

end


%--------------------------------------------------------------------------
% Mapa da mancha de prediçao
figure
axesm('MapProjection','mercator','MapLatLimit',R.LatitudeLimits+[-1 1])
geoshow(Lb, R, DisplayType="texturemap")
geoshow(enb.Latitude,enb.Longitude,DisplayType="point",ZData=elevenb, ...
    MarkerEdgeColor="k",MarkerFaceColor="c",MarkerSize=10,Marker="o")

colormap(turbo)
text1 = "Carangola 102,1MHz";
delta = 0.0005;
textm(enb.Latitude+delta,enb.Longitude+delta,text1)
cb = colorbar;
cb.Label.String = "Atenuação (dB)";