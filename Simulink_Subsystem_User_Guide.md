# Simulink Component Modelling — End-to-End User Guide

> **Scope:** This guide walks you through the complete workflow of building a reusable, masked Simulink component from scratch — from the motivation for using subsystems, all the way to wiring the finished block into your top-level model and tuning the solver. The LED and LASER diode models serve as concrete worked examples throughout.

---

## Table of Contents

1. [Why Use a Subsystem?](#1-why-use-a-subsystem)
2. [Step 1 — Define the Subsystem](#2-step-1--define-the-subsystem)
3. [Step 2 — Create a Mask](#3-step-2--create-a-mask)
4. [Step 3 — Insert Mask Parameters](#4-step-3--insert-mask-parameters)
5. [Step 4 — Write the Initialization Code](#5-step-4--write-the-initialization-code)
   - [The Fixed Boilerplate Structure](#51-the-fixed-boilerplate-structure)
   - [Inside the Boilerplate — What You Customize](#52-inside-the-boilerplate--what-you-customize)
6. [Step 5 — Build the Internal Block Diagram](#6-step-5--build-the-internal-block-diagram)
7. [Step 6 — Add the Subsystem to the Main Model](#7-step-6--add-the-subsystem-to-the-main-model)
8. [Step 7 — Configure Stimulus and Solver](#8-step-7--configure-stimulus-and-solver)
9. [Worked Example A — LED Subsystem](#9-worked-example-a--led-subsystem)
10. [Worked Example B — LASER Diode Subsystem](#10-worked-example-b--laser-diode-subsystem)
11. [Quick-Reference Checklist](#11-quick-reference-checklist)

---

## 1. Why Use a Subsystem?

When building a Simulink model of a physical device (e.g., an LED, a LASER diode, a fiber channel), a naïve approach places every individual math block — multipliers, adders, transfer functions — directly on the top-level canvas. This quickly becomes unmanageable:

| Problem with a flat model | Solution provided by a subsystem |
|:---|:---|
| Canvas becomes a spaghetti diagram | All internals are hidden behind a single, named block icon |
| Repeating the same calculation in multiple models | The subsystem file is reused; change once, update everywhere |
| Each parameter must be set by editing deep internal blocks | The **Mask** exposes a single clean dialog box for all inputs |
| Static pre-calculations (efficiencies, unit conversions) waste computation inside the diagram | The **Mask Initialization Script** runs once at compile time |
| Collaborators must understand every internal block | They only see the labeled ports and the dialog box |

> **Core principle:** A subsystem groups related blocks into one reusable component. A *mask* then wraps that subsystem with a custom dialog box and a background initialization script, reducing the visual model to only the blocks that absolutely must run at every time step.

---

## 2. Step 1 — Define the Subsystem

### 2.1 What belongs inside a subsystem?

A subsystem should represent exactly one physical component or one well-defined mathematical stage (e.g., *optical transmitter*, *fiber channel*, *photodetector*). Ask yourself:

- Does this group of blocks always appear together?
- Can the group be characterized by a fixed set of physical parameters?
- Would the rest of the model benefit from seeing only ports (`In` / `Out`)?

If yes to all three — extract it into a subsystem.

### 2.2 Creating the subsystem file

**Method A — Empty subsystem (recommended for new components)**

1. In the Simulink toolstrip, go to **File → New → Subsystem**.  
   Alternatively: **Blank Model → drag-in a Subsystem block from the Ports & Subsystems library**.
2. Double-click the block to open its canvas.
3. Simulink automatically places one **Inport** (`In1`) and one **Outport** (`Out1`) to define the signal boundary.

**Method B — Convert existing blocks**

1. On the main canvas, drag a selection rectangle around the blocks you want to group.
2. Right-click the selection → **Create Subsystem from Selection**.
3. Simulink automatically creates the Inports and Outports at the boundary.

### 2.3 Name the ports descriptively

Inside the subsystem canvas:

- Double-click the **Inport** block → change the name to something physical, e.g., `I_in` (drive current in Amperes).
- Double-click the **Outport** block → e.g., `P_out` (optical power in Watts).

This makes the port labels appear on the block icon in the parent model.

---

## 3. Step 2 — Create a Mask

A **mask** is a layer placed on top of a subsystem that gives it:
- A custom **dialog box** (parameter prompts instead of raw block properties)
- A background **initialization script** (MATLAB code that runs before simulation)
- An optional custom **icon** and **description**

### 3.1 Opening the Mask Editor

With the subsystem block selected (or its canvas open):

**Option A (Toolstrip):** In the **Simulink** toolstrip, select the **Subsystem** tab → click **Edit Mask**.

**Option B (Right-click):** Right-click the subsystem block on the parent canvas → **Mask → Edit Mask...**.

**Option C (Keyboard shortcut):** `Ctrl+M` while the subsystem block is selected.

The **Mask Editor** window opens. It has four tabs:
- **Icon & Ports** — Custom drawing commands for the block icon
- **Parameters & Dialog** — Define the user input fields
- **Initialization** — MATLAB code that runs at model initialization
- **Documentation** — Help text and description

---

## 4. Step 3 — Insert Mask Parameters

Every physical quantity the user must supply is defined here as a **Parameter**.

### 4.1 Adding a parameter

1. In the **Mask Editor**, open the **Parameters & Dialog** tab.
2. Click the **+** (Add Parameter) button in the toolbar.
3. A new row appears in the dialog tree. For each parameter, fill in:

| Field | Purpose | Example |
|:---|:---|:---|
| **Name** | The MATLAB variable name used in the init script. Must be a valid identifier. | `lambda` |
| **Prompt** | The label the user sees in the dialog box | `Emission Wavelength (nm)` |
| **Type** | `edit` (text box), `checkbox`, `popup`, etc. | `edit` |
| **Evaluate** | ✅ Checked — Simulink evaluates the string as a MATLAB expression | Checked |
| **Tunable** | Whether the value can change during simulation | Typically unchecked |

> **Tip:** Keep the **Name** field identical to the symbol used in your mathematical model (e.g., `tau_r`, `R1`, `gamma`). This makes the initialization script self-documenting.

### 4.2 Organizing parameters into groups

For clarity, add **Group Box** separators between logically related parameters:

1. Click the small dropdown arrow on the **+** button → select **Group Box**.
2. Drag parameters into the group box in the dialog tree.
3. Give the group box a descriptive label, e.g., `Cavity & Structural Parameters`.

**Example grouping for a LASER diode:**

```
┌─ Cavity & Structural Parameters ─────────────────┐
│  Emission Wavelength (nm)     [lambda]            │
│  Cavity Length (m)            [L]                 │
│  Loss Coefficient (1/m)       [gamma]             │
│  Mirror Reflectivity          [R1]                │
├─ Time Constants & Lifetimes ──────────────────────┤
│  Non-radiative Lifetime (ns)  [tau_nr]            │
│  Radiative Lifetime (ns)      [tau_r]             │
│  Carrier Lifetime (ns)        [tau_sp]            │
│  Photon Lifetime (ns)         [tau_ph]            │
├─ Operating Currents ──────────────────────────────┤
│  Drive Current (mA)           [I_d]               │
│  Threshold Current (mA)       [I_th]              │
│  Pre-bias Current (mA)        [I_0]               │
└───────────────────────────────────────────────────┘
```

### 4.3 Saving the mask

Click **Apply** then **OK**. The subsystem block icon will now show the custom name.  
To verify: double-click the subsystem block in the parent model — you should see your custom dialog box, not the raw canvas.

---

## 5. Step 4 — Write the Initialization Code

This is the most critical step. The initialization code is a MATLAB script that Simulink runs **once** when the model starts (or whenever parameters change). Its job is to:

1. **Read** the user-supplied values from the mask dialog
2. **Convert units** to SI if necessary
3. **Calculate** all derived quantities (efficiencies, gain, filter coefficients)
4. **Write** the computed results back to the mask workspace so blocks inside the subsystem can use them

### 5.1 The Fixed Boilerplate Structure

> ⚠️ **There is a mandatory boilerplate that must be followed for all initialization scripts in this project.** The code must be wrapped in a `classdef` with a `Static` method named `MaskInitialization` that accepts `maskInitContext` as its single argument. Deviating from this structure will cause Simulink to fail silently or not execute the script at all.

```matlab
% ============================================================
%  MANDATORY BOILERPLATE — Do NOT change the class structure,
%  method signature, or workspace access pattern.
% ============================================================
classdef <ClassName>          % e.g., laser_tf_init / led_tf_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            % Access the mask workspace object — ALWAYS this first line
            ws = maskInitContext.MaskWorkspace;

            % ── SECTION 1: Retrieve parameters from dialog ───────────
            <param_name> = ws.get('<param_name>');
            % (one line per parameter defined in the Mask Editor)

            % ── SECTION 2: Define universal physical constants ────────
            h = 6.62e-34;   % Planck's constant (J·s)
            c = 2.9979e8;   % Speed of light (m/s)
            q = 1.602e-19;  % Elementary charge (C)

            % ── SECTION 3: Convert units to SI ───────────────────────
            % (only if the dialog accepts non-SI inputs, e.g., nm, mA, ns)

            % ── SECTION 4: Compute derived quantities ─────────────────
            % (efficiencies, gains, transfer function coefficients, etc.)

            % ── SECTION 5: Push results back to the mask workspace ────
            ws.set('<result_variable>', <result_variable>);
            % (one line per variable that the internal blocks will reference)
        end
    end
end
```

**Why a `classdef`?** Simulink's mask initialization engine requires the initialization code to be a proper MATLAB class with a static method. This is not standard MATLAB script syntax — it's a deliberate Simulink convention that:
- Keeps the initialization code isolated from the base workspace
- Allows Simulink to call the code safely during model compilation
- Prevents naming conflicts between multiple masked subsystems

### 5.2 Inside the Boilerplate — What You Customize

#### Section 1 — Retrieving Parameters

Each parameter you defined in the Mask Editor must be retrieved using `ws.get()`. The argument **must exactly match** the `Name` field you set in the Parameters tab:

```matlab
lambda  = ws.get('lambda');   % Must match the Name field in the mask
tau_r   = ws.get('tau_r');
I_th    = ws.get('I_th');
```

#### Section 2 — Universal Constants

Always define the three fundamental constants in this section. They are used in the photon energy–quantum efficiency formula $E_{photon} = hc/\lambda q$:

```matlab
h = 6.62e-34;   % Planck's constant
c = 2.9979e8;   % Speed of light in vacuum
q = 1.602e-19;  % Elementary charge
```

#### Section 3 — Unit Conversion

If the mask dialog accepts values in practical units (nm, mA, ns) for user convenience, convert them to SI here **before** any calculation:

```matlab
% Converting from practical to SI units
lambda_m  = lambda  * 1e-9;  % nm  → m
I_d_A     = I_d     * 1e-3;  % mA  → A
tau_sp_s  = tau_sp  * 1e-9;  % ns  → s
```

> **Note:** If the mask already prompts in pure SI units (as in the LED example where `lambda` is entered in metres), this section can be omitted — but the section header should remain as a comment placeholder.

#### Section 4 — Computing Derived Quantities

This is model-specific. Compute whatever intermediate and final variables are needed:

```matlab
% Efficiencies
eta_int = tau_nr / (tau_nr + tau_r);
eta_ext = log(1/R1) / (gamma * L + log(1/R1));

% DC static gain
HT_0 = ((h * c) / (lambda_m * q)) * eta_int * eta_ext * ((I_d_A - I_th_A) / I_d_A);

% Transfer function coefficients
f0_sq = (I_0_A - I_th_A) / (tau_sp_s * tau_ph_s * I_th_A);
beta  = I_0_A / (tau_sp_s * I_th_A);
```

#### Section 5 — Writing Back to the Workspace

Every variable that a block inside the subsystem references by name must be explicitly pushed back:

```matlab
ws.set('HT_0',  HT_0);
ws.set('f0_sq', f0_sq);
ws.set('beta',  beta);
```

> ⚠️ **Critical:** Variables computed in the initialization script do **not** automatically appear in the mask workspace for blocks to use. You must call `ws.set()` for each one. Forgetting this is the single most common bug — the block diagram will error with "undefined variable" even though the script ran correctly.

---

## 6. Step 5 — Build the Internal Block Diagram

Now that the mask is configured and the initialization script will supply the computed variables, build the actual signal-processing network inside the subsystem's canvas.

### 6.1 Design principle

**Keep the diagram minimal.** The initialization script has already handled every static calculation. The blocks left in the diagram should only represent operations that must be evaluated at every simulation time step, i.e.:

- Multiplication by a computed gain constant → **Gain block**
- Dynamic filtering / frequency response → **Transfer Fcn block**
- Signal routing → **Sum block, Mux/Demux**

### 6.2 Typical signal chain

For a transfer-function-based component, the canonical chain is:

```
[Inport] → [Gain: HT_0] → [Transfer Fcn: H*(s)] → [Outport]
```

This maps to two blocks plus the ports — the entire model of an LED or LASER diode reduces to this chain.

### 6.3 Configuring the Gain block

1. Drag a **Gain** block from the **Math Operations** library onto the subsystem canvas.
2. Double-click it → set the **Gain** field to the variable name computed by the init script, e.g., `HT_0`.
3. Simulink will look for `HT_0` in the mask workspace at simulation start.

### 6.4 Configuring the Transfer Fcn block

1. Drag a **Transfer Fcn** block from the **Continuous** library.
2. Double-click it → set:
   - **Numerator coefficients:** A MATLAB vector expression, e.g., `[f0_sq]`
   - **Denominator coefficients:** e.g., `[1, beta, f0_sq]`
3. The variables `f0_sq` and `beta` are resolved from the mask workspace at simulation start.

> **Coefficient ordering:** Simulink expects highest-power first. For $H^*(s) = \frac{f_0^2}{s^2 + \beta s + f_0^2}$, the denominator is `[1, beta, f0_sq]` — corresponding to $1 \cdot s^2 + \beta \cdot s^1 + f_0^2 \cdot s^0$.

### 6.5 Wiring the blocks

- Hover over an output port until you see the crosshair cursor, then click-drag to the input port of the next block.
- Alternatively: click the source block, `Ctrl+click` the destination block — Simulink auto-routes the wire.
- Name each signal line by double-clicking it (e.g., label the line between Gain and Transfer Fcn `P_base`).

---

## 7. Step 6 — Add the Subsystem to the Main Model

### 7.1 Adding by drag-and-drop (from file)

If the subsystem was saved as a standalone `.slx` file:

1. In the Simulink Library Browser or MATLAB file browser, locate the subsystem `.slx` file.
2. Drag it directly from the file browser onto the main model canvas.
3. Simulink creates a **Model Reference** block linked to the file.

### 7.2 Adding via copy-paste

If the subsystem is embedded in another model:

1. Open the source model, find the subsystem block.
2. `Ctrl+C` → switch to the target model canvas → `Ctrl+V`.
3. The complete subsystem (including its mask) is pasted.

### 7.3 Adding from the Library Browser

If the subsystem has been saved in a custom library:

1. **Simulink Toolstrip → Library Browser** (or `Ctrl+Shift+L`).
2. Navigate to your custom library.
3. Drag the block onto the canvas.

### 7.4 Connecting the subsystem

1. The subsystem block shows its named ports (`I_in`, `P_out`, etc.) as small arrows on the sides.
2. Draw signal lines from the source blocks (e.g., a Pulse Generator + Sum) to the input port.
3. Draw signal lines from the output port to the sink blocks (e.g., a Scope).

### 7.5 Double-click to enter parameters

Double-click the subsystem block on the main canvas — the custom mask dialog box appears. Fill in all the physical parameters and click **OK**. Simulink will call the initialization script and populate the mask workspace before the simulation starts.

---

## 8. Step 7 — Configure Stimulus and Solver

### 8.1 Stimulus (drive current source)

The specific stimulus depends on the physical operating requirements of the device:

**For a LASER diode (pre-biased above threshold):**

The small-signal model is only valid when $I_d > I_{th}$. A square wave swinging to zero would violate this. Use a **pre-biased pulse**:

```
[Constant: I_bias (e.g., 1e-3 A)] ──┐
                                      ├── [Sum] ──→ [LASER subsystem]
[Pulse Generator: ΔI (e.g., 2e-3 A)] ┘
```

The resulting current oscillates between `I_bias` and `I_bias + ΔI` — always above threshold.

**For an LED (unipolar pulse):**

LEDs are diodes and require unipolar (non-negative) currents. A standard Simulink Pulse Generator outputting from 0 A to peak amplitude is sufficient.

### 8.2 Solver configuration

**Open:** **Modeling** tab → **Model Settings** (or `Ctrl+E`).

The solver must be configured tightly enough to capture the fastest dynamics in the model. The critical setting is **Max step size**:

| Device | Critical time constant | Recommended max step size |
|:---|:---|:---|
| **LED** | Radiative lifetime $\tau_r$ (ns range) | `1e-10` s (0.1 ns) |
| **LASER diode** | Photon lifetime $\tau_{ph}$ (ps range) | `1e-12` s (1 ps) |

**Recommended solver settings:**

```
Simulation stop time:  [10x the longest period of interest, e.g., 10e-9]
Type:                  Fixed-step  OR  Variable-step
Solver:                ode4 (Runge-Kutta 4th order) for fixed-step
                       ode45 for variable-step
Max step size:         [As determined by the table above]
```

> **Why does max step size matter?** If the step size is too large, the solver skips over fast transients (e.g., relaxation oscillations in a LASER), producing jagged plots or missing the peak ringing entirely. Always set it to at least 10× smaller than the fastest time constant.

---

## 9. Worked Example A — LED Subsystem

### 9.1 Mathematical model

The LED output power is modeled as:
$$P_e(f) = H_T(f) \cdot I_d(f) = H_T(0) \cdot H_T^*(s) \cdot I_d(s)$$

Where the static gain and 1st-order low-pass response are:
$$H_T(0) = \frac{hc}{\lambda q} \eta_{int} \eta_{inj} \eta_{ext}, \quad H_T^*(s) = \frac{1}{\tau_r s + 1}$$

### 9.2 Mask parameters

| Prompt | Name | Unit |
|:---|:---|:---|
| Emission Wavelength | `lambda` | m (SI — no conversion needed) |
| Radiative Lifetime | `tau_r` | s (SI) |
| Non-radiative Lifetime | `tau_nr` | s (SI) |
| Injection Efficiency | `eta_inj` | — |
| Semiconductor refractive index | `n_s` | — |
| Ambient refractive index | `n_a` | — |

### 9.3 Initialization code

```matlab
classdef led_tf_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            % Access the mask workspace object
            ws = maskInitContext.MaskWorkspace;

            % 1. Retrieve parameters from the dialog box
            lambda  = ws.get('lambda');
            tau_r   = ws.get('tau_r');
            tau_nr  = ws.get('tau_nr');
            eta_inj = ws.get('eta_inj');
            n_s     = ws.get('n_s');
            n_a     = ws.get('n_a');

            % Universal Constants
            h = 6.62e-34;
            c = 2.9979e8;
            q = 1.602e-19;

            % 2. Calculate Efficiencies
            eta_int = tau_nr / (tau_nr + tau_r);
            eta_ext = (1 - ((n_s - n_a)/(n_s + n_a))^2) * (1 - cos(n_a/n_s));

            % 3. Calculate HT_0 (The DC Transfer Function)
            HT_0 = ((h * c) / (lambda * q)) * eta_int * eta_inj * eta_ext;

            % 4. Push the calculated variables back to the mask workspace
            ws.set('HT_0',  HT_0);
            ws.set('tau_r', tau_r);
        end
    end
end
```

### 9.4 Internal block diagram

```
[Inport: I_d] → [Gain: HT_0] → [Transfer Fcn: 1/(tau_r·s + 1)] → [Outport: P_f]
```

Transfer Fcn settings:
- **Numerator:** `[1]`
- **Denominator:** `[tau_r, 1]`

### 9.5 Main model configuration

| Setting | Value |
|:---|:---|
| Pulse amplitude | `0.05` (50 mA) |
| Pulse period | `40e-9` (40 ns, → 25 MHz) |
| Pulse width | `50%` |
| Output gain (mW display) | `1000` |
| Max step size | `1e-10` s |

---

## 10. Worked Example B — LASER Diode Subsystem

### 10.1 Mathematical model

The LASER output optical power is governed by a 2nd-order dynamic response due to relaxation oscillations:

$$H_T(f) = H_T(0) \cdot H_T^*(s)$$

Where:
$$H_T(0) = \frac{hc}{\lambda q} \eta_{int} \eta_{ext} \cdot \frac{I_d - I_{th}}{I_d}$$
$$H_T^*(s) = \frac{f_0^2}{s^2 + \beta s + f_0^2}, \quad f_0^2 = \frac{I_0 - I_{th}}{\tau_{sp} \tau_{ph} I_{th}}, \quad \beta = \frac{I_0}{\tau_{sp} I_{th}}$$

### 10.2 Mask parameters

Organized into three groups:

| Group | Prompt | Name | Dialog Unit |
|:---|:---|:---|:---|
| Cavity & Structural | Emission Wavelength | `lambda` | nm |
| Cavity & Structural | Cavity Length | `L` | m |
| Cavity & Structural | Loss Coefficient | `gamma` | 1/m |
| Cavity & Structural | Mirror Reflectivity | `R1` | — |
| Time Constants | Non-radiative Lifetime | `tau_nr` | ns |
| Time Constants | Radiative Lifetime | `tau_r` | ns |
| Time Constants | Carrier Lifetime | `tau_sp` | ns |
| Time Constants | Photon Lifetime | `tau_ph` | ns |
| Operating Currents | Drive Current | `I_d` | mA |
| Operating Currents | Threshold Current | `I_th` | mA |
| Operating Currents | Pre-bias Current | `I_0` | mA |

> Note: The LASER mask accepts `lambda` in **nm** and currents in **mA** for practical convenience. The initialization script handles all conversions to SI.

### 10.3 Initialization code

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
            I_d_A    = I_d  * 1e-3;    I_0_A  = I_0  * 1e-3;
            I_th_A   = I_th * 1e-3;
            tau_sp_s = tau_sp * 1e-9;  tau_ph_s = tau_ph * 1e-9;

            % 3. Calculate Efficiencies
            eta_int = tau_nr / (tau_nr + tau_r);
            eta_ext = log(1/R1) / (gamma * L + log(1/R1));

            % 4. Calculate HT_0 (Static Gain)
            current_modifier = (I_d_A - I_th_A) / I_d_A;
            HT_0 = ((h * c) / (lambda_m * q)) * eta_int * eta_ext * current_modifier;

            % 5. Calculate Dynamic Variables
            f0_sq = (I_0_A - I_th_A) / (tau_sp_s * tau_ph_s * I_th_A);
            beta  = I_0_A / (tau_sp_s * I_th_A);

            % 6. Push calculated variables back to workspace
            ws.set('f0_sq', f0_sq);
            ws.set('beta',  beta);
            ws.set('HT_0',  HT_0);
        end
    end
end
```

### 10.4 Internal block diagram

```
[Inport: I_in] → [Gain: HT_0] → [Transfer Fcn: f0_sq / (s² + β·s + f0_sq)] → [Outport: P_out]
```

Transfer Fcn settings:
- **Numerator:** `[f0_sq]`
- **Denominator:** `[1, beta, f0_sq]`

### 10.5 Main model configuration

**Drive current (pre-biased pulse):**

```
[Constant: 1e-3]  ──┐
                     ├── [Sum] ──→ [LASER]
[Pulse Generator]  ──┘
   Amplitude: 2e-3
   Period: 2e-9 (500 MHz)
   Width: 50%
```

**Solver settings:**

| Setting | Value | Reason |
|:---|:---|:---|
| Stop Time | `10e-9` s | 5 complete 500 MHz cycles |
| Solver | `ode4` (fixed-step) | Stable for stiff photon lifetime dynamics |
| Max Step Size | `1e-12` s (1 ps) | Photon lifetime is ~1 ps; must resolve it |

---

## 11. Quick-Reference Checklist

Use this checklist whenever you are building a new Simulink component:

```
SUBSYSTEM
  [ ] Created subsystem (New → Subsystem or group selection)
  [ ] Named Inports and Outports with physical meaning
  [ ] Saved subsystem file

MASK — PARAMETERS TAB
  [ ] Created a parameter entry for every physical input
  [ ] Name field matches the symbol used in the math model
  [ ] Prompt field uses human-readable label + units
  [ ] Parameters grouped into logical Group Boxes
  [ ] "Evaluate" checkbox ON for all numeric inputs

MASK — INITIALIZATION TAB
  [ ] Boilerplate classdef structure in place
  [ ] Class name is unique per subsystem (e.g., led_tf_init)
  [ ] First line inside method: ws = maskInitContext.MaskWorkspace;
  [ ] ws.get() for every parameter defined in the Parameters tab
  [ ] Universal constants defined (h, c, q)
  [ ] Unit conversions applied before calculations
  [ ] ws.set() for every variable referenced by internal blocks

INTERNAL BLOCK DIAGRAM
  [ ] Gain block value set to mask workspace variable (e.g., HT_0)
  [ ] Transfer Fcn numerator/denominator use mask workspace variables
  [ ] Signal lines named for readability
  [ ] Inport connects through chain to Outport

MAIN MODEL
  [ ] Subsystem block placed on main canvas
  [ ] Signal lines connected to its ports
  [ ] Mask dialog opened and all parameters entered
  [ ] Stimulus configured for device requirements (biased vs. unipolar)
  [ ] Solver Max Step Size set ≤ 1/10 of the fastest time constant
  [ ] Simulation runs without errors and output matches expectations
```

---

## Appendix — Key Simulink Paths

| Task | Navigation |
|:---|:---|
| Open Mask Editor | Right-click block → **Mask → Edit Mask** or `Ctrl+M` |
| Open Model Settings | **Modeling** tab → **Model Settings** or `Ctrl+E` |
| Library Browser | `Ctrl+Shift+L` |
| Transfer Fcn block | Library: **Simulink → Continuous → Transfer Fcn** |
| Gain block | Library: **Simulink → Math Operations → Gain** |
| Pulse Generator | Library: **Simulink → Sources → Pulse Generator** |
| Scope | Library: **Simulink → Sinks → Scope** |

---

*Guide authored for M.Tech Optical Fiber Communications Lab — based on the LED and LASER diode modelling workflow.*
