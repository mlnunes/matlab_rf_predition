%--------------------------------------------------------------------------
% Entrada de dados para predição de cobertura
%--------------------------------------------------------------------------

dadosPredicao = struct;

% Gerais
dadosPredicao.modeloPredicao = 'Hata';
dadosPredicao.frequencia = 102.1e6;
dadosPredicao.dadosRelevo = 'data/terreno_carangola.tif';
dadosPredicao.dadosClutter = '';
  
% Dados estação móvel
dadosPredicao.Movel.Antena.Altura= 1.6;

% Dados estação base
dadosPredicao.Base.Nome = 'FM Carangola';
dadosPredicao.Base.Latitude =  -20.725683333333333;
dadosPredicao.Base.Longitude = -42.03616666666667;
dadosPredicao.Base.Potencia = 275.5;
dadosPredicao.Base.Antena.Altura = 8;
dadosPredicao.Base.Antena.ArquivoDados = "data/AIR6419_B42_NR_dlMacro_H0_V0_3500_PWR.msi";
dadosPredicao.Base.Antena.Modelo = "AIR6419";
dadosPredicao.Base.Antena.Funcao = "TX";
dadosPredicao.Base.Antena.Azimute = 0;
dadosPredicao.Base.Antena.tiltMecanico = 0;
dadosPredicao.Base.Antena.Tipo = 'isotropic';
