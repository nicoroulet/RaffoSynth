import matplotlib.pyplot as plt      

asm=[map(int,x.strip().split()) for x in open("../data/asm_256.out").readlines()]
run_asm = [x[1] for x in asm]
osc_asm = [x[2] for x in asm]
eq_asm = [x[3] for x in asm]


cpp=[map(int,x.strip().split()) for x in open("../data/cpp_256.out").readlines()]
run_cpp = [x[1] for x in cpp]
osc_cpp = [x[2] for x in cpp]
eq_cpp = [x[3] for x in cpp]


oscasm=[map(int,x.strip().split()) for x in open("../data/oscasm_256.out").readlines()]
run_oscasm = [x[1] for x in oscasm]

plt.plot(run_asm, label="run asm", color='r', linewidth=1.5)
plt.plot(osc_asm, ':', label="osciladores asm", color='r', linewidth=2.5)
plt.plot(eq_asm, '--', label="eq asm", color='r', linewidth=1.5)
plt.plot(run_cpp, label="run cpp", color='b', linewidth=1.5)
plt.plot(osc_cpp, ':', label="osciladores cpp", color='b', linewidth=2.5)
plt.plot(eq_cpp, '--', label="eq cpp", color='b', linewidth=1.5)
plt.plot(run_oscasm, label="run oscasm", color='g', linewidth=1.5)

plt.legend(loc=2)
plt.xlabel("Llamadas de la funcion run")
plt.ylabel("Tiempo (clock ticks)")
plt.savefig("../plots/tiempos_asm_vs_cpp.png", bbox_inches='tight')
plt.show()