clc
clear

K = 16;          % ������ ����� �� �����������
N = 31;          % ������ ����� ����� �����������

[genpoly,t] = bchgenpoly(N, K);

t
length(genpoly.x)
dlmwrite('polynom.txt',genpoly.x, 'delimiter', '')
