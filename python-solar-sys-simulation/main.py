from body import celestialBody
from system import System
from animation import run_animation
from config import MASS_SUN, MASS_EARTH, MASS_MARS, three_body_problem
import numpy as np


# Define celestial bodies with ID, radius (m), mass (kg), density (kg/m^3 if mass=0), position (m), and velocity (m/s)
sun = celestialBody(0, 6.96e8, MASS_SUN , 0, [0, 0, 0], [0, 0, 0])                   # SUN
earth = celestialBody(1, 6.371e6, MASS_EARTH, 0, [1.496e11, 0, 0], [0, 2.978e4, 0])  # EARTH
mars = celestialBody(2, 3.39e6, MASS_MARS , 0, [2.279e11, 0, 0], [0, 2.407e4, 0])    # MARS

if not three_body_problem:

    # Generate additional 100 planets
    np.random.seed(0)
    extra_planets = []   #initialise list of extra planets

    for i in range(3, 100): # 3 planets already made so extra 97 needed

        # here some random values are obtained using normal distribiton for 
        distance = np.random.uniform(5e10, 2.5e11)   # distance from sun
        angle_xy = np.random.uniform(0, 2*np.pi)     
        angle_z = np.random.uniform(-np.pi/8, np.pi/8)

        # derive the position in 3D space
        x = distance * np.cos(angle_xy) * np.cos(angle_z)
        y = distance * np.sin(angle_xy) * np.cos(angle_z)
        z = distance * np.sin(angle_z)

        # get appropriate velocity based on the planet-Sun distance/interaction
        # based on centrifugal force F = mv^2/r
        v = np.sqrt(6.673e-11 * sun.mass / distance) 

        vx = -v * np.sin(angle_xy)              # to a x component
        vy = v * np.cos(angle_xy)               # to a y component
        vz = np.random.uniform(-0.05, 0.05) * v #introduce small z-velocity between -5/5%

        radius = np.random.uniform(1e5, 10e6)  # between 100 km and 10000 km
        mass = np.random.uniform(1e20, 1e26)  # small planet or moon
        planet = celestialBody(i, radius, mass, 0, [x, y, z], [vx, vy, vz])
        extra_planets.append(planet)
        # List of all celestial bodies in the system
        celestials = [sun, earth, mars] + extra_planets
else:
    # List of all celestial bodies in the system
    celestials = [sun, earth, mars] 


# call the function to setup the system
system = System(celestials)

run_animation(system)