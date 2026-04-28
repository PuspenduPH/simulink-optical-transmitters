% Input Argument of MaskInitialization function is a struct with properties
% BlockHandle, MaskObject and MaskWorkspace. Example: maskInitContext.BlockHandle

% Input Argument of Parameter Callbacks is a struct with properties
% BlockHandle and ParameterObject. Example: callbackContext.ParameterObject

classdef led_mask_init
    methods(Static)
        function MaskInitialization(maskInitContext)
            % Access the mask workspace object
            ws = maskInitContext.MaskWorkspace;

            % 1. Retrieve parameters from the dialog box
            lambda_ns  = ws.get('lambda');
            tau_r_ns   = ws.get('tau_r');
            tau_nr_ns  = ws.get('tau_nr');
            eta_inj = ws.get('eta_inj');
            n_s     = ws.get('n_s');
            n_a     = ws.get('n_a');

            % Universal Constants
            h = 6.62e-34;       % plank's constant
            c = 2.9979e8;       % Speed of Light
            q = 1.602e-19;      % Electron's Charge

            % converting variables back to SI units
            lambda = lambda_ns*1e-9;   
            tau_r = tau_r_ns*1e-9;
            tau_nr = tau_nr_ns*1e-9;

            % 2. Calculating Efficiencies 
            eta_int = tau_nr / (tau_nr + tau_r);
            eta_ext = (1 - ((n_s - n_a)/(n_s + n_a))^2) * (1 - cos(n_a/n_s));

            % 3. Calculating HT_0 
            HT_0 = ((h * c) / (lambda * q)) * eta_int * eta_inj * eta_ext;

            % 4. Push the calculated variables back to the mask workspace
            ws.set('HT_0', HT_0);
            ws.set('tau_r', tau_r); 
        end
    end
end