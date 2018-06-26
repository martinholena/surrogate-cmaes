exp_id = 'exp_doubleEC_ic_04_10D';
exp_description = 'aDTS, model selection with BIC, 8 GP models, 5 insts, 10D';

% BBOB/COCO framework settings

bbobParams = { ...
  'dimensions',         { 10 }, ...
  'functions',          num2cell(1:24), ...      % all functions: num2cell(1:24)
  'opt_function',       { @opt_s_cmaes }, ...
  'instances',          num2cell(1:5), ...    % default is [1:5, 41:50]
  'maxfunevals',        { '250 * dim' }, ...
  'resume',             { false }, ...
};

% Surrogate manager parameters

surrogateParams = { ...
  'evoControl',         { 'doubletrained' }, ...    % 'none', 'individual', 'generation', 'restricted'
  'observers',          { {'DTScreenStatistics', 'DTFileStatistics', 'DTICLogger'} },... % logging observers
  'printICs',           { true }, ... % print information criteria to stdout
  'modelType',          { 'modelsel' }, ...               % 'gp', 'rf', 'bbob'
  'updaterType',        { 'rankDiff' }, ...         % OrigRatioUpdater
  'DTAdaptive_updateRate',     { 0.3 }, ...
  'DTAdaptive_updateRateDown', { 'obj.updateRate' }, ...
  'DTAdaptive_maxRatio',       { 1.0 }, ...
  'DTAdaptive_minRatio',       { 0.04 }, ...
  'DTAdaptive_lowErr',         { '@(x) [ones(size(x,1),1) log(x(:,1)) x(:,2) log(x(:,1)).*x(:,2) x(:,2).^2] * [0.11; -0.0092; -0.13; 0.044; 0.14]' }, ...
  'DTAdaptive_highErr',        { '@(x) [ones(size(x,1),1) log(x(:,1)) x(:,2) log(x(:,1)).*x(:,2) x(:,2).^2] * [0.35; -0.047; 0.44; 0.044; -0.19]' }, ...
  'DTAdaptive_defaultErr',     { 0.05 }, ...
  'evoControlMaxDoubleTrainIterations', { 1 }, ...
  'evoControlPreSampleSize',       { 0.75 }, ...       % {0.25, 0.5, 0.75}, will be multip. by lambda
  'evoControlNBestPoints',         { 0 }, ...
  'evoControlValidationGenerationPeriod', { 4 }, ...
  'evoControlValidationPopSize',   { 0 }, ...
  'evoControlOrigPointsRoundFcn',  { 'ceil' }, ...  % 'ceil', 'getProbNumber'
  'evoControlIndividualExtension', { [] }, ...      % will be multip. by lambda
  'evoControlBestFromExtension',   { [] }, ...      % ratio of expanded popul.
  'evoControlTrainRange',          { 10 }, ...      % will be multip. by sigma
  'evoControlTrainNArchivePoints', { '15*dim' },... % will be myeval()'ed, 'nRequired', 'nEvaluated', 'lambda', 'dim' can be used
  'evoControlSampleRange',         { 1 }, ...       % will be multip. by sigma
  'evoControlOrigGenerations',     { [] }, ...
  'evoControlModelGenerations',    { [] }, ...
  'evoControlValidatePoints',      { [] }, ...
  'evoControlRestrictedParam',     { 0.05 }, ...
};

% Hyperparameter priors
pg1 = '{@priorGauss, log(0.01), 2}';
pt1 = '{@priorT, log(1), 4, 5}';

% Specification of model set for model selector

ell = 0.5;
sf = 2;

modelOptions = struct( ...
  'name',   {'SE', 'NN', 'LIN', 'QUAD', 'PER', 'ADD', 'SE+NN', 'SE+LIN'}, ...
  'type',   repmat({'gp'}, 1, 8), ...
  'params', { ...
    struct( ...   % SE
      'covFcn',   '@covSEiso', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([ell sf])') ...
    ), ...
    struct( ...   % NN
      'covFcn',   '@covNNone', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([ell sf])') ...
    ), ...
    struct( ...   % LIN
      'covFcn',   '{@covPoly, ''eye'', 1}', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([1 1])') ...
    ), ...
    struct( ...   % QUAD
      'covFcn',   '{@covPoly, ''eye'', 2}', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([1 1])') ...
    ), ...
    struct( ...   % PER
      'covFcn',   '{@covPERiso, {@covSEiso}}', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([0.1 ell sf])') ...
    ), ...
    struct( ...   % ADD
      'covFcn',   '{@covADD, {[1], @covSEisoU}}', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([ones(1, 10) ell])') ... % CAUTION: dim-dependent!
    ), ...
    struct( ...   % SE + NN
      'covFcn',   '{@covSum, {@covSEiso, @covNNone}}', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([ell sf ell sf])') ...
    ), ...
    struct( ...   % SE + QUAD
      'covFcn',   '{@covSum, {@covSEiso, {@covPoly, ''eye'', 2}}}', ...
      'hyp',      struct('lik', log(0.01), 'cov', log([ell sf 1 1])') ...
    ) ...
  } ...
);
%
% modelOptions = struct( ...
%   'name',   {'LIN', 'QUAD'}, ...
%   'type',   repmat({'gp'}, 1, 2), ...
%   'params', { ...
%     struct( ...   % LIN
%       'covFcn',   '{@covPoly, ''eye'', 1}', ...
%       'hyp',      struct('lik', log(0.01), 'cov', log([1 1])), ...
%       'prior',    struct('lik', {{pg1}}, 'cov', {{pt2 pt1}}) ...
%     ), ...
%     struct( ...   % QUAD
%       'covFcn',   '{@covPoly, ''eye'', 2}', ...
%       'hyp',      struct('lik', log(0.01), 'cov', log([1 1])), ...
%       'prior',    struct('lik', {{pg1}}, 'cov', {{pt2 pt1}}) ...
%     ), ...
%   } ...
% );

% Model parameters

modelParams = { ...
  'modelOptions', { modelOptions }, ...
  'sharedModelOptions', { ...
    struct( ...
      'meanFcn',            { 'meanZero' }, ...
      'likFcn',             { 'likGauss' }, ...
      'predictionType',     { 'poi' }, ...
      'useShift',           { false }, ...
      'normalizeY',         { true }, ...
      'centerX',            { true }, ...
      'trainAlgorithm',     { 'fmincon' }, ...
      'cmaesCheckBounds',   { false } ...
    ) ...
  }, ...
  'ic',                 { 'bic' }, ...
  'factory',            { 'ModelFactory' }, ...
  'trainsetType',       { 'nearest' }, ... % inherited properties
  'predictionType',     { 'poi' }, ...
  'trainRange',         { 4 }, ...
  'trainsetSizeMax',    { '20*dim' }, ...
  'transformCoordinates', { true } ...
};

% CMA-ES parameters

cmaesParams = { ...
  'PopSize',            { '(8 + floor(6*log(N)))' }, ...        %, '(8 + floor(6*log(N)))'};
  'Restarts',           { 50 }, ...
  'DispModulo',         { 0 }, ...
};

logDir = '/storage/plzen1/home/repjak/public';
