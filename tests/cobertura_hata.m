clear;
%parpool('local', 4)
freq = 778e6;
movel_hrx = 1.6;
[A,R] = readgeoraster("data/terreno_col.tif");
A = double(A);
res_atual = ((R.LatitudeLimits(2) - R.LatitudeLimits(1))/R.RasterSize(1));
fator_escala = 5;
res_nova = res_atual/fator_escala;
A_resampled = repelem(A, fator_escala, fator_escala);
Pwr_rx = zeros(size(A_resampled));
Lb = zeros(size(A_resampled));
R_resampled = R;
R_resampled.RasterSize = size(A_resampled);
enb = txsite("Name","enb", ...
    "Latitude",-19.84413056, ...
    "Longitude",-43.94696389, ...
    "Antenna",design(dipole,freq), ...
    "AntennaHeight",16, ...        % Units: meters
    "TransmitterFrequency",freq, ... % Units: Hz
    "TransmitterPower",80);
ponto = rxsite(Name="Pt", Latitude=-19.84413056,Longitude=-43.94696389);
elevenb = geointerp(A, R, enb.Latitude, enb.Longitude, "nearest");
[enbX, enbY, enbzone] = utils.deg2utm(enb.Latitude, enb.Longitude);
centro_i =  R_resampled.CellExtentInLatitude / 2;
centro_j =  R_resampled.CellExtentInLongitude / 2;
latitudes = R_resampled.LatitudeLimits(1):...
    R_resampled.CellExtentInLatitude:R_resampled.LatitudeLimits(2);
longitudes = R_resampled.LongitudeLimits(1): ...
    R_resampled.CellExtentInLongitude:R_resampled.LongitudeLimits(2);
latitudes = latitudes + centro_i;
longitudes = longitudes + centro_j;
Llat = numel(latitudes)-1;
Llon = numel(longitudes)-1;
for n = 1:Llat
    for m = 1:Llon
        ponto.Latitude = latitudes(n);
        ponto.Longitude = longitudes(m);
        elevponto = A_resampled(n, m);
        [distKm, Azimuth] = utils.Propagation.Distance(enb, ponto);
        hata = model.Hata(enb.TransmitterFrequency /1e6, ...
            enb.AntennaHeight, elevenb, movel_hrx, elevponto, distKm);
        Lb(n, m) = hata.Lb;
        Pwr_rx(n, m) = hata.PRX;
    end
end

figure
axesm('MapProjection','mercator','MapLatLimit',...
    R_resampled.LatitudeLimits+[-1 1])
%usamap(A_resampled, R_resampled)
geoshow(Lb, R_resampled, DisplayType="texturemap")
geoshow(enb.Latitude,enb.Longitude,DisplayType="point",ZData=elevenb, ...
    MarkerEdgeColor="k",MarkerFaceColor="c",MarkerSize=10,Marker="o")

colormap(turbo)
text1 = "eNB";
delta = 0.0005;
textm(enb.Latitude+delta,enb.Longitude+delta,text1)
cb = colorbar;
cb.Label.String = "Atenuação (dB)";