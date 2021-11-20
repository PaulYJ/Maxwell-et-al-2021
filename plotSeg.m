function plotSeg(output,imseries)

    series_idx=[output.series];
    plot_idx=find(series_idx==imseries);
    plot_temp=zeros(size(output(1).peakmap));
    
    for i = 1:length(plot_idx)
        def_map=output(plot_idx(i)).peakmap>0;
        plot_temp(def_map)=i;
    end
    
    imagesc(plot_temp);

end