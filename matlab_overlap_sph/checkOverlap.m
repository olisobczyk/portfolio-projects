%{

This function is called from main.m file, which is checking if the spheres
with specified coordinates and radius overlap in a 3-D space.

This function is used from the main.m script to check if the
two given spheres overlap by checking Euclidean distance between
their centers.

INPUT: (sph1, sph2) - structures
OUTPUT: isOverlap - boolean 
%}

function isOverlap = checkOverlap(sph1, sph2)
    
    distC = norm(sph1.center - sph2.center);
        % distance between spheres greater than sum of their radii
    isOverlap = (distC <= sph1.radius + sph2.radius);

return