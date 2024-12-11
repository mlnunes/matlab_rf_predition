clear;
%parpool('local', 4)
freq = 778e6;
movel_hrx = 1.6;
[A,R] = readgeoraster("data/terreno_col.tif");
A = double(A);
fator_escala = 1;
A_resampled = repelem(A, fator_escala, fator_escala);
Pwr_rx = zeros(size(A_resampled));
Lb = zeros(size(A_resampled));
R_resampled = R;
R_resampled.RasterSize = size(A_resampled);
enb = txsite("Name","enb", ...
    "Latitude",-19.84413056, ...
    "Longitude",-43.94696389, ...
    "Antenna",'isotropic', ...
    "AntennaHeight",16, ...        % Units: meters
    "TransmitterFrequency",freq, ... % Units: Hz
    "TransmitterPower",80);
elevenb = A_resampled(ceil((enb.Latitude - R_resampled.LatitudeLimits(1))/...
        R_resampled.CellExtentInLatitude),...
        ceil((enb.Longitude - R_resampled.LongitudeLimits(1))/...
        R_resampled.CellExtentInLongitude));
[enbX, enbY, enbzone] = utils.deg2utm(enb.Latitude, enb.Longitude);
centro_i =  R_resampled.CellExtentInLatitude / 2;
centro_j =  R_resampled.CellExtentInLongitude / 2;
latitudes = R_resampled.LatitudeLimits(1):...
    R_resampled.CellExtentInLatitude:...
    R_resampled.LatitudeLimits(2);
latitudes = latitudes + centro_i;
longitudes = R_resampled.LongitudeLimits(1):...
    R_resampled.CellExtentInLongitude:...
    R_resampled.LongitudeLimits(2);
longitudes = longitudes + centro_j;
Llat = numel(latitudes)-1;
Llon = numel(longitudes)-1;
d = uiprogressdlg(uifigure);
% parfor i = 1:Llat
for n = 1:Llat
    for m = 1:Llon
        percent_exec = ((n - 1) * Llon + m)/(Llat * Llon);
        d.Message = sprintf('Executado: %.1f %%', (percent_exec * 100));
        d.Value = percent_exec;
        run_P1812 = model.P1812(enb, ...
            rxsite("Latitude",latitudes(n), ...
            "Longitude", longitudes(m), ...
            "AntennaHeight",1.7), ...
            A_resampled, R_resampled, enbX, enbY, enbzone, elevenb);
        Pwr_rx(n, m) = run_P1812.PRX;
        Lb(n ,m) = run_P1812.Lb;
    end
end
d.close();
figure
axesm('MapProjection','mercator','MapLatLimit',R_resampled.LatitudeLimits+[-1 1])
geoshow(Lb, R_resampled, DisplayType="texturemap")
geoshow(enb.Latitude,enb.Longitude,DisplayType="point",ZData=elevenb, ...
    MarkerEdgeColor="k",MarkerFaceColor="c",MarkerSize=10,Marker="o")

colormap(turbo)
text1 = "eNB";
delta = 0.0005;
textm(enb.Latitude+delta,enb.Longitude+delta,text1)
cb = colorbar;
cb.Label.String = "Atenuação (dB)";