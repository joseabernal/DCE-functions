function [t_s,Cp_AIF_mM]=DCEFunc_getParkerModAIF(t_res_s,t_acq_s,t_start_s,Hct, varargin)
%Returns a modified version of population average plasma AIF (Parker 2006) in mMol and at time points t
%Modifications make decay bi-exponential to more accurately represent typical data over a 20-minute acquisition, as described in Heye et al., Neuroimage (2016)
%Useful for simulations.
%OUTPUT:
%t_s: time points are placed at intervals of t_res_s, starting at t_res_s/2
%(assuming linear k-space sampling, this generates time points relative to the start of
%acquisition)
%Cp_AIF_mM: column vector containing arterial plasma concentrations
%INPUT:
%t_res_s=temporal resolution
%t_acq_s=duration of acquisition
%t_start_s=time of start of injection (applies a time shift to the modified Parker function)
%Hct=hematocrit (this converts the Cb values determined by the (modified) Parker function to Cp values)
%-- variable inputs --
% 'MSS2' or 'MSS3' - changes aplha and beta values to match decay according to
% patients from these studies

t_s=((t_res_s/2):t_res_s:(t_acq_s-t_start_s)).'; %calculate time points (starting at t_res/2)
t_min=t_s/60; %Parker function uses minute units, so convert time;

%%set (modified) Parker function parameters
A1=0.809; A2=0.330;
T1=0.17046; T2=0.365;
sigma1=0.0563; sigma2=0.132;
s=38.078; tau=0.483;
%alpha=1.050; beta=0.1685; %(original Parker values)
alpha=3.1671; beta=1.0165;

% take decay_type from variable input, if none then assign MSS2 values
if isempty(varargin) == 1;
    alpha2=0.5628; beta2=0.0266; % default to MSS2 values
elseif isempty(varargin) == 0;
    decay_type = varargin{1};
    switch decay_type
    case 'MSS2' % matches MSS2 patients with Dotarem
        alpha2=0.5628; beta2=0.0266;
    case 'MSS3' % matches MSS3 patients with Gadovist
        alpha2=0.765; beta2=0.0325;
    end
end

Cb_mM=(A1/(sigma1*sqrt(2*pi)))*exp(-((t_min-T1).^2)/(2*sigma1^2)) + ... %calculate Cb
    (A2/(sigma2*sqrt(2*pi)))*exp(-((t_min-T2).^2)/(2*sigma2^2)) + ...
    (alpha*exp(-beta*t_min) + alpha2*exp(-beta2*t_min))./(1+exp(-s*(t_min-tau)));

Cp_AIF_mM=Cb_mM/(1-Hct); %convert to Cp

t_preContrast_s=fliplr(t_start_s-t_res_s/2:-t_res_s:0).'; %pre-injection time points (calculate backwards to zero, then reverse, so that time interval is constant)

t_s=[ t_preContrast_s ; t_s + t_start_s]; %add pre-contrast time points to time values
Cp_AIF_mM=[zeros(size(t_preContrast_s)) ; Cp_AIF_mM]; % add pre-contrast concentration values (zeros)

end