function Image = Create_Image()

% высота и ширина картинки
Image_Hight = 400;
Image_Width = 300;
Image = zeros(Image_Hight, Image_Width);

% число квадратов на картинке по вертикали и горизонтали
Sqr_RoW = 8;
Sqr_Col = 6;
fill_value = logical(1);
 
for row = 1:Sqr_RoW
    for col = 1:Sqr_Col
       Image((1+(row-1)*Image_Hight/Sqr_RoW):row*Image_Hight/Sqr_RoW, (1+(col-1)*Image_Width/Sqr_Col):col*Image_Width/Sqr_Col) = fill_value;
       fill_value = not(fill_value);
    end
    fill_value = not(fill_value);
end

%imshow(Image)

end
