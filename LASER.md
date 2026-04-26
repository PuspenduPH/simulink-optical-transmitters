
## 1. Theoretical Background and Mathematical Model of Fabry-Perot (FP) Laser Diode

The behavior of a multimode Fabry-Perot LASER diode can be analyzed using a small-signal frequency-domain model. When driven by an injected current $I_d(f)$, the output optical power $P_e(f)$ is determined by the total transfer function $H_T(f)$ of the LASER:

$$
P_e(f) = H_T(f) \cdot I_d(f)
$$

The transfer function $H_T(f)$ is decomposed into two parts: a static DC gain $H_T(0)$ and a dynamic frequency response $H_T^*(f)$.
$$H_T(f) = H_T(0) \cdot H_T^*(f)$$

### 1.1 DC Transfer Function: $H_T(0)$
The term $H_T(0)$ represents the static quantum efficiency of the light source (in Watts/Ampere) when operated above the threshold current ($I_d > I_{th}$). It is defined by the physical constants and the internal/external efficiencies:

$$
H_T(0) = \left( \frac{hc}{\lambda q} \right) \eta_{int} \eta_{ext} \left[ \frac{I_d - I_{th}}{I_d} \right]$$

Where:
* $\eta_{int} = \frac{\tau_{nr}}{\tau_{nr} + \tau_r}$ (Internal Quantum Efficiency)
* $\eta_{ext} = \frac{\ln(1/R_1)}{\gamma L + \ln(1/R_1)}$ (External Quantum Efficiency)

### 1.2 Dynamic Transfer Function: $H_T^*(s)$
The dynamic part, $H_T^*(f)$, governs the high-frequency transient response, notably the relaxation oscillations (ringing) that occur when the current changes rapidly. To implement this in Simulink, we transform the frequency-domain equation into the Laplace ($s$) domain ($s = j2\pi f$):

$$H_T^*(s) = \frac{f_0^2}{s^2 + \beta s + f_0^2}$$

The resonant frequency squared ($f_0^2$) and damping factor ($\beta$) depend heavily on the operating currents and carrier/photon lifetimes:
$$f_0^2 = \frac{I_0 - I_{th}}{\tau_{sp} \tau_{ph} I_{th}}$$
$$\beta = \frac{I_0}{\tau_{sp} I_{th}}$$

### 1.3 Physical Parameters
| Parameter | Symbol | Description | Unit |
| :--- | :--- | :--- | :--- |
| **Emission wavelength** | $\lambda$ | Operating wavelength of the laser | nm |
| **Recombination times** | $\tau_{nr}$, $\tau_r$ | Non-radiative and radiative lifetimes | ns |
| **Cavity dimension** | $L$ | Longitudinal length of the cavity | m |
| **Loss coefficient** | $\gamma$ | Internal optical losses | 1/m |
| **Mirror reflectancy** | $R_1$ | Reflectivity of the cavity facets | Dimensionless |
| **Lifetimes** | $\tau_{sp}$, $\tau_{ph}$ | Carrier and photon lifetimes | ns |
| **Operating Currents** | $I_d$, $I_{th}$, $I_0$ | Injection, threshold, and pre-biasing currents | mA |

---

## 2. Creation of the LASER Subsystem

To optimize simulation performance and keep the block diagram clean, static calculations (like $H_T(0)$) are performed in the background using a **Mask Initialization Script** rather than physical math blocks. 

### 2.1 Mask and Dialog Box
The subsystem is masked to provide a user-friendly dialog interface. The parameters listed in section 1.3 are entered into the Mask Editor under three logical groups:
1. **Cavity & Structural Parameters:** $\lambda$, $L$, $\gamma$, $R_1$
2. **Time Constants & Lifetimes:** $\tau_{nr}$, $\tau_r$, $\tau_{sp}$, $\tau_{ph}$
3. **Operating Currents:** $I_d$, $I_{th}$, $I_0$

### 2.2 Initialization Code (MATLAB Script)
The initialization script extracts user inputs from the mask, converts them to standard SI units (Amperes, meters, seconds), evaluates the complex efficiency equations, and pushes the resulting variables back to the workspace for the blocks to use.

```matlab
classdef laser_tf_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            % Access the mask workspace object
            ws = maskInitContext.MaskWorkspace;
            
            % 1. Retrieve parameters from dialog
            lambda = ws.get('lambda');  tau_nr = ws.get('tau_nr');
            tau_r  = ws.get('tau_r');   L      = ws.get('L');
            gamma  = ws.get('gamma');   R1     = ws.get('R1');
            I_d    = ws.get('I_d');     I_th   = ws.get('I_th');
            I_0    = ws.get('I_0');     tau_sp = ws.get('tau_sp');
            tau_ph = ws.get('tau_ph');
            
            % Universal Constants
            h = 6.62e-34;  c = 2.9979e8;  q = 1.602e-19;
            
            % 2. Convert to SI units
            lambda_m = lambda * 1e-9;
            I_d_A    = I_d * 1e-3;       I_0_A    = I_0 * 1e-3;
            I_th_A   = I_th * 1e-3;
            tau_sp_s = tau_sp * 1e-9;    tau_ph_s = tau_ph * 1e-9;
            
            % 3. Calculate Efficiencies
            eta_int = tau_nr / (tau_nr + tau_r);
            eta_ext = log(1/R1) / (gamma * L + log(1/R1));
            
            % 4. Calculate HT_0 (Static Gain)
            current_modifier = (I_d_A - I_th_A) / I_d_A;
            HT_0 = ((h * c) / (lambda_m * q)) * eta_int * eta_ext* current_modifier;
            
            % 5. Calculate Dynamic Variables
            f0_sq = (I_0_A - I_th_A) / (tau_sp_s * tau_ph_s * I_th_A);
            beta  = I_0_A / (tau_sp_s * I_th_A);
            
            % 6. Push calculated variables back to workspace
            ws.set('f0_sq', f0_sq);
            ws.set('beta', beta);
            ws.set('HT_0', HT_0);
        end
    end
end
```

