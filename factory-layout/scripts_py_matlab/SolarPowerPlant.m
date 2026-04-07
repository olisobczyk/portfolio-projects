function [Energy,Efficiency,Helio,Tower,Field] = SolarPowerPlant(Properties)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% https://www.pveducation.org/pvcdrom/properties-of-sunlight/solar-time#HRA
%% DESIGN CALCULATIONS OF HELIOSTAT FIELD LAYOUT FOR SOLAR THERMAL POWER GENERATION HNIN WAH, NANG SAW YUZANA KYAING
%% These below are constants

% TIME 
% time to calculate later on
Time.DaysYear = 365;

% EFFICEINCY
%{ 
Efficiency.Block is the efficiency due to shadowing and blockage of the
beams from particular heliostats due to their height.
Efficiency.Reflectivity is the efficiency of the mirrors and it is assumed
to be perfect and that the mirrors are perfectly clean 
Efficiency.Atmosphere is due to the distance of the heliostats and thesolar
power tower
Linke Factor is due to weather conditions and the bigger the worse
conditions and are set randomly to make it as real as possible
%}
Efficiency.Block = (100 - 5.60)/100;
Efficiency.Reflectivity = 0.96;
Efficiency.Atmosphere = 0.99; 
LinkeFactor = 1.5; 

% SOLAR TIME 

%Local Solar Time, these are the constants for Lombok 
%constant solar flux at the atmosphere
Solar.Solar_Constant_Flux = 1367; %[W/m^2]
Angle.Longitude = 116.3; 
Angle.Lattitude = -8.65;
Solar.Timezone = 8;
Solar.LocStandTimeMer = 15 * Solar.Timezone;

%below is the vector of time for every 30 minutes in a day from 6am till
%9pm
Solar.LocalHour = hours(6) + minutes(0:30:900); 

% HELIOSTATS AND FIELD CHARACTERISTICS
%{
THese contatns are given in the main file and give the specific nformation
about the helisotats, tower and field properties. The helio seperation is
fixed and is the distance between adjecent heliostats.
%}
%HELIOSTATS
Helio.Width = Properties.Helio.Width;
Helio.Length = Properties.Helio.Length;
Helio.Heigth = Properties.Helio.Heigth;
Helio.Area = Properties.Helio.Area;
Helio.Seperation = 0.2;
%TOWER
Tower.Height = Properties.Tower.Height;
Tower.DiameterSpot = Tower.Height/95 * Properties.Tower.DiamSpot;
Tower.AbsorvHeight = Tower.Height/95 * Properties.Tower.AbsorvHeight;
Tower.ReflectorLength = Tower.Height/95 *Properties.Tower.ReflLength;
%FIELD
Field.ZonesAmount = Properties.Field.ZonesAmount;
Field.AmountHelioRow(1) = Properties.Field.FirstRow;

%% calculations
% angle for which the beam from the helisotats is recieved 
Angle.Reciever = asind((-2* Tower.DiameterSpot * Tower.ReflectorLength + Tower.AbsorvHeight * sqrt(4*Tower.ReflectorLength^2 + Tower.AbsorvHeight^2 - Tower.DiameterSpot^2))/(4*Tower.ReflectorLength^2 + Tower.AbsorvHeight^2));
Angle.Vertical = 90 - Angle.Reciever;

% distance between centers of adjecent heliostats
Field.CharDiam = (sqrt(Helio.Width^2 + Helio.Length^2) + Helio.Seperation);

%{
RadiusDistanceMin is the distant between adjecnt helisotats for them not to
                crash within each other.
Tower_Dist is the distance from the tower to following rows
Azimut Spacing is the angle between next heliostats in the row
Rows is the amount of rows within each zone
AmountHelioRow is the amount of Heliostats within each row
%}
       Field.RadiusDistanceMin = Field.CharDiam * cosd(30);
       Field.Tower_Dist(1) = Field.AmountHelioRow(1) * Field.CharDiam / (2 * pi);
       Field.AzimutSpacing(1) = 2 * asin(Field.CharDiam/(2 * Field.Tower_Dist(1)));
       
for i = 1:Field.ZonesAmount
    % calculations for the first row are different and are needed for the
    % further rows
    if i<Field.ZonesAmount
       Field.AzimutSpacing(i+1) = Field.AzimutSpacing(1)/ (2^(i));
       Field.AmountHelioRow(i+1) = ceil(2 * pi/Field.AzimutSpacing(i+1));
    end
       Field.Tower_Dist(i+1) = 2^(i) * Field.CharDiam/Field.AzimutSpacing(1);
       Field.Rows(i) = ceil((Field.Tower_Dist(i+1)-Field.Tower_Dist(i))/(Field.RadiusDistanceMin));
