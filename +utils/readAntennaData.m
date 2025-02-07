function antenaObj = readAntennaData(filename, Nome, Tipo, Azimute, Tilt_mec)
    %----------------------------------------------------------
    % Carrega a função parse para cada extensão de arquivo de 
    % definição de características de antena e retorna um objeto
    % da classe utils/antena
    %
    % filename: arquivo de dados da antena
    % Nome: nome ou modelo da antena
    % Tipo: uso como 'TX' ou 'RX'
    % Azimute: azimute da antena (GMS)
    % Tilt_mec: valor da inclinação mecânica (+90° a -90°) GMS
    %
    %-----------------------------------------------------------

    arguments

        filename {mustBeFile}
        Nome char
        Tipo char {mustBeMember(Tipo, {'TX', 'RX'})} = 'TX'
        Azimute double {mustBeInRange(Azimute,0,360,"exclude-upper")} = 0.0
        Tilt_mec double {mustBeInRange(Tilt_mec,-90, 90)} = 0.0
   
    end

    %-------------------------------------------------------------
    % instancia um objeto utils.antena e carrega as propriedades
    % informadas pelos argumentos da função
    
    antenaObj = utils.antena(Nome, Tipo, Azimute, Tilt_mec);
    
    %--------------------------------------------------------------
    % verfica se o arquivo de dados da antena é do tipo .msi

    if endsWith(filename, '.msi')
        %----------------------------------------------------------
        % carrega o arquivo
    
        antenaData = utils.getMsiData(filename);
        
        %----------------------------------------------------------
        % parse dos dados
        antenaObj.Ganho = antenaData.Data(2);

        % encontra os inícios dos segmentos de dados de ganho
        idx = find(antenaData.Data == 360);

        % carrega o array de ganhos horizontais
        ganhoH = zeros((idx(2) - idx(1) - 1) ,2);

        % espelha o diagrama para o 0° corresponder a frente da antena
        ganhoH(:, 1) = wrapTo360(antenaData.NAME(idx(1)+1:idx(2)-1) - 180);

        ganhoH(:, 2) = antenaData.Data(idx(1)+1:idx(2)-1);
        antenaObj.H_ganho = double(ganhoH);

        % carrega o array de ganhos vertiais
        nRowsAntenaData = size(antenaData, 1);
        ganhoV = zeros(nRowsAntenaData - idx(2), 2);
        
        % espelha o diagrama para o 0° corresponder a frente da antena
        % alinhado com o horizonte
        ganhoV(:, 1) = wrapTo360(180 - antenaData.NAME(idx(2) + 1 : nRowsAntenaData));
        
        ganhoV(:, 2) = antenaData.Data(idx(2)+ 1 : nRowsAntenaData);
        antenaObj.V_ganho = double(ganhoV);

    else
        error("Pendente de implementação")

    end
    
end