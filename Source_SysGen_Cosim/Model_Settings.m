clc
clear

Clock_Freq = 20 * 10^6;     %%% ������� ��������� ������� � ��
Data_Rate = Clock_Freq/10;   %%% �������� ������ � ���/�

% �������� � ������
Channel_Delay = 10;

% ���������� ������ � ������
Channel_Err_Prob = 0.02;

% ��������� ������
Intererence_Mean_Period = 1500;       % ������� ������������ ����� ���������� ������ � ��������
Intererence_Error_Probability = 0.5; % ����������� �������� ���� �� ����� �������� ������
Intererence_Max_Width = 80;          % ������������ ������������ �������� ������ � �������� 

% ��������� �������� �����������
Image = Create_Image();

% ����������� ����������� � ������
[Hight Width] = size(Image);
Image = reshape(Image',[1, Hight*Width]);
