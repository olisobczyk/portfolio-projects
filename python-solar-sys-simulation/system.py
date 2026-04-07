import numpy as np 

class System:
    def __init__(self, celestials):
        # Initializes the system with celestial bodies and center of mass tracking
        self.celestials = celestials
        self.com_x = []
        self.com_y = []
        self.com_z = []

        # initialise the positions and mass arrays
        self.positions = np.zeros((len(celestials), 3)) 
        self.masses = np.zeros(len(celestials))
        self.com_totalM = 0

        # get masses and positions of the system
        for c in self.celestials:
            self.positions[c.ID, :] = c.position
            self.masses[c.ID] = c.mass
            self.com_totalM += c.mass # get total mass of system

    def step(self, dt):

        # get center of mass before each step
        self.updateCoM()

        # Advances the system state by one time step using Velocity Verlet integration
        for c in self.celestials:
            c.updateForce(self.celestials)
        for c in self.celestials:
            c.updateVelocity(dt / 2)
        for c in self.celestials:
            # update new position and update it in the system
            c.updatePosition(dt)
            self.positions[c.ID, :] = c.position 
        for c in self.celestials:
            c.updateForce(self.celestials)
        for c in self.celestials:
            c.updateVelocity(dt / 2)



    def updateCoM(self):
        # Calculates and stores the center of mass of the system
        com = np.sum(self.positions * self.masses[:, np.newaxis], axis=0) / self.com_totalM

        # stored as such for tracking purposes in the plot 
        self.com_x.append(com[0])
        self.com_y.append(com[1])
        self.com_z.append(com[2])