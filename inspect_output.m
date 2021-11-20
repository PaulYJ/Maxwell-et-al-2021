function inspect_output(output,series_target)
    series_ext = [output.series];
    series_idx = find(series_ext==series_target);
    filename = output(series_idx(1)).file;
    reader=bfGetReader(filename);
    omeMeta = reader.getMetadataStore();
    numOfSeries=omeMeta.getImageCount();
%    for im = 1:numOfSeries
%        CurrentSeries = im-1;
%        reader.setSeries(CurrentSeries);
%        numOfPlane(im)=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
%    end
%    IdxOfSeries=find(numOfPlane>10);
    CurrentSeries = series_target-1;
       reader.setSeries(CurrentSeries);
    numOfPlane_temp=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
    dim = omeMeta.getPixelsSizeX(CurrentSeries).getValue();
    %zsize=omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER).doubleValue();
    raw = zeros(dim, dim, numOfPlane_temp);
    for i = 1:numOfPlane_temp
            %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
            raw(:,:,i) = bfGetPlane(reader, i);
    end
    
    mask = zeros(dim,dim);
    for i = 1:length(series_idx)
        [~,peak_temp(i)]=max(output(series_idx(i)).spectrum);
        map_temp=output(series_idx(i)).peakmap>0;
        mask=mask+bwperim(map_temp);
    end
    
    edge = zeros(dim,dim);
    for i = 1:length(series_idx)
        map_temp=output(series_idx(i)).plaquemap>0;
        edge=edge+bwperim(map_temp);
    end
    
    maxpro=max(raw(:,:,round(mean(peak_temp)-5):round(mean(peak_temp)+5)),[],3);
    figure
    imagesc(maxpro);
    colormap bone
    
    yellow = cat(3, ones(size(maxpro)), ones(size(maxpro)), zeros(size(maxpro)));
    hold on
    h = imshow(yellow);
    hold off
    set(h, 'AlphaData', mask)
    
    cyan = cat(3, zeros(size(maxpro)), ones(size(maxpro)), ones(size(maxpro)));
    hold on
    p = imshow(cyan);
    hold off
    set(p, 'AlphaData', edge)
end