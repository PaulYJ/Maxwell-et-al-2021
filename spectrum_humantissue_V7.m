Filename=File;
reader=bfGetReader(Filename);
omeMeta = reader.getMetadataStore();
numOfSeries=omeMeta.getImageCount();
for im = 1:numOfSeries
    CurrentSeries = im-1;
    reader.setSeries(CurrentSeries);
    numOfPlane(im)=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
end

if all(numOfPlane>2)
    IdxOfSeries=find(numOfPlane>10);
    for im = 1:length(IdxOfSeries)
        stat = strcat(string(im),' of ', string(length(IdxOfSeries)));
        disp(stat);
        CurrentSeries = IdxOfSeries(im)-1;
        reader.setSeries(CurrentSeries);
        numOfPlane_temp=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
        dim = omeMeta.getPixelsSizeX(CurrentSeries).getValue();
        xsize=omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER).doubleValue();
        %zsize=omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER).doubleValue();
        if dim>512
            continue
        end
        raw = zeros(dim, dim, numOfPlane_temp);
        for i = 1:numOfPlane_temp
                %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
                raw(:,:,i) = bfGetPlane(reader, i);
        end
        raw_lowsample=medfilt3(raw);
        [~,peak_idx]=max(raw_lowsample,[],3);
        % using a dynamic determination to the projection
        % contrast is defined by maximal - mean

        proj_plane=max(peak_idx,[],'all');
        if proj_plane<6
            project_plane=6;
        end
        if proj_plane>size(raw,3)-5
            proj_plane=size(raw,3)-5;
        end

        [peak_map,~]=max(raw_lowsample(:,:,proj_plane+2:proj_plane+5),[],3);

        %[peak_seg,~]=segComp(imgaussfilt(peak_idx,2));

        %
        %peak_map_f=imgaussfilt(peak_map,2);
        %if max(peak_map_f(peak_seg))<max(peak_map_f(~peak_seg))
        %    peak_seg=~peak_seg;
        %end
        %peak_seg = activecontour(peak_map, peak_seg, 1, 'edge');

        %[int_seg,~]=segComp(peak_map);
        %[int_seg,~]=segComp(peak_map);
        %if mean(peak_map(int_seg))<mean(peak_map(~int_seg))
        %    int_seg=~int_seg;
        %end
        disp('Starting segmentation...');
        seg_temp=segComp(peak_map,raw_lowsample);
        %int_seg = activecontour(peak_map, int_seg, 1, 'edge');

        seg_temp=bwmorph(seg_temp,'clean',3);


        [LIST,LABEL]=bwboundaries(seg_temp);
        if length(LIST)>1
            for i = 1:length(LIST)-1
                for j = i+1:length(LIST)
                    dismap(i,j)=shapemindistance(LIST{i},LIST{j});
                end
            end
            dismap(i+1,j)=0;

            disthreshold= round (8/xsize); %8 micron distance threshold
            dismap_th=((dismap>0) .* (dismap<disthreshold));
            P_CLU=graph(dismap_th,'upper');
            plaque_bins = conncomp(P_CLU);
        else
            plaque_bins = 1;
        end

        plaque_map=zeros(dim,dim);
        for i = 1:max(plaque_bins)
            plaque_idx_temp=(plaque_bins==i);
            coordinate_temp=[];
            coordinate_temp2=[];
            coordinate_temp=LIST(plaque_idx_temp);
            coordinate_temp2=cell2mat(coordinate_temp);
            for j = 1:size(coordinate_temp2,1)
                plaque_map(coordinate_temp2(j,1),coordinate_temp2(j,2))=i;
            end
        end

        area_threshold = 25;
        pix_threshold = ceil(area_threshold/xsize/xsize);
        pla_num=0;
        plaque_map_th = zeros(dim,dim);
        for i = 1:max(plaque_bins)
            plaque_temp = (plaque_map==i);
            plaque_temp = imfill(plaque_temp,'holes');
            if sum(plaque_temp,'all')>pix_threshold
                pla_num=pla_num+1;
                plaque_map_th(plaque_temp)=pla_num;
            end
        end
        

        max_pro=max(raw(:,:,end-20:end),[],3);
        plaque_map_ext = zeros(dim,dim);
        plaque_map_edge = zeros(dim,dim);
        SE2=strel('square',2);
        disp('Optimizing plaque boundaries...');
        for i = 1:pla_num           
            ext_mask=mask_optimize(max_pro,plaque_map_th==i);
            core_mask=imerode(ext_mask,SE2);
            plaque_map_edge(ext_mask)=i;
            plaque_map_ext(core_mask)=i;
        end

        [~,peak_idx]=max(raw,[],3);

        output_temp=[];
        for i = 1:pla_num
            output_temp(i).file = Filename;
            output_temp(i).series = IdxOfSeries(im);
            mask_temp = plaque_map_ext==i;
            output_temp(i).area = sum(mask_temp,'all');
            raw_temp = raw.*mask_temp;
            output_temp(i).spectrum = squeeze(mean(raw_temp,[1,2])).*512.*512./output_temp(i).area;
            output_temp(i).peakmap = peak_idx.*mask_temp;
            mask_temp2 = plaque_map_edge==i;
            output_temp(i).plaquemap=mask_temp+mask_temp2;
            raw_temp2 = raw.*(mask_temp2-mask_temp);
            output_temp(i).Edge_spectrum = squeeze(mean(raw_temp2,[1,2])).*512.*512./(sum(mask_temp2,'all')-sum(mask_temp,'all'));
            xpro=squeeze(sum(mask_temp2,1));
            xlim_up = find(xpro>0,1,'first');
            xlim_dn = find(xpro>0,1,'last');
            ypro=squeeze(sum(mask_temp2,2));
            ylim_up = find(ypro>0,1,'first');
            ylim_dn = find(ypro>0,1,'last');
            background_mask=zeros(dim,dim);
            xlim=(xlim_dn-xlim_up)*0.5;
            ylim=(ylim_dn-ylim_up)*0.5;
            xlim_up_ext=round(max(1,xlim_up-xlim));
            xlim_dn_ext=round(min(dim,xlim_dn+xlim));
            ylim_up_ext=round(max(1,ylim_up-ylim));
            ylim_dn_ext=round(min(dim,ylim_dn+ylim));
            background_mask(ylim_up_ext:ylim_dn_ext,xlim_up_ext:xlim_dn_ext)=1;
            SE = strel('disk',5,4);
            background_mask=background_mask-imdilate(mask_temp2,SE);
            background_temp=raw.*background_mask;
            output_temp(i).background = squeeze(mean(background_temp,[1,2]));
        end
        if ~isempty(output_temp)
            area_temp=[output_temp.area];
            remove_temp=find(area_temp>20000);
            output_temp(remove_temp)=[];
        end

        if exist('output','var')
            output=[output,output_temp];
        else
            output=output_temp;
        end
       

        clearvars -except Filename File reader omeMeta numOfSeries IdxOfSeries im output
    end
