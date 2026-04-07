%% Code for the Grassmann diagram of the geothermal powerplant
% group 3 Project Analysis
% made by Oliwier Sobczyk
% edited by Benjamin Knulst
% add the folder where your plotflowdiagram folder is!!!
% here:
addpath('C:\Pobieranie\Szkoła\Matlab\plotFlowDiagram\plotFlowDiagrams');
% imports data from the newest Stream_Data file
% (make sure to add it in the folder where you are working)
close all 
clc, clear
StreamData = Stream_Data(); 


%% how to read:
% file is divided into 3 parts: out of turbine lins, turbine 1 line and
% turbine 23 line
%***************************************************************************
%* reservour heat input   <- name of the component
%*    components(1).coordinateX = 0;    | info about
%*    components(1).coordinateY = 0;    | -coordinates
%*    components(1).drawBlock = false;  | -name,in/out alignment(t/c/b) 
%*         RESERVOUIR to INPUT (663.597,heat,~) <- name of the connection,
%*                                                with the info: value,type of energy and type of line
%*            Streams:(1)+(13)   <- used streams for calculations
%*        components(1).out(1).value = 663.597; ^
%*        components(1).out(1).target = 2;      | values, targets, source 
%*        components(2).in(1).source= 1;        | additional info,shape of
%*        components(1).out(1).type = 'heat';   | the line if included
%**************************************************************************
% some default settings:
defaultSettings
defaults.blockWidth = 10;
defaults.units = 'MW';
defaults.FontSize = 10;
defaults.out.FontSize = 10;
defaults.TextRotation = 90;
defaults.minArrowWidth = 0.25;
defaults.borderWidth = [5,5,5,5];
%% components coordinates
% reservour heat input
components(1).coordinateX = 10;
components(1).coordinateY = 0;
components(1).drawBlock = false;
    % RESERVOUIR to INPUT (663.597,heat,~)
        %Streams:(1)+(13)
    components(1).out(1).value = (StreamData(1).energy + StreamData(13).energy)/1000;
    components(1).out(1).target = 2;
    components(2).in(1).source = 1;
    components(1).out(1).type = 'heat';
% input block
components(2).coordinateX = 30;
components(2).coordinateY = 'i1';
components(2).name = 'Steam Seperator';
    % INPUT TO LOSS(3) (34.074,energy loss,~)
        %Streams:(1)+(13)-(21)-(22)-(2)-(14)
    components(2).out(1).value = (StreamData(1).energy+StreamData(13).energy-StreamData(21).energy-StreamData(22).energy-StreamData(2).energy-StreamData(14).energy)/1000;
    components(2).out(1).target = 3;
    components(3).in(1).source= 2;
    components(2).out(1).type = 'energy loss';
    components(2).out(1).FontSize = 6;
    components(2).out(1).textShift = [0,3];
    % iNPUT TO STEAM(4) (10.241,saturated liquid,~)
        %Streams:(21)+(22)
    components(2).out(2).value = (StreamData(21).energy+StreamData(22).energy)/1000;
    components(2).out(2).target = 4;
    components(4).in(1).source= 2;
    components(2).out(2).type = 'saturated liquid';
    components(2).out(2).FontSize = 2;
    components(2).out(2).textShift = [-8,-5];  
    % iNPUT TO MOISTURE(6) (619.282,mixture,~)
        %Streams:(2)+(14)
    components(2).out(3).value = (StreamData(2).energy+StreamData(14).energy)/1000;
    components(2).out(3).target = 6;
    components(6).in(1).source= 2;
    components(2).out(3).type = 'mixture';
% heat loss 
components(3).coordinateX = 45;
components(3).coordinateY = 'i1';
components(3).drawBlock = false;
% steam TRAP
components(4).coordinateX = 60;
components(4).coordinateY = 'i1';
components(4).name = 'Steam Trap';
components(4).FontSize = 5;
components(4).TextRotation = 0;
    % Steam TO LOSS(5) (10.241,energy loss,~)
        %Streams:(21)+(22)-(23)
    components(4).out(1).value = (StreamData(23).energy)/1000;
    components(4).out(1).target = 5;
    components(5).in(1).source= 4;
    components(4).out(1).type = 'energy loss';
    components(4).out(1).FontSize = 6;
    components(4).out(1).textShift = [1,3];
