classdef volumeAnnotationToolZ < handle    
    properties
        Figure
        FigureContext
        Axis
        PlaneHandle
        TransparencyHandle
        PlaneIndex
        NPlanes
        NLabels
        LabelIndex
        Volume
        ImageSize
        LabelMasks
        MouseIsDown
        PenSize
        PenSizeText
        RadioDraw
        RadioErase
        Dialog
        LowerThreshold
        UpperThreshold
        LowerThresholdSlider
        UpperThresholdSlider
        Slider
        SliderZ
        DidAnnotate
    end
    
    methods
        function tool = volumeAnnotationToolZ(V,nLabels)
% work in progress; similar to volumeAnnotationTool; only displays z view
% 
% volumeAnnotationTool(V,nClasses)
% A tool to annotate a 3D volume for machine learning
% V should be 'double' and in the range [0,1]
% nClasses is the number of classes (1,2,3,...)
%
% example
% -------
% load mri
% V = double(squeeze(D))/255;
% VAT = volumeAnnotationTool(V,2);
% % [annotate, click 'Done']
% MaskClass1 = VAT.LabelMasks(:,:,:,1);
% MaskClass2 = VAT.LabelMasks(:,:,:,2);
            
            tool.DidAnnotate = 0;
            
            tool.Volume = V;
            tool.NPlanes = size(V,3);
            tool.PlaneIndex = round(tool.NPlanes/2);
            
            tool.NLabels = nLabels;
            tool.LabelMasks = zeros(size(V,1),size(V,2),size(V,3),nLabels);
            tool.LabelIndex = 1;
            labels = cell(1,nLabels);
            for i = 1:nLabels
                labels{i} = sprintf('Class %d',i);
            end
            
            tool.LowerThreshold = 0;
            tool.UpperThreshold = 1;
               
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            % z
            tool.Figure = figure('Name','Plane Z','NumberTitle','off','CloseRequestFcn',@tool.closeTool,...
                'WindowButtonMotionFcn', @tool.mouseMove, 'WindowButtonDownFcn', @tool.mouseDown, 'WindowButtonUpFcn', @tool.mouseUp, ...
                'windowscrollWheelFcn', @tool.mouseScroll, 'Position',[150+dwidth 100 600 650],'KeyPressFcn',@tool.keyPressed);
            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            I = tool.Volume(:,:,tool.PlaneIndex);
            tool.PlaneHandle = imshow(tool.applyThresholds(I)); hold on;
            J = zeros(size(I)); J = cat(3,ones(size(I,1),size(I,2),2),J);
            tool.TransparencyHandle = imshow(J); tool.TransparencyHandle.AlphaData = zeros(size(I));
            hold off;
            tool.ImageSize = size(I);
            tool.Axis.Title.String = sprintf('z = %d', tool.PlaneIndex);
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'VolumeAnnotationToolZ',...
                                'CloseRequestFcn', @tool.closeTool,...
                                'Position',[100 100 dwidth 10*dborder+12*cheight],...
                                'KeyPressFcn',@tool.keyPressed);
            
            % pencil/eraser slider
            tool.PenSize = 3;
            uicontrol('Parent',tool.Dialog,'Style','text','String','Pencil/Eraser Size','Position',[dborder+20 8.5*dborder+11*cheight cwidth-20 cheight],'HorizontalAlignment','left');
            tool.PenSizeText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PenSize),'Position',[dborder+20+(cwidth-20)/2-25 9*dborder+10*cheight 50 cheight],'HorizontalAlignment','center');
            uicontrol('Parent',tool.Dialog,'Style','edit','String','10','Position',[dborder+cwidth-50 9*dborder+10*cheight 50 cheight],'HorizontalAlignment','right','Callback',@tool.changeSliderRange,'Tag','sliderMax');
            uicontrol('Parent',tool.Dialog,'Style','edit','String','1','Position',[dborder+20 9*dborder+10*cheight 50 cheight],'HorizontalAlignment','left','Callback',@tool.changeSliderRange,'Tag','sliderMin');
            tool.Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',10,'Value',tool.PenSize,'Position',[dborder+20 9*dborder+9*cheight cwidth-20 cheight],'Callback',@tool.sliderManage,'Tag','pss');
            addlistener(tool.Slider,'Value','PostSet',@tool.continuousSliderManage);
                            
            % erase/draw
            tool.RadioDraw = uicontrol('Parent',tool.Dialog,'Style','radiobutton','Position',[dborder+20 8*dborder+8*cheight 70 cheight],'String','Draw','Callback',@tool.radioDraw);
            tool.RadioErase = uicontrol('Parent',tool.Dialog,'Style','radiobutton','Position',[dborder+90 8*dborder+8*cheight 70 cheight],'String','Erase','Callback',@tool.radioErase);
            tool.RadioDraw.Value = 1;
                            
            % class popup
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder+20 7*dborder+7*cheight cwidth-20 cheight],'Callback',@tool.popupManage);
                            
            % z slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','z','Position',[dborder 5*dborder+5*cheight 20 cheight]);
            tool.SliderZ = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes,'Value',tool.PlaneIndex,'Position',[dborder+20 5*dborder+5*cheight cwidth-20 cheight],'Tag','zs');
            addlistener(tool.SliderZ,'Value','PostSet',@tool.continuousSliderManage);

            % lower threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','_t','Position',[dborder 4*dborder+3*cheight 20 cheight]);
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder+20 4*dborder+3*cheight cwidth-20 cheight],'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','^t','Position',[dborder 3*dborder+2*cheight 20 cheight]);
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder+20 3*dborder+2*cheight cwidth-20 cheight],'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % done button
            buttonDoneLabel = 'Done';
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',buttonDoneLabel,'Position',[dborder+20 dborder cwidth-20 2*cheight],'Callback',@tool.buttonDonePushed);
            
            tool.MouseIsDown = false;
            
            uiwait(tool.Dialog)
        end
        
        function keyPressed(tool,~,event)
            addToZ = 0;
            if strcmp(event.Key,'add') || strcmp(event.Key,'equal') || strcmp(event.Key,'rightarrow') || strcmp(event.Key,'uparrow')
                addToZ = 1;
            elseif strcmp(event.Key,'subtract') || strcmp(event.Key,'hyphen') || strcmp(event.Key,'leftarrow') || strcmp(event.Key,'downarrow')
                addToZ = -1;
            end
            
            if addToZ ~= 0
