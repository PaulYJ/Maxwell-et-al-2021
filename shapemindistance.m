function mindistance=shapemindistance(shape1,shape2)

    len1=size(shape1,1);
    len2=size(shape2,1);
    if len1 > len2
        temp1=shape2;
        temp2=shape1;
    else
        temp1=shape1;
        temp2=shape2;
    end
    
    group_dis=[];
    for i = 1:size(temp1,1)
        temp = [];
        temp = sqrt((temp1(i,1)-temp2(:,1)).^2+(temp1(i,2)-temp2(:,2)).^2);
        group_dis(i)=min(temp);
    end
    mindistance=min(group_dis);

end