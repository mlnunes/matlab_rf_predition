classdef P1812
    properties
        Lb
        PRX
    end

    methods
        function obj = P1812(siteTX, siteRX, A, R, C, S, gAnt, p, pL, sigmaL)
            % siteTX, siteRX:   classe Site de iteresse
            % A, R:             geoTiff [A, R] dados de elevalção
            % C, S:             geoTiff [C, R] dados de clutter
            % p:                Nível de disponibilidade requerido para transmissão
            %                   
            % pL:               Percentagem de tempo em que a perda de transmissão 
            %                   não ultrapassa o valor calculado (entre 1% e 99%)
            % sigmal:           Desvios padrão da variabilidade espacial calculados
            %                   utilizando o método stdDev.m, conforme descrito nos
            %                   itens 4.8 e 4.10 da recomendação 1812
            % gAnt:             ganho da antena na direção (dB)
            % Lb:               atenuação (dB)
            % p_rx:             Intensidade de campo elétrico (V/m
            

            % bloco arguments (conversão, validação, valor padrão)
            arguments
                siteTX 
                siteRX 
                A 
                R 
                C 
                S
                gAnt = 0
                p = 1 
                pL = 50 
                sigmaL = 0

            end

            PTX = siteTX.TransmitterPower / 1e3;
            [perfil_distancia, perfil_elevacao, perfil_clutter] = utils.levanta_perfil(siteTX, siteRX, A, R, C, S);
            
            %--------------------------------------------------------------
            % calcula o array de alturas adicional conforme a classificação
            % de clutter REC P1812.7 seção 3.2.1, tabela 2
            alturas_clutter = perfil_clutter;
            alturas_clutter(ismember(alturas_clutter, [1 2])) = 0;
            alturas_clutter(alturas_clutter == 3) = 10;
            alturas_clutter(alturas_clutter == 4) = 15;
            alturas_clutter(alturas_clutter == 5) = 20;

            idx = size(perfil_distancia, 2);

            if idx > 2
                [obj.Lb, obj.PRX] = tl_p1812( ...
                            siteTX.TransmitterFrequency/1e9, ...  % GHz
                            p, ...
                            perfil_distancia, ... %(1:idx)./1000, ...
                            perfil_elevacao, ... %(1:idx), ...
                            alturas_clutter, ...
                            perfil_clutter, ...
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
            obj.PRX = obj.PRX + gAnt;
            obj.Lb = obj.Lb - gAnt;
        end
    end
end