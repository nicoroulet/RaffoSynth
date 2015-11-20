import matplotlib.pyplot as plt
from sys import stdin

# recibe por stdin los valores de cpp y asm (<run cpp> <osc cpp> <eq cpp> <run asm> <osc asm> <eq asm>)
# posible uso: (tail -n 1 input_cpp | awk '{printf $2 " " $3 " " $4 " "}' && tail -n 1 input_asm | awk '{print $2 " " $3 " " $4}') | python barplot.py


vals = map(float, stdin.readline().strip().split())
labels = ["run cpp", "osc cpp", "eq cpp", "run asm", "osc asm", "eq asm"]
xs = [1,2,4,5,7,8]
colors = ['r', 'r', 'b', 'b', 'g', 'g']

reorder = [0, 3, 1, 4, 2, 5]

vals = [vals[i] for i in reorder]
labels = [labels[i] for i in reorder]

plt.bar(xs, vals, color=colors)
plt.xticks([x+0.4 for x in xs], labels)
plt.show()