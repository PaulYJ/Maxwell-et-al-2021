function updated_mask=mask_optimize(ori,mask_temp)    
    
    %mask_temp=plaque_map_th==2;
    ori_mask=mask_temp;
    addition_sum =100;
    count= 1;
    iteration=1;
    while addition_sum >10
        peri = bwboundaries(mask_temp);
        temp=cell2mat(peri);
        start_state=zeros(size(temp,1),1);
        for n = 1:size(temp,1)
            start_state(n)=ori(temp(n,1),temp(n,2));
        end
        
%         [N,edge] = histcounts(start_state,'BinWidth',5);
%         [~,max_idx]=max(N);
%         fit_temp_x= edge(1:max_idx);
%         fit_temp_y= N(1:max_idx);
% 
%         [xData, yData] = prepareCurveData( fit_temp_x, fit_temp_y );
%         ft = fittype( 'gauss1' );
%         opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
%         opts.Display = 'Off';
%         opts.Lower = [-Inf xData(end)-5 0];
%         opts.Robust = 'Bisquare';
%         opts.StartPoint = [max(yData) fit_temp_x(end) std(xData)];
%         opts.Upper = [Inf xData(end)+5 Inf];
%         [fitresult, ~] = fit( xData, yData, ft, opts );
        dynamic_threshold=mean(start_state)-(1.25-0.1*(iteration-1))*std(start_state);
        SE = strel('disk',2,4);
        BW = imdilate(mask_temp,SE);
        ITE= logical(BW-mask_temp);
        mask_threshold=ori>dynamic_threshold;

        addition=ITE.*mask_threshold;
        addition_sum = sum(addition,'all');
        
        updated_mask=addition + mask_temp;
        mask_temp=logical(updated_mask);
%         figure
%         imagesc(ori.*updated_mask);
        count = count + 1;
        
        if count >50
            count = 1;
            iteration = iteration + 1;
            mask_temp=ori_mask;
        end    
    end
    updated_mask=logical(updated_mask);
end