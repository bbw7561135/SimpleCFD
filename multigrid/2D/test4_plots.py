import numpy as np
import matplotlib.pyplot as plt

nx = np.fromfile('test4_nx.dat', dtype = np.float64)
L2 = np.fromfile('test4_l2.dat', dtype = np.float64)

ax = plt.subplot(111)
ax.set_xscale('log')
ax.set_yscale('log')

plt.scatter(nx, L2, marker="x")
plt.plot(nx,L2[0]*(nx[0]/nx)**2,"--",color="r")

plt.xlabel("n cells")
plt.ylabel("L2 norm - multigrid vs analytical")
plt.title("test4")
plt.savefig("test4_convergence.png")
