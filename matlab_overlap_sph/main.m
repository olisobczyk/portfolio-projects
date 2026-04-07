%{
Oliwier Piotr Sobczyk - s2597047

This is the main.m file for the final Assignment for Matlab Course 

USER INPUT The user is asked for input to run the file for 
    -> the pre-defined set of spheres
    -> load them from xls file
    -> generate desired amount of  random spheres
        -> then specify number of spheres

CHECK FUNCTIONS included:
    -> sphereGen.m
        -> sphereStruc.m
    -> findOverlapSpheres.m    
        -> checkOverlap.m
    -> svDisp.m

CHECK for FILES included:
    -> sphereDef.xls 

###### DESCRIPTION #######

Task of this script is to evalaute the collision of the spheres based
on their defined centers and radii:

    sph_n = sphereStruc([x, y, z], R]
        x,y,z - coordinates of center (float/int)
        R - radius of the sphere (float/int)
        sph_n - handle of created sphere structure

and then evaluating them using the function findOverlapSpheres:

    [overlapSph, spheres] = findOverlapSheres(spheres)
        
        spheres - structure containing all defined spheres
        sphOvPairs - list pairs (i ,j) with overlaped sphere inidicies


%}
%% generating the spheres (xls/pre-defined/random)

prompt = 'Specify the set of spheres (type: xls/predef/rand): ';
choice = input(prompt,"s");

spheres = sphereGen(choice);

clearvars -except spheres

%% evaluation of overlap
% ~ is not necessary but reminds that there are two outputs
[overlapSph,~] = findOverlapSpheres(spheres);

% Display results
fprintf('There are %d spheres which overlap. Overlapping Sphere Pairs (by Index): \n',length(unique(overlapSph)));
disp(overlapSph);

%% save and display results

prompt = 'Do you wish to save and display results y/n?: ';
choice = input(prompt,"s");

if choice == "y"
    svDisp(overlapSph, spheres)
else
    disp('Thank you for using this script')
end

clearvars -except spheres overlapSph

