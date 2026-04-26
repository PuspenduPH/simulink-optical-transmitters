# Simulink Modeling of a Quantum-Well (QW) LASER Diode

## 1. Theoretical Background and Mathematical Model

Unlike standard LEDs and linearized Fabry-Perot lasers which can be modeled using small-signal frequency-domain transfer functions, accurately capturing the large-signal transient dynamics of a Quantum-Well (QW) LASER requires solving its non-linear rate equations in the time domain. 

The Simulink model directly implements the coupled differential equations governing the carrier density $N(t)$ and photon density $S(t)$ within the active region of the laser cavity:

**Carrier Density Rate Equation:**
$$\frac{dN}{dt} = \frac{I}{qV_{act}} - g_0(N - N_0)(1 - \epsilon S)S - \frac{N}{\tau_n} + \frac{N_e}{\tau_n}$$

**Photon Density Rate Equation:**
$$\frac{dS}{dt} = \Gamma g_0(N - N_0)(1 - \epsilon S)S + \frac{\Gamma \beta N}{\tau_n} - \frac{S}{\tau_p}$$

**Optical Output Power:**
The emitted optical power $P_f(t)$ is directly proportional to the internal photon density $S(t)$:
$$P_f(t) = S(t) \left[ \frac{V_{act} \eta hc}{\Gamma \tau_p \lambda_0} \right]$$

### 1.1 Physical Parameters
The model utilizes the following geometric and physical parameters:

| Parameter | Symbol | Description | Initial Unit |
| :--- | :--- | :--- | :--- |
| **Lasing wavelength** | $\lambda_0$ | Operating wavelength | cm |
| **Active region volume** | $V_{act}$ | Volume of the laser cavity | cm$^3$ |
| **Optical confinement** | $\Gamma$ | Fraction of optical mode in active layer | Dimensionless |
| **Spontaneous emission** | $\beta$ | Coupling factor | Dimensionless |
| **Photon lifetime** | $\tau_p$ | Cavity photon decay time | ps |
| **Gain coefficient** | $g_0$ | Differential gain | cm$^3$/s |
| **Transparency density**| $N_0$ | Carrier density at transparency | 1/cm$^3$ |
| **Carrier lifetime** | $\tau_n$ | Electron-hole recombination time | ps |
| **Quantum efficiency** | $\eta$ | Differential quantum efficiency per facet| Dimensionless |
| **Equilibrium carriers** | $N_e$ | Equilibrium carrier density | 1/cm$^3$ |

---

## 2. Creation of the QW LASER Subsystem

The physical rate equations present a significant unit-scaling challenge, as typical values span from picoseconds ($10^{-12}$) to particle densities ($10^{23}$ in SI). To guarantee numerical stability, all inputs are converted to pure SI units (meters, seconds, kilograms) via a mask initialization script prior to block evaluation.

### 2.1 Mask Initialization Code (MATLAB Script)
This script acts as the physics engine's pre-processor. It fetches the mixed-unit parameters from the user dialog, converts them strictly to SI units, and calculates the fixed constant multipliers required by the Simulink integrators.