else
   ROI_series=find(numOfPlane==2);
   Stack_series=setdiff([1:numOfSeries],ROI_series);
   assignROI(ROI_series,Stack_series,Filename);
   disp('Press any key after finishing with ROI assignment');
   pause
   for im = 1:length(ROI)
        stat = strcat(string(im),' of ', string(length(ROI)));
        disp(stat);
        CurrentSeries = ROI(im)-1;
        reader.setSeries(CurrentSeries);
        numOfPlane_temp=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
        dim = omeMeta.getPixelsSizeX(CurrentSeries).getValue();
        xsize=omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER).doubleValue();
        %zsize=omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER).doubleValue();
        raw = zeros(dim, dim, numOfPlane_temp);
        for i = 1:numOfPlane_temp
                %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
                raw(:,:,i) = bfGetPlane(reader, i);
        end
        max_pro=max(raw,[],3);
        med_pro=medfilt2(max_pro,[2,2]);
        seg_temp=segmentSinglePlane(med_pro);
        seg_temp=bwmorph(seg_temp,'clean',3);


        [LIST,LABEL]=bwboundaries(seg_temp);
        if length(LIST)>1
            for i = 1:length(LIST)-1
                for j = i+1:length(LIST)
                    dismap(i,j)=shapemindistance(LIST{i},LIST{j});
                end
            end
            dismap(i+1,j)=0;

            disthreshold= round (10/xsize); %10 micron distance threshold
            dismap_th=((dismap>0) .* (dismap<disthreshold));
            P_CLU=graph(dismap_th,'upper');
            plaque_bins = conncomp(P_CLU);
        else
            plaque_bins = 1;
        end

        plaque_map=zeros(dim,dim);
        for i = 1:max(plaque_bins)
            plaque_idx_temp=(plaque_bins==i);
            coordinate_temp=[];
            coordinate_temp2=[];
            coordinate_temp=LIST(plaque_idx_temp);
            coordinate_temp2=cell2mat(coordinate_temp);
            for j = 1:size(coordinate_temp2,1)
                plaque_map(coordinate_temp2(j,1),coordinate_temp2(j,2))=i;
            end
        end

        area_threshold = 30;
        pix_threshold = ceil(area_threshold/xsize/xsize);
        pla_num=0;
        plaque_map_th = zeros(dim,dim);
        for i = 1:max(plaque_bins)
            plaque_temp = (plaque_map==i);
            plaque_temp = imfill(plaque_temp,'holes');
            if sum(plaque_temp,'all')>pix_threshold
                pla_num=pla_num+1;
                plaque_map_th(plaque_temp)=pla_num;
            end
        end
        
        plaque_map_ext = zeros(dim,dim);
        plaque_map_edge = zeros(dim,dim);
        SE2=strel('square',1);

        for i = 1:pla_num
            ext_mask=mask_optimize(max_pro,plaque_map_th==i);
            plaque_map_edge(ext_mask)=i;            
            core_mask=imerode(ext_mask,SE2);
            plaque_map_ext(core_mask)=i;
        end
        
        CurrentSeries2 = Stack(im)-1;
        reader.setSeries(CurrentSeries2);
        numOfPlane_temp=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries2)),getValue(omeMeta.getPixelsSizeT(CurrentSeries2)));
        dim = omeMeta.getPixelsSizeX(CurrentSeries2).getValue();
        %zsize=omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER).doubleValue();
        raw_stack = zeros(dim, dim, numOfPlane_temp);
        for i = 1:numOfPlane_temp
                %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
                raw_stack(:,:,i) = bfGetPlane(reader, i);
        end
        [~,peak_idx]=max(raw_stack,[],3);
        
        output_temp=[];
        for i = 1:pla_num
            output_temp(i).file = Filename;
            output_temp(i).series = Stack(im);
            mask_temp = plaque_map_ext==i;
            output_temp(i).area = sum(mask_temp,'all');
            raw_temp = raw_stack.*mask_temp;
            output_temp(i).spectrum = squeeze(mean(raw_temp,[1,2])).*512.*512./output_temp(i).area;
            output_temp(i).peakmap = peak_idx.*mask_temp;
            mask_temp2 = plaque_map_edge==i;
            output_temp(i).plaquemap=mask_temp+mask_temp2;
            raw_temp2 = raw_stack.*(mask_temp2-mask_temp);
            output_temp(i).Edge_spectrum = squeeze(mean(raw_temp2,[1,2])).*512.*512./(sum(mask_temp2,'all')-sum(mask_temp,'all'));
            xpro=squeeze(sum(mask_temp2,1));
            xlim_up = find(xpro>0,1,'first');
            xlim_dn = find(xpro>0,1,'last');
            ypro=squeeze(sum(mask_temp2,2));
            ylim_up = find(ypro>0,1,'first');
            ylim_dn = find(ypro>0,1,'last');
            background_mask=zeros(dim,dim);
            xlim=(xlim_dn-xlim_up)*0.5;
            ylim=(ylim_dn-ylim_up)*0.5;
            xlim_up_ext=round(max(1,xlim_up-xlim));
            xlim_dn_ext=round(min(dim,xlim_dn+xlim));
            ylim_up_ext=round(max(1,ylim_up-ylim));
            ylim_dn_ext=round(min(dim,ylim_dn+ylim));
            background_mask(ylim_up_ext:ylim_dn_ext,xlim_up_ext:xlim_dn_ext)=1;
            SE = strel('disk',5,4);
            background_mask=background_mask-imdilate(mask_temp2,SE);
            background_temp=raw_stack.*background_mask;
            output_temp(i).background = squeeze(mean(background_temp,[1,2]));
        end
        
        if ~isempty(output_temp)
            area_temp=[output_temp.area];
            remove_temp=find(area_temp>11000);
            output_temp(remove_temp)=[];
        end

        if exist('output','var')
            output=[output,output_temp];
        else
            output=output_temp;
        end
        clearvars -except Filename File reader omeMeta numOfSeries IdxOfSeries im output ROI Stack
   end
   clearvars -except File Filename omeMeta numOfSeries output
end


    
        
    
        