---

## 3. Subsystem Block Architecture

Because the initialization script handles the heavy mathematical lifting, the visual architecture inside the LASER subsystem is vastly simplified. It consists of only four blocks in series:

1. **Inport (`I_in`):** Receives the continuous-time electrical current signal (in Amperes) from the main model.
2. **Gain Block (`HT_0`):** Acts as a scalar multiplier. It applies the steady-state quantum efficiency ($H_T(0)$) calculated by the script. It converts the input current into a baseline optical power (Watts).
3. **Transfer Fcn Block:** This standard Simulink block natively implements the continuous-time $s$-domain equation $H_T^*(s)$. 
   * **Numerator coefficients:** `[f0_sq]`
   * **Denominator coefficients:** `[1, beta, f0_sq]`
   This block applies the frequency-domain attenuation and phase shifts required to simulate the high-frequency ringing (relaxation oscillations).
4. **Outport (`P_out`):** Outputs the fully modulated optical power (in Watts).

### 3.1 Model Snapshots

| Top-Level Model | Subsystem Internals |
|:---:|:---:|
| ![FP Laser main model](FP%20Laser/ARTIFACTS/Model%20Snapshots/main%20model.png) | ![FP Laser subsystem](FP%20Laser/ARTIFACTS/Model%20Snapshots/subsystem.png) |

**Top-level model:** The main canvas shows the pre-biased current drive circuit (Constant bias + Pulse Generator feeding a Sum block) connected to the masked LASER subsystem block, which outputs to a Scope.

**Subsystem internals:** The internal canvas confirms the minimalist design — the drive current passes through the `HT_0` Gain block (static quantum efficiency) and then through the `Transfer Fcn` block (2nd-order resonant dynamics) before reaching the output port. The initialization script has already pre-computed all coefficients, so the diagram contains no extra math.

---

## 4. Main Model Configuration

To accurately test the LASER model and observe its relaxation oscillations, the main simulation environment must be carefully configured. 

### 4.1 Drive Current Configuration (The Inputs)
The small-signal frequency-domain model is only mathematically valid when the laser is operated strictly above its threshold current ($I_d > I_{th}$). Dropping the current to zero between pulses would require the large-signal non-linear rate equations to model the resulting turn-on delay.

To simulate a high-speed telecommunications pulse, we use a pre-biased square wave:
* **Constant Block (Pre-bias):** Set to `1e-3` (1 mA). This keeps the laser constantly "on" and idling in the stimulated emission region, ensuring zero turn-on delay.
* **Pulse Generator:** * Amplitude: `2e-3` (2 mA)
  * Period: `2e-9` (2 ns, equivalent to 500 MHz)
  * Pulse Width: `50%`
* **Sum Block:** Adds the bias and pulse together. The resulting current supplied to the laser oscillates between 1 mA and 3 mA.

### 4.2 Solver Details
Because the photon lifetime ($\tau_{ph}$) of the laser is extremely short (1 picosecond), the high-frequency ringing occurs on a sub-nanosecond scale. Simulink's solver must be tightly constrained to capture this dynamically unstable period.
* **Stop Time:** `10e-9` (10 nanoseconds, providing exactly 5 full cycles).
* **Solver Selection:** Fixed-step (`ode4` Runge-Kutta) or Variable-step with a strictly enforced maximum step size.
* **Max Step Size:** `1e-12` (1 picosecond). Without this constraint, the solver would step over the fast transients, resulting in jagged lines or numerical instability.

---

## 5. Simulation Results

| Single-Panel (Power vs. Time) | Dual-Panel (Current + Power) |
|:---:|:---:|
| ![FP Laser scope 1x1](FP%20Laser/ARTIFACTS/Plots/laser_res_1x1.png) | ![FP Laser scope 2x1](FP%20Laser/ARTIFACTS/Plots/laser_res_2x1.png) |

### Reading the Scope — What the Physics Tells Us

**Relaxation oscillations at every rising edge.** Each time the drive current steps from 1 mA to 3 mA, the laser's optical power $P_e(t)$ does not immediately settle to its new steady-state value. Instead it overshoots and rings with a characteristic decaying oscillation. This is the signature of the 2nd-order resonant pole in $H_T^*(s)$.

Physically, the ringing arises from a competition between two coupled populations:
1. The injected carriers ($N$) build up faster than the photon field ($S$) can respond.
2. The surplus carriers drive a burst of stimulated emission, suddenly depleting $N$.
3. With fewer carriers, gain drops below the loss threshold, so $S$ collapses.
4. Carriers then accumulate again, and the cycle repeats — each iteration damped by the cavity losses — until a new equilibrium is reached.

**The resonant frequency** $f_0 = \sqrt{(I_0 - I_{th})/(\tau_{sp}\,\tau_{ph}\,I_{th})}$ tells you how fast this pendulum swings: higher bias above threshold or shorter lifetimes push $f_0$ into the GHz range, ultimately setting the laser's modulation bandwidth ceiling.

**The dual-panel view** (right plot) shows the input drive current (top) alongside the optical power (bottom) on the same time axis, making it easy to correlate each current edge with its corresponding oscillatory burst and measure the settling time directly.



