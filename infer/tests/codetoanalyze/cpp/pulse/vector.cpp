/*
 * Copyright (c) 2018-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
#include <iostream>
#include <vector>

void deref_vector_element_after_push_back_bad(std::vector<int>& vec) {
  int* elt = &vec[1];
  vec.push_back(42);
  std::cout << *elt << "\n";
}

void deref_local_vector_element_after_push_back_bad() {
  std::vector<int> vec = {0, 0};
  int* elt = &vec[1];
  vec.push_back(42);
  std::cout << *elt << "\n";
}

void two_push_back_ok(std::vector<int>& vec) {
  vec.push_back(32);
  vec.push_back(52);
}

void push_back_in_loop_ok(std::vector<int>& vec, std::vector<int>& vec_other) {
  for (const auto& i : vec_other) {
    vec.push_back(i);
  }
}

void FP_reserve_then_push_back_ok(std::vector<int>& vec) {
  vec.reserve(vec.size() + 1);
  int* elt = &vec[1];
  vec.push_back(42);
  std::cout << *elt << "\n";
}

void FP_reserve_then_push_back_loop_ok(std::vector<int>& vec,
                                    std::vector<int>& vec_other) {
  vec.reserve(vec.size() + vec_other.size());
  int* elt = &vec[1];
  for (const auto& i : vec_other) {
    vec.push_back(i);
  }
  std::cout << *elt << "\n";
}

void FP_init_fill_then_push_back_loop_ok(std::vector<int>& vec_other) {
  std::vector<int> vec(vec_other.size());
  int* elt = &vec[1];
  for (const auto& i : vec_other) {
    vec.push_back(i);
  }
  std::cout << *elt << "\n";
}
