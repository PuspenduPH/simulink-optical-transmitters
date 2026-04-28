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

### 1.1 Physical Parameters
The model utilizes the following geometric and physical parameters:

| Parameter | Symbol | Description | Initial Unit | Value |
| :--- | :--- | :--- | :--- | :--- |
| **Lasing wavelength** | $\lambda_0$ | Operating wavelength | cm | $1.55 \times 10^{-4}$ |
| **Active region volume** | $V_{act}$ | Volume of the laser cavity | cm$^3$ | $1.5 \times 10^{-10}$ |
| **Optical confinement** | $\Gamma$ | Fraction of optical mode in active layer | - | $0.3$ |
| **Spontaneous emission** | $\beta$ | Coupling factor | - | $1.0 \times 10^{-4}$ |
| **Photon lifetime** | $\tau_p$ | Cavity photon decay time | ps | $2.0$ |
| **Gain coefficient** | $g_0$ | Differential gain | cm$^3$/s | $2.5 \times 10^{-6}$ |
| **Transparency density**| $N_0$ | Carrier density at transparency | 1/cm$^3$ | $1.0 \times 10^{18}$ |
| **Carrier lifetime** | $\tau_n$ | Electron-hole recombination time | ps | $1000$ |
| **Quantum efficiency** | $\eta$ | Differential quantum efficiency per facet| - | $0.4$ |
| **Equilibrium carriers** | $N_e$ | Equilibrium carrier density | 1/cm$^3$ | $0$ |

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

### 2.3 Model Snapshots: Test Harness Variants

| Unipolar Hot-Start (Pulse Generator) | Bipolar Cold-Start (Signal Generator) |
|:---:|:---:|
| ![QW Laser main model](QW%20Laser/ARTIFACTS/Model%20Snapshots/main_model_pg.png) | ![QW Laser signal generator model](QW%20Laser/ARTIFACTS/Model%20Snapshots/main_model_sg.png) |

**Top-level model:** The main canvas features a **Test Harness** utilizing a Multiport Switch. This allows seamless toggling between an unbiased (Case 1) or pre-biased (Case 2) current source. 
* **The Unipolar Variant (Left):** Uses a standard `Pulse Generator` which starts "High", immediately driving the laser at its maximum state from $t=0$.
* **The Bipolar Variant (Right):** Replaces the pulse generator with a `Signal Generator` outputting a $\pm 0.5$ mA square wave summed with a 10 mA DC bias. This starts the simulation "Low" at 9.5 mA, allowing observation of the laser's physical cold-start transient before high-speed modulation begins.

---

## 3. Main Model Configuration and Scope Architecture

Due to the highly stiff nature of these coupled differential equations, Simulink's solver must be rigidly defined. The solver is set to **Fixed-step (ode4 Runge-Kutta)** with a step size of `1e-13` (100 femtoseconds) to ensure numerical stability during rapid photon bursts.

### 3.1 Elimination of Cosmetic Gains and Muxing
In the original literature, Multiplexer (Mux) blocks and arbitrary scaling gains were used to artificially squash all variables onto a single Scope graph. We discarded the arbitrary gain blocks and Muxes. Instead, we routed the raw, unscaled signals directly into a **4-panel Scope layout**. This allows Simulink to dynamically auto-scale the Y-axis for each individual trace, acting as a pure physics engine and outputting exact, unadulterated SI values ($20 \times 10^{23}$ m$^{-3}$ for density, $50 \mu$W for power).

---

## 4. Multi-Test Harness and Physical Analysis

### 4.1 Test Case 1: Unbiased Pulse (0 mA to 10 mA)
To observe turn-on delay limits, the active circuit supplies a raw 10 mA pulse.
* **The Physics:** Grounded at 0 mA, the active region is depleted of electrons ($N \approx 0$). When the 10 mA pulse is injected, it takes time for electrons to fill the conduction band and reach the transparency threshold ($N_0$). 
* **The Result:** A significant **turn-on delay** ($\sim 0.4$ ns) occurs. Once $N(t)$ crosses the threshold, population inversion triggers a massive burst of stimulated emission, causing severe relaxation oscillations (ringing).

### 4.2 Test Case 2: Pre-Biased Modulation (Gain Clamping)
To simulate actual telecommunication conditions, the laser is pre-biased above threshold. We explored this using two distinct initialization profiles:

#### Variant A: The Ideal Hot-Start (Pulse Generator)
The source defaults to maximum current (10.5 mA) immediately at $t=0$, assuming the laser has been running infinitely long prior to the simulation. The carrier density is instantly clamped, and no initial transient is observed.

#### Variant B: The Realistic Cold-Start Transient (Signal Generator)
The bipolar signal generator begins its first cycle at its minimum value ($10 \text{ mA} - 0.5 \text{ mA} = 9.5 \text{ mA}$). This perfectly simulates turning on the DC power supply, waiting for the laser to warm up, and *then* transmitting data.

---

## 5. Simulation Results and Comparative Analysis

| Case 1: Unbiased — Delay + Ringing | Case 2A: Pre-biased — Ideal Hot-Start | Case 2B: Pre-biased — Realistic Cold-Start |
|:---:|:---:|:---:|
| ![Unbiased Case](QW%20Laser/ARTIFACTS/Plots/test_case1.png) | ![QW Laser test case 2](QW%20Laser/ARTIFACTS/Plots/test_case2_pg.png) | ![QW Laser signal generator scope](QW%20Laser/ARTIFACTS/Plots/test_case2_sg.png) |

### Reading the Scope — The Cold-Start Transient Timeline (Case 2B)

The introduction of the bipolar signal generator reveals a highly accurate physical timeline of a laser powering on from an empty state before it begins transmitting data:

* **0 to 10 ns (The Pumping Phase):** The simulation begins with 9.5 mA injected into an empty cavity. The optical power ($P_f$) and photon density ($S$) remain perfectly flat at zero. During this time, the electrons are slowly filling the conduction band, visible as a smooth exponential rise in the carrier density trace ($N(t)$).
* **10 to 15 ns (Turn-On Delay & Ringing):** Right around 12 ns, the carrier density successfully crosses the transparency threshold ($N_0$). The laser achieves population inversion and violently turns on. This generates the initial massive photon spike and subsequent relaxation oscillations. 
* **15 to 20 ns (Steady-State Biasing):** The ringing dampens completely. The optical power flattens into a steady, horizontal baseline. This flat line is the physical manifestation of the 9.5 mA DC Bias. The laser is now idling, fully saturated with carriers, and awaiting data.
* **20 ns Onward (High-Speed Modulation):** At exactly $t=20$ ns, the Signal Generator flips to its positive cycle, stepping the total current from 9.5 mA to 10.5 mA. Because the laser spent the first 20 ns warming up and clamping its carrier density at the threshold, this new 10.5 mA data pulse experiences **zero turn-on delay**. It instantly converts into optical power with a heavily damped, tight ringing profile, proving the necessity of pre-biasing in high-bandwidth links.