```matlab
classdef rate_equations_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            ws = maskInitContext.MaskWorkspace;
            
            % 1. Retrieve raw parameters from the dialog box
            lambda0_cm = ws.get('lambda0');  Vact_cm3 = ws.get('Vact');
            Gamma      = ws.get('Gamma');    beta     = ws.get('beta');
            tau_p_ps   = ws.get('tau_p');    g0_cm3_s = ws.get('g0');
            N0_cm3     = ws.get('N0');       tau_n_ps = ws.get('tau_n');
            eta        = ws.get('eta');      Ne_cm3   = ws.get('Ne');
            
            % 2. Convert ALL parameters to pure SI units (m, m^3, s, 1/m^3)
            lambda0 = lambda0_cm * 1e-2;     % cm to m
            Vact    = Vact_cm3 * 1e-6;       % cm^3 to m^3
            tau_p   = tau_p_ps * 1e-12;      % ps to s
            tau_n   = tau_n_ps * 1e-12;      % ps to s
            g0      = g0_cm3_s * 1e-6;       % cm^3/s to m^3/s
            N0      = N0_cm3 * 1e6;          % 1/cm^3 to 1/m^3
            Ne      = Ne_cm3 * 1e6;          % 1/cm^3 to 1/m^3
            
            % Constants
            q = 1.60218e-19; 
            h = 6.626e-34; 
            c = 2.9979e8;
            
            % Epsilon (Gain-saturation term, converted from cm^3 to m^3)
            eps_val_cm3 = 3.4e-23;
            eps_val = eps_val_cm3 * 1e-6;    
            
            % 3. Calculate the Gain multipliers in pure SI
            G_I       = 1 / (q * Vact);
            G_Ne      = Ne / tau_n;
            G_N_decay = 1 / tau_n;
            G_S_decay = 1 / tau_p;
            G_Pf      = (Vact * eta * h * c) / (Gamma * tau_p * lambda0);
            
            % 4. Push variables back to workspace
            ws.set('G_I', G_I);           ws.set('G_Ne', G_Ne);
            ws.set('G_N_decay', G_N_decay); ws.set('G_S_decay', G_S_decay);
            ws.set('G_Pf', G_Pf);         ws.set('eps_val', eps_val);
            ws.set('g0', g0);             ws.set('N0', N0);
        end
    end
end
```

### 2.2 Subsystem Block Architecture
Unlike the small-signal models, this subsystem employs closed-loop time-domain numerical integration. 
* Two `1/s` Integrator blocks are utilized to continually update $N(t)$ and $S(t)$.
* Mathematical operators (`Product`, `Sum`) explicitly recreate the polynomial $(N - N_0)(1 - \epsilon S)S$ gain-saturation mechanism at each time step.
* The output $P_f$ is extracted via a simple linear gain (`G_Pf`) applied to the photon density $S(t)$.

### 2.3 Model Snapshots

| Top-Level Model | Rate Equations Subsystem |
|:---:|:---:|
| ![QW Laser main model](QW%20Laser/ARTIFACTS/Model%20Snapshots/main%20model.png) | ![QW Laser rate eq subsystem](QW%20Laser/ARTIFACTS/Model%20Snapshots/sub_rate_eq.png) |

**Top-level model:** The main canvas shows the **Test Harness** at the left — the Multiport Switch and its masked selector block route either the unbiased (Case 1) or pre-biased (Case 2) current source into the QW LASER subsystem. The four Scope outputs ($N$, $S$, $I$, $P_f$) are visible on the right, each displayed on its own auto-scaled panel.

**Rate equations subsystem:** The internal canvas is substantially more complex than the LED or FP Laser subsystems. It contains two closed integrator loops (one for $N(t)$, one for $S(t)$) with feedback paths implementing the gain-saturation product $(N - N_0)(1-\epsilon S)S$, reflecting the fundamentally nonlinear, large-signal nature of these rate equations.

---

## 3. Main Model Configuration and Scope Architecture

Due to the highly stiff nature of these coupled differential equations, Simulink's solver must be rigidly defined. The solver is set to **Fixed-step (ode4 Runge-Kutta)** with a step size of `1e-13` (100 femtoseconds) to ensure numerical stability during rapid photon bursts.

### 3.1 Elimination of Cosmetic Gains and Muxing
In the original literature, the authors utilized Multiplexer (Mux) blocks and arbitrary scaling gains to artificially squash all variables onto a single Scope graph. This approach obscures the true physical values and is highly prone to calculation errors.

**Our Methodology:** We completely discarded the arbitrary gain blocks and Muxes. Instead, we routed the raw, unscaled signals directly into a **4-panel Scope layout**. This allows Simulink to dynamically auto-scale the Y-axis for each individual trace. Consequently, the simulation acts as a pure physics engine, outputting exact, unadulterated SI values ($20 \times 10^{23}$ m$^{-3}$ for density, $50 \mu$W for power) that can be directly verified against theoretical expectations.

---

## 4. Multi-Test Harness and Physical Analysis

To seamlessly evaluate the laser's dynamics under different operating regimes without modifying the block diagram, a **Test Harness** was constructed using a `Multiport Switch`. A masked subsystem selector feeds an integer logic signal (1 or 2) into the control port of the switch, dynamically toggling between two isolated input circuits.