% steam seperator loss
components(5).coordinateX = 45;
components(5).coordinateY = 'i1';
components(5).drawBlock = false;
% moisture
components(6).coordinateX = 60;
components(6).coordinateY = 'i1';
components(6).inputsAlignment = 'b';
components(6).name = 'Moisture Separator';
    % moisture to loss(7) (0.423,energy loss,~)
        % Streams: (2)+(14)-(3)-(15)
    components(6).out(1).value = (StreamData(2).energy+StreamData(14).energy-StreamData(3).energy-StreamData(15).energy)/1000;
    components(6).out(1).target = 7;
    components(7).in(1).source= 6;
    components(6).out(1).type = 'energy loss';
    components(6).out(1).textShift = [2,3];
    components(6).out(1).FontSize = 6;
    % moisture to turbine 2 and 3(8) (388.773,saturated vapor,~)
        %Streams: 2 * ((16) + (17))
    components(6).out(2).value = (2*(StreamData(16).energy+StreamData(17).energy))/1000;
    components(6).out(2).target = 8;
    components(8).in(1).source= 6;
    components(6).out(2).type = 'saturated vapor';
    % moisture to turbine 1(16)(229.458,saturated vapor,~)
        %Streams: (4)
    components(6).out(3).value = StreamData(4).energy/1000;
    components(6).out(3).target = 16;
    components(16).in(1).source= 6;
    components(6).out(3).type = 'saturated vapor';
    % moisture to open water heater(17) (0.831,saturated vapor,hvh)
        % Streams: (25)
    components(6).out(4).value = StreamData(25).energy/1000;
    components(6).out(4).target = 17;
    components(17).in(2).source= 6;
    components(6).out(4).type = 'saturated vapor';
    components(6).out(4).shape = 'hvh';
    components(6).out(4).textShift = [12,-4];
    components(6).out(4).FontSize = 7;
    components(6).out(4).verticalLinesX = 115;
% moisture loss
components(7).coordinateX = 80;
components(7).coordinateY = 'i1';
components(7).drawBlock = false;

%% TURBINE 2 AND 3 LINE

% turbine 2&3
components(8).coordinateX = 95;
components(8).coordinateY = 'i1';
components(8).inputsAlignment = 'b';
components(8).name = 'Turbines 2 and 3';
components(8).FontSize = 9;
    % turbine 2&3 to generator(9) (61.8556,work,~)
        % Streams 2 * ((16) + (17))
    components(8).out(1).value = (2*(StreamData(16).energy+StreamData(17).energy-StreamData(18).energy))/1000;
    components(8).out(1).target = 9;
    components(9).in(1).source= 8;
    components(8).out(1).type = 'work';
    components(8).out(1).FontSize = 8;
    components(8).out(1).textShift = [0,5];
    % turbine 2&3 to condenser(11) (326.9174,mixture,~)
        % Streams 2 * (18)
    components(8).out(2).value = 2*(StreamData(18).energy)/1000;
    components(8).out(2).target = 11;
    components(11).in(2).source= 8;
    components(8).out(2).type = 'mixture';
% generator 
components(9).coordinateX = 120;
components(9).coordinateY = 'i1';
components(9).name = 'Generator';
components(9).TextRotation = 0;
components(9).FontSize = 7;
    % generator(9) to loss(10) (1.85567,energy loss,~)
        % Streams 2 * 0.03 * ((16) + (17) - (18))
    components(9).out(1).value = (2*0.03*(StreamData(16).energy+StreamData(17).energy-StreamData(18).energy))/1000;
    components(9).out(1).target = 10;
    components(10).in(1).source = 9;
    components(9).out(1).type = 'energy loss';
    components(9).out(1).FontSize = 5;
    components(9).out(1).textShift = [0,2];
    % generator to electricity (12) (60,electricity,~)
        %Streams: 2 * 0.97 * ((16) + (17) - (18))
    components(9).out(2).value = (2*0.97*(StreamData(16).energy+StreamData(17).energy-StreamData(18).energy))/1000;
    components(9).out(2).target = 12;
    components(12).in(1).source = 9;
    components(9).out(2).type = 'electricity';
    components(9).out(2).FontSize = 8;
    components(9).out(2).textShift = [3,5];
