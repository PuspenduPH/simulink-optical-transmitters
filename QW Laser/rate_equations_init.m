% Input Argument of MaskInitialization function is a struct with properties
% BlockHandle, MaskObject and MaskWorkspace. Example: maskInitContext.BlockHandle

% Input Argument of Parameter Callbacks is a struct with properties
% BlockHandle and ParameterObject. Example: callbackContext.ParameterObject

classdef rate_equations_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            ws = maskInitContext.MaskWorkspace;

            % 1. Retrieving raw parameters from the dialog box
            lambda0_cm = ws.get('lambda0');
            Vact_cm3   = ws.get('Vact');
            Gamma      = ws.get('Gamma');
            beta       = ws.get('beta');
            tau_p_ps   = ws.get('tau_p');
            g0_cm3_s   = ws.get('g0');
            N0_cm3     = ws.get('N0');
            tau_n_ps   = ws.get('tau_n');
            eta        = ws.get('eta');
            Ne_cm3     = ws.get('Ne');

            % 2. Converting ALL parameters to pure SI units (m, m^3, s, 1/m^3)
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

            % Epsilon (Gain-saturation term)
            % Units are volume (cm^3) to cancel out S(t) in the (1 - eps*S) term
            eps_val_cm3 = 3.4e-23;
            eps_val = eps_val_cm3 * 1e-6;    % cm^3 to m^3

            % 3. Calculating the Gain multipliers in pure SI
            G_I       = 1 / (q * Vact);
            G_Ne      = Ne / tau_n;
            G_N_decay = 1 / tau_n;
            G_S_decay = 1 / tau_p;
            G_Pf      = (Vact * eta * h * c) / (Gamma * tau_p * lambda0);

            % 4. Pushing variables back to workspace
            ws.set('G_I', G_I);
            ws.set('G_Ne', G_Ne);
            ws.set('G_N_decay', G_N_decay);
            ws.set('G_S_decay', G_S_decay);
            ws.set('G_Pf', G_Pf);
            ws.set('eps_val', eps_val);
            ws.set('g0', g0);
            ws.set('N0', N0);
        end
    end
end