end


%{
to be used in the for loop for day
equation of Time: is the correction of thime due to earths and eccentricrity
                  and it varies between +20 and -15 minutes
Time Correction Factor: correction due to timezone , longitude and
                        including equation of Time. Factor 4 accounts for 4
                        minutes per 1 degree angle
Local Solar TIme: sum of local Time and Time Correction in minuts/60(hours)
Angle Hour: converts the local solar time (LST) into the number of degrees which the sun moves across the sky.
Declination Angle: due to earths tilt the angle of the light is different throughout the year
                  oscialtes between 23 and -23 degrees
Elevation Angle: is the angle between the sun and earths surface
Zenith Angle: Angle between Zenith and current time
%}
for nDay = 1:Time.DaysYear
% BETA ANGLE FOR EQ.OF TIME   
Angle.Beta = 360/365 * (nDay - 81);
% EQUATION OF TIME
Solar.EqOfTime =  9.87 * sind(2*Angle.Beta) - 7.53 * cosd(Angle.Beta) - 1.5 * sind(Angle.Beta);
% SOLAR TIME CORRECTION
Solar.TimeCorrection = 4 * (Angle.Longitude - Solar.LocStandTimeMer) + Solar.EqOfTime;
% LOCAL SOLAR TIME
Solar.LocalSolarTime = Solar.LocalHour + minutes(Solar.TimeCorrection);
% HOUR ANGLE
Angle.HourAngle = hours(15 * ( Solar.LocalSolarTime - hours(12)));
% DECLINATION ANGLE
Angle.Declination = -23.45 * cosd(360/365 * (nDay + 10));
% ELEVATION ANGLE
Angle.Elevation = asind(sind(Angle.Declination) * sind(Angle.Lattitude) + cosd(Angle.Declination) * cosd(Angle.Lattitude) * cosd(Angle.HourAngle));
% ANGLE ZENITH
Angle.Zenith = 90 - Angle.Elevation;
% AZIMUT ANGLE
Angle.Azimut = asind((cosd(Angle.Declination) * sind(Angle.HourAngle))/sind(Angle.Zenith));
% HOUR ANGLE CONDITIONAL
Angle.HourAngleCond = 180 - Angle.Azimut;
% SURFACE AZIMUTH ANGLE
Angle.SurfaceAzimut = Angle.Azimut + 90;

% calculating optical mass of the atmosphere (if u went through solar
% incidence angle this one will be easy for you)
for k=1:length(Angle.Elevation)
if Angle.Elevation(k) > 30
mass_optical(k) = 1/sind(Angle.Elevation(k));
else
mass_optical(k) = (1.002432 * (sind(Angle.Elevation(k))).^2 + 0.148386* (sind(Angle.Elevation(k))) + 0.0096467)/ ((sind(Angle.Elevation(k))).^3 + 0.149864*(sind(Angle.Elevation(k))).^2 + 0.0102963*(sind(Angle.Elevation(k))) + 0.000303978);
end
% calculating the Rayleigh Optical thickness for air mass
if mass_optical(k) <= 20
airthickness(k) = 1/(6.6296 + 1.7513*mass_optical(k) - 0.1202*mass_optical(k).^2 + 0.0065 * mass_optical(k).^3 - 0.00013 * mass_optical(k).^4);
else
airthickness(k) = 1/(10.04 + 0.718 * mass_optical(k));     
end
end
clear k
% solar flux with respect to the day of the year 
Solar_Flux_day = Solar.Solar_Constant_Flux * (1 + 0.033 * cosd(360 * nDay/365)) * cosd(Angle.Zenith);
% cosinus efficiency 
Efficiency.Cosinus = sqrt(2)/2 * (sind(Angle.Elevation) * cosd(Angle.Vertical) - cosd(Angle.SurfaceAzimut - Angle.HourAngleCond).* cosd(Angle.Elevation) .* sind(Angle.Vertical) +1).^0.5;
% beam irradiance
Beam_Irradiance = Solar_Flux_day .* exp(-0.8662 * LinkeFactor .* mass_optical .* airthickness);
Energy.BeamIrradiation(nDay,:) = Beam_Irradiance .* Efficiency.Atmosphere;
Energy.BeamIrradiation(nDay,Energy.BeamIrradiation(nDay,:)>0) = Energy.BeamIrradiation(nDay,Energy.BeamIrradiation(nDay,:)>0);

