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
            % (Assuming your variables are named as they were in the SLX file)
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

            lambda = lambda*1e-9;
            tau_nr = tau_nr*1e-9;
            tau_r = tau_r*1e-9;
            
            % 2. Calculate Efficiencies (Equations 4 & 5)
            eta_int = tau_nr / (tau_nr + tau_r);
            eta_ext = (1 - ((n_s - n_a)/(n_s + n_a))^2) * (1 - cos(n_a/n_s));

            % 3. Calculate HT_0 (The DC Transfer Function, Equation 3)
            HT_0 = ((h * c) / (lambda * q)) * eta_int * eta_inj * eta_ext;

            % 4. Push the calculated variables back to the mask workspace
            ws.set('HT_0', HT_0);
            ws.set('tau_r', tau_r); 
        end
    end
end