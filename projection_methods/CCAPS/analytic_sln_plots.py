import numpy as np
import matplotlib.pyplot as plt

xc = np.fromfile('xc.dat', dtype = np.float64)
yc  = np.fromfile('yc.dat', dtype = np.float64)
u = np.fromfile('u.dat', dtype = np.float64)
v = np.fromfile('v.dat', dtype = np.float64)
utest = np.fromfile('utest.dat', dtype = np.float64)
vtest = np.fromfile('vtest.dat', dtype = np.float64)
udiff = np.fromfile('udiff.dat', dtype = np.float64)
vdiff = np.fromfile('vdiff.dat', dtype = np.float64)
divu = np.fromfile('divu.dat', dtype = np.float64)
phi = np.fromfile('phi.dat', dtype = np.float64)

u = u.reshape(yc.size, xc.size)
v = v.reshape(yc.size, xc.size)
utest = utest.reshape(yc.size, xc.size)
vtest = vtest.reshape(yc.size, xc.size)
udiff = udiff.reshape(yc.size, xc.size)
vdiff = vdiff.reshape(yc.size, xc.size)
divu = divu.reshape(yc.size, xc.size)
phi = phi.reshape(yc.size, xc.size)


plt.clf()
plt.contourf(xc, yc, u, 255) 
#plt.grid(True)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('u (simulated)')
#plt.show()
plt.savefig('u0.png')

plt.clf()
plt.contourf(xc, yc, v, 255) 
#plt.grid(True)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('v (simulated)')
#plt.show()
plt.savefig('v0.png')

plt.clf()
plt.contourf(xc, yc, utest, 255) 
#plt.grid(True)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('u (analytic)')
#plt.show()
plt.savefig('u1.png')

plt.clf()
plt.contourf(xc, yc, vtest, 255) 
#plt.grid(True)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('v (analytic)')
#plt.show()
plt.savefig('v1.png')

plt.clf()
plt.contourf(xc, yc, udiff, 255) 
#plt.grid(True)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('u (sim) - u(analytical)')
#plt.show()
plt.savefig('u3.png')

plt.clf()
plt.contourf(xc, yc, vdiff, 255) 
#plt.grid(Trve)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('v (sim) - v(analytical)')
#plt.show()
plt.savefig('v3.png')

plt.clf()
plt.contourf(xc, yc, divu, 255) 
#plt.grid(Trve)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('divu')
#plt.show()
plt.savefig('divu.png')

plt.clf()
plt.contourf(xc, yc, phi, 255) 
#plt.grid(Trve)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('phi')
#plt.show()
plt.savefig('phi.png')



