function BW = segComp(X,raw)
%segmentImage Segment image using auto-generated code from imageSegmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the imageSegmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 18-Apr-2020
%----------------------------------------------------


% Normalize input data to range in [0,1].
Xmin = min(X(:));
Xmax = max(X(:));

if isequal(Xmax,Xmin)
    X = 0*X;
else
    X = (X - Xmin) ./ (Xmax - Xmin);
end
%X=imadjust(X);
% Auto clustering
%ori=X;

contrast = 5;
BW= false(size(X));
processed_map=false(size(X));
itr=1;

count=0;
while any(contrast > 1.5) && any(~processed_map,'all') && count<26
    contrast=[];
    status=strcat('Iteration round: ',num2str(itr));
    disp(status);
    [x_loc,y_loc]=find(X==max(X(~processed_map),[],'all'));
    for i=1:length(x_loc)
        if processed_map(x_loc(i),y_loc(i))
            continue
        end
        temp=squeeze(raw(x_loc(i),y_loc(i),:));
        corr_map=zeros(size(X));
        status=strcat('Processing seed: ',num2str(i),'/',num2str(length(x_loc)));
        disp(status);
        for m=1:size(raw,1)
            parfor n=1:size(raw,2)
                target=squeeze(raw(m,n,:));
                corr_temp=corrcoef(temp,target);
                corr_map(m,n)=corr_temp(1,2);
            end
        end
        corr_threshold=imbinarize(corr_map,0.97);
        labeled_map=bwlabel(corr_threshold);
        target_idx=labeled_map(x_loc(i),y_loc(i));
        target_mask=labeled_map==target_idx;
        stats = regionprops(target_mask,'Area','BoundingBox');
        if stats.Area>50000
            corr_threshold=imbinarize(corr_map,0.99);
            labeled_map=bwlabel(corr_threshold);
            target_idx=labeled_map(x_loc(i),y_loc(i));
            target_mask=labeled_map==target_idx;
            stats = regionprops(target_mask,'Area','BoundingBox');
        end
        xlim_low_1=max([1,round(stats.BoundingBox(1)-10)]);
        ylim_low_1=max([1,round(stats.BoundingBox(2)-10)]);
        xlim_high_1=min([xlim_low_1+stats.BoundingBox(3)+20,size(raw,1)]);
        ylim_high_1=min([ylim_low_1+stats.BoundingBox(4)+20,size(raw,2)]);

        rough_region=X(ylim_low_1:ylim_high_1,xlim_low_1:xlim_high_1);
        s = rng;
        rng('default');

        %wavelength=[2,4,8];
        %orientation = 0:45:135;
        %g = gabor(wavelength,orientation);
        %gabormag = imgaborfilt(double(rough_region),g);
        corr_map(isnan(corr_map))=0;
        featureSet = cat(3,rough_region,corr_threshold(ylim_low_1:ylim_high_1,xlim_low_1:xlim_high_1));
        
        L = imsegkmeans(single(featureSet),2,'NormalizeInput',true,'NumAttempts',2);
        mean1=prctile(rough_region(L==1),99,'all');
        mean2=prctile(rough_region(L==2),99,'all');
        mean_sum=[mean1,mean2];
        [~,tar]=max(mean_sum);
        temp_mask=L==tar;
        temp_num=X(temp_mask);
        if length(find(temp_num==0.0123))/length(temp_num) > 0.1
           processed_map(ylim_low_1:ylim_high_1,xlim_low_1:xlim_high_1)=true;      
           continue
        end    
        
        DE = strel('disk',10,4); 
        updated_mask= bwareafilt(imdilate(temp_mask, DE),1);
        
        stats = regionprops(updated_mask,'BoundingBox');
        xlim_low=max([1,round(stats.BoundingBox(1))]);
        ylim_low=max([1,round(stats.BoundingBox(2))]);
        xlim_high=min([xlim_low+stats.BoundingBox(3),size(rough_region,2)]);
        ylim_high=min([ylim_low+stats.BoundingBox(4),size(rough_region,1)]);
        rough_region2=rough_region(ylim_low:ylim_high,xlim_low:xlim_high);
        updated_mask=temp_mask(ylim_low:ylim_high,xlim_low:xlim_high);
        % Erode mask with disk
        size_est=sqrt(sum(updated_mask,'all'));
        
        radius = ceil(size_est/50);
        decomposition = 0;
        se = strel('disk', radius, decomposition);
        updated_mask2 = imerode(updated_mask, se);

        %calculate SNR
        med1=prctile(rough_region2(updated_mask2),75,'all');
        med2=prctile(rough_region2(~updated_mask2),75,'all');
        con_temp=med1/med2;
        if isnan(con_temp)
            con_temp=1;
        elseif isinf(con_temp)
            con_temp=2;
        end
        contrast=[contrast,con_temp];
        num_mask_pix=length(rough_region2(updated_mask));
        rough_region2(updated_mask)=ones(num_mask_pix,1).*0.0123;      
        
        X((ylim_low_1+ylim_low-1):(ylim_low_1+ylim_high-1),(xlim_low_1+xlim_low-1):(xlim_low_1+xlim_high-1))=rough_region2;
        processed_map((ylim_low_1+ylim_low-1):(ylim_low_1+ylim_high-1),(xlim_low_1+xlim_low-1):(xlim_low_1+xlim_high-1))=true;
        %update mask/raw image
        if con_temp>1.5
            BW((ylim_low_1+ylim_low-1):(ylim_low_1+ylim_high-1),(xlim_low_1+xlim_low-1):(xlim_low_1+xlim_high-1))=updated_mask2;       
            count=count+1;
        end
    end
    itr=itr+1;
    
end


end

