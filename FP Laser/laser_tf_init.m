% Input Argument of MaskInitialization function is a struct with properties
% BlockHandle, MaskObject and MaskWorkspace. Example: maskInitContext.BlockHandle

% Input Argument of Parameter Callbacks is a struct with properties
% BlockHandle and ParameterObject. Example: callbackContext.ParameterObject

classdef laser_tf_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            % Access the mask workspace object
            ws = maskInitContext.MaskWorkspace;

            % 1. Retrieve ALL parameters from the dialog box
            lambda = ws.get('lambda');
            tau_nr = ws.get('tau_nr');
            tau_r  = ws.get('tau_r');
            L      = ws.get('L');
            gamma  = ws.get('gamma');
            R1     = ws.get('R1');
            I_d    = ws.get('I_d');
            I_th   = ws.get('I_th');
            I_0    = ws.get('I_0');
            tau_sp = ws.get('tau_sp');
            tau_ph = ws.get('tau_ph');

            % Universal Constants
            h = 6.62e-34;
            c = 2.9979e8;
            q = 1.602e-19;

            % 2. Convert to standard SI units
            lambda_m = lambda * 1e-9;    % nm to meters
            I_d_A    = I_d * 1e-3;       % mA to Amperes
            I_0_A    = I_0 * 1e-3;       % mA to Amperes
            I_th_A   = I_th * 1e-3;      % mA to Amperes
            tau_sp_s = tau_sp * 1e-9;    % ns to seconds
            tau_ph_s = tau_ph * 1e-9;    % ns to seconds

            % 3. Calculate Efficiencies
            eta_int = tau_nr / (tau_nr + tau_r);
            eta_ext = log(1/R1) / (gamma * L + log(1/R1));

            % 4. Calculate HT_0 (The DC Transfer Function)
            current_modifier = (I_d_A - I_th_A) / I_d_A;
            HT_0 = ((h * c) / (lambda_m * q)) * eta_int * eta_ext * current_modifier;

            % 5. Calculate Transfer Function Variables
            f0_sq = (I_0_A - I_th_A) / (tau_sp_s * tau_ph_s * I_th_A);
            beta  = I_0_A / (tau_sp_s * I_th_A);

            % 6. Push the calculated variables back to the mask workspace 
            ws.set('f0_sq', f0_sq);
            ws.set('beta', beta);
            ws.set('HT_0', HT_0);
        end
    end
end