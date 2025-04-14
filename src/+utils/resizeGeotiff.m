function [AA, RR] = resizeGeotiff(A, R)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    s = R.RasterSize;
    rows = s(1);
    cols = s(2);
    newRows = ceil(rows / 3);
    newCols = ceil(cols / 3);
    AA = zeros(newRows, newCols);

    AA(1, 1) = mean(A(1: 3, 1 : 3), "all");    
    for r = 1 : newRows - 1
        for c = 1 : newCols - 1
            uR = 3 * r + 3;
            uC = 3 * c + 3;
            if uR > rows
                uR = rows;
            end

            if uC > cols
                uC = cols;
            end

            AA(r, c) = mean(A(3 * r + 1 : uR, 3 * c + 1 : uC), "all");

        end
    end

    RR = R;
    RR.RasterSize= [newRows, newCols];

end