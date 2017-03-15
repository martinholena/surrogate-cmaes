function [dTable, ranks] = duelTable(data, varargin)
% [rankTable, ranks] = duelTable(data, settings)
% Creates and prints table containing rankings for different evaluations.
%
% Input:
%   data     - cell array of data
%   settings - pairs of property (string) and value or struct with 
%              properties as fields:
%
%     'DataNames'   - cell array of data names (e.g. names of algorithms)
%     'DataDims'    - dimensions of data
%     'DataFuns'    - functions of data
%     'Evaluations' - evaluations chosen to count
%     'Format'      - table format | ('tex', 'figure')
%     'Ranking'     - type of ranking (see help createRankingTable)
%                       'tolerant' - equal rank independence
%                       'precise'  - equal ranks shift following ranks
%                       'median'   - equal ranks replaced by medians of
%                                    shifted ranks (from 'precise')
%     'ResultFile'  - file containing resulting table
%     'Statistic'   - statistic of data | string or handle (@mean, @median)
%     'TableDims'   - dimensions chosen to count
%     'TableFuns'   - functions chosen to count
%
% Output:
%   rankTable - table of rankings
%   ranks     - rankings for each function and dimension
%
% See Also:
%   createRankingTable, speedUpPlot, speedUpPlotCompare, dataReady

  % initialization
  dTable = [];
  if nargin < 1 || isempty(data)
    help duelTable
    return
  end
  settings = settings2struct(varargin);

  numOfData = length(data);
  datanames = defopts(settings, 'DataNames', ...
    arrayfun(@(x) ['ALG', num2str(x)], 1:numOfData, 'UniformOutput', false));
  defaultDims = [2, 3, 5, 10, 20, 40];
  funcSet.dims   = defopts(settings, 'DataDims', defaultDims(1:size(data{1}, 2)));
  funcSet.BBfunc = defopts(settings, 'DataFuns', 1:size(data{1}, 1));
  tableFormat = defopts(settings, 'Format', 'tex');
  dims    = defopts(settings, 'TableDims', funcSet.dims);
  BBfunc  = defopts(settings, 'TableFuns', funcSet.BBfunc);
  evaluations = defopts(settings, 'Evaluations', [1/3, 1]);
  defResultFolder = fullfile('exp', 'pproc', 'tex');
  resultFile = defopts(settings, 'ResultFile', fullfile(defResultFolder, 'duelTable.tex'));
  fileID = strfind(resultFile, filesep);
  resultFolder = resultFile(1 : fileID(end) - 1);
  
  % create ranking table
  extraFields = {'DataNames', 'ResultFile'};
  fieldID = isfield(settings, extraFields);
  createSettings = rmfield(settings, extraFields(fieldID));
  createSettings.Mode = 'target';
  [~, ranks, values] = createRankingTable(data, createSettings);
  
  % if there is R-package for computation of p-values
  countPVal = exist('multComp', 'file');
  pValData = [];
  
  nDim = length(dims);
  for d = 1:nDim
    for e = 1:length(evaluations)
      if countPVal
        fValData = cell2mat(arrayfun(@(x) values{x, d}(e, :), BBfunc, 'UniformOutput', false)');
        pValData{d, e} = multComp(fValData);
      end
      rankData = cell2mat(arrayfun(@(x) ranks{x, d}(e, :), BBfunc, 'UniformOutput', false)');
      dTable{d, e} = createDuelTable(rankData);
    end
  end
  
  % print table
  switch tableFormat
      
    % prints table to latex file
    case {'tex', 'latex'}
      if ~exist(resultFolder, 'dir')
        mkdir(resultFolder)
      end
      
      if nDim > 1
        resultFile = arrayfun(@(x) [resultFile(1:end-4), '_', num2str(x), ...
          'D', resultFile(end-3:end)], dims, 'UniformOutput', false);
      else
        resultFile{1} = resultFile;
      end
      for d = 1:nDim
        FID = fopen(resultFile{d}, 'w');
        printTableTex(FID, dTable(d, :), dims(d), evaluations, datanames, pValData)
        fclose(FID);
        
        fprintf('Table written to %s\n', resultFile{d});
      end
      
    otherwise
      error('Format ''%s'' is not supported.', tableFormat)
  end

end

function dt = createDuelTable(ranks)
% create duel table
% rank of data in row is lower than rank of data in column
  [nFun, nData] = size(ranks);
  
  dt = zeros(nData);
  for f = 1:nFun
    for dat = 1:nData
      id = ranks(f, dat) < ranks(f, :);
      dt(dat, :) = dt(dat, :) + id;
    end
  end
end

function printTableTex(FID, table, dims, evaluations, datanames, pVal)
% Prints table to file FID

  [numOfData, nColumns] = size(table);
  nDims = length(dims);
  nEvals = length(evaluations);
  
  % symbol for number of evaluations reaching the best target
  bestSymbol = '\bestFED';
  
  fprintf(FID, '\\begin{table}\n');
  fprintf(FID, '\\centering\n');
  fprintf(FID, '\\begin{tabular}[pos]{ l %s }\n', repmat([' |', repmat(' c', 1, nEvals)], 1, numOfData+1));
  fprintf(FID, '\\hline\n');
  fprintf(FID, ' %dD ', dims);
  for dat = 1:numOfData
    fprintf(FID, '& \\multicolumn{%d}{c|}{%dD} ', nEvals, datanames{dat});
  end
%   fprintf(FID, '& \\multicolumn{%d}{c}{$\\sum$} \\\\\n', nEvals);
  printString = '';
  for dat = 1:nDims + 1
    for e = 1:nEvals
      printString = [printString, ' & ', num2str(evaluations(e)), bestSymbol];
    end
  end
  fprintf(FID, 'FE/D %s \\\\\n', printString);
  fprintf(FID, '\\hline\n');
  % make datanames equally long
  datanames = sameLength(datanames);
  % find max sums of ranks
  maxTableRanks = max(table);
  % data rows
  for dat = 1:numOfData
    printString = '';
    % columns
    for col = 1:nColumns
      sumRank = table(dat, col);
      if sumRank == maxTableRanks(col)
        % print best data in bold
        printString = [printString, ' & ', '\textbf{', num2str(sumRank), '}'];
      else
        printString = [printString, ' & ', num2str(sumRank)];
      end
    end
    fprintf(FID, '%s%s \\\\\n', datanames{dat}, printString);
  end
  fprintf(FID, '\\hline\n');
  fprintf(FID, '\\end{tabular}\n');
  % evaluation numbers
  evalString = arrayString(evaluations, ',');
  % dimension numbers 
  dimString = arrayString(dims, ',');
  % caption printing
  fprintf(FID, '\\vspace{1mm}\n');
  fprintf(FID, ['\\caption{Counts of the 1st ranks from %d benchmark functions according to the lowest achieved ', ...
                '$\\Delta_f^\\text{med}$ for different FE/D = \\{%s\\} and dimensions D = \\{%s\\}. ', ...
                'Ties of the 1st ranks are counted for all respective algorithms. ', ...
                'The ties often occure when $\\Delta f_T = 10^{-8}$ is reached (mostly on f1 and f5).}\n'], ...
                pVal, evalString, dimString);
               
  fprintf(FID, '\\label{tab:fed}\n');
  fprintf(FID, '\\end{table}\n');
  
end

function str = arrayString(vector, delimiter)
% returns string containing 'vector' elements separated by 'delimiter'
  str = num2str(vector(1));
  for e = 2:length(vector);
    str = [str, delimiter, ' ', num2str(vector(e))];
  end
end

function cellOfStr = sameLength(cellOfStr)
% returns cell array of strings with added empty space to the same length
  maxLength = max(cellfun(@length, cellOfStr));
  cellOfStr = cellfun(@(x) [x, repmat(' ', 1, maxLength - length(x))], cellOfStr, 'UniformOutput', false);
end