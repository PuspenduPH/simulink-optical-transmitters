# 📡 Simulink Optical Component Simulations

> **Small-signal & large-signal Simulink models of optical transmitters** — LED, Fabry-Perot Laser diode, and Quantum-Well Laser diode — implemented as reusable masked subsystems with physics-based MATLAB initialization scripts.

---

## 🗂️ Table of Contents

- [📡 Simulink Optical Component Simulations](#-simulink-optical-component-simulations)
  - [🗂️ Table of Contents](#️-table-of-contents)
  - [🔭 Overview](#-overview)
  - [💡 Simulated Components](#-simulated-components)
    - [1. LED Diode](#1-led-diode)
    - [2. Fabry-Perot (FP) Laser Diode](#2-fabry-perot-fp-laser-diode)
    - [3. Quantum-Well (QW) Laser Diode](#3-quantum-well-qw-laser-diode)
  - [📁 Project Structure](#-project-structure)
  - [🚀 Getting Started](#-getting-started)
    - [Prerequisites](#prerequisites)
    - [Running a Simulation](#running-a-simulation)
  - [🏗️ Modeling Methodology](#️-modeling-methodology)
  - [📊 Simulation Results](#-simulation-results)
    - [LED — Optical Power Transient at 25 MHz](#led--optical-power-transient-at-25-mhz)
      - [Model Canvas](#model-canvas)
    - [FP Laser — Relaxation Oscillations at 500 MHz](#fp-laser--relaxation-oscillations-at-500-mhz)
      - [Model Canvas](#model-canvas-1)
      - [Scope Output](#scope-output)
    - [QW Laser — Turn-On Delay vs. Gain Clamping](#qw-laser--turn-on-delay-vs-gain-clamping)
      - [Model Canvas](#model-canvas-2)
      - [Scope Output — Test Cases](#scope-output--test-cases)
  - [📐 Key Parameters \& Equations](#-key-parameters--equations)
    - [Physical Constants Used](#physical-constants-used)
    - [Efficiency Definitions](#efficiency-definitions)
  - [📚 Documentation](#-documentation)
  - [📖 References](#-references)
    - [Primary Research Paper](#primary-research-paper)
    - [MathWorks Documentation](#mathworks-documentation)
  - [📝 License](#-license)

---

## 🔭 Overview

This project provides a structured collection of **MATLAB/Simulink models** for simulating the dynamic electro-optical response of semiconductor light sources used in fiber-optic communication links. Each component is implemented as a **masked Simulink subsystem** with:

- A user-friendly **dialog box** for entering physical device parameters
- A **MATLAB mask initialization script** (using the mandatory `classdef` boilerplate) that handles unit conversion and pre-computes static gains and transfer function coefficients at compile time
- A minimal internal **block diagram** containing only the blocks that must run at every simulation time step

The models directly implement the governing equations (transfer functions and rate equations) referenced from standard photonics literature, making them suitable for academic study, M.Tech lab assignments, and research verification.

---

## 💡 Simulated Components

### 1. LED Diode

| Property | Details |
|:---|:---|
| **Model file** | `LED/led_res.slx` |
| **Init script** | `LED/LEDcbV2.m` |
| **Documentation** | `LED.md` |
| **Approach** | Small-signal frequency-domain (1st-order low-pass) |

**Transfer Function:**

$$P_e(f) = H_T(f) \cdot I_d(f) = H_T(0) \cdot H_T^*(s) \cdot I_d(s)$$

$$H_T(0) = \frac{hc}{\lambda q}\, \eta_{int}\, \eta_{inj}\, \eta_{ext}, \qquad H_T^*(s) = \frac{1}{\tau_r s + 1}$$

The LED response is governed by the carrier recombination lifetime $\tau_r$ and models the smooth exponential rise and decay of optical power under a unipolar 25 MHz drive pulse (0 – 50 mA). The solver max step size is constrained to 0.1 ns to faithfully render the transient.

---

### 2. Fabry-Perot (FP) Laser Diode

| Property | Details |
|:---|:---|
| **Model file** | `FP Laser/laser_res.slx` |
| **Init script** | `FP Laser/laser_tf_init.m` |
| **Documentation** | `LASER.md` |
| **Approach** | Small-signal frequency-domain (2nd-order resonant) |

**Transfer Function:**

$$H_T(0) = \frac{hc}{\lambda q}\,\eta_{int}\,\eta_{ext}\left[\frac{I_d - I_{th}}{I_d}\right]$$

$$H_T^*(s) = \frac{f_0^2}{s^2 + \beta s + f_0^2}, \quad f_0^2 = \frac{I_0 - I_{th}}{\tau_{sp}\,\tau_{ph}\,I_{th}}, \quad \beta = \frac{I_0}{\tau_{sp}\,I_{th}}$$

The 2nd-order resonant pole captures the **relaxation oscillations** (ringing) produced when the laser is pulse-modulated at 500 MHz above threshold. A pre-biased drive current (1 mA bias + 2 mA pulse) keeps the device in the stimulated-emission regime at all times, ensuring zero turn-on delay. Solver step size is fixed at 1 ps to resolve the sub-nanosecond transients.

---

### 3. Quantum-Well (QW) Laser Diode

| Property | Details |
|:---|:---|
| **Model file** | `QW Laser/qw_laser_response.slx` |
| **Init script** | `QW Laser/rate_equations_init.m` |
| **Documentation** | `QW_LASER.md` |
| **Approach** | Large-signal time-domain (coupled rate equations) |

Unlike the small-signal models above, the QW Laser directly integrates the **coupled carrier-photon rate equations** at each time step:

$$\frac{dN}{dt} = \frac{I}{qV_{act}} - g_0(N - N_0)(1 - \epsilon S)S - \frac{N}{\tau_n} + \frac{N_e}{\tau_n}$$

$$\frac{dS}{dt} = \Gamma g_0(N - N_0)(1 - \epsilon S)S + \frac{\Gamma\beta N}{\tau_n} - \frac{S}{\tau_p}$$

$$P_f(t) = S(t) \cdot \frac{V_{act}\,\eta\,hc}{\Gamma\,\tau_p\,\lambda_0}$$

A **multi-port test harness** (Multiport Switch) allows seamless switching between two test cases without modifying the block diagram:

| Test Case | Drive Signal | Observed Physics |
|:---|:---|:---|
| **Case 1** | 0 mA → 10 mA (unbiased) | Turn-on delay (~0.4 ns) + severe relaxation oscillations |
| **Case 2** | 9.5 mA bias + 1.0 mA pulse | Gain clamping — zero turn-on delay, instantaneous $P_f$ response |

The solver runs at **fixed-step ode4 (Runge-Kutta 4th order)** with a 100 fs step size to maintain numerical stability through the stiff photon-density bursts.

---

## 📁 Project Structure

```
Simulink Optical Simulations Project/
│
├── FP Laser/
│   ├── laser_res.slx                  # Simulink model — FP Laser diode
│   ├── laser_tf_init.m                # Mask initialization script
│   └── ARTIFACTS/
│       ├── Model Snapshots/
│       │   ├── main model.png         # Top-level model canvas screenshot
│       │   └── subsystem.png          # Internal subsystem block diagram
│       └── Plots/
│           ├── laser_res_1x1.png      # Scope output — single panel
│           └── laser_res_2x1.png      # Scope output — dual panel
│
├── LED/
│   ├── led_res.slx                    # Simulink model — LED diode
│   ├── LEDcbV2.m                      # Mask initialization script
│   └── ARTIFACTS/
│       ├── Model Snapshots/
│       │   ├── main model.png
│       │   └── subsystem.png
│       └── Plots/
│           └── (scope plots)
│
├── QW Laser/
│   ├── qw_laser_response.slx          # Simulink model — QW Laser (rate equations)
│   ├── rate_equations_init.m          # Mask initialization script
│   └── ARTIFACTS/
│       ├── Model Snapshots/
│       │   ├── main model.png
│       │   └── sub_rate_eq.png        # Rate equations subsystem internals
│       └── Plots/
│           ├── test_case1.png         # Unbiased pulse — turn-on delay
│           └── test_case2.png         # Pre-biased — gain clamping
│
├── LASER.md                           # FP Laser — theory, model, and solver guide
├── LED.md                             # LED — theory, model, and solver guide
├── QW_LASER.md   # QW Laser — full documentation
├── Simulink_Subsystem_User_Guide.md   # End-to-end guide for building masked subsystems
└── Simulink toolbox for simulation and analysis of optical fiber links.pdf  # Base reference paper
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|:---|:---|
| MATLAB | R2021a or later (recommended R2023b+) |
| Simulink | Included with MATLAB |
| Control System Toolbox | Required for Transfer Fcn blocks |

No additional MATLAB toolboxes or third-party libraries are required.

### Running a Simulation

1. **Clone or download** this repository to your local machine.

2. **Open MATLAB** and set the working directory to the component folder of interest, e.g.:
   ```matlab
   cd('path/to/Simulink Optical Simulations Project/FP Laser')
   ```

3. **Open the Simulink model:**
   ```matlab
   open_system('laser_res.slx')   % FP Laser
   % or
   open_system('led_res.slx')     % LED
   % or
   open_system('qw_laser_response.slx')  % QW Laser
   ```

4. **Enter device parameters** — double-click the masked subsystem block on the canvas to open the parameter dialog. Default values matching the reference paper are pre-loaded.

5. **Run the simulation** — click **Run** (▶) in the Simulink toolstrip or press `Ctrl+T`.

6. **View results** — double-click the **Scope** block to inspect the optical power output, carrier density, and photon density waveforms.

> **Note for the QW Laser:** Use the **Test Case Selector** masked subsystem to switch between unbiased (Case 1) and pre-biased (Case 2) drive configurations without editing any block internals.

---

## 🏗️ Modeling Methodology

All subsystems follow a **consistent architecture** documented in `Simulink_Subsystem_User_Guide.md`:

```
┌─────────────────────────────────────────────────────┐
│                  Masked Subsystem                   │
│                                                     │
│  ┌─────────────┐  Runs ONCE at compile time:        │
│  │  Mask Dialog │──► classdef MaskInitialization()  │
│  │  (user input)│    - ws.get()  all parameters     │
│  └─────────────┘    - Unit conversion to SI         │
│                      - Compute HT_0, f0_sq, β, …    │
│                      - ws.set()  back to workspace  │
│                                                     │
│  Internal block diagram (runs EVERY time step):     │
│  [Inport] → [Gain: HT_0] → [Transfer Fcn / ODE]    │
│                                        → [Outport]  │
└─────────────────────────────────────────────────────┘
```

**Why this pattern?**

| Concern | Solution |
|:---|:---|
| Static calculations waste simulation time | Moved to initialization script (runs once) |
| Mixed units (nm, mA, ps) are error-prone | Centralized SI conversion in the init script |
| Deep blocks hard to configure | Mask dialog exposes all parameters cleanly |
| Model reuse across projects | Self-contained `.slx` file with embedded mask |

---

## 📊 Simulation Results

### LED — Optical Power Transient at 25 MHz

The 1st-order low-pass response produces the characteristic smooth exponential rise and decay of optical power under a 50 mA unipolar square wave drive.

#### Model Canvas

| Top-Level Model | Subsystem Internals |
|:---:|:---:|
| ![LED main model](LED/ARTIFACTS/Model%20Snapshots/main%20model.png) | ![LED subsystem](LED/ARTIFACTS/Model%20Snapshots/subsystem.png) |

#### Scope Output

![LED scope output](LED/ARTIFACTS/Plots/scope_led.png)

---

### FP Laser — Relaxation Oscillations at 500 MHz

The 2nd-order resonant transfer function reproduces the characteristic ringing that occurs at each rising edge of the modulated current. The oscillations decay exponentially as the photon and carrier populations re-equilibrate.

#### Model Canvas

| Top-Level Model | Subsystem Internals |
|:---:|:---:|
| ![FP Laser main model](FP%20Laser/ARTIFACTS/Model%20Snapshots/main%20model.png) | ![FP Laser subsystem](FP%20Laser/ARTIFACTS/Model%20Snapshots/subsystem.png) |

#### Scope Output

| Single-Panel (Power vs. Time) | Dual-Panel (Current + Power) |
|:---:|:---:|
| ![FP Laser scope 1x1](FP%20Laser/ARTIFACTS/Plots/laser_res_1x1.png) | ![FP Laser scope 2x1](FP%20Laser/ARTIFACTS/Plots/laser_res_2x1.png) |

---

### QW Laser — Turn-On Delay vs. Gain Clamping

| | Test Case 1 (Unbiased) | Test Case 2 (Pre-biased) |
|:---|:---|:---|
| **Drive** | 0 → 10 mA step | 9.5 mA + 1 mA pulse |
| **Turn-on delay** | ~0.4 ns | None |
| **$N(t)$ behavior** | Rises, overshoots $N_0$, rings | Clamped flat at threshold |
| **$P_f(t)$ behavior** | Delayed burst + oscillations | Clean, instantaneous modulation |

#### Model Canvas

| Top-Level Model | Rate Equations Subsystem |
|:---:|:---:|
| ![QW Laser main model](QW%20Laser/ARTIFACTS/Model%20Snapshots/main%20model.png) | ![QW Laser rate eq subsystem](QW%20Laser/ARTIFACTS/Model%20Snapshots/sub_rate_eq.png) |

#### Scope Output — Test Cases

| Case 1: Unbiased (Turn-On Delay + Ringing) | Case 2: Pre-biased (Gain Clamping) |
|:---:|:---:|
| ![QW Laser Case 1](QW%20Laser/ARTIFACTS/Plots/test_case1.png) | ![QW Laser Case 2](QW%20Laser/ARTIFACTS/Plots/test_case2.png) |

---

## 📐 Key Parameters & Equations

### Physical Constants Used

| Symbol | Value | Description |
|:---|:---|:---|
| $h$ | $6.626 \times 10^{-34}$ J·s | Planck's constant |
| $c$ | $2.9979 \times 10^8$ m/s | Speed of light |
| $q$ | $1.602 \times 10^{-19}$ C | Elementary charge |

### Efficiency Definitions

$$\eta_{int} = \frac{\tau_{nr}}{\tau_{nr} + \tau_r} \quad \text{(Internal quantum efficiency)}$$

$$\eta_{ext} = \frac{\ln(1/R_1)}{\gamma L + \ln(1/R_1)} \quad \text{(External quantum efficiency — LASER)}$$

$$\eta_{ext} = \left[1 - \left(\frac{n_s - n_a}{n_s + n_a}\right)^2\right]\left[1 - \cos\!\left(\frac{n_a}{n_s}\right)\right] \quad \text{(External quantum efficiency — LED)}$$

---

## 📚 Documentation

| File | Contents |
|:---|:---|
| [`LED.md`](LED.md) | LED theory, transfer function derivation, mask parameters, solver settings |
| [`LASER.md`](LASER.md) | FP Laser theory, small-signal model, initialization code walkthrough |
| [`QW_LASER.md`](QW_LASER.md) | QW Laser rate equations, test harness design, gain-clamping analysis |
| [`Simulink_Subsystem_User_Guide.md`](Simulink_Subsystem_User_Guide.md) | End-to-end step-by-step guide for building masked subsystems from scratch |

---

## 📖 References

### Primary Research Paper

All physical parameters, governing equations, and modeling methodology are derived from:

> C. F. de Melo, C. A. Lima, L. D. S. de Alcantara, R. O. dos Santos, and J. C. W. A. Costa, **"A Simulink™ toolbox for simulation and analysis of optical fiber links,"** in *Education and Training in Optics and Photonics*, Technical Digest Series (Optica Publishing Group, 1999), paper NTE240.

The full paper is included in the project root as [`Simulink toolbox for simulation and analysis of optical fiber links.pdf`](Simulink%20toolbox%20for%20simulation%20and%20analysis%20of%20optical%20fiber%20links.pdf).

The rate equations for the QW Laser (carrier density $N(t)$, photon density $S(t)$, and optical power $P_f(t)$) follow the standard coupled-differential formulation used in semiconductor laser physics literature.

### MathWorks Documentation

| Topic | Link |
|:---|:---|
| Getting Started with Simulink | [Simulink — Getting Started](https://in.mathworks.com/help/simulink/getting-started-with-simulink.html) |
| Subsystem block reference | [Simulink — Subsystem Block](https://in.mathworks.com/help/simulink/slref/subsystem.html) |
| Mask Initialization & Callback Code | [Simulink — Initialize Mask](https://in.mathworks.com/help/simulink/ug/initialize-mask.html) |

---

## 📝 License

This project is shared for academic and educational purposes. Feel free to reference, adapt, or build upon the models — attribution appreciated.

---

*Made with ❤️ and MATLAB R2026a*
