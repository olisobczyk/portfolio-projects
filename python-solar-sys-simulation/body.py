import numpy as np
from config import G #gravitational constant


class celestialBody:
    def __init__(self, ID, radius, mass, density, position, velocity):
        # Initializes a celestial body with physical and motion parameters
        self.ID = ID                                    # Identifier
        self.radius = radius                            # Radius of the body
        self.position = np.array(position, dtype=float) # 3D position vector
        self.velocity = np.array(velocity, dtype=float) # 3D velocity vector
        self.acceleration = np.zeros(3)                 # Initialized acceleration vector
        self.force = np.zeros(3)                        # Initialized force vector
        # Mass is either given or computed from radius and density
        self.mass = mass if mass != 0 else (4/3 * np.pi * radius**3 * density)

    def updateForce(self, celestials):
        # Calculates the net gravitational force on the body from other bodies
        self.force = np.zeros(3)    # each time the force is different 

        for other in celestials:                      # check interaction for each celestial
            if other is not self:                     # but not with itself
                disp = other.position - self.position # displacement vector between two celestials
                r = np.linalg.norm(disp)              # displacement normalised 
                if r > 0 :                            # should be (self.radius + other.radius) but:
                    # collsions not taken into account
                    self.force += G * self.mass * other.mass * disp / r**3  # Newtonian force calculation
    
        # Update acceleration from net force
        self.acceleration = self.force / self.mass


    def updateVelocity(self, dt):
    # Updates velocity using current acceleration
        self.velocity += self.acceleration * dt

    def updatePosition(self, dt):
    # Updates position using current velocity and acceleration (Verlet step)
        self.position += self.velocity * dt + 0.5 * self.acceleration * dt**2