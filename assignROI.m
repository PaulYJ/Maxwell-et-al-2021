function assignROI(ROI_series,Stack_series,Filename)
   reader=bfGetReader(Filename);
   omeMeta = reader.getMetadataStore();
   
   num_col=ceil(length(ROI_series)/10);
   H = figure('Units','normalized','Position', [0.1,0.1,0.2*num_col,0.8]);
   
   for i=1:length(ROI_series)
       temp_name=strcat('ROI series: ');
       var_name=strcat('txt',num2str(i));
       x_loc=floor((i-1)/10)/num_col+0.01;
       y_loc=1-(mod((i-1),10)*0.09+0.08);
       menu(i).text=uicontrol('Parent',H,'Style','text','Units','normalized','Position',[x_loc,y_loc,0.3/num_col,0.04],'String',temp_name,'FontSize',10);
       menu(i).roiedit=uicontrol('Parent',H,'Style','edit','Units','normalized','Position',[x_loc+0.25/num_col,y_loc+0.01,0.05,0.04]);
       set(menu(i).roiedit,'string',num2str(ROI_series(i)));
       menu(i).name=uicontrol('Parent',H,'Style','text','Units','normalized','Position',[x_loc+0.15/num_col,y_loc-0.04,0.3/num_col,0.04],'String',string(omeMeta.getImageName(ROI_series(i)-1)),'FontSize',10);
       menu(i).text2=uicontrol('Parent',H,'Style','text','Units','normalized','Position',[x_loc+0.39/num_col,y_loc,0.15,0.04],'String','Stack series: ','FontSize',10);
       menu(i).stackedit=uicontrol('Parent',H,'Style','edit','Units','normalized','Position',[x_loc+0.7/num_col,y_loc+0.01,0.05,0.04]);
       set(menu(i).stackedit,'string',num2str(Stack_series(i)));
       menu(i).name2=uicontrol('Parent',H,'Style','text','Units','normalized','Position',[x_loc+0.5/num_col,y_loc-0.04,0.35/num_col,0.04],'String',string(omeMeta.getImageName(Stack_series(i)-1)),'FontSize',10);
       menu(i).text3=uicontrol('Parent',H,'Style','text','Units','normalized','Position',[x_loc+0.4/num_col,y_loc,0.03,0.04],'String','>>>','FontSize',10);
   end
   con_botton=uicontrol('Parent',H,'Style','pushbutton','Units','normalized','Position', [0.9, 0.02, 0.08, 0.05], 'String', 'Confirm','ForegroundColor','b','FontSize',10,'CallBack', @conCallback);
   ref_botton=uicontrol('Parent',H,'Style','pushbutton','Units','normalized','Position', [0.8, 0.02, 0.08, 0.05], 'String', 'Refresh','ForegroundColor','r','FontSize',10,'CallBack', @roiCallback);
    
    function roiCallback(ref_botton,~)
       for i=1:length(menu)
           temp=menu(i).roiedit.String;
           if isempty(temp)
               set(menu(i).name,'string',[]);
               set(menu(i).name2,'string',[]);
           else
               num=str2num(temp);
               idx=find(ROI_series==num);
               name_rep=string(omeMeta.getImageName(ROI_series(idx)-1));
               set(menu(i).name,'string',name_rep);
               temp2=menu(i).stackedit.String;
               num2=str2num(temp2);
               idx2=find(Stack_series==num2);
               name_rep2=string(omeMeta.getImageName(Stack_series(idx2)-1));
               set(menu(i).name2,'string',name_rep2);
           end
       end
    end
        

    function conCallback(con_botton,~)
        j=1;
        for i=1:length(menu)
            temp=menu(i).roiedit.String;
            if ~isempty(temp)
                ROI(j)=str2num(temp);
                Stack(j)=str2num(menu(i).stackedit.String);
                j=j+1;
            end
        end
        assignin('base','ROI',ROI);
        assignin('base','Stack',Stack);
        close(H);
    end
    
end    