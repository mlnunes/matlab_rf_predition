classdef Hata < handle
    %----------------------------------------------------------------------
    % Cálculo de predição de cobertura conforme modelo COST-231/Hata
    %
    % Lb: atenuação resultante (dB)
    % PRX: potência recebida (dBm)
    % siteTX: classe TX
    % siteRX: classe RX
    % A, R: geoTiff [A, R] dados de elevação
    % C, S: geoTiff [A, R] dados de clutter
    %----------------------------------------------------------------------
    properties
        Lb double
        PRX double
        siteTX txsite
        siteRX rxsite
        A (:, :) double
        R
        C (:, :) double
        S
    end

    methods
        function obj = Hata(siteTX, siteRX, A, R, C, S)
            obj.siteTX = siteTX;
            obj.siteRX = siteRX;
            obj.A = A;
            obj.R = R;
            obj.C = C;
            obj.S = S;
        end

        function calculo(obj, gAnt)
            %--------------------------------------------------------------
            % Calcula o nivel de sinal recebido e a atenuação até a estação
            % de recepção
            % gAnt: ganho da antena
            %--------------------------------------------------------------
            arguments
                obj 
                gAnt double
            end
            
            PTX = log10(obj.siteTX.TransmitterPower/1e-3);
            hTX = obj.siteTX.AntennaHeight;
            hRX = obj.siteRX.AntennaHeight;
            [n, m] = utils.get_raster_idx(obj.siteRX.Latitude, obj.siteRX.Longitude, obj.R);
            elevRX = obj.A(n, m);
            [n, m] = utils.get_raster_idx(obj.siteTX.Latitude, obj.siteTX.Longitude, obj.R);
            elevTX = obj.A(n, m);
            d = utils.Propagation.Distance(obj.siteTX, obj.siteRX, "km");
            freq = obj.siteTX.TransmitterFrequency/1e6;

            if (hTX  + elevTX) > (hRX + elevRX)
                hTX = (hTX  + elevTX) - (hRX + elevRX);
                if hTX < 10.0
                    hRX = 10.0 - hTX;
                    hTX = 10.0;
                end
            else
                hTX = (hRX + elevRX) - (hTX  + elevTX);
            end
            hTX = cast(hTX, 'double');
            dist_enlace = sqrt(((hTX/1000)^2 + d^2));
            ahrx = (1.1* log10(freq)-0.7)*hRX-(15.56*log10(freq)-0.8);
            L = 69.55+26.16*log10(freq)-13.82*log10(hTX)-ahrx+(44.9-6.55*log10(hTX))*log10(dist_enlace);
            obj.Lb = L - gAnt;
            obj.PRX = PTX + gAnt - L;
        end
    end
end