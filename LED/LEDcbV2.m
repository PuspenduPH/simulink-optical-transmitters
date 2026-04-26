% Input Argument of MaskInitialization function is a struct with properties
% BlockHandle, MaskObject and MaskWorkspace. Example: maskInitContext.BlockHandle

% Input Argument of Parameter Callbacks is a struct with properties
% BlockHandle and ParameterObject. Example: callbackContext.ParameterObject

% Universal Constants
h = 6.62e-34;     % Planck's constant (J.s)
c = 2.99793e8;    % Light velocity (m/s)
q = 1.60218e-19;  % Electron charge (C)
n_a = 1;

% Efficiency Calculations
eta_int = tau_nr / (tau_nr + tau_r);
eta_ext = (1 - ((n_s - n_a)/(n_s + n_a))^2) * (1 - cos(n_a/n_s));

% DC Transfer Function (Quantum Efficiency in W/A)
HT_0 = (h * c / (lambda * q)) * eta_int * eta_inj * eta_ext;