%electricity
components(12).coordinateX = 140;
components(12).coordinateY = 'i1';
components(12).drawBlock = false;
% generator loss
components(10).coordinateX = 130;
components(10).coordinateY = 'i1';
components(10).drawBlock = false;
% condensator
components(11).coordinateX = 170;
components(11).coordinateY = 'i2';
components(11).name = 'Condenser';
    % condensator to loss(13) (0,energy loss,~)
        %Streams: 2 * ((18) + (19) - (20))
    components(11).out(1).value = (2*(StreamData(18).energy+StreamData(19).energy-StreamData(20).energy))/1000;
    components(11).out(1).target = 13;
    components(13).in(1).source = 11;
    components(11).out(1).type = 'energy loss';
    components(11).out(1).FontSize = 5;
    % condensator to chminey(14) (641.564,compressed liquid,~)
        %Streams: 2 * (20)
    components(11).out(2).value = (2*StreamData(20).energy)/1000;
    components(11).out(2).target = 14;
    components(14).in(1).source= 11;
    components(11).out(2).type = 'compressed liquid';
% condenser loss
components(13).coordinateX = 190;
components(13).coordinateY = 'i1';
components(13).drawBlock = false;
% chimney 
components(14).coordinateX = 250;
components(14).coordinateY = 'i1';
components(14).name = 'Cooling Tower';
    % chimney to loss (15) (326.917,energy loss,~)
        %Streams: 2 * ((20) - (19))
    components(14).out(2).value = (2*(StreamData(20).energy-StreamData(19).energy))/1000;
    components(14).out(2).target = 15;
    components(15).in(1).source= 14;
    components(14).out(2).type = 'energy loss';
    % chimney to condensator (11) (314.6456,mixture,hvhvh)
        %Streams: 2 * (19)
    components(14).out(1).value = (2*StreamData(19).energy)/1000;
    components(14).out(1).target = 11;
    components(11).in(1).source = 14;
    components(14).out(1).shape = 'hvhvh';
    components(14).out(1).horizontalLinesY = 50;
    components(14).out(1).verticalLinesX = [265 150];
    components(14).out(1).type = 'mixture';
% chimney loss
components(15).coordinateX = 265;
components(15).coordinateY = 'i1';
components(15).drawBlock = false;

%% TURBINE 1 LINE

% turbine 1
components(16).coordinateX = 95;
components(16).coordinateY = 'i1';
components(16).inputsAlignment = 't';
components(16).name = 'Turbine 1';
    % turbine 1 to generator(19) (41.237,work,~)
        %Streams (4) - (5)
    components(16).out(2).value = (StreamData(4).energy-StreamData(5).energy)/1000;
    components(16).out(2).target = 18;
    components(18).in(1).source = 16;
    components(16).out(2).type = 'work';
    components(16).out(2).FontSize = 8;
    components(16).out(2).textShift = [0,-4];
    % turbine 1 to condensator(21) (188.2207,mixture,~)
        %Streams: (5)
    components(16).out(1).value = StreamData(5).energy/1000;
    components(16).out(1).target = 21;
    components(21).in(1).source = 16;
    components(16).out(1).type = 'mixture';
% Open water heater
components(17).coordinateX = 190;
components(17).coordinateY = -30;
components(17).name = 'Open Water heater';
components(17).TextRotation = 0;
components(17).FontSize = 5;
    % open water heater to loss(20) (0,energy loss,~)
        %Streams: (25) + (6) - (7)
    components(17).out(1).value = (StreamData(25).energy+StreamData(6).energy-StreamData(7).energy)/1000;
    components(17).out(1).target = 20;
    components(20).in(1).source= 17;
    components(17).out(1).type = 'energy loss';
    components(17).out(1).FontSize = 5;
    components(17).out(1).textShift = [0,2];
    % open water heater to daeraator(23) (16.4448,mixture,~)
        %Streams: (7)
    components(17).out(2).value = StreamData(7).energy/1000;
    components(17).out(2).target = 23;
    components(23).in(1).source = 17; 
    components(17).out(2).type = 'mixture';
    components(17).out(2).FontSize = 6;
    components(17).out(2).textShift = [2,3];
