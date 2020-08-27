clc
clear

K = 16;          % ������ ����� �� �����������
N = 31;          % ������ ����� ����� �����������


%%% ���������� ����������� �������
[genpoly,t] = bchgenpoly(N, K);
BCH_Polynom = double(genpoly.x);
Parity_Matix = cyclgen(N, BCH_Polynom);

syndrom = syndtable(Parity_Matix);

dlmwrite('syndrome_mem.txt', '{', 'delimiter', '')

for idx = 1:2^(N-K)-1
    dlmwrite('syndrome_mem.txt', strcat(num2str(N),'''b', strrep(num2str(syndrom(idx,:)),' ',''), ','), 'delimiter', '', '-append')
end

dlmwrite('syndrome_mem.txt', strcat(num2str(N),'''b', strrep(num2str(syndrom(2^(N-K),:)),' ','')), 'delimiter', '', '-append')
dlmwrite('syndrome_mem.txt', '};', '-append', 'delimiter', '')

