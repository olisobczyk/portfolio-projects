G = 6.673e-11 # gravitaitional constant 
TIMESTEP = 3600 * 6  # 6 hours
STEPS = 2000 # amount of time updates, default 2000
SKIP = 1 # skip every N-th frame of animation
PLOT_LIMIT = 3e11 # plot limit in x,y,z +/- direction (m)
# mass of the initial 3 bodies in (kg)
mass_inc = 0 # increase mass of EARTH and MARS by a factor of 10
MASS_SUN = 1.989e30
MASS_EARTH = 5.972e24 * 10**mass_inc
MASS_MARS = 6.42e23 * 10**mass_inc
three_body_problem = False # set True if want to simulate SUN, EARTH & MARS only