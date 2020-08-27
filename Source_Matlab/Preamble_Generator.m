clc
clear

Preamble_Len = 64;
Preamble = zeros(1, Preamble_Len);
for idx = 1:Preamble_Len
    if rand > 0.5
        Preamble(idx) = 0;
    else
        Preamble(idx) = 1;
    end
end

dlmwrite('Preamble.txt', strrep(num2str(Preamble),' ',''), 'delimiter', '')
Preamble = Preamble.*2-1;
cor_func = xcorr(Preamble);
