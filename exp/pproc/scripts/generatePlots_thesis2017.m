%% Lukas Thesis 2017 plots
% Script for making graphs showing the dependence of minimal function
% values on the number of function values of compared algorithms.
%
% Created for Lukas' thesis

%% load data

% checkout file containing all loaded data
tmpFName = fullfile('/tmp', 'lt2017comparison.mat');
if (exist(tmpFName', 'file'))
  load(tmpFName);
elseif (exist('/mnt/arx/skola/phd/2017/thesis/lt2017comparison.mat'))
  load('/mnt/arx/skola/phd/2017/thesis/lt2017comparison.mat');
else

% needed function and dimension settings
funcSet.BBfunc = 1:24;
funcSet.dims = [2, 3, 5, 10];
maxEvals = 250;

% folder for results
actualFolder = pwd;
articleFolder = fullfile(actualFolder(1:end - 1 - length('surrogate-cmaes')), 'latex_scmaes', 'lukas_thesis');
plotResultsFolder = fullfile(articleFolder, 'img');
tableFolder = fullfile(articleFolder, 'data');
[~,~] = mkdir(plotResultsFolder);
[~,~] = mkdir(tableFolder);

% path settings
exppath = fullfile('exp', 'experiments');

cedaG_bbob = fullfile(exppath, 'EDA_BBOB/CEDA_2');
cedaT_bbob = fullfile(exppath, 'EDA_BBOB/CEDA_5');
egna_bbob1 = fullfile(exppath, 'EDA_BBOB/EGNA_4');
egna_bbob2 = fullfile(exppath, 'EDA_BBOB/EGNA_8');
gauss_bbob = fullfile(exppath, 'EDA_BBOB/GaussEDA_7');
cmaes_bbob = fullfile(exppath, 'CMA-ES_1pop');

cedaG_traj = fullfile(exppath, 'EDA_SAGAS/CEDA_traj_2');
cedaT_traj = fullfile(exppath, 'EDA_SAGAS/CEDA_traj_3');
egna_traj  = fullfile(exppath, 'EDA_SAGAS/EGNA_traj_6');
gauss_traj = fullfile(exppath, 'EDA_SAGAS/GaussEDA_traj_5');
cmaes_traj = fullfile(exppath, 'EDA_SAGAS/CMAES_traj');

% load data
dataFoldersBBOB = { cedaG_bbob, ...
  cedaT_bbob, ...
  egna_bbob1, ...
  egna_bbob2, ...
  gauss_bbob, ...
  cmaes_bbob};
dataFoldersTraj = { cedaG_traj, ...
  cedaT_traj, ...
  egna_traj, ...
  gauss_traj, ...
  cmaes_traj};

[evalsBBOB, settingsBBOB] = catEvalSet(dataFoldersBBOB, funcSet, 250);
funcSetTraj.BBfunc = [26];
funcSetTraj.dims = [12];
[evalsTraj, settingsTraj] = catEvalSet(dataFoldersTraj, funcSetTraj, 2500);

% find ids in settings
clear findSet
findSet.algName = 'CEDA_2';
cedaG_bbob_Id = getStructIndex(settingsBBOB, findSet);
clear findSet
findSet.algName = 'CEDA_5';
cedaT_bbob_Id = getStructIndex(settingsBBOB, findSet);
clear findSet
findSet.algName = 'EGNA_4';
egna_bbob1_Id = getStructIndex(settingsBBOB, findSet);
clear findSet
findSet.algName = 'EGNA_8';
egna_bbob2_Id = getStructIndex(settingsBBOB, findSet);
clear findSet
findSet.algName = 'GaussEDA_7';
gauss_bbob_Id = getStructIndex(settingsBBOB, findSet);
clear findSet
findSet.algName = 'CMA-ES_1pop';
cmaes_bbob_Id = getStructIndex(settingsBBOB, findSet);

clear findSet
findSet.algName = 'CEDA_traj_2';
cedaG_traj_Id = getStructIndex(settingsTraj, findSet);
clear findSet
findSet.algName = 'CEDA_traj_3';
cedaT_traj_Id = getStructIndex(settingsTraj, findSet);
clear findSet
findSet.algName = 'EGNA_traj_6';
egna_traj_Id = getStructIndex(settingsTraj, findSet);
clear findSet
findSet.algName = 'GaussEDA_traj_5';
gauss_traj_Id = getStructIndex(settingsTraj, findSet);
clear findSet
findSet.algName = 'CMAES_traj';
cmaes_traj_Id = getStructIndex(settingsTraj, findSet);

% extract data
cedaG_bbob_data  = evalsBBOB(:, :, cedaG_bbob_Id);
cedaT_bbob_data  = evalsBBOB(:, :, cedaT_bbob_Id);
egna_bbob1_data = evalsBBOB(:, :, egna_bbob1_Id);
egna_bbob2_data = evalsBBOB(:, :, egna_bbob2_Id);
gauss_bbob_data = evalsBBOB(:, :, gauss_bbob_Id);
cmaes_bbob_data = evalsBBOB(:, :, cmaes_bbob_Id);
cedaG_traj_data  = evalsTraj(:, :, cedaG_traj_Id);
cedaT_traj_data  = evalsTraj(:, :, cedaT_traj_Id);
egna_traj_data  = evalsTraj(:, :, egna_traj_Id);
gauss_traj_data = evalsTraj(:, :, gauss_traj_Id);
cmaes_traj_data = evalsTraj(:, :, cmaes_traj_Id);

% color settings
% scmaes_gpCol = [255, 165,   0];  % orange (#ffa500)
cedaG_bbobCol = [255,   0,   0];  % light red (#ff0000)
cedaG_trajCol = [255,   0,   0];  % light red (#ff0000)
cedaT_bbobCol = [255,   0, 255];  % magenta (#ff00ff)
cedaT_trajCol = [255,   0, 255];  % magenta (#ff00ff)
egna_bbob1Col = [154, 205,  50];  % yellow grass green (#9acd32)
egna_trajCol  = [154, 205,  50];  % yellow grass green (#9acd32)
egna_bbob2Col = [  0, 127,   0];  % dark forrest green (#007f00)
gauss_bbobCol = [  0,   0, 255];  % middle blue (#0000ff)
gauss_trajCol = [  0,   0, 255];  % middle blue (#0000ff)
cmaes_bbobCol = [  0,   0,   0];  % black (#000000)
cmaes_trajCol = [  0,   0,   0];  % black (#000000)
% bobyqaCol    = [ 12, 240, 248];  % light azure
% smacCol      = [255, 192, 203];  % solomon pink (#ffc0cb)
% fminconCol   = getAlgColors(23); % 23=middle yellow
% fmincon_pureCol = [  0, 127,   0]; % dark forrest green (#007f00)

% scmaesMark      = 'p';
cedaG_bbobMark   = 'o';
cedaG_trajMark   = 'o';
cedaT_bbobMark   = 's';
cedaT_trajMark   = 's';
egna_bbob1Mark  = '^';
egna_bbob2Mark  = '>';
gauss_bbobMark  = '<';
cmaes_bbobMark  = 'x';
cmaes_trajMark  = 'x';
egna_trajMark   = 'v';
gauss_trajMark  = '<';
% bobyqaMark      = '<';
% smacMark        = 'd';
% fminconMark     = '>';
% fmincon_pureMark = 'p';

if (~exist(tmpFName, 'file'))
  save(tmpFName);
end

end


%% BBOB algorithm comparison
% Scaled function values of f1-f24 in dimensions 2, 5, 10 and 20.

for plotDims = [2, 5, 10]
  %%
  data = {...
          cedaG_bbob_data, ...
          cedaT_bbob_data, ...
          egna_bbob1_data, ...
          egna_bbob2_data, ...
          gauss_bbob_data, ...
          cmaes_bbob_data, ...
          ... % ceda_traj_data, ...
          ... % egna_traj_data, ...
          ... % gauss_traj_data, ...
          ... % cmaes_traj_data, ...
          };
  datanames = {...
      'CEDA (Gauss. c.)', ...
      'CEDA (t-copula)', ...
      'EGNAv1', ...
      'EGNAv2', ...
      'GaussianEDA', ...
      'CMA-ES', ...
      ... % 'CEDA', ...
      ... % 'EGNA', ...
      ... % 'GaussianEDA', ...
      ... % 'CMA-ES', ...
      };

  colors = [cedaG_bbobCol; cedaT_bbobCol; egna_bbob1Col; egna_bbob2Col; ...
      gauss_bbobCol; cmaes_bbobCol] / 255;
      % , ceda_trajCol; egna_trajCol; gauss_trajCol; cmaes_trajCol]' / 255;
  markers = {cedaG_bbobMark, cedaT_bbobMark, egna_bbob1Mark, egna_bbob2Mark, ...
      gauss_bbobMark, cmaes_bbobMark};
      % , ceda_trajMark, egna_trajMark, gauss_trajMark, cmaes_trajMark};

  plotFuns = 1:24;

  clear pdfNames
  pdfNames = {};
  for f = plotFuns
    for d = plotDims
      pdfNames{end+1} = fullfile(plotResultsFolder, sprintf('eda_bbob_f%d_%dD', f, d));
    end
  end

  close all
  han = relativeFValuesPlot(data, ...
                                'DataNames', datanames, 'DataDims', funcSet.dims, ...
                                'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                                'PlotFuns', plotFuns(1:(end/2)), 'PlotDims', plotDims, ...
                                'AggregateDims', false, 'OneFigure', false, ...
                                'Statistic', 'quantile', ... 'quantile', ... % @median, ...
                                'Quantiles', [true, true, false(1,4)], ...
                                'AggregateFuns', false, ...
                                'LineSpecification', '-', ...
                                'LineWidth', [ 2, 2, ones(1,4) ], ...
                                'LegendOption', 'split', 'MaxEval', 250, ...
                                'Markers', markers, ...
                                'PlotGrid', [6, 2], ...
                                'ScaleY08', false, ...
                                'FunctionNames', true);

  print2pdf(han, pdfNames(1:(end/2)), 1)

  close all
  han = relativeFValuesPlot(data, ...
                                'DataNames', datanames, 'DataDims', funcSet.dims, ...
                                'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                                'PlotFuns', plotFuns((end/2+1):end), 'PlotDims', plotDims, ...
                                'AggregateDims', false, 'OneFigure', false, ...
                                'Statistic', 'quantile', ... 'quantile', ... % @median, ...
                                'Quantiles', [true, true, false(1,4)], ...
                                'AggregateFuns', false, ...
                                'LineSpecification', '-', ...
                                'LineWidth', [ 2, 2, ones(1,4) ], ...
                                'LegendOption', 'split', 'MaxEval', 250, ...
                                'Markers', markers, ...
                                'PlotGrid', [6, 2], ...
                                'ScaleY08', false, ...
                                'FunctionNames', true);

  print2pdf(han, pdfNames((end/2+1):end), 1)
  close all
end



%{
scmaes_gpCol = [255, 165,   0];  % orange (#ffa500)
dts005Col    = [255,   0,   0];  % light red (#ff0000)
dts_adaptCol = [255,   0, 255];  % magenta (#ff00ff)
maesCol      = [154, 205,  50];  % yellow grass green (#9acd32)
gpopCol      = [  0,   0, 255];  % middle blue (#0000ff)
cmaesCol     = [  0,   0, 128];  % navy blue (#000080)
cmaes2popCol = [  0, 191, 191];  % light petroleum (#00bfbf)
saacmesCol   = [100, 149, 237];  % cornflower blue (#6495ed)
lmmCol       = [173, 255,  47];  % shining light green (#adff2f)
bobyqaCol    = [ 12, 240, 248];  % light azure
smacCol      = [255, 192, 203];  % solomon pink (#ffc0cb)
fminconCol   = getAlgColors(23); % 23=middle yellow
fmincon_pureCol = [  0, 127,   0]; % dark forrest green (#007f00)
%}

%% SAGAS Trajectory

plotDims = [12];

data = {cedaG_traj_data, ...
        cedaT_traj_data, ...
        egna_traj_data, ...
        gauss_traj_data, ...
        cmaes_traj_data, ...
        };
datanames = {...
    'CEDA (Gauss. c.)', ...
    'CEDA (t-copula)', ...
    'EGNA', ...
    'GaussianEDA', ...
    'CMA-ES', ...
    };

colors = [cedaG_trajCol; cedaT_trajCol; egna_trajCol; gauss_trajCol; cmaes_trajCol] / 255;
markers = {cedaG_trajMark, cedaT_trajMark, egna_trajMark, gauss_trajMark, cmaes_trajMark};

plotFuns = 26;

clear pdfNames
pdfNames = {};
for f = plotFuns
  for d = plotDims
    pdfNames{end+1} = fullfile(plotResultsFolder, sprintf('eda_traj_f%d_%dD', f, d));
  end
end

funcSetTraj.BBfunc = [26];
funcSetTraj.dims = [12];

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSetTraj.dims, ...
                              'DataFuns', funcSetTraj.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', 'quantile', ... 'quantile', ... % @median, ...
                              'Quantiles', [true, true, false(1,3)], ...
                              'AggregateFuns', false, ...
                              'LineSpecification', '-', ...
                              'LineWidth', [ 2, 2, ones(1,3) ], ...
                              'LegendOption', 'show', 'MaxEval', 2500, ...
                              'Markers', markers, ...
                              'ScaleY08', false, ...
                              'LogY', false, ...
                              'FunctionNames', false);

ax = gca();
ax.YScale = 'linear';
ax.YLim = [0, 4000];
title('SAGAS Trajectory problem, 12-D')
ylabel('fitness (time in years)');
                            
print2pdf(han, pdfNames, 1);
close all;

% Table with the best fitness values
for i = 1:length(data)
  fmins(i,:) = data{i}{1}(end,:);
end
cellTable = [num2cell(mean(fmins,2)'); num2cell(std(fmins,[],2)')];
lt = LatexTable([{'mean'; 'std. dev.'}, cellTable]);
lt.headerRow = {'', 'CEDA', 'CEDA', '\multirow{2}{*}{EGNA}', 'Gaussian', ...
    '\multirow{2}{*}{CMA-ES}'; ...
    '', 'Gauss. cop.', '$t$-copula', '', 'EDA', ''};
% lt.headerRow = [{''}, datanames];
lt.opts.tableColumnAlignment = num2cell('l c c c c c');
lt.opts.numericFormat = '%.2f';
lt.opts.booktabs = 1;
lt.opts.latexHeader = 0;
latexRows = lt.toStringRows(lt.toStringTable);
% delete the lines \begin{tabular}{...} \toprule
% and              \bottomrule  \end{tabular}
latexRows([1,2,end-1,end]) = [];
% save the result in the file
fid = fopen('../latex_scmaes/lukas_thesis/data/EDA_bestfitness.tex', 'w');
for i = 1:length(latexRows)
  % if (i > 3 && i < length(latexRows) && ~isempty(regexp(latexRows{i}, '^ *\\multirow', 'once')))
  %   fprintf(fid, '\\hline\n');
  % end
  fprintf(fid, '%s\n', latexRows{i});
end
fclose(fid);


%% Aggregated algorithm comparison on BBOB
% Aggregated  scaled function values in dimensions 2, 3, 5, 10

plotDims = [2, 3, 5, 10];

data = {...
        cedaG_bbob_data, ...
        cedaT_bbob_data, ...
        egna_bbob1_data, ...
        egna_bbob2_data, ...
        gauss_bbob_data, ...
        cmaes_bbob_data, ...
        ... % ceda_traj_data, ...
        ... % egna_traj_data, ...
        ... % gauss_traj_data, ...
        ... % cmaes_traj_data, ...
        };
datanames = {...
    'CEDA (Gauss. c.)', ...
    'CEDA (t-copula)', ...
    'EGNAv1', ...
    'EGNAv2', ...
    'GaussianEDA', ...
    'CMA-ES', ...
    ... % 'CEDA', ...
    ... % 'EGNA', ...
    ... % 'GaussianEDA', ...
    ... % 'CMA-ES', ...
    };

colors = [cedaG_bbobCol; cedaT_bbobCol; egna_bbob1Col; egna_bbob2Col; ...
    gauss_bbobCol; cmaes_bbobCol] / 255;
    % , ceda_trajCol; egna_trajCol; gauss_trajCol; cmaes_trajCol]' / 255;
markers = {cedaG_bbobMark, cedaT_bbobMark, egna_bbob1Mark, egna_bbob2Mark, ...
    gauss_bbobMark, cmaes_bbobMark};
    % , ceda_trajMark, egna_trajMark, gauss_trajMark, cmaes_trajMark};

plotFuns = 1:24;

clear pdfNames
pdfNames = {};
for d = plotDims
  pdfNames{end+1} = fullfile(plotResultsFolder, sprintf('eda_bbob_agg_%dD', d));
end

close all
han = relativeFValuesPlot(data, ...
                              'DataNames', datanames, 'DataDims', funcSet.dims, ...
                              'DataFuns', funcSet.BBfunc, 'Colors', colors, ...
                              'PlotFuns', plotFuns, 'PlotDims', plotDims, ...
                              'AggregateDims', false, 'OneFigure', false, ...
                              'Statistic', @median, 'AggregateFuns', true, ...
                              'LineSpecification', '-', ...
                              'LegendOption', 'split', 'MaxEval', 250, ...
                              'Markers', markers, ...
                              'PlotGrid', [2, 2], ...
                              'FunctionNames', true);

print2pdf(han, pdfNames, 1)

%% final clearing
close all
