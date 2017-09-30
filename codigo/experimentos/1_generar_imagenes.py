#!/usr/bin/env python

from libtest import *
import subprocess
import sys

# Este script crea las multiples imagenes de prueba a partir de unas
# pocas imagenes base.


IMAGENES=["lena32.bmp"]

assure_dirs()

sizes = getSizes()

#print sizes
#sizes=['16x16', '32x16', '64x16', '128x16', '128x16', '128x16', '128x16', '128x16',  ]


for filename in IMAGENES:
	print(filename)

	for size in sizes:
		sys.stdout.write("  " + size)
		name = filename.split('.')
		file_in  = IMGDIR + "/" + filename
		file_out = TESTIMGDIR + "/" + name[0] + "." + size + "." + name[1]
		resize = "convert -resize " + size + "! " + file_in + " " + file_out
		subprocess.call(resize, shell=True)

print("")
