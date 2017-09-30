import ReadOutput
from libtest import *
from subprocess import *


def genExtra(name):
	name = name.split(".")
	if len(name) != 3 or name[1].find("x") < 0:
		return ["16", "16", "0", "0"]
	size = name[1].split("x")
	return size + ["0","0"]



extra = [
	["16", "16", "0", "0"],
	[""],
	["120"]
]

assure_dirs()
#imagenes = [ ["img/lena32.bmp"] ]
imagenes = archivos_tests()


bin = "./build/tp2"
times = ["-t", "100"]

#p = Popen([bin, times, filtros[0], version[0][0], imagenes[0], extra[0]], stdout=PIPE)
#recorro filtros


reporte = open(DATADIR + "/output.txt", "w")

for img in imagenes:
	imgpath = TESTIMGDIR + "/" + img

	for f in range(3):

		#recorro versiones de filtro
		for v in range(len(versiones[f])):

			#corro cada version
			extras = extra[f]
			if(f == 0): extras = genExtra(img)
			p = Popen([bin] + ["-o", OUTIMGS] + times + filtros[f] + ["-i"] + versiones[f][v] + [imgpath] + extras, stdout=PIPE)
			data = p.stdout.readlines()

			parsed = ReadOutput.parse(data)
			ret = [ "Filtro:", filtros[f],  "Version:", versiones[f][v], "Img:", img, "Tiempos:", parsed[0] ]
			ret = " ".join([str(x) for x in ret])
			reporte.write(ret + "\n")
			detalle = open(DATADIR + "/detail-" + "".join(filtros[f]) + "".join(versiones[f][v]) + ".log","w")
			detalle.write(",".join([str(x) for x in parsed[1]]))
				
			print ret
