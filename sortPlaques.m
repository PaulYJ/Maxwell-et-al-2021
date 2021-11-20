function sortPlaques (output)
    S = inputname(1);
    
    if ~isfield(output, 'sort')
        im = 1;
        comm2 = strcat(S,'(1).sort= [];');
        evalin('base',comm2);
    else 
        for n=1:length(output)
            if isempty(output(n).sort)
                im=n;
                break
            end
        end
    end


    
    H = figure('Units','normalized','Position', [0.3,0.1,0.4,0.8]);
    axes1 = axes('Units','normalized','Position', [0.15,0.35,0.75,0.6],'Parent',H);
    %colormap(axes1,gray);
    Filename=output(im).file;
    CurrentSeries=output(im).series-1;
    reader=bfGetReader(Filename);
    
    omeMeta = reader.getMetadataStore();
    numOfPlane=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
    dim = omeMeta.getPixelsSizeX(CurrentSeries).getValue();
    raw = zeros(dim, dim, numOfPlane);
    reader.setSeries(CurrentSeries);
    for i = 1:numOfPlane
            %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
            raw(:,:,i) = bfGetPlane(reader, i);
    end
    cmax=max(reshape(raw,[],1));
    T=numOfPlane;
    
    map_temp=output(im).peakmap>0;
    mask=bwperim(map_temp);
    yellow = cat(3, ones(dim), ones(dim), zeros(dim));
    
    frame = round(T/2);
    
    %slider bar
    b = uicontrol('Parent',H,'Style','slider','Units','normalized','Position',[0.18,0.3,0.7,0.02], 'value',frame, 'min',0, 'max',T, 'SliderStep', [1/(T-1),0.1],'FontSize',10);
    bListener = addlistener(b,'Value','PostSet',@(s,e) XListenerCallBack);
    bl1 = uicontrol('Parent',H,'Style','text','Units','normalized','Position',[0.13,0.27,0.03,0.03], 'String','1','FontSize',10);
    bl2 = uicontrol('Parent',H,'Style','text','Units','normalized','Position',[0.9,0.27,0.03,0.03], 'String',num2str(T),'FontSize',10);
    bl3 = uicontrol('Parent',H,'Style','text','Units','normalized','Position',[0.42,0.26,0.2,0.03],'String','Frame','FontSize',10);
    prog = strcat('Current Plaque Candidate:',num2str(im));
    bl5 = uicontrol('Parent',H,'Style','text','Units','normalized','Position',[0.1,0.22,0.4,0.04],'String',prog,'FontSize',10);
    b14 = uicontrol('Style','Edit','Units','normalized','Position',[0.45, 0.2, 0.15, 0.03],'String','1','FontSize',10);
    b.Callback = @XSliderCallback;
    
    %Choice button
    yes_button = uicontrol('Parent',H,'Style','pushbutton','Units','normalized','Position', [0.7, 0.05, 0.1, 0.1], 'String', 'YES','ForegroundColor','b','FontSize',10);
    yes_button.Callback = @YesCallback;
    no_button = uicontrol('Parent',H,'Style','pushbutton','Units','normalized','Position', [0.2, 0.05, 0.1, 0.1], 'String', 'NO', 'ForegroundColor','r','FontSize',10);
    no_button.Callback = @NoCallback;

    
    function XSliderCallback(es,~)
        current=round(es.Value);
        frame = current;
        temp = raw(:,:,current);
        image(temp,'Parent',axes1,'CDataMapping','scaled');
        b14.String=num2str(current);
        axes1.Visible='Off';
        colormap(axes1,gray);
        axes1.CLim=([0,cmax]);
        hold on
        j = imshow(yellow);
        hold off
        set(j, 'AlphaData', mask)
        %PL.XData=[current, current];
    end

    function XListenerCallBack
        current = round((get(b,'Value')));
        frame = current;
        b14.String=num2str(current);
        temp = raw(:,:,current);
        image(temp,'Parent',axes1,'CDataMapping','scaled');
        axes1.Visible='Off';
        colormap(axes1,gray);
        axes1.CLim=([0,cmax]);
        hold on
        j = imshow(yellow);
        hold off
        set(j, 'AlphaData', mask)
        %PL.XData=[current, current];
    end

    function YesCallback (yes_button,~)
        comm = strcat(S,'(',num2str(im),').sort= 1;');
        evalin('base',comm);
        im = im+1;
        CurrentSeries=output(im).series-1;
        reader.setSeries(CurrentSeries);
        numOfPlane=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
        dim = omeMeta.getPixelsSizeX(CurrentSeries).getValue();
        raw = zeros(dim, dim, numOfPlane);
        T=numOfPlane;
        for i = 1:numOfPlane
            %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
            raw(:,:,i) = bfGetPlane(reader, i);
        end
        cmax=max(reshape(raw,[],1));
        temp=raw(:,:,frame);
        image(temp,'Parent',axes1,'CDataMapping','scaled');
        colormap(axes1,gray);
        axes1.CLim=([0,cmax]);
        axes1.Visible='Off';
        
        map_temp=output(im).peakmap>0;
        mask=bwperim(map_temp);
        yellow = cat(3, ones(dim), ones(dim), zeros(dim));
        hold on
        j = imshow(yellow);
        hold off
        set(j, 'AlphaData', mask)
               
        prog = strcat('Current Cell Candidate:',num2str(im));
        bl5.String=prog;
    end

    function NoCallback (no_button,~)
        comm = strcat(S,'(',num2str(im),').sort= 0;');
        evalin('base',comm);
        im = im+1;
        CurrentSeries=output(im).series-1;
        reader.setSeries(CurrentSeries);
        numOfPlane=max(getValue(omeMeta.getPixelsSizeZ(CurrentSeries)),getValue(omeMeta.getPixelsSizeT(CurrentSeries)));
        dim = omeMeta.getPixelsSizeX(CurrentSeries).getValue();
        raw = zeros(dim, dim, numOfPlane);
        T=numOfPlane;
        for i = 1:numOfPlane
            %raw(:,:,i) = bfGetPlane(reader, numOfPlane+i);
            raw(:,:,i) = bfGetPlane(reader, i);
        end
        cmax=max(reshape(raw,[],1));
        temp=raw(:,:,frame);
        image(temp,'Parent',axes1,'CDataMapping','scaled');
        colormap(axes1,gray);
        axes1.CLim=([0,cmax]);
        axes1.Visible='Off';
        
        map_temp=output(im).peakmap>0;
        mask=bwperim(map_temp);
        yellow = cat(3, ones(dim), ones(dim), zeros(dim));
        hold on
        j = imshow(yellow);
        hold off
        set(j, 'AlphaData', mask)
               
        prog = strcat('Current Cell Candidate:',num2str(im));
        bl5.String=prog;
    end
end