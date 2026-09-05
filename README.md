# Adaptive Frequency Hopping

**Risk-aware adaptive frequency hopping with multi-armed bandits and online learning.**

This repository contains the research implementation of an adaptive frequency-hopping framework for communication systems operating under uncertain and potentially adversarial interference.

The project studies how a transmitter can adaptively select communication channels while balancing **communication utility**, **exploration**, and **exposure to predictive or adaptive jamming**.

---

## Overview

Adaptive frequency hopping can be formulated as a sequential decision-making problem.

At each time step, the transmitter selects a channel, observes communication feedback, and updates its channel-selection strategy. The challenge becomes more difficult when channel quality is nonstationary or when the interference process reacts to predictable transmission behavior.

This project develops a risk-aware online-learning framework based on ideas from:

- Multi-Armed Bandits
- Online Learning
- Adaptive Frequency Hopping
- Wireless Communications
- Adversarial Decision Making
- Risk-Aware Model Selection

The objective is not only to maximize communication performance, but also to control the predictability and exposure associated with channel-selection decisions.

---

## Method at a Glance

```text
Channel observations / feedback
            │
            ▼
     Online learner
            │
            ├───────────────┐
            │               │
            ▼               ▼
   Utility estimation    Risk estimation
            │               │
            └───────┬───────┘
                    ▼
            Policy adaptation
                    │
                    ▼
          Frequency selection
                    │
                    ▼
        Communication outcome
                    │
                    └────────── feedback咕咕嘎嘎