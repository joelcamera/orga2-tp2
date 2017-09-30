from scipy.stats import norm
import matplotlib.mlab as mlab
import matplotlib.pyplot as plt

# read data from a text file. One number per line
arch = "experimentos/data/detail-cropflipasm-j1.log"
datos = []
for item in open(arch,'r').read().split(","):
    item = item.strip()
    if item != '':
        try:
            datos.append(float(item))
        except ValueError:
            pass

# best fit of data
(mu, sigma) = norm.fit(datos)

# the histogram of the data
n, bins, patches = plt.hist(datos, 60, normed=1, facecolor='green', alpha=0.75)

# add a 'best fit' line
y = mlab.normpdf( bins, mu, sigma)
l = plt.plot(bins, y, 'r--', linewidth=2)

#plot
plt.xlabel('Smarts')
plt.ylabel('Probability')
plt.title('Clocks necesarios para aplicar un filtro')
plt.grid(True)

plt.show()