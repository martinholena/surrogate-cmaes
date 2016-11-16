exp_id = 'exp_doubleEC_11_test';
exp_description = 'Surrogate CMA-ES, fixed DTS 0.05 (adaptive code) for logging purposes, UpdateRate={0.3}, DTIterations={1}, PreSampleSize=0.75, sd2 criterion, 2pop';

% BBOB/COCO framework settings

bbobParams = { ...
  'dimensions',         { 2 }, ...
  'functions',          { 8 }, ...      % all functions: num2cell(1:24)
  'opt_function',       { @opt_s_cmaes }, ...
  'instances',          { [1] }, ...    % default is [1:5, 41:50]
  'maxfunevals',        { '250 * dim' }, ...
  'progressLog'         { true }, ...
  'resume',             { true }, ...
};

% Surrogate manager parameters

surrogateParams = { ...
  'evoControl',         { 'doubletrained' }, ...    % 'none', 'individual', 'generation', 'restricted'
  'observers',          { {'DTModelSaver', 'DTScreenStatistics', 'DTFileStatistics'} },... % logging observers
  'modelType',          { 'gp' }, ...               % 'gp', 'rf', 'bbob'
  'updaterType',        { 'rankDiff' }, ...         % OrigRatioUpdater
  'DTAdaptive_aggregateType', { 'lastValid' }, ...
  'DTAdaptive_updateRate',     { 0.3 }, ...
  'DTAdaptive_maxRatio',      { 0.05 }, ...
  'DTAdaptive_minRatio',      { 0.05 }, ...
  'DTAdaptive_lowErr',        { 0.15 }, ...
  'DTAdaptive_highErr',       { 0.40 }, ...
  'DTAdaptive_defaultErr',    { 0.20 }, ...
  'evoControlMaxDoubleTrainIterations', { 1 }, ...
  'evoControlPreSampleSize',       { 0.75 }, ...       % {0.25, 0.5, 0.75}, will be multip. by lambda
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

% Model parameters

modelParams = { ...
  'useShift',           { false }, ...
  'predictionType',     { 'sd2' }, ...
  'trainAlgorithm',     { 'fmincon' }, ...
  'covFcn',             { '{@covMaterniso, 5}' }, ...
  'hyp',                { struct('lik', log(0.01), 'cov', log([0.5; 2])) }, ...
  'nBestPoints',        { 0 }, ...
  'minLeaf',            { 2 }, ...
  'inputFraction',      { 1 }, ...
  'normalizeY',         { true }, ...
};

% CMA-ES parameters

cmaesParams = { ...
  'PopSize',            { '(8 + floor(6*log(N)))' }, ...        %, '(8 + floor(6*log(N)))'};
  'Restarts',           { 50 }, ...
  'DispModulo',         { 0 }, ...
  % 'CMA',                { struct('damps', '1.5 + 2*max(0,sqrt((mueff-1)/(N+1))-1) + cs') }, ...
};

logDir = '/storage/plzen1/home/bajeluk/public';