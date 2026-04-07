
%{
THIS SCRIPT IS MADE FOR CALCUALTING THE ENERGY, AND PROPERTIES OF THE FIELD
OF A SOLAR POWER PLANT. THe script consists of the properties of the field,
heliostats and the needed energy. User gets the decision to make which
output is the best for him by choosing the number. Script uses the
fucntion:
[Energy,Efficiency_Overall,TowerBest,FieldZoneBestBest,FieldFirstRowBestBest,AreaBEstBest] = EnergyEfficiencySolar(Properties,EnergyNeeded,decision);
OUTPUTS:
Best results for:Energy,Efficiency_Overall,TowerBest,FieldZoneBestBest,
FieldFirstRowBestBest,AreaBEstBest for the desired output
INPUT:
Properties of the Heliostats,Tower and Field
Needed Yearly Energy in kJ
decision is the decision for the desired output between 1 and 3
1 - maximmum power
2 - minimum required power
3 - minimum area per needed power
%}
clc,clear
close all
%% properties of the heliostats and the Tower

%HELIO
Properties.Helio.Width = 7;
Properties.Helio.Length = 7;
Properties.Helio.Heigth = 7;
Properties.Helio.Area = 49;

%TOWER
Properties.Tower.DiamSpot = 10;
Properties.Tower.AbsorvHeight = 20;
Properties.Tower.ReflLength = 8;

%ENERGY NEEDED [kJ]
Needed.EnergyNeededYear = 2.121e+10*365;
Needed.EnergyNeededDay = 2.121e+10;

% for the user to choose the best option fot him
disp('Choose option(number) :')
disp(["1 - maximmum power ";
     "2 - minimum required power";
     "3 - minimum area per needed power"])
prompt ='Make the decision: ';
% input for decision
decision = input(prompt);

%% call to the function
[Best] = EnergyEfficiencySolar(Properties,Needed,decision);
% END OF THE FUNCTION EnergyEfficiencySolar

% adding the best properties to properties structure
 Properties.Tower.Height = Best.Tower;
 Properties.Field.ZonesAmount = Best.FieldZone;
 Properties.Field.FirstRow = Best.FieldFirstRow;
 Properties.Decision = 0;
 % with these properties calling to the SOlarPlant function
[Energy,Efficiency,Helio,Tower,Field] = SolarPowerPlant(Properties);

% data preparation for plotting
SolarIrradianceDaily = Energy.EnergySolarDaySeconds';
BeamIrradianceDaily = Energy.BeamIrradiation';
MaxSolarRadiance = max(SolarIrradianceDaily);
SumSolarRadiance = sum(SolarIrradianceDaily);
SumBeamIrradiance = sum(BeamIrradianceDaily);
% plotting the figures

% MAXIMUM FOR EACH DAY
figure
pl(1) = plot(1:365,MaxSolarRadiance);
title('Maximum Sollar Radiance')
xlabel('Days N');
ylabel('Solar Radiance [W/m^2]');
xlim([0 365]);

% SUM FOR EACH DAY
figure
hold on
pl(2) = plot(1:365,SumSolarRadiance);
pl(3) = plot(1:365,SumBeamIrradiance);
title('Sum of Daily Solar Radiance');
xlabel('Days N');
ylabel('Solar Radiance [W/m^2]');
xlim([0 365]);
% END OF THE SCRIPT 
%(v TRASH v)
clear prompt decision 