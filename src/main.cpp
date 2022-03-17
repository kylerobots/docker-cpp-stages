#include <gtsam/nonlinear/NonlinearFactorGraph.h>

#include <iostream>

int main(int argc, char const *argv[]) {
  gtsam::NonlinearFactorGraph graph;
  std::cout << "Graph size = " << graph.size() << std::endl;
}
