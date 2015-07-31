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

// #pragma once
// #include <chrono>
// #include <fstream>

// using namespace std;
// using namespace std::chrono;
// class Tiempo {
// public:
//   void start() {
//     start_pt = system_clock::now();
//   }
//   void stop() {
//     time += duration<double>(system_clock::now() - start_pt).count();
//   }
//   double time;
//   // double time() const {
//   //   return duration<double>(end_pt - begin_pt).count();
//   // }
// private:
//   std::chrono::time_point<std::chrono::system_clock> start_pt;
// };

