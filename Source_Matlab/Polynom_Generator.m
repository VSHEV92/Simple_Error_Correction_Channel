clc
clear

K = 16;          % размер слова до кодирования
N = 31;          % размер слова после кодирования

[genpoly,t] = bchgenpoly(N, K);

t
length(genpoly.x)
dlmwrite('polynom.txt',genpoly.x, 'delimiter', '')
