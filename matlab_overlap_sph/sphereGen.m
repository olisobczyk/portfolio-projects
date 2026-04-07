%{
This function is called from main.m file, which is checking if the spheres
with specified coordinates and radius overlap in a 3-D space.

This function creats spheres with [x y z] coordinates and R radius. 
The user has choice in main.m to obtain these between 
xls(data from xls)\ predef(predefined spheres)\ rand(new n random spheres).

The user can choose in line 52,53 the max,min coordinates and radii
Currently x,y,z max/min = 40 &-40 and r max/min = 1 & 5

CHECK FUNCTIONS included:
    -> sphereGen.m (itself)
    -> sphereStruc.m - to create sphere structure

CHECK for file:
    -> sphereDef.xls in same directory

INPUT  : (choice) "string" with (xls/predef/rand) or list of spheres
          this list is in form [x1,y1,z1,r1;...;xn,yn,zn,rn]
OUTPUT : spheres = structure with sphere centers and radii

%}


function spheres = sphereGen(choice)
    
    if ischar(choice)
        switch choice  % choice is a string 
    
    
            case 'xls'  % read from sphereDef.xls file 
    
                sph_list = xlsread('sphereDef.xls', 'Spheres','A1:D50');
                defArr = numArray(sph_list); % check if all are valid
                spheres = iterSpheres(defArr(:,1:3),defArr(:,4));
                
            case 'predef' % use the predefined data below
    
                spheres(1) = sphereStruc([0 0 11], 3);
                spheres(2) = sphereStruc([5 5 25], 1);
                spheres(3) = sphereStruc([1 2 4], 2);
                spheres(4) = sphereStruc([2 8 2], 4);
                spheres(5) = sphereStruc([6 6 9], 6);
                spheres(6)=  sphereStruc([3 8 13], 3);
    
            case 'rand'  % create random data
                    
                % user has to decide on number of spheres:
                n_rand = NaN;
                while isnan(n_rand) || n_rand < 2
                    userInput = input('Specify amount of random spheres: ', 's'); % Get input as string
                    n_rand = str2double(userInput); % Convert to number
                    
                    % Check if conversion was successful and number is valid
                    if isnan(n_rand) || n_rand < 2
                        disp('Invalid input. Please enter a number greater than or equal to 2.');
                    end
                end
                
                % generate random coordinates & radius, specify:
                R_min = 1;  cord_min = -40;   % min R & min x,y,z
                R_max = 5;  cord_max = 40;  % max R & max x,y,z
                
                % and calculation done here V
                rand_xyz = rand(n_rand,3) .* randi([cord_min cord_max],n_rand,3) ;
                rand_R = randi([R_min R_max],n_rand,1); 
    
                % forward data rand_xyz & rand_R to create set of sph struc
                spheres = iterSpheres(rand_xyz,rand_R);
    
            otherwise   % if wrong string then type again and recall function
    
                prompt = ['Wrong input. Specify the set of spheres, type: ' ...
                    'xls / predef / rand: '];
                choice = input(prompt,"s");
                spheres = sphereGen(choice);
    
        end  % switch end

    elseif size(choice,1) > 1 % choice is a list 

        defArr = numArray(choice); % check if all are valid
        spheres = iterSpheres(defArr(:,1:3),defArr(:,4));
        
    else
        error(['Supported input is not a defined choice or a proper list in' ...
            'form [x1,y1,z1,r1;...;xn,yn,zn,rn]'])
    end % if end

return


%% aditional functions for structure

% function to make the structure
function spheres = iterSpheres(centers, radii)

    % define the structure of desired size
     spheres(length(radii)) = struct('center',[],'radius',[]);

     for i = 1:length(radii)
         spheres(i).center = centers(i,:);
         spheres(i).radius = radii(i);
     end

return 


function numericArr = numArray(arr)
    
    if isstring(arr) | ischar(arr)
        numericArr = str2double(arr); %if any non double then NaN appers
    else 
        numericArr = arr;
    end
    
    % Find indices where NaN appears (indicating a string input)
    [rowIdx, colIdx] = find(isnan(numericArr));
    
    % Display results
    if isempty(rowIdx) | isnan(numericArr)
        disp('No string characters found in the array.');
        numericArr = arr;
        return
    else
        fprintf('Found %d string characters, if continue please change', ...
            length(rowIdx))
        for i = 1:length(rowIdx)
            disp('String characters found at the following indices:');
            disp([rowIdx(i), colIdx(i)]); % Display row-column pairs
            newNum = input('New number: ');
            numericArr(rowIdx,colIdx) = newNum;
        end
        disp('Array was succesfully converted')
    end


return