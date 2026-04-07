%{
This function is called from main.m file, which is checking if the spheres
with specified coordinates and radius overlap in a 3-D space.

Function does a double loop through all the spheres to check 
if sphere(i) colides with sphere(j) by calling function checkOverlap

INPUT : spheres    -  structure with structures containing spheres OR a 
                      list in form [x1,y1,z1,r1;...;xn,yn,zn,rn]
OUTPUT: overlapSph - list containing indices of overlapping spheres
        spheres    -  structure with structures containing spheres

CHECK FUNCTIONS included:  
    -> checkOverlap.m

%}

function [overlapSph,spheres] = findOverlapSpheres(spheres)
    
    % in case list was supported 
    if ~isstruct(spheres)
        spheres = sphereGen(spheres);
        disp('Input has been processed')
    end

    % predefine empty array, at this point final size not known
    overlapSph = [];
    n_sph = length(spheres);
    
    %{
    i & j are build such that the previous spheres are not checked twice
    because for i < j the spheres were already checked for overlapping.
    e.g for spheres{i}, spheres{i+n} is checked, therefore for spheres{i+1},
    , spheres{i+1 - n}, were checked wirh i iteration. This also prevents
    checking itself as always spheres{i} & spheres{i+1+n} are compared
    %}

    for i = 1 : (n_sph - 1)  
        for j = (i + 1) : n_sph
                
                % checkoverlap returns boolean(T/F) of overlap 
            if checkOverlap(spheres(i), spheres(j))
                overlapSph = [overlapSph; i j];
            end
        end
    end


end