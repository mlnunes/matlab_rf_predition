classdef P1812
    properties
        Lb
        PRX
    end

    methods
        function obj = P1812(siteTX, siteRX, A, R, siteTXX, siteTXY, siteTXzone, elevsiteTX, p, pL, sigmaL, Gh, Gv, Gmax)
            % siteTX, siteRX:   classe Site de iteresse
            % A, R:             geoTiff [A, R]
            % p:                Nível de disponibilidade requerido para transmissão
            %                   
            % pL:               Percentagem de tempo em que a perda de transmissão 
            %                   não ultrapassa o valor calculado (entre 1% e 99%)
            % sigmal:           Desvios padrão da variabilidade espacial calculados
            %                   utilizando o método stdDev.m, conforme descrito nos
            %                   itens 4.8 e 4.10 da recomendação 1812
            % Gh:               ganho horizontal da antena transmissora (dB)
            % Gv:               ganho veritcal da antena receptora (dB)
            % Gmax:             ganho máximo da antena (dB)
            % Lb:               atenuação (dB)
            % p_rx:             Intensidade de campo elétrico (V/m
            

            % bloco arguments (conversão, validação, valor padrão)
            switch nargin
                case 8
                    p = 1;
                    pL = 50;
                    sigmaL = 0;
                    Gh = 0;
                    Gv = 0;
                    Gmax = 0;
                case 9
                    pL = 50;
                    sigmaL = 0;
                    Gh = 0;
                    Gv = 0;
                    Gmax = 0;
                otherwise
            end
            Gant = Gmax + Gv + Gh;
            % [dist, Azimuth] = utils.Propagation.Distance(siteTX, siteRX);
            % direcao = mod((450 - Azimuth), 360);
            %PTX = (10^((10*log10(siteTX.TransmitterPower) + Gant)/10)) / 1e3; % pow2db
            PTX = siteTX.TransmitterPower / 1e3;
            [perfil_distancia, perfil_elevacao] = utils.levanta_perfil(siteTX, siteRX, A, R);
            idx = size(perfil_distancia, 2);

            if idx > 2
                [obj.Lb, obj.PRX] = tl_p1812( ...
                            siteTX.TransmitterFrequency/1e9, ...  % GHz
                            p, ...
                            perfil_distancia, ... %(1:idx)./1000, ...
                            perfil_elevacao, ... %(1:idx), ...
                            zeros(1, idx), ...
                            3 * ones(1, idx), ...
                            4 * ones(1, idx),... 
                            siteTX.AntennaHeight, ...
                            siteRX.AntennaHeight, ...
                            1, ...
                            'phi_t', siteTX.Latitude, ...
                            'phi_r', siteRX.Latitude, ...
                            'lam_t', siteTX.Longitude, ...
                            'lam_r', siteRX.Longitude, ...
                            'pL', pL, ...
                            'sigmaL', sigmaL, ...
                            'Ptx', PTX);
            else
                obj.PRX = PTX;
                obj.Lb = 0;
            end
        end
    end
end