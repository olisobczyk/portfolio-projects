This project was made by: Oliwier Piotr Sobczyk s2597047
University of Twente | 2025
Faculty of Mechanical Engineering 

########################################################

	3D Celestial Mechanics Simulation

This Python project simulates the gravitational interactions between celestial bodies (e.g. planets, stars) using Newtonian mechanics. It uses Velocity Verlet integration for accuracy and stability and Matplotlib for dynamic 3D visualization.

How to Run

1. Install required packages:

pip install numpy matplotlib
python main.py

#########################################################

			Features

- Simulates motion of multiple celestial bodies using mutual gravitational forces
- Tracks and visualizes the **center of mass (COM)** trajectory
- Animates the 3D positions and COM in real-time
- Realistic physical constants and scaling

			Physics Used

The simulation models each body using:
- Newton's Law of Universal Gravitation
- Second law of motion: `F = m * a`
- Verlet integration for position updates

#########################################################

			FILE OVERVIEW

# File: body.py
class CelestialBody:
    - Initialize with position, velocity, mass
    - Compute gravitational forces from other bodies
    - Update velocity and position using Verlet integration

# File: system.py
class System:
    - Hold all CelestialBody instances
    - Perform one full Velocity Verlet step
    - Track center of mass over time

# File: main.py
- Create instances of Sun, Earth, Mars
- Initialize System with all bodies

# File: config.py
- Define timestep and number of steps
- Define constants
- set the problem to analyse
- set the mass of the 2 planets and sun


# File: animation.py
- For each frame:
    - Advance system by 'skip' steps
    - Update positions, velocities, and center of mass
- Setup Matplotlib 3D and 2D axes
- Use FuncAnimation to create animation
- Update scatter plots and trails
- Add legend or label annotations

