from libtest import *

output = open(DATADIR + "/output.txt")
data = output.read().split("\n")

sizes = getSizes()

def pixels(anchoXalto):
	partes = anchoXalto.split("x")
	return int(partes[0]) * int(partes[1])

for i,f in enumerate(filtros):

	for v in versiones[i]:
		#print str(f),str(v)

		for s in sizes:

			caso = "Filtro: " + str(f) +  " Version: " + str(v) 
			for x in data:

				if x.find(caso) == 0 and x.find(s) > 0:
					anchoXalto = x.split("lena32.")[1].split(".bmp")[0]
					print anchoXalto, ",", pixels(anchoXalto), ",", f, ",", str(v).replace(","," "), ",", x.split("Tiempos: (")[1].split(",")[0]
					#print line, line[:-1].split("Tiempos: (")[1].split(", ")[0]