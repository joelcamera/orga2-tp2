import os
import subprocess
from os import listdir
from os.path import isfile, join

DATADIR = "./experimentos/data"
IMGDIR = "./img"
TESTIMGDIR = DATADIR + "/generadas"
OUTIMGS = DATADIR + "/procesadas"

TP2ALU = "./build/tp2"


filtros = [ ["cropflip"], ["sepia"], ["ldr"] ] 

versiones = [ 
    [ ["c"],            ["asm", "-j", "1"],   ["asm", "-j", "2"], ["asm", "-j", "3"] ],
    [ ["c"],            ["asm", "-j", "1"],   ["asm", "-j", "2"] ],
    [ ["c", "-j", "1"], ["c", "-j", "2"],     ["asm", "-j", "1"], ["asm", "-j", "2"], ["asm", "-j", "3"] ]
]


def make_dir(name):
    if not os.path.exists(name):
        os.mkdir(name)


def assure_dirs():
    make_dir(DATADIR)
    make_dir(TESTIMGDIR)
    make_dir(OUTIMGS)


def archivos_tests():
    return [f for f in listdir(TESTIMGDIR) if isfile(join(TESTIMGDIR, f))]


def getSizes():
    sizes = []
    for i in range(10):
        sizes.append( str(pow(2,i)*16) + "x16" )
    for i in range(10):
        sizes.append( "16x" + str(pow(2,i)*16) )
    for i in range(10):
        sizes.append( str(pow(2,i)*16) + "x" + str(pow(2,i)*16) )
    return sizes

