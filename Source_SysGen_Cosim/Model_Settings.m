clc
clear

Clock_Freq = 20 * 10^6;     %%% частота тактового сигнала в Гц
Data_Rate = Clock_Freq/10;   %%% скорость данных в бит/с

% задержка в канале
Channel_Delay = 10;

% верояность ошибки в канале
Channel_Err_Prob = 0.02;

% параметры помехи
Intererence_Mean_Period = 1500;       % средняя длительность между импульсами помехи в отсчетах
Intererence_Error_Probability = 0.5; % вероятность инверсии бита во время импульса помехи
Intererence_Max_Width = 80;          % максимальная длительность импульса помехи в отсчетах 

% формируем тестовое изображение
Image = Create_Image();

% преобразуем изображение в строку
[Hight Width] = size(Image);
Image = reshape(Image',[1, Hight*Width]);