% angle for each heliostat row for the whole field 
                     
 % OPTICAL EFFICIENCY - product of all efficiencies                    
Efficiency.Optical = Efficiency.Atmosphere * Efficiency.Cosinus * Efficiency.Reflectivity * Efficiency.Block;
 % DAILY EFFICIENCY - mean of Optical Efficiency
Efficiency_Daily(nDay) = mean(Efficiency.Optical);

%{
Below is the double for loop which bases on Zones and amount of Rowes in
each zones. For each Row in every zone the are calculations made. Which are
the Angle betweeen the heliostats and the tower, distance between tower and
heliostats and Rotation of the helisotat. 
Next the Angle of the Solar light incident on the Heliostat is calculated. 
%}

a = Angle.Lattitude;
b = Angle.Declination;
c = Angle.SurfaceAzimut;
d = Angle.HourAngle;

for Zones = 1:Field.ZonesAmount
    for AmountRows = 1:Field.Rows(Zones)
        Angle.SolarTowerAlt = atand((Tower.Height - Helio.Heigth)/(Field.Tower_Dist(Zones) + (AmountRows -1) * Field.RadiusDistanceMin));
        Field.BeamDistance = sqrt((Field.Tower_Dist(Zones) + (AmountRows -1) * Field.RadiusDistanceMin)^2 + (Tower.Height - Helio.Heigth)^2);
        Angle.HelioRotation = (Angle.SolarTowerAlt + Angle.Elevation)/2;
        
        e = Angle.HelioRotation;
    
 % solar incidence angle(well i would recommend not even trying to understand what is here :P)   
        Angle.SolarIncidence = acosd((sind(a).*sind(b).*cosd(e)) - (cosd(a).*sind(b).*sind(e).*cosd(c))... 
                               + (cosd(a).*cosd(b).*cosd(d).*cosd(e)) + (sind(a).*cosd(d).*cosd(b).*sind(e).*cosd(c))...      
                               + (cosd(b).*sind(d).*sind(e).*sind(c)));

 % SOLAR IRRADIATION - product of Solar Irradiance sin of Solar Incidence
 %                     Angle and Optical Efficiency
 % Area of the Heliostats in the chosen Row
 AreaOfTheHelio = Field.AmountHelioRow(Zones) * Helio.Area;
PowerHelioRows(AmountRows,:) = (Beam_Irradiance .* sind(Angle.SolarIncidence)  .* Efficiency.Optical) .* AreaOfTheHelio;
 
% the negative values are thrown out - sorted
 SortedPowerHelioRows(AmountRows,PowerHelioRows(AmountRows,:)>0) = PowerHelioRows(AmountRows,PowerHelioRows(AmountRows,:)>0);

    end %END OF THE AMOUNTROWS FOR LOOP
%sum of the Power for every row in each Zone    
Power.PowerSolar(Zones,:) = sum(SortedPowerHelioRows(:,:));

end %END OF THE ZONES FOR LOOP

% sum of the power for All zones each Day
Energy.PowerSolarDay(nDay,:) = sum(Power.PowerSolar(:,:));

if Properties.Decision == 3 && nDay>2
check = sum(60.*30.*Energy.PowerSolarDay(nDay,:)./1000);
if check - Properties.EnergyNeeded < -Properties.EnergyNeeded * 0.03
    Energy.PowerSolarDay = 0;
    check = 0;
    break
end
end 

end % END OF nDAY FOR LOOP
clear a b c d e

% efficiency of the whole year
Efficiency.Efficiency_Daily = mean(Efficiency.Optical);

% SOLAR ENERGY - for every second in the 30 minutes intervals
Energy.EnergySolarDaySeconds = 60.*30.*Energy.PowerSolarDay./1000;
% AREA OF THE HELIOSTATS
Helio.AmountOfTheHelio = 0;
%Helio. sum of every Heliostat's Area on the Field
for i = 1:Field.ZonesAmount
 Helio.AmountOfTheHelio =  Helio.AmountOfTheHelio + Field.AmountHelioRow(i) .* Field.Rows(i);
end
Helio.AreaOfTheHelio = Helio.AmountOfTheHelio * Helio.Area;

% YEARLY ENERGY GAIN - product of Solar Energy and Area of Heliostats
Energy.Energy_Annual = sum(sum(Energy.EnergySolarDaySeconds));
Energy.Energy_DailyAverage = (Energy.Energy_Annual)/365;

end