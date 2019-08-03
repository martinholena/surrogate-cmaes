%% ECML PKDD 2019 IAL workshop article plots: Knowledge-based Selection of Gaussian Process Surrogates
%
% *Paper abstract:*
% Many real-world problems belong to the area of continuous
% black-box optimization. If the black-box function is also cost-aware,
% regression surrogate models are often utilized by optimization algorithms
% to save evaluations of the original cost-aware function. Choosing a
% suitable surrogate model or a suitable setting of its hyperparameters is
% a complex selection problem, where research into reusing knowledge
% represented by features of black-box function landscape is only starting.
% In this paper, we report the research into surrogate model selection,
% where knowledge from the previous experience with using the model is
% utilized to design a metalearing system. As a proof of concept, we
% provide a study investigating the influence of landscape features on the
% performance of various Gaussian process covariance functions as surrogate
% models for the state-of-the-art optimization algorithm in the cost-aware
% continuous black-box optimization.
% 
% Here we provide additional material which was not fully incorporated in
% the original paper.
%
% Created for ECML PKDD 2019 IAL workshop article.

%%

% load data for algorithm run results

% checkout file containing all loaded data
tmpFName = fullfile('/tmp', 'ecml2019_public_alg_data.mat');
if (exist(tmpFName', 'file'))
  load(tmpFName);
else

% needed function and dimension settings
funcSet.BBfunc = 1:24;
funcSet.dims = [2, 3, 5, 10, 20];
maxEvals = 250;

% folder for results
actualFolder = pwd;
articleFolder = fullfile(actualFolder(1:end - 1 - length('surrogate-cmaes')), 'latex_scmaes', 'ecml2019workshop');
plotResultsFolder = fullfile(articleFolder, 'images');
tableFolder = fullfile(articleFolder, 'tex');
[~, ~] = mkdir(plotResultsFolder);
[~, ~] = mkdir(tableFolder);

% path settings
exppath = fullfile('exp', 'experiments');

dts_meta_path = fullfile(exppath, 'exp_doubleEC_28_metaGP_pi');
dts_cov_path = fullfile(exppath, 'exp_doubleEC_28_5cov');
% cmaes_path = fullfile(exppath, 'CMA-ES');

% load data
dataFolders = {dts_meta_path; ...
               dts_cov_path; ...
               };

[evals, settings] = catEvalSet(dataFolders, funcSet);

% find ids in settings
clear findSet
findSet.modelOpts.bestModelSelection = 'pitra2019landscape';
metaId = getStructIndex(settings, findSet);

clear findSet
findSet.modelOpts.hypOptions.covFcn = '{@covPoly, ''eye'', 1}';
linId = getStructIndex(settings, findSet);
findSet.modelOpts.hypOptions.covFcn = '@covSEiso';
seId = getStructIndex(settings, findSet);
findSet.modelOpts.hypOptions.covFcn = '{@covMaterniso, 5}';
matId = getStructIndex(settings, findSet);
findSet.modelOpts.hypOptions.covFcn = '@covRQiso';
rqId = getStructIndex(settings, findSet);
findSet.modelOpts.hypOptions.covFcn = '{@covSEvlen, {@meanSum, {@meanLinear, @meanConst}}}';
gibbsId = getStructIndex(settings, findSet);

% extract data
meta_data = evals(:, :, metaId);
lin_data = evals(:, :, linId);
se_data = evals(:, :, seId);
mat_data = evals(:, :, matId);
rq_data = evals(:, :, rqId);
gibbs_data = evals(:, :, gibbsId);

% color settings
metaCol     = getAlgColors('dtscmaes');

linCol   = [255, 165,   0];  % orange (#ffa500)
seCol    = [255,   0,   0];  % light red (#ff0000)
matCol   = [255,   0, 255];  % magenta (#ff00ff)
rqCol    = [  0,   0, 255];  % middle blue (#0000ff)
gibbsCol = [133, 55,  106];  % dark violet (#85376a)

% marker settings
metaMark   = 'o';
linMark  = 'p';
seMark = '>';
matMark    = 'd';
rqMark  = 'x';
gibbsMark   = 'v';

if (~exist(tmpFName, 'file'))
  save(tmpFName);
end

end

%% Covariance function comparison (aggregated): Meta, LIN, SE, Matern, RQ, Gibbs
% Scaled medians (solid lines) and first and third quartiles
% (dash-dot lines) of the distances to the optima
% ${\Delta_f}^\textrm{med}$ in dimensions 2, 3, 5, 10, and 20 for
% DTS-CMA-ES with different settings of GP covariance function.
% Medians/quartiles were calculated across 15 independent instances for
% each algorithm and are shown in the $\log_{10}$ scale.
%
% Results aggregated accross all 24 BBOB functions and subgroups.

% Group aggregation of function values across dimensions 2, 3, 5, 10, 20.

data = { ...
        meta_data, ...
        lin_data, ...
        se_data, ...
        mat_data, ...
        rq_data, ...
        gibbs_data ...
        };

datanames = { ...
    'T-DTS', ...
    'LIN', ...
    'SE', ...
    'Matern', ...
    'RQ', ...
    'Gibbs' ...
    };

colors = [metaCol; linCol; seCol; matCol; rqCol; gibbsCol]/255;
markers = {metaMark; linMark; seMark; matMark; rqMark; gibbsMark};

% dims
plotDims = [2, 3, 5, 10, 20];

clear pdfNames
pdfNames = {};
funGroups = {'_f1-5', '_f6-9', '_f10-14', '_f15-19', '_f20-24', ''};
for d = plotDims
  for fg = 1:numel(funGroups)
    pdfNames{end+1} = fullfile(plotResultsFolder, sprintf('alg%s_%dD', funGroups{fg}, d));
  end
end

close all
han = groupFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ...
                              'Quantiles', true(1, 6), ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'first', ...
                              'MaxEval', maxEvals, ...
                              'Markers', markers, ...
                              'PlotGrid', [], ...
                              'MaxInstances', Inf, ...
                              'FunctionNames', true);

print2pdf(han, pdfNames, 1)

%% Covariance function comparison in 2D: Meta, LIN, SE, Matern, RQ, Gibbs
% Scaled medians (solid lines) and first and third quartiles
% (dash-dot lines) of the distances to the optima
% ${\Delta_f}^\textrm{med}$ in dimension 2 for
% DTS-CMA-ES with different settings of GP covariance function.
% Medians/quartiles were calculated across 15 independent instances for
% each algorithm and are shown in the $\log_{10}$ scale.

data = { ...
        meta_data, ...
        lin_data, ...
        se_data, ...
        mat_data, ...
        rq_data, ...
        gibbs_data ...
        };

datanames = { ...
    'T-DTS', ...
    'LIN', ...
    'SE', ...
    'Matern', ...
    'RQ', ...
    'Gibbs' ...
    };

colors = [metaCol; linCol; seCol; matCol; rqCol; gibbsCol]/255;
markers = {metaMark; linMark; seMark; matMark; rqMark; gibbsMark};

% 2D
plotFuns = [1:24];
plotDims = [2];

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ...
                              'Quantiles', true(1, 6), ...
                              'AggregateFuns', false, ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'first', ...
                              'MaxEval', maxEvals, ...
                              'Markers', markers, ...
                              'PlotGrid', [], ...
                              'MaxInstances', Inf, ...
                              'FunctionNames', true);

%% Covariance function comparison in 3D: Meta, LIN, SE, Matern, RQ, Gibbs
% Scaled medians (solid lines) and first and third quartiles
% (dash-dot lines) of the distances to the optima
% ${\Delta_f}^\textrm{med}$ in dimension 3 for
% DTS-CMA-ES with different settings of GP covariance function.
% Medians/quartiles were calculated across 15 independent instances for
% each algorithm and are shown in the $\log_{10}$ scale.

% 3D
plotFuns = [1:24];
plotDims = [3];

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ...
                              'Quantiles', true(1, 6), ...
                              'AggregateFuns', false, ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'first', ...
                              'MaxEval', maxEvals, ...
                              'Markers', markers, ...
                              'PlotGrid', [], ...
                              'MaxInstances', Inf, ...
                              'FunctionNames', true);

%% Covariance function comparison in 5D: Meta, LIN, SE, Matern, RQ, Gibbs
% Scaled medians (solid lines) and first and third quartiles
% (dash-dot lines) of the distances to the optima
% ${\Delta_f}^\textrm{med}$ in dimension 5 for
% DTS-CMA-ES with different settings of GP covariance function.
% Medians/quartiles were calculated across 15 independent instances for
% each algorithm and are shown in the $\log_{10}$ scale.

% 5D
plotFuns = [1:24];
plotDims = [5];

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ...
                              'Quantiles', true(1, 6), ...
                              'AggregateFuns', false, ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'first', ...
                              'MaxEval', maxEvals, ...
                              'Markers', markers, ...
                              'PlotGrid', [], ...
                              'MaxInstances', Inf, ...
                              'FunctionNames', true);

%% Covariance function comparison in 10D: Meta, LIN, SE, Matern, RQ, Gibbs
% Scaled medians (solid lines) and first and third quartiles
% (dash-dot lines) of the distances to the optima
% ${\Delta_f}^\textrm{med}$ in dimension 10 for
% DTS-CMA-ES with different settings of GP covariance function.
% Medians/quartiles were calculated across 15 independent instances for
% each algorithm and are shown in the $\log_{10}$ scale.

% 10D
plotFuns = [1:24];
plotDims = [10];

clear pdfNames
pdfNames = {};
for f = plotFuns
  for d = plotDims
    pdfNames{end+1} = fullfile(plotResultsFolder, sprintf('alg_f%d_%dD', f, d));
  end
end

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ...
                              'Quantiles', true(1, 6), ...
                              'AggregateFuns', false, ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'first', ...
                              'MaxEval', maxEvals, ...
                              'Markers', markers, ...
                              'PlotGrid', [], ...
                              'MaxInstances', Inf, ...
                              'FunctionNames', true);

%% Covariance function comparison in 20D: Meta, LIN, SE, Matern, RQ, Gibbs
% Scaled medians (solid lines) and first and third quartiles
% (dash-dot lines) of the distances to the optima
% ${\Delta_f}^\textrm{med}$ in dimension 20 for
% DTS-CMA-ES with different settings of GP covariance function.
% Medians/quartiles were calculated across 15 independent instances for
% each algorithm and are shown in the $\log_{10}$ scale.

% 20D
plotFuns = [1:24];
plotDims = [20];

clear pdfNames
pdfNames = {};
for f = plotFuns
  for d = plotDims
    pdfNames{end+1} = fullfile(plotResultsFolder, sprintf('alg_f%d_%dD', f, d));
  end
end

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ...
                              'Quantiles', true(1, 6), ...
                              'AggregateFuns', false, ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'first', ...
                              'MaxEval', maxEvals, ...
                              'Markers', markers, ...
                              'PlotGrid', [], ...
                              'MaxInstances', Inf, ...
                              'FunctionNames', true);

%%

close all
clear

% load data for RDE results

% checkout file containing all loaded data
tmpFName = fullfile('/tmp', 'ecml2019_public_rde_data.mat');
if (exist(tmpFName', 'file'))
  load(tmpFName);
else

%%

% folder for results
actualFolder = pwd;
articleFolder = fullfile(actualFolder(1:end - 1 - length('surrogate-cmaes')), 'latex_scmaes', 'ecml2019workshop');
plotResultsFolder = fullfile(articleFolder, 'images');
tableFolder = fullfile(articleFolder, 'tex');
[~, ~] = mkdir(plotResultsFolder);
[~, ~] = mkdir(tableFolder);

% create tables from calculated features and save them

expfolder = fullfile('exp', 'experiments');
exp_id = 'exp_DTSmodels_meta_02';
exp_meta_output = fullfile(expfolder, exp_id, 'meta_output', 'exp_DTSmodels_meta_02_res.mat');
printScriptMess = false;

if ~isfile(exp_meta_output)
  if printScriptMess
    fprintf('Loading metalearing results\n')
  end
  [results, settings, resParams] = metaLearn_loadResults(fullfile(expfolder, exp_id), ...
    'ShowOutput', true, ...
    'SaveResults', exp_meta_output);
end

clear actualFolder articleFolder

%%

% Load calculated data

if printScriptMess
  fprintf('Loading results\n')
end
if isfile(exp_meta_output)
  res = load(exp_meta_output, 'results', 'settings', 'resParams');
else
  error('%s does not exist', exp_meta_output)
end

results = res.results;
mfts = res.resParams.mfts;

nModel = numel(unique(results.model));
% create model labels
modelLabels = {'NN', 'SE', 'LIN', 'Q', ...
               'Mat', 'RQ', 'SE+Q', 'Gibbs'};

%%

% Removing metafeatures
% Remove user-defined, constant, NaN, and linearly dependent metafeatures.

% Process metafeatures

if printScriptMess
  fprintf('Processing metafeatures\n')
end
% remove user-defined metafeatures

% list of excluded metafeatures
%  3: basic.lower_min
%  4: basic.lower_max
%  5: basic.upper_min
%  6: basic.upper_max
%  7: basic.objective_min
%  8: basic.objective_max
%  9: basic.blocks_min
% 10: basic.blocks_max
% 11: basic.cells_total
% 12: basic.cells_filled
% 13: basic.minimize_fun

mfts_sets = {'archive', 'train', 'traintest'};
rem_mfts = {};
for ms = 1:numel(mfts_sets)
  mss = [mfts_sets{ms}, '_'];
  rem_mfts = [rem_mfts, {...
      [mss, 'basic_lower_min'], ...
      [mss, 'basic_lower_max'], ...
      [mss, 'basic_upper_min'], ...
      [mss, 'basic_upper_max'], ...
      [mss, 'basic_objective_min'], ...
      [mss, 'basic_objective_max'], ...
      [mss, 'basic_blocks_min'], ...
      [mss, 'basic_blocks_max'], ...
      [mss, 'basic_cells_total'], ...
      [mss, 'basic_cells_filled'], ...
      [mss, 'basic_minimize_fun'], ...
      [mss, 'ela_metamodel_lin_simple_intercept'] ...
    }];
end
% also remove only train and trainset metafeatures identical for all mfts
% sets
rem2_mfts = {};
for ms = 2:numel(mfts_sets)
  mss = [mfts_sets{ms}, '_'];
  rem2_mfts = [rem2_mfts, {...
      [mss, 'basic_dim'], ...
      [mss, 'cmaes_cma_evopath_c_norm'], ...
      [mss, 'cmaes_cma_evopath_s_norm'], ...
      [mss, 'cmaes_cma_generation'], ...
      [mss, 'cmaes_cma_restart'], ...
      [mss, 'cmaes_cma_step_size'] ...
    }];
end
rem_mfts = [rem_mfts, rem2_mfts];

if printScriptMess
  fprintf('Removing user-defined metafeatures:\n')
end
for m = 1:numel(rem_mfts)
  mId = strcmp(mfts.Properties.VariableNames, rem_mfts{m});
  if printScriptMess
    fprintf('%s\n', rem_mfts{m})
  end
  mfts = mfts(:, ~mId);
end

% rename archive identical columns (see above)
mfts.Properties.VariableNames{'archive_basic_dim'} = 'dimension';
mfts.Properties.VariableNames{'archive_cmaes_cma_evopath_c_norm'} = ...
                                      'cmaes_evopath_c_norm';
mfts.Properties.VariableNames{'archive_cmaes_cma_evopath_s_norm'} = ...
                                      'cmaes_evopath_s_norm';
mfts.Properties.VariableNames{'archive_cmaes_cma_generation'} = ...
                                      'cmaes_generation';
mfts.Properties.VariableNames{'archive_cmaes_cma_restart'} = ...
                                      'cmaes_restart';
mfts.Properties.VariableNames{'archive_cmaes_cma_step_size'} = ...
                                      'cmaes_step_size';
% rename observations columns
mfts.Properties.VariableNames{'archive_basic_observations'} = 'archive_observations';
mfts.Properties.VariableNames{'train_basic_observations'}   = 'train_observations';
mfts.Properties.VariableNames{'traintest_basic_observations'} = 'traintest_observations';

% create mfts table, where only user defined metafeatures are not present
full_mfts = mfts;

clear rem_mfts rem2_mfts m mId mss

%%

% Remove constant or NaN features
varMfts = varfun(@nanvar, mfts(:, 6:end), 'OutputFormat','uniform');
constId = varMfts == 0;
nanId = isnan(varMfts);

% constant
% add fun, dim, inst, id, and gen columns
constId = [false(1, 5), constId]; 
if any(constId) && printScriptMess
  fprintf('Removing constant metafeatures:\n')
  constNumId = find(constId);
  for m = constNumId
    fprintf('%s\n', mfts.Properties.VariableNames{m})
  end
end

% NaN
% add fun, dim, inst, id, and gen columns
nanId = [false(1, 5), nanId];
if any(nanId) && printScriptMess
  fprintf('Removing NaN metafeatures:\n')
  nanNumId = find(nanId);
  for m = nanNumId
    fprintf('%s\n', mfts.Properties.VariableNames{m})
  end
end
% actual removement
mfts(:, constId | nanId) = [];

clear varMfts constId nanId constNumId nanNumId m

%%

% Remove linearly dependent metafeatures

% tolerance for linear dependency
tol = eps; % eps;

mfts_only = mfts(:, 6:end);
mfts_arr = table2array(mfts_only);
nanInfMftsId = isnan(mfts_arr) + 2*isinf(mfts_arr);
% find columns where nan and Inf positions are identical
[~, nanInfDependent] = ismember(nanInfMftsId', nanInfMftsId', 'rows');
% cycle through identical positions to find linear dependencies of the
% remaining data
nanInfGroup = unique(nanInfDependent);
mfId = [];
for g = nanInfGroup'
  gid = g == nanInfDependent;
  % array consisting non-nan or inf rows of specific group
  subArray = mfts_arr(~nanInfMftsId(:, find(gid, 1, 'first')), gid);
  % exclude equal metafeatures
  [~, gEqId] = intersect(subArray', subArray', 'rows');
  % normalize columns
%   subArray = subArray./repmat(sum(subArray), size(subArray, 1), 1);
  % find linear independent columns of reduced group table
  [~, gDepId] = licols(subArray(:, gEqId), tol);
  gidNum = find(gid);
  % add independent metafeatures including NaNs and Infs
  mfId = [mfId; gidNum(gEqId(gDepId))];
end
% resulting table
mfts_indep = [mfts(:, 1:5), mfts_only(:, sort(mfId))];

nFeat = numel(mfId);
% print dependent metafeatures
if nFeat < numel(mfts_only.Properties.VariableNames)
  mfts_dep = mfts_only.Properties.VariableNames(...
    ~ismember(mfts_only.Properties.VariableNames, ...
              mfts_indep.Properties.VariableNames));
  if printScriptMess
    fprintf('Removing dependent metafeatures:\n')
    for m = 1:numel(mfts_dep)
      fprintf('%s\n', mfts_dep{m})
    end
  end
end

clear tol mfts_only mfts_arr nanInfMftsId nanInfDependent nanInfGroup mfId ...
      g gid subArray gEqId gDepId gidNum nFeat mfts_dep m

%%

% Cat model results with metafeatures

if printScriptMess
  fprintf('Concatenating model results and metafeatures\n')
end
err_name = {'rdeValid', 'rde'};
errPenalty = 1;
modelLabels_friend = {'NN', 'SE', 'LIN', 'QUAD', ...
                     'Matern', 'RQ', 'SE_QUAD', 'Gibbs'};
full_mfts_err = full_mfts;

for e = 1:numel(err_name)
  % form table containing rde results from all models
  for m = 1:nModel
    model_err = results(results.model == m, {'fun', 'dim', 'inst', 'gen', 'id', err_name{e}});
    model_err.Properties.VariableNames{err_name{e}} = ...
      sprintf('%s_%s', err_name{e}, modelLabels_friend{m});
    if m == 1
      err_table = model_err;
    else
      err_table = outerjoin(err_table, model_err, 'MergeKeys', true);
    end
  end
  % join all metafeatures and error values of individual models without
  % replacing missing errors
  full_mfts_err = innerjoin(err_table, full_mfts_err);
  % model error column names
%   modelLabels_err = cellfun(@(x) [err_name, '_', x], modelLabels_friend, ...
%                             'UniformOutput', false);
%   full_mfts_err.Properties.VariableNames = ...
%     [modelLabels_err, full_mfts_err.Properties.VariableNames(9:end)];
end
% create extra full_mfts_err for visualisation
full_mfts_vis = full_mfts_err;
% remove identification columns (fun, dim, inst, gen, model)
full_mfts_err = full_mfts_err(:, [1, 3, 5, 6:end]);

% replace missing errors and inf errors by penalty term
% cannot use fillmissing(err_table, 'constant', errPenalty) - not 
% implemented in R2015b
for m = 1:nModel
  col_name = sprintf('%s_%s', err_name{e}, modelLabels_friend{m});
  err_table.(col_name)(isnan(err_table.(col_name))) = errPenalty;
end

% join metafeatures and error values of individual models
mfts_err = innerjoin(err_table, mfts_indep);
full_mfts_vis = innerjoin(err_table, full_mfts_vis(:, [1:5, 22:end]));

clear err_name errPenalty modelLabels_friend full_mfts full_mfts_err e m ...
      model_err err_table col_name

%%
if (~exist(tmpFName, 'file'))
  save(tmpFName);
end

end

%% $\textrm{RDE}_\mu$ regardless sample set
% Features in the following plots pertain to all types of sample sets.
% 
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

if printScriptMess
  fprintf('Starting visual inspection\n')
end
nPointsToPlot = 200;
logBound = 5;
medianLineWidth = 1.8;
quartileLineWidth = 1;
medianLineStyle = '-';
quartileLineStyle = '-.';

kerColor = getAlgColors([1, 2, 3, 12, 10, 11, 8, 5]) / 255;
% plot only the following kernels
useKernels = [2, 3, 5, 6, 8];

nExtF = 55;
mfts_order_id = [14, 16:18, 20:21]; % identical for sample sets
mfts_order_nonid = [...        not identical for sample sets
              15, 80, 138, ... observations
              19, 78, 136, ... cma_mean_dist
              22, 79, 137, ... cma_lik
              reshape(22 + repmat([0,58,116]', 1, nExtF) ...
                + [(1:nExtF); (1:nExtF); (1:nExtF)], 1, 3*nExtF)];

close all

metafeaturePlot(full_mfts_vis(:, mfts_order_id), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_id), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on number of observations
% 
% Number of observations differs according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 1:3;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on CMA-ES features
% 
% CMA features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 4:9;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on Dispersion features
% 
% Dispersion features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 10:57;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on y-Distribution features
% 
% y-Distribution features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 58:66;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on Levelset features
% 
% Levelset features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 67:120;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on Metamodel features
% 
% Metamodel features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 121:144;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on Information content features
% 
% Information content features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$, 
% |train| $\mathcal{T}$, and
% |traintest| $\mathcal{T}_\mathcal{P}$.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

fId = 145:159;

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%% $\textrm{RDE}_\mu$ on NBC features
% 
% NBC features differ according to the sample set on
% which they were calculated: 
% |archive| $\mathcal{A}$ and 
% |train| $\mathcal{T}$.
% NBC features are 
% impossible to calculate using points without fitness values.
% Therefore, values calculated on |traintest| $\mathcal{T}_\mathcal{P}$ 
% are missing.
%
% Median (solid lines) and first and third quartiles
% (dash-dot lines) of $\textrm{RDE}_\mu$ values dependency on individual
% features for all tested covariances calculated on all available datasets.

close all

% remove traintest plots
fId = sort([160:3:174, 161:3:174]);

metafeaturePlot(full_mfts_vis(:, mfts_order_nonid(fId)), full_mfts_vis(:, 6:13), ...
                'DataColor', kerColor, ...
                'DataNames', modelLabels, ...
                'MftsNames', full_mfts_vis.Properties.VariableNames(mfts_order_nonid(fId)), ...
                'NValues', 200, ...
                'LogBound', 2, ...
                'QuantileRange', [0.05, 0.95], ...
                'MedianLW', 1.8, ...
                'QuartileLW', 1, ...
                'MedianLS', '-', ...
                'QuartileLS', '-.', ...
                'UseData', useKernels ...
  );

%%

% finalize script
clear
close all