### 4.1 Test Case 1: Unbiased Pulse (0 mA to 10 mA)
To observe turn-on delay limits, the active circuit supplies a raw 10 mA pulse.

* **The Physics:** When the laser is grounded at 0 mA, the active region is depleted of electrons ($N \approx 0$). When the 10 mA pulse is injected, the laser cannot emit light immediately. It takes time for the injected electrons to fill the conduction band and reach the critical transparency threshold ($N_0$). 
* **The Result:** The scope reveals a significant **turn-on delay** of approximately 0.4 ns. The carrier density $N(t)$ rises smoothly. Only after $N(t)$ crosses the threshold does population inversion occur, triggering a sudden, massive burst of stimulated emission. This rapid depletion and refilling of carriers causes severe relaxation oscillations (ringing).

### 4.2 Test Case 2: Pre-Biased High-Speed Modulation (9.5 mA to 10.5 mA)
To simulate actual telecommunication operating conditions, the active circuit supplies a 9.5 mA DC bias summed with a 1.0 mA modulation pulse.

* **The Physics (Gain Clamping):** At 9.5 mA, the laser is biased well above its lasing threshold. At this state, the carrier density $N(t)$ becomes "clamped." Because the cavity is already undergoing continuous stimulated emission, any additional electrons injected into the system do not increase the overall carrier population; instead, they immediately recombine with holes to produce photons. 
* **The Result:** The simulation perfectly validates this phenomenon. The carrier density $N(t)$ trace becomes a nearly flat, solid line clamped at its saturation limit. When the 1.0 mA modulation pulse hits, there is **zero turn-on delay**. The optical power $P_f$ reacts instantaneously, proving that pre-biasing is strictly required for high-bandwidth optical links.

---

## 5. Simulation Results

| Case 1: Unbiased — Turn-On Delay + Ringing | Case 2: Pre-biased — Gain Clamping |
|:---:|:---:|
| ![QW Laser test case 1](QW%20Laser/ARTIFACTS/Plots/test_case1.png) | ![QW Laser test case 2](QW%20Laser/ARTIFACTS/Plots/test_case2.png) |

### Reading the Scope — What the Physics Tells Us

#### Case 1 — Unbiased Pulse

**Turn-on delay (~0.4 ns).** After the current steps to 10 mA, the optical power $P_f$ remains at zero for approximately 0.4 ns. During this silent period, the injected carriers are filling the conduction band — $N(t)$ rises steadily but has not yet crossed the transparency threshold $N_0$ required for population inversion. No net stimulated emission occurs yet, so no light is produced.

**Sudden burst + relaxation oscillations.** Once $N(t) > N_0$, optical gain exceeds the cavity loss and a massive avalanche of stimulated emission begins. The photon density $S(t)$ spikes sharply, rapidly depleting the carrier reservoir. This carrier depletion then kills the gain, $S(t)$ collapses, carriers refill, gain recovers, and another burst occurs — producing the damped ringing visible in $P_f$. The oscillations decay exponentially as the system finds a new steady state dictated by the balance of injection and stimulated emission.

**A communication disaster.** The 0.4 ns delay plus the ringing tail mean that this drive scheme is completely unusable for reliable high-speed data transmission. A receiver cannot distinguish the delayed, distorted pulse from noise or from an adjacent symbol.

#### Case 2 — Pre-biased Pulse

**Flat carrier density (gain clamping).** The 9.5 mA bias keeps the laser deep in the lasing regime continuously. The $N(t)$ trace is nearly horizontal — any electron injected above the threshold immediately stimulates a photon and leaves the conduction band. The carrier population is "clamped" by the cavity gain-loss balance and cannot accumulate further.

**Instantaneous optical response.** When the 1.0 mA modulation pulse is superimposed, the additional injection converts directly and immediately into additional photons. The $P_f$ trace steps cleanly with essentially zero delay and zero ringing — the transfer from current to light is nearly linear and instantaneous at this operating point.

**Why this matters.** This comparison is the central design lesson of the experiment: pre-biasing eliminates the nonlinear turn-on delay because the device never leaves the lasing regime. In a real fiber-optic system, this means the LASER can faithfully follow a high-speed NRZ data stream, with each '1' bit producing a clean, immediate optical pulse.
