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
                    └────────── feedback
```

---                    

## Research Questions

This project investigates questions including:

- How should frequency hopping be formulated as an online decision problem?
- How can communication reward and jamming exposure be modeled jointly?
- When should the learner favor exploitation versus exploration?
- How should a system adapt when the environment changes over time?
- Can risk-aware policy selection improve robustness without sacrificing excessive communication utility?
- What performance guarantees can be established relative to independent online-learning baselines?

--- 

## Main Components

# Online Channel Selection
Channel selection is modeled as a sequential learning problem in which the transmitter continuously updates its policy from observed communication feedback.

# Risk-Aware Adaptation
The learner incorporates an explicit notion of exposure or risk in addition to conventional reward optimization.
This allows the system to distinguish between actions that are immediately attractive and actions that may make future transmissions easier to predict or attack.

# Adaptive Model Selection
Multiple online-learning behaviors can be combined or selected according to the observed environment, allowing the system to adapt between different operating regimes.

# Multi-Step Evaluation
The framework is evaluated in terms of both communication performance and adversarial exposure over long sequential horizons.

--- 

## Baselines

The experimental study includes representative online-learning and bandit baselines such as:

UCB
Thompson Sampling
EXP3
contextual / risk-aware online-learning methods
adaptive frequency-hopping baselines

Exact configurations are provided with the reproducibility package.

--- 

## Repository Status

Paper companion repository under preparation.

The final repository will contain:

implementation of the proposed method;
baseline algorithms;
experiment configurations;
reproducibility scripts;
evaluation utilities;
paper figures and tables;
tests and environment information.

The public implementation will be frozen together with the corresponding manuscript.

--- 

## Reproducibility

The final release will provide scripts for reproducing the main experimental results and paper-facing figures.

Reproduction instructions will be documented in:

```text
docs/REPRODUCIBILITY.md

```
## Citation
Citation information will be added when the corresponding manuscript or preprint becomes publicly available.

## Author
# Chen Yanbo
Research interests: signal processing, wireless communications, machine learning, online learning, optimization, and intelligent systems.