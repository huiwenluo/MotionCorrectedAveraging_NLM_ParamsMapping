function [r2starmap,fatfraction] = processFatWater(image,TE1,dTE,nTE)
%% testSynthetic_hernando_111110
%%
%% Test fat-water algorithms on synthetic data
%%
%% Author: Diego Hernando
%% Date created: August 19, 2011
%% Date last modified: February 29, 2012

% Add to matlab path
BASEFOLDER = '/Users/huiwenluo/Desktop/NLMcode/toolbox/012_graphcut3D/';
addpath([BASEFOLDER 'graphcut']);
addpath([BASEFOLDER 'common']);
addpath([BASEFOLDER 'descent']);
addpath([BASEFOLDER 'mixed_fitting']);
addpath([BASEFOLDER 'matlab_bgl']);
addpath /Users/huiwenluo/Desktop/NLMcode/toolbox/007_fatWaterFitMex/


%% Set recon params
% General parameters
algoParams.species(1).name = 'water';
algoParams.species(1).frequency = 0;
algoParams.species(1).relAmps = 1;
algoParams.species(2).name = 'fat';
algoParams.species(2).frequency = ([-3.80, -3.40, -2.60, -1.94, -0.39, 0.60]);
algoParams.species(2).relAmps = [0.087 0.693 0.128 0.004 0.039 0.048];

% Algorithm-specific parameters
algoParams.size_clique = 1; % Size of MRF neighborhood (1 uses an 8-neighborhood, common in 2D)ims =
algoParams.range_r2star = [0 80]; % Range of R2* values
algoParams.NUM_R2STARS = 4; % Number of R2* values for quantization
algoParams.range_fm = [-300 300]; % Range of field map values
algoParams.NUM_FMS = 201; % Number of field map values to discretize
algoParams.NUM_ITERS = 40; % Number of graph cut iterations
algoParams.SUBSAMPLE = 2; % Spatial subsampling for field map estimation (for speed)
algoParams.DO_OT = 0; % 0,1 flag to enable optimization transfer descent (final stage of field map estimation)
algoParams.LMAP_POWER = 2; % Spatially-varying regularization (2 gives ~ uniformn resolution)
algoParams.lambda = 0.02; % Regularization parameter
algoParams.LMAP_EXTRA = 0.00; % More smoothing for low-signal regions
algoParams.TRY_PERIODIC_RESIDUAL = 0;



allims = permute(image,[1 2 4 5 6 3]);



imDataParams.TE = TE1 + [0:(nTE-1)]*dTE;
imDataParams.FieldStrength = 3;
imDataParams.PrecessionIsClockwise = -1;






imDataParams.images = allims;


% Process with fieldmap smoothness constraints for initial guess
initParams = fw_i2cm1i_3pluspoint_hernando_graphcut( imDataParams, algoParams );


% Process complex with independent initial phase for water/fat
[outParams_fwci] = fwFit_ComplexLS_1r2star( imDataParams, algoParams, initParams );
fwci_ff = computeFF(outParams_fwci);
fwci_w = outParams_fwci.species(1).amps;
fwci_f = outParams_fwci.species(2).amps;
fwci_fm = outParams_fwci.fieldmap;
fwci_r2star = outParams_fwci.r2starmap;

% Process mixed with common initial phase for water/fat
[outParams_fwxc] = fwFit_MixedLS_1r2star( imDataParams, algoParams, initParams );
fwxc_ff = computeFF(outParams_fwxc);
fwxc_w = outParams_fwxc.species(1).amps;
fwxc_f= outParams_fwxc.species(2).amps;
fwxc_fm = outParams_fwxc.fieldmap;
fwxc_r2star= outParams_fwxc.r2starmap;

% Process magn with common initial phase for water/fat
imDataMagn = imDataParams;
imDataMagn.images = abs(imDataParams.images);
initMagn = initParams;
initMagn.species(1).amps = abs(initParams.species(1).amps);
initMagn.species(2).amps = abs(initParams.species(2).amps);
[outParams_fwmc] = fwFit_MagnLS_1r2star( imDataMagn, algoParams, initMagn );
fwmc_ff = computeFF(outParams_fwmc);
fwmc_w = outParams_fwmc.species(1).amps;
fwmc_f = outParams_fwmc.species(2).amps;
fwmc_r2star = outParams_fwmc.r2starmap;


fatfraction = fwmc_ff;
r2starmap = fwmc_r2star;
end