% generator 
components(18).coordinateX = 120;
components(18).coordinateY = 'i1';
components(18).name = 'Generator';
components(18).TextRotation = 0;
components(18).FontSize = 7;
    % generator to loss(18) (1.237,energy loss,~)
        %Streams: 0.03 * ((4) - (5))
    components(18).out(2).value = (0.03*(StreamData(4).energy-StreamData(5).energy))/1000;
    components(18).out(2).target = 19;
    components(19).in(1).source = 18;
    components(18).out(2).type = 'energy loss';
    components(18).out(2).FontSize = 5;
    components(18).out(2).textShift = [0,-2];
    % generator to electricity (30) (75.613)
    components(18).out(1).value = 40;
    components(18).out(1).target = 29;
    components(29).in(1).source = 18;
    components(18).out(1).type = 'electricity';
    components(18).out(1).FontSize = 8;
    components(18).out(1).textShift = [3,-4];
% electricity
components(29).coordinateX = 140;
components(29).coordinateY = 'i1';
components(29).drawBlock = false;
% generator loss
components(19).coordinateX = 130;
components(19).coordinateY = 'i1';
components(19).drawBlock = false;
% open heater loss
components(20).coordinateX = 200;
components(20).coordinateY = 'i1';
components(20).drawBlock = false;
% condensaotr
components(21).coordinateX = 170;
components(21).coordinateY = 'i1';
components(21).inputsAlignment = 't';
components(21).outputsAlignment= 'b';
components(21).name = 'Condenser';
    % condensator to loss(22) (4.5708,energy loss,~)
        %Streams: (5) + (10) - (11) - (6)
    components(21).out(2).value = (StreamData(5).energy+StreamData(10).energy-StreamData(11).energy-StreamData(6).energy)/1000;
    components(21).out(2).target = 22;
    components(22).in(1).source = 21;
    components(21).out(2).type = 'energy loss';
    components(21).out(2).FontSize = 5;
    components(21).out(2).textShift = [8,-2];
    % condensator to chimney (26) (353.72,mixture,~)
        %Streams: (11)
    components(21).out(1).value = StreamData(11).energy/1000;
    components(21).out(1).target = 26;
    components(26).in(1).source= 21;
    components(21).out(1).type = 'mixture';
    % condensator to open heater (17) (15.6135,saturated liquid,hvh)
        %Streams: (6)
    components(21).out(3).value = StreamData(6).energy/1000;
    components(21).out(3).target = 17;
    components(17).in(1).source = 21;
    components(21).out(3).shape = 'hvh';
    components(21).out(3).verticalLinesX = 180;
    components(21).out(3).type = 'saturated liquid';
    components(21).out(3).FontSize = 7;
    components(21).out(3).textShift = [-5,0];
% condensator loss
components(22).coordinateX = 190;
components(22).coordinateY = 'i1';
components(22).drawBlock = false;
% aerATOR
components(23).coordinateX = 215;
components(23).coordinateY = 'i1';
components(23).name = 'Deaerator';
components(23).inputsAlignment = 't';
components(23).outputsAlignment = 'c';
components(23).TextRotation = 0;
components(23).FontSize = 5;
    % dearator to loss(28) (2.293355,energy loss,~)
        %Streams: (7) - (8)
    components(23).out(1).value = (StreamData(7).energy-StreamData(8).energy)/1000;
    components(23).out(1).target = 28;
    components(28).in(1).source = 23; 
    components(23).out(1).type = 'energy loss';
    components(23).out(1).FontSize = 5;
    components(23).out(1).textShift = [0,2];
    % aerATOR to pumps(24) (14.151,saturated liquid,~)
        %Streams: (8)
    components(23).out(2).value = StreamData(8).energy/1000;
    components(23).out(2).target = 24;
    components(24).in(1).source = 23; 
    components(23).out(2).type = 'saturated liquid';
    components(23).out(2).FontSize = 6;
    components(23).out(2).textShift = [3,3];
