function newoutput=copyROI(sourceOutput,plaqueNum,newImageFile,newSeries,outputflag)
    if nargin == 4
        outputflag = 0;
    end
    plaque_loc = sourceOutput(plaqueNum).peakmap>0;
    reader=bfGetReader(newImageFile);
    reader.setSeries(newSeries-1);
    omeMeta = reader.getMetadataStore();
    numOfPlane_temp=max(getValue(omeMeta.getPixelsSizeZ(newSeries-1)),getValue(omeMeta.getPixelsSizeT(newSeries-1)));
    raw = zeros(size(plaque_loc,1), size(plaque_loc,2), numOfPlane_temp);
    for i = 1:numOfPlane_temp
            %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
            raw(:,:,i) = bfGetPlane(reader, i);
            intensity(i)=max(raw(:,:,i),[],'all');
    end
    [~,peak_loc]=max(intensity);
    maxpro=max(raw(:,:,peak_loc-4:peak_loc+4),[],3);
    
    figure
    imagesc(maxpro);
    colormap gray
    mask=bwperim(plaque_loc);
    yellow = cat(3, ones(size(maxpro)), ones(size(maxpro)), zeros(size(maxpro)));
    hold on
    h = imshow(yellow);
    hold off
    set(h, 'AlphaData', mask)
    
    if outputflag == 1
        newoutput.file= newImageFile;
        newoutput.series= newSeries;
        newoutput.area= sourceOutput(plaqueNum).area;
        [~,peak_map_all]=max(raw,[],3);
        for i = 1:numOfPlane_temp
            temp=raw(:,:,i);
            spec(i)=mean(temp(plaque_loc));
        end
        newoutput.spectrum=spec;
        newoutput.peakmap=peak_map_all.*plaque_loc;
        
        dim=size(plaque_loc,1);
        xpro=squeeze(sum(plaque_loc,1));
        xlim_up = find(xpro>0,1,'first');
        xlim_dn = find(xpro>0,1,'last');
        ypro=squeeze(sum(plaque_loc,2));
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
        background_mask=background_mask-imdilate(plaque_loc,SE);
        background_temp=raw.*background_mask;
        newoutput.background = squeeze(mean(background_temp,[1,2]));
    end
    
end