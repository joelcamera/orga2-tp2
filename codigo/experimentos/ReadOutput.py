import sys

def promedio(seq):
	return sum(seq)/len(seq)

def filtrar(seq):
	prom = promedio(seq)
	prom *= 1.15
	ret = []
	for x in seq:
		if x < prom:
			ret.append(x)
	return ret
	

def parse(data):
	experimento = data[0:4]
	casos = []
	for x in data:
		if x.find("ejecucion:") == 0:
			casos.append(int(x.split("\n")[0].split("ciclos: ")[1]))
	
	#print data
	return [( min(casos), promedio(casos), promedio(filtrar(casos))), casos ]





if __name__ == "__main__":
	if len(sys.argv) == 1: 
		print "Pasar file con logs"
		exit()

	f = open(sys.argv[1])
	data = f.readlines()
	print parse(data)