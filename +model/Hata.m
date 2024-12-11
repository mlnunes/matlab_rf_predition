classdef Hata
    properties
        Lb
        PRX
    end

    methods
        function obj = Hata(freq, hTX, elevTX, hRX, elevRX, d, PTX, Gh, Gv, Gmax)
            switch nargin
                case 6
                    PTX = 0;
                    Gh = 0;
                    Gv = 0;
                    Gmax = 0;
                case 7
                    PTX = log10(PTX/(1e-6));
                    Gh = 0;
                    Gv = 0;
                    Gmax = 0;
                otherwise
            end
            Gant = Gmax + Gv + Gh;
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
            obj.Lb = 69.55+26.16*log10(freq)-13.82*log10(hTX)-ahrx+(44.9-6.55*log10(hTX))*log10(dist_enlace);
            obj.PRX = PTX + Gant - obj.Lb;
        end
    end
end