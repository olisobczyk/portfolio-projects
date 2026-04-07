%{ 
this function joins the data of a given sphere into one
structure, hence it is easier to access 
OUTPUT: 
sphere
    sphere.center - center of the sphere
    sphere.radius - radius of the sphere
INPUT:
    center - [x,y,z] coordinates 
    radius - R as float
%}
function sphere = sphereStruc(center, radius)
    
    if nargin == 1 || nargin == 0
        error(' Sphere not defined properly. Check center and radius')
    end
    
    sphere.center = center;
    sphere.radius = radius;
return