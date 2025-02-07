function [A, R] = read_clutter(nome_arquivo)
    %----------------------------------------------------------------------
    % Carrega os dados de um geotiff contendo informações de clutter e
    % transpõem os valores de representação para o formato adequado ao script
    % model/p1812/tl_p1812.m:
    % água/mar(1), aberto/rural (2), suburbano (3), urbano/árvores/floresta (4),
    % urbano denso (5)
    %
    % A: matriz de represntação de clutter
    % R: estrutura de definição da matriz A
    % nome_arquivo: localização/nome do arquivo contendo as informações de
    % clutter
    %----------------------------------------------------------------------
    % Validação do argumento
    
    arguments
        
        nome_arquivo string
        
    
    end
    
    %----------------------------------------------------------------------
    % carrega os dados de clutter do arquivo geotiff
    
    [A, R] = readgeoraster(nome_arquivo);
    
    %----------------------------------------------------------------------
    % traspõe os valores da classificação do arquivo carregado
    % para a definição do tl_p1812
    
    A(ismember(A, [3 4 14 15])) = 4;
    A(ismember(A, [5 6 26])) = 3;
    A(ismember(A, [1 2])) = 5;
    A(ismember(A, [0 7 8 9 10 11 12 13 16 17 18 19 22 23 25 27 28])) = 2;
    A(ismember(A, [20 21 24])) = 1;
    
    %----------------------------------------------------------------------

end