%                 currentZValue = tool.SliderZ.Value;
%                 candidateZValue = currentZValue+addToZ;
%                 if candidateZValue >= tool.SliderZ.Min && candidateZValue <= tool.SliderZ.Max
%                     tool.SliderZ.Value = candidateZValue;
%                     callbackdata = [];
%                     callbackdata.AffectedObject.Tag = 'zs';
%                     callbackdata.AffectedObject.Value = candidateZValue;
%                     continuousSliderManage(tool,0,callbackdata);
%                 end


                candidatePlaneIndex = tool.PlaneIndex+addToZ;
                if candidatePlaneIndex >= 1 && candidatePlaneIndex <= tool.NPlanes
                    tool.PlaneIndex = candidatePlaneIndex;

                    I = tool.Volume(:,:,tool.PlaneIndex);
                    tool.PlaneHandle.CData = tool.applyThresholds(I);
                    tool.TransparencyHandle.AlphaData = 0.5*tool.LabelMasks(:,:,tool.PlaneIndex,tool.LabelIndex);

                    tool.Axis.Title.String = sprintf('z = %d', tool.PlaneIndex);
                    
                    tool.SliderZ.Value = candidatePlaneIndex;
                end
            end
        end
        
        function changeSliderRange(tool,src,~)
            value = str2double(src.String);
            if strcmp(src.Tag,'sliderMin')
                tool.Slider.Min = value;
                tool.Slider.Value = value;
                tool.PenSize = value;
                tool.PenSizeText.String = sprintf('%d',value);
            elseif strcmp(src.Tag,'sliderMax')
                tool.Slider.Max = value;
                tool.Slider.Value = value;
                tool.PenSize = value;
                tool.PenSizeText.String = sprintf('%d',value);
            end
        end
        
        function sliderManage(tool,src,~)
            tool.PenSize = round(src.Value);
            tool.TransparencyHandle.AlphaData =  0.5*tool.LabelMasks(:,:,tool.PlaneIndex,tool.LabelIndex);
        end
        
        function radioDraw(tool,src,~)
            tool.RadioErase.Value = 1-src.Value;
        end
        
        function radioErase(tool,src,~)
            tool.RadioDraw.Value = 1-src.Value;
        end
        
        function popupManage(tool,src,~)
            tool.LabelIndex = src.Value;
            tool.TransparencyHandle.AlphaData =  0.5*tool.LabelMasks(:,:,tool.PlaneIndex,tool.LabelIndex);
        end
        
        function mouseDown(tool,~,~)
            tool.MouseIsDown = true;
        end
        
        function mouseUp(tool,~,~)
            tool.MouseIsDown = false;
        end
        
        function mouseMove(tool,~,~)
            if tool.MouseIsDown
                ps = tool.PenSize;
                p = tool.Axis.CurrentPoint;
                col = round(p(1,1));
                row = round(p(1,2));
                imageSize = tool.ImageSize;
                if row > ps && row <= imageSize(1)-ps && col > ps && col <= imageSize(2)-ps
                    [Y,X] = meshgrid(-ps:ps,-ps:ps);
                    Curr = tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.PlaneIndex,tool.LabelIndex);
                    Mask = sqrt(X.^2+Y.^2) < ps;
                    if tool.RadioDraw.Value == 1
                        tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.PlaneIndex,tool.LabelIndex) = max(Curr,Mask);
                        tool.TransparencyHandle.AlphaData(row-ps:row+ps,col-ps:col+ps) = 0.5*max(Curr,Mask);
                    elseif tool.RadioErase.Value == 1
                        tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.PlaneIndex,tool.LabelIndex) = min(Curr,1-Mask);
                        tool.TransparencyHandle.AlphaData(row-ps:row+ps,col-ps:col+ps) = min(Curr,0.5*(1-Mask));
                    end
                end

            end
        end
        
        function mouseScroll(tool,src,callbackdata)
            vsc = callbackdata.VerticalScrollCount;
            if strcmp(src.Name,'Plane Z')
                if (vsc == -1 && tool.SliderZ.Value > tool.SliderZ.Min) || ...
                    (vsc == 1 && tool.SliderZ.Value < tool.SliderZ.Max)
                    
                    tool.SliderZ.Value = tool.SliderZ.Value+vsc;
                end
                tag = 'zs';
                val = tool.SliderZ.Value;
            end
            
            callbackdata = [];
            callbackdata.AffectedObject.Tag = tag;
            callbackdata.AffectedObject.Value = val;
            continuousSliderManage(tool,0,callbackdata);
        end
        
        function continuousSliderManage(tool,~,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts') || strcmp(tag,'lts')
                if strcmp(tag,'uts')
                    tool.UpperThreshold = value;
                elseif strcmp(tag,'lts')
                    tool.LowerThreshold = value;
                end
                
                I = tool.Volume(:,:,tool.PlaneIndex);
                tool.PlaneHandle.CData = tool.applyThresholds(I);
            elseif strcmp(tag,'zs')
                tool.PlaneIndex = round(value);

                I = tool.Volume(:,:,tool.PlaneIndex);
                tool.PlaneHandle.CData = tool.applyThresholds(I);
                tool.TransparencyHandle.AlphaData = 0.5*tool.LabelMasks(:,:,tool.PlaneIndex,tool.LabelIndex);

                tool.Axis.Title.String = sprintf('z = %d', tool.PlaneIndex);
            elseif strcmp(tag,'pss')
                tool.PenSize = round(callbackdata.AffectedObject.Value);
                ps = tool.PenSize;
                tool.PenSizeText.String = sprintf('%d',ps);
                [Y,X] = meshgrid(-ps:ps,-ps:ps);
                Mask = sqrt(X.^2+Y.^2) < ps;
                
                imageSize = tool.ImageSize;
                r1 = ceil(tool.Axis.YLim(1));
                r2 = floor(tool.Axis.YLim(2));
                c1 = ceil(tool.Axis.XLim(1));
                c2 = floor(tool.Axis.XLim(2));
                rM = round(mean(tool.Axis.YLim));
                cM = round(mean(tool.Axis.XLim));
                tool.TransparencyHandle.AlphaData(max(1,r1):min(imageSize(1),r2),max(1,c1):min(imageSize(2),c2)) = 0;
                if r1 >= 1 && r2 <= imageSize(1) && c1 >= 1 && c2 <= imageSize(2) ...
                        && rM-ps >= 1 && rM+ps <= imageSize(1) && cM-ps >=1 && cM+ps <= imageSize(2)
                    tool.TransparencyHandle.AlphaData(rM-ps:rM+ps,cM-ps:cM+ps) = Mask;
                end
            end
        end
        
        function T = applyThresholds(tool,I)
            T = I;
            T(T < tool.LowerThreshold) = tool.LowerThreshold;
            T(T > tool.UpperThreshold) = tool.UpperThreshold;
            T = T-min(T(:));
            T = T/max(T(:));
        end
        
        function closeTool(tool,~,~)
            delete(tool.Figure);
            delete(tool.FigureContext);
            delete(tool.Dialog);
        end
        
        function buttonDonePushed(tool,~,~)
            NoOverlap = sum(tool.LabelMasks,4) <= 1;
            tool.LabelMasks = tool.LabelMasks.*repmat(NoOverlap,[1 1 1 tool.NLabels]);
            tool.DidAnnotate = 1;
            tool.closeTool();
        end
    end
end
