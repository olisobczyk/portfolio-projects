%{
This function is called from main.m file, which is checking if the spheres
with specified coordinates and radius overlap in a 3-D space.

svDisp is the final functiond used when the user chooses to save and
display the results. With this function The indicies of the overalapping 
spheres are saved in a text file 'overlapSpheres.txt' and a figure is made
in 3-D with blue dots (not overlapping spheres) and red dots (overlapping
sphers).

INPUT: overlapSph double with indicies of overlapped spheres
       spheres structure with fields: 'center','radius' of each sphere

OUTPUT: no output but new overlapSphers.txt file
        and Figure in 3D space.

%}

function svDisp(overlapSph, spheres)

    % save results in a text file
    fid = fopen("overlapSpheres.txt", "w");
    fprintf(fid,' INDICIES OF OVERLAPPED SPHERES \n');
    fprintf(fid,'|  %d  |  %d  |\n',overlapSph); % two columns with indicies
    fclose(fid);
    
    % display results
    coord = reshape([spheres.center], 3, [])'; % get coordinates to Nx3 array
    coordOv  = coord(unique(overlapSph),:); % coordinates of overlapped spheres
    coord(unique(overlapSph),:) =[];  % coordinates of not overlapped spheres

    % plot figure 
    figure
    plot3(coord(:,1),coord(:,2),coord(:,3),'.','MarkerSize',100)
    hold on 
    plot3(coordOv(:,1),coordOv(:,2),coordOv(:,3),'r.','MarkerSize',100)
    xlabel('x');ylabel('y');zlabel('z');title('Generated spheres')

end