%AERATOR LOSS
components(28).coordinateX = 225;
components(28).coordinateY = 'i1';
components(28).drawBlock = false;
% PUMPS
components(24).coordinateX = 240;
components(24).coordinateY = 'i1';
components(24).inputsAlignment = 't';
components(24).name = 'Pumps';
components(24).TextRotation = 0;
components(24).FontSize = 5;
    % pumps to loss (25) (0,energy loss,~)
        %Streams: error :P
    components(24).out(2).value = 0;
    components(24).out(2).target = 25;
    components(25).in(1).source= 24;
    components(24).out(2).type = 'energy loss';
    components(24).out(2).FontSize = 5;
    components(24).out(2).textShift = [0,-2];
    % pumps to chimney(26) (14.151,compressed liquid,hvh)
        %Streams: (9)
    components(24).out(1).value = StreamData(9).energy/1000;
    components(24).out(1).target = 26;
    components(26).in(2).source = 24;
    components(24).out(1).shape = 'hvh';
    components(24).out(1).verticalLinesX = 250;
    components(24).out(1).type = 'compressed liquid';
    components(24).out(1).FontSize = 7;
    components(24).out(1).textShift = [4,0];
% PUMPS LOSS
components(25).coordinateX = 250;
components(25).coordinateY = 'i1';
components(25).drawBlock = false;
% CHIMNEY 1
components(26).coordinateX = 250;
components(26).coordinateY = 'i1';
components(26).name = 'Cooling Tower';
    % chimney to loss (27) (182.187,energy loss,~)
        %Streams:(12) - (10)
    components(26).out(1).value = (StreamData(12).energy-StreamData(10).energy)/1000;
    components(26).out(1).target = 27;
    components(27).in(1).source = 26;
    components(26).out(1).type = 'energy loss';
    % chimney to condensator (21) (185.6839,mixture,hvhvh)
        %Streams: (10)
    components(26).out(2).value = StreamData(10).energy/1000;
    components(26).out(2).target = 21;
    components(21).in(2).source = 26;
    components(26).out(2).shape = 'hvhvh';
    components(26).out(2).horizontalLinesY = -40;
    components(26).out(2).verticalLinesX = [265 150];
    components(26).out(2).type = 'mixture';
% CHIMNEY LOSS
components(27).coordinateX = 265;
components(27).coordinateY = 'i1';
components(27).drawBlock = false;

% double loop to 'delete' too small values that are neglible and make the
% diagram less readable
for i=1:length(components)
   for j=1:length(components(i).out)
       if components(i).out(j).value>12
            if components(i).out(j).value>50
                if components(i).out(j).value>100
                    if components(i).out(j).value>300
                        if components(i).out(j).value>500
                           components(i).FontSize = 10; 
                           components(i).out(j).FontSize = 10;
                        end
                    else
                        components(i).FontSize = 9;
                        components(i).out(j).FontSize = 9; 
                    end
                else
                    components(i).FontSize = 8;
                    components(i).out(j).FontSize = 8;
                end
            else
                components(i).FontSize = 7;
                components(i).out(j).FontSize = 7;  
            end
       end
       if  components(i).out(j).value<10
           components(i).out(j).FontSize = 0.001;
       end
   end
end

defaults.nominalValue = (StreamData(1).energy+StreamData(13).energy)/1000;
plotFlowDiagram;
% legend for the diagram
hold on
h=zeros(7,1);
h(1)=plot(nan,nan,'s','MarkerEdgeColor',[255 128 128]/255,'MarkerFaceColor',[255 128 128]/255);
h(2)=plot(nan,nan,'s','MarkerEdgeColor',[255 255 77]/255,'MarkerFaceColor',[255 255 77]/255);
h(3)=plot(nan,nan,'s','MarkerEdgeColor',[0 102 255]/255,'MarkerFaceColor',[0 102 255]/255);
h(4)=plot(nan,nan,'s','MarkerEdgeColor',([172 206 255]./255),'MarkerFaceColor',([172 206 255]./255));
h(5)=plot(nan,nan,'s','MarkerEdgeColor',[115 171 255]./255,'MarkerFaceColor',[115 171 255]./255);
h(6)=plot(nan,nan,'s','MarkerEdgeColor',[255 179 102]/255,'MarkerFaceColor',[255 179 102]/255);
h(7)=plot(nan,nan,'s','MarkerEdgeColor',[160 202 83]/255,'MarkerFaceColor',[160 202 83]/255);
h(8)=plot(nan,nan,'s','MarkerEdgeColor',[230 240 255]/255,'MarkerFaceColor',[230 240 255]/255);
lgd=legend(h,{'Heat','Energy Loss','Saturated Liquid','Saturated vapor','Mixture','Work','Electricity','Superheated Vapor'},'Location','northwest');
title(lgd,'Forms of energy');
title('Sankey Diagram for Geothermal Powerplant in Lombok');