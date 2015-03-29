#pragma once
#include <ctime>

class Tiempo {
public:
  void start() { start_pt = clock(); }
  void stop() { time += clock() - start_pt; }
  clock_t time;
private:
  clock_t start_pt;
};