clear
history
'history' is used in Neutral DDE with Two Delays.
 
siteA = Site(0,0,100e6)

siteA = 

  Site with properties:

                Latitude: 0
               Longitude: 0
    TransmitterFrequency: 100000000

siteB(0,0.009,100e6);
Unrecognized function or variable 'siteB'.
 
Did you mean:
siteB = Site(0,0.009,100e6);
Propagation.Distance(siteA, siteB)

ans =

    1.0008

Propagation.Distance(siteA, siteB, 'km')

ans =

    1.0008

Propagation.Distance(siteA, siteB, m)
Unrecognized function or variable 'm'.
 
Propagation.Distance(siteA, siteB, 'm')

ans =

   1.0008e+03

[pathLoss, distKm, Azimuth] = RF.CallPathLoss(siteA, siteB, 'Free space');
The class RF has no Constant property or Static method named 'Propagation'.

Error in Propagation.PathLoss (line 12)
             [distKm, Azimuth] = RF.Propagation.Distance(txSite, rxSite);

Error in RF.CallPathLoss (line 5)
            [pathLoss, distKm, Azimuth] = Propagation.PathLoss(txSite, rxSite, propModel);
 
[pathLoss, distKm, Azimuth] = Propagation.PathLoss(siteA, siteB, 'Free space')
The class RF has no Constant property or Static method named 'Propagation'.

Error in Propagation.PathLoss (line 12)
             [distKm, Azimuth] = RF.Propagation.Distance(txSite, rxSite);
 
[pathLoss, distKm, Azimuth] = RF.CallPathLoss(siteA, siteB, 'Free space');
The class RF has no Constant property or Static method named 'Propagation'.

Error in Propagation.PathLoss (line 12)
             [distKm, Azimuth] = RF.Propagation.Distance(txSite, rxSite);

Error in RF.CallPathLoss (line 5)
            [pathLoss, distKm, Azimuth] = Propagation.PathLoss(txSite, rxSite, propModel);
 
Propagation.Distance(siteA, siteB, 'm')

ans =

   1.0008e+03

[pathLoss, distKm, Azimuth] = Propagation.PathLoss(siteA, siteB, 'Free space')

pathLoss =

   72.4543


distKm =

    1.0008


Azimuth =

    90

siteA

siteA = 

  Site with properties:

                Latitude: 0
               Longitude: 0
    TransmitterFrequency: 100000000

siteB

siteB = 

  Site with properties:

                Latitude: 0
               Longitude: 0.0090
    TransmitterFrequency: 100000000

 20+43/60+32.46/3600

ans =

   20.7257

42+2/60+10.02/3600

ans =

   42.0361

siteA = Site(_, __, 102.1e6)
 siteA = Site(_, __, 102.1e6)
              ↑
Error: Invalid text character. Check for unsupported symbol, invisible character, or pasting of non-ASCII characters.
 
siteA = Site(20.7257, 42.0361, 102.1e6)

siteA = 

  Site with properties:

                Latitude: 20.7257
               Longitude: 42.0361
    TransmitterFrequency: 102100000

siteB = Site(20.7167, 42.0361, 102.1e6)

siteB = 

  Site with properties:

                Latitude: 20.7167
               Longitude: 42.0361
    TransmitterFrequency: 102100000

[pathLoss, distKm, Azimuth] = Propagation.PathLoss(siteA, siteB, 'Free space')

pathLoss =

   72.6348


distKm =

    1.0008


Azimuth =

   180

0.7167*60

ans =

   43.0020

0.002*3600

ans =

    7.2000

load('perfil.mat')
load('perfil.mat', 'elevation')
load('perfil.mat', 'distance')
x = load('perfil.mat', 'distance')

x = 

  struct with fields:

    distance: [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 … ] (1×779 double)

y = load('perfil.mat', 'elevation');
plot(x,y)
Error using plot
Not enough input arguments.
 
plot(x,y)
Error using plot
Not enough input arguments.
 
figure(1)
plot(x,y)
Error using plot
Not enough input arguments.
 
plot.show()
Dot indexing into the result of a function call requires parentheses after the function name. The supported syntax is 'plot().show'.
 
load('perfil.mat', 'elevation')
figure;plot(elevation,distance)
Warning: MATLAB has disabled some advanced graphics rendering features by switching to software OpenGL. For more information, click
here. 
figure;plot(distance,elevation)



[A,R] = readgeoraster("terreno_col.tif");
enb = Site(-19.84413056, -43.94696389, 778e6);
[enbX, enbY, enbzone] = deg2utm(enb.Latitude, enb.Longitude);
enbU = [enbX, enbY];
ponto = Site(-19.8433545, -43.947591499999994, 778e6);
elevenb = A(ceil(R.latitudeToIntrinsicY(enb.Latitude)), ceil(R.longitudeToIntrinsicX(enb.Longitude)));
elevponto = A(ceil(R.latitudeToIntrinsicY(ponto.Latitude)), ceil(R.longitudeToIntrinsicX(ponto.Longitude)));
[pathLoss, distKm, Azimuth] = Propagation.PathLoss(enb, ponto, 'Free space');
direcao = mod((450 - Azimuth), 360);
perfil_elevacao = [];
perfil_distancia = 2:2:ceil(distKm*1000);
cosseno = cos(direcao * pi/180);
seno = sin(direcao * pi/180);
qxs = [];
qys = [];

for i = perfil_distancia
    qx = enbU(1) + cosseno * i;
    qy = enbU(2) + seno * i;
    [projecao_lat, projecao_lon] = utm2deg(qx, qy, enbzone);
    qx = projecao_lon;
    qy = projecao_lat;
    qxs = [qxs; qx];
    qys = [qys; qy];
    elev = A(ceil(R.latitudeToIntrinsicY(qy)),  ceil(R.longitudeToIntrinsicX(qx)));
    perfil_elevacao = [perfil_elevacao, elev];
end

[attHata, p_rx] = hata(enb.TransmitterFrequency /1e6, 16, elevenb, 1.6, elevponto, distKm);

%elevenb = A(ceil(R.latitudeToIntrinsicY(enb.Latitude)), ceil(R.longitudeToIntrinsicX(enb.Longitude)));
%[X, Y] = meshgrid(longitudes(1: end - 1), latitudes(1 : end - 1));
%s = surface(X, Y, A_resampled)
%s.EdgeColor = 'none';
%parfor for i = 1:Llat
%enbU = [enbX, enbY];