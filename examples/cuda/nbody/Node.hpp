#pragma once

#include <Point.hpp>

struct Node {
        Point pos; // DR: X, Y, Z location
        float mass;
        bool Leaf;
        char idx;
        Node *pred;
};

