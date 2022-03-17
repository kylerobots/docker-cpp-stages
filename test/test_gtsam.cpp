#include <gtest/gtest.h>
#include <gtsam/nonlinear/NonlinearFactorGraph.h>

TEST(gtsam, gtsam) {
  gtsam::NonlinearFactorGraph graph;
  ASSERT_EQ(graph.size(), 0);
}