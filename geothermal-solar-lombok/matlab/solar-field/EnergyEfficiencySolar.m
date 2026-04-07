function [Best] = EnergyEfficiencySolar(Properties,Needed,Decision)
%{
Purpose of this function is to call another function and find the best
optimized results from it. The function is:
[Energy(j,k),Efficiency_Overall(j,k),AreaNeeded(j,k)] = SolarPowerPlant(Properties)
OUTPUT:
Arrays for:
*Energy [kJ]
*Efficiency_Optical
*Needed Area [m^2]
Based on different Zones amount and different amout of Heliostats in the
first row. Yet to be dependent on the main file. For now it can be changed
here in Tower Height, Field zOnes amount and Field First Row.
%}
% Properties for the for loop
TowerHeight =70:5:100;
FieldZonesAmount = 2 : 1: 4;
FieldFirstRow = 10:1:50;
% add the decision to propertiese
Properties.Decision = Decision;
Properties.EnergyNeeded = Needed.EnergyNeededDay;
%{ 
For loops to run between three different possibilites between Tower HEight,
Fieldzones amount and Field First Row for Finding the best solution.
Needles to say the maximum output will be with the biggest values of these
properties but still is calcualted. As also the minimum required energy and
minimum area to produce the minimum energy.
%}
% TOWER HEIGHT
for i = 1:1:length(TowerHeight)
    clc
    disp(['Tower height is currently: ' num2str(TowerHeight(i))]);
    Properties.Tower.Height = TowerHeight(i);
    %FIELDZONESAMOUNT
    for j = 1:1:length(FieldZonesAmount)
        disp(['Current Amount of Zones Are: ' num2str(FieldZonesAmount(j))]);
        Properties.Field.ZonesAmount = FieldZonesAmount(j);
        %FIELDFIRSTROW
        for k = 1:1:length(FieldFirstRow)
            Properties.Field.FirstRow = FieldFirstRow(k);
            % call to the function
            [Energy(j,k),Efficiency(j,k),~,~,Field] = SolarPowerPlant(Properties) ;
            % extracting energy daily
            Energy_Daily(j,k) = Energy(j,k).Energy_Annual;
            % calculations of the Needed Area
            AreaNeeded(j,k) = (2^(length(Field.Rows)) * Field.CharDiam/Field.AzimutSpacing(1))^2*pi;
                %check whether the efficiency isnt the same every time, and
                %probably it will be no matter the conditions
                %{
                if k>=2
                    if (Efficiency(j,k).Efficiency_Daily == Efficiency(1,1).Efficiency_Daily)
                        Efficiency(j,k).Efficiency_Daily = 0;
                    end %END OF IF FUNCTION   
                end %END OF k>2 IF FUNCTION 
                %}
        end %FIELDFIRSTROW - END of FOR LOOP        
    end %FIELDZONESAMOUNT - END of FOR LOOP   
%{
becasuse there are three variables there had to be made two if functions 
to find the otpital results from the function. Hence the if function is 
based on the decision number from 1 to 3 explained in the main file. Here 
the Best outputs are the vectors of energy, fieldZones, Area and Amountin
the first Row.
 %}
    
%MAXIMUM ENERGY

if Decision == 1
    Energy_Best(i) = max(max(Energy_Daily));
    [y2,x2] = find((Energy_Daily) == max(max(Energy_Daily)));
    AreaBest(i) = AreaNeeded(y2,x2);
    FieldZoneBest(i) = FieldZonesAmount(y2);
    FieldFirstRowBEst(i) = FieldFirstRow(x2); 
    
%JUST ENOUGH ENERGY

elseif Decision == 2
    %finding the minimum difference for the optimum energy
    MinimumDifference = min(min((abs(Energy_Daily-Needed.EnergyNeededYear))));
    Energy_Best(i) = Energy_Daily(((abs(Energy_Daily-Needed.EnergyNeededYear))== MinimumDifference));
    [y2,x2] = find(Energy_Daily == Energy_Best(i));
    AreaBest(i) = AreaNeeded(y2,x2);
    FieldZoneBest(i) = FieldZonesAmount(y2);
    FieldFirstRowBEst(i) = FieldFirstRow(x2); 
    
% MINIMUM AREA

elseif Decision ==3
    %selectiong the minimum area from the array of area that corresponds to
    %just eneough or more energy
    if any(any(Energy_Daily>0))
    AreaBest(i) = min(min(AreaNeeded(Energy_Daily>0)));
    [y2,x2] = find(AreaNeeded == AreaBest(i));
    Energy_Best(i) = Energy_Daily(y2,x2);
    FieldZoneBest(i) = FieldZonesAmount(y2);
    FieldFirstRowBEst(i) = FieldFirstRow(x2); 
    end
end %END OF THE DECISION LOOP 



end %TOWER HEIGHT - END of FOR LOOP

%{
Now after 3 for loops the outpus vectors will be changed basing on the
decision number same as the previous step resulting in the final scalars of
the desired output.
%}
%MAXIMUM ENERGY
if Decision ==1
    EnergyBest = max(Energy_Best);
    x = find(Energy_Best == max(Energy_Best));
    x = min(x);
    Best.Area = AreaBest(x);
    Best.Energy = EnergyBest;

%JUST ENOUGH ENERGY

elseif Decision==2
    Best.Energy = min(Energy_Best);
    x = find(Energy_Best == min(Energy_Best));
    x = min(x);
    Best.Area = AreaBest(x);

% MINIMUM AREA

elseif Decision==3
    Best.Area = min(AreaBest);
    x = find(AreaBest == Best.Area);
    x = min(x);
    Best.Energy= Energy_Best(x);
    
end %END OF THE DECISION LOOP 

% corresponding FieldZones, TowerHeight and First Row for the given outputs
Best.FieldZone = FieldZoneBest(x);
Best.FieldFirstRow = FieldFirstRowBEst(x); 
Best.Tower = TowerHeight(x);
end