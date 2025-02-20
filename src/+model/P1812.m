classdef P1812 < model.base
    %----------------------------------------------------------------------
    % Cálculo de predição de cobertura conforme modelo ITU-R P.1812-6
    %----------------------------------------------------------------------

    methods
        
        function calculo(obj, gAnt, p, pL, sigmaL)
            %--------------------------------------------------------------
            % Calcula o nivel de sinal recebido e a atenuação até a estação
            % de recepção
            % gAnt: ganho da antena
            % p:                Nível de disponibilidade requerido para transmissão          
            % pL:               Percentagem de tempo em que a perda de transmissão 
            %                   não ultrapassa o valor calculado (entre 1% e 99%)
            % sigmal:           Desvios padrão da variabilidade espacial calculados
            %                   utilizando o método stdDev.m, conforme descrito nos
            %                   itens 4.8 e 4.10 da recomendação 1812
            %--------------------------------------------------------------
            arguments
                obj 
                gAnt double
                p = 1
                pL = 50
                %--------------------------------------------------------------
                % Cálculo do sigma L segundo a eq. 64 da recomendação:
                % sigmal = ((0.024*freq+0.52)*(resolução do mapa))^0.28
                %--------------------------------------------------------------
                sigmaL = ((24e-3 * (obj.siteTX.TransmitterFrequency/1e9) + 0.52) * (obj.R.CellExtentInLatitude * 111320))^(0.28)
            end

 
            PTX = obj.siteTX.TransmitterPower / 1e3;
            [perfil_distancia, perfil_elevacao, perfil_clutter] = utils.levanta_perfil(obj.siteTX, obj.siteRX, obj.A, obj.R, obj.C, obj.S);
            
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
                [obj.Lb, obj.PRX] = tl_p1812( obj.siteTX.TransmitterFrequency/1e9, ...  % GHz
                            p, ...
                            perfil_distancia, ... %(1:idx)./1000, ...
                            perfil_elevacao, ... %(1:idx), ...
                            alturas_clutter, ...
                            perfil_clutter, ...
                            4 * ones(1, idx),... 
                            obj.siteTX.AntennaHeight, ...
                            obj.siteRX.AntennaHeight, ...
                            1, ...
                            'phi_t', obj.siteTX.Latitude, ...
                            'phi_r', obj.siteRX.Latitude, ...
                            'lam_t', obj.siteTX.Longitude, ...
                            'lam_r', obj.siteRX.Longitude, ...
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