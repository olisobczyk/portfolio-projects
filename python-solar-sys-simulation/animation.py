import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import numpy as np
from config import PLOT_LIMIT, TIMESTEP, STEPS, SKIP

def run_animation(system):

    N_celestial = len(system.celestials) # get the amount of celestials
    # create the plot and, set the size and make it in 3D
    fig = plt.figure(figsize=(10, 10))  # 3D plot for orbital motion
    ax = fig.add_subplot(projection='3d')

    # set the plot limits, name axes and give title
    ax.set_xlim(-PLOT_LIMIT, PLOT_LIMIT)
    ax.set_ylim(-PLOT_LIMIT, PLOT_LIMIT)
    ax.set_zlim(-PLOT_LIMIT, PLOT_LIMIT)
    ax.set_title("3D Celestial Mechanics Simulation")
    ax.set_xlabel("X (m)")
    ax.set_ylabel("Y (m)")
    ax.set_zlabel("Z (m)")


    # set the colors and size for SUN, EARTH, MARS, EXTRA PLANETS
    colors = ['yellow', 'blue', 'red'] + ['gray'] * (N_celestial - 3) # amount of planets varies 
    sizes = [300, 50, 40] + [10] * (N_celestial - 3)
    
    # get positions of the planets into an array
    init_x, init_y, init_z = system.positions[:, 0], system.positions[:, 1],system.positions[:, 2]

    # set the initial position 
    sc = ax.scatter(init_x, init_y, init_z, c=colors[:N_celestial], s=sizes[:N_celestial], alpha=0.8)
    com_trail, = ax.plot([], [], [], 'ko-', markersize=2,label="Center of Mass")

    def init():
        # Initialize animation: clear all markers and trails
        sc._offsets3d = ([], [], [])  # reset scatter plot for celestial bodies
        com_trail.set_data([], [])  # reset X-Y trail for center of mass
        com_trail.set_3d_properties([])  # reset Z trail for center of mass


    def update(frame):
        # Updates simulation and visuals for each animation frame
        for _ in range(SKIP): # possibility to skip N frames defined in config
            system.step(TIMESTEP)

        # get the current x,y,z positions
        x = system.positions[:,0]
        y = system.positions[:,1]
        z = system.positions[:,2]
        sc._offsets3d = (x, y, z)
        
        # set the 3D coordinates of the trail of CoM
        com_trail.set_data(system.com_x, system.com_y)
        com_trail.set_3d_properties(system.com_z)

        return sc, com_trail,

    # Run animation
    ani = FuncAnimation(fig, update, frames=STEPS//SKIP, init_func=init, interval=30, blit=False)
    plt.tight_layout()
    plt.legend()
    plt.show()