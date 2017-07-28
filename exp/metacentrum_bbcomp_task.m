function status = metacentrum_bbcomp_task(exp_id, exppath_short, problemID_str, opts_str)
% metacentrum_bbcomp_task -- Matlab part of BBComp 2017 competition scripts to be MCR-compiled
%
% Usage:
%   metacentrum_bbcomp_task(exp_id, exppath_short, problemID_str, opts_str)

  % Input parameter settings
  %
  % ID/opts input parse settings
  if (~exist('problemID_str', 'var'))
    problemID_str = []; end
  if (~exist('opts_str', 'var'))
    opts_str = []; end

  id            = parseCmdParam('problemID_str', problemID_str, 1:5);
  cmd_opts      = parseCmdParam('opts_str', opts_str, struct());

  % run the script EXP_ID.m if it exists
  opts = struct();
  expScript = fullfile(exppath_short, [exp_id '.m']);
  if (exist(expScript, 'file'))
    % eval the script line by line (as it cannot be run()-ed when deployed)
    fprintf('Running the script ''%s''...\n', expScript);
    fid = fopen(expScript);
    tline = fgetl(fid);
    while (ischar(tline))
      eval(tline);
      tline = fgetl(fid);
    end
    fclose(fid);
  end
  % and re-write the options specified on command-line
  if (isstruct(cmd_opts) && ~isempty(cmd_opts))
    cmd_fnames = fieldnames(cmd_opts);
    for i = 1:length(cmd_fnames)
      opts.(cmd_fnames{i}) = cmd_opts.(cmd_fnames{i});
    end
  end

  % EXPID -- unique experiment identifier (directory in where
  %          the results are expected to be placed)
  opts.exp_id     = exp_id;
  % EXPPATH_SHORT
  opts.exppath_short = exppath_short;
  opts.exppath = [exppath_short filesep exp_id];
  RESULTSFILE = [opts.exppath '/' exp_id '_results_' num2str(id) '.mat'];
  if (isempty(getenv('SCRATCHDIR')))
    username = getenv('USER');
    OUTPUTDIR = sprintf('/tmp/%s_%d/job_output', username, id);;     % set OUTPUTDIR empty if $SCRATCHDIR var does not exist
  else
    OUTPUTDIR = [getenv('SCRATCHDIR') filesep 'job_output'];
  end
  [~, ~] = mkdir(OUTPUTDIR);

  % datapath is typically on the computing node in   $SCRATCHDIR/job_output/bbcomp_output:
  datapath = [OUTPUTDIR filesep 'bbcomp_output'];
  if (isempty(strfind(datapath, exppath_short)))
    % localDatapath is typically on the NFS server in
    %   $HOME/prg/surrogate-cmaes/exp/experiments/$EXPID/bbcomp_output_tmp
    % and the bbcomp results are stored here after each completed instance
    localDatapath = [opts.exppath filesep 'bbcomp_output_tmp'];
    [~, ~] = mkdir(localDatapath);
  end
  [~, ~] = mkdir(datapath);
  surrogateParams.datapath = datapath;

  % Metacentrum task and node properties
  cmd_opts.machine = '';
  nodeFile = fopen(getenv('PBS_NODEFILE'), 'r');
  if (nodeFile > 0)
    cmd_opts.machine = fgetl(nodeFile);
    fclose(nodeFile);
  end

  try
    [bbc_client, dim, maxfunevals, loadedevals, flgresume] = init_bbc_client(bbcompParams, datapath, id);
    % Wait 5 mins due to the CPU limit for the job
    pause(360);
  catch ME
    fields = strsplit(ME.identifier, ':');
    if strcmp(fields{1}, 'BbcClient')
      error('Could not initialize BBCOMP client: %s. Error message:\n%s', ...
          ME.identifier, ME.message);
    else
      rethrow(ME);
    end
  end

  % copy log files from the previous run
  localDatapathPrev = [opts.exppath filesep 'bbcomp_output'];
  if (exist(localDatapathPrev, 'file') && ~strcmp(datapath, localDatapathPrev))
    cmd = ['cp -pR ' localDatapathPrev '/proxy_logs/*_' num2str(id-1) '.log* ' ...
      localDatapathPrev filesep sprintf('%s_{log,eclog,cmaesvars}_%dD_%d* ', exp_id, dim, id) ...
      datapath ...
    ];
    fprintf('Copying files from the previous run: \n');
    fprintf(cmd);
    system(cmd);
  end

  % DEBUG
%   FUN = @frosen;
%   dim = 2;
%   maxfunevals = 10000;
  % /DEBUG

  fprintf('==== Summary of the testing assignment ====\n');
  fprintf('     problemID:    %s\n', num2str(id));
  fprintf('     dimension:    %s\n', num2str(dim));
  fprintf('   maxfunevals:    %s\n', num2str(maxfunevals));
  fprintf('selected track:    %s\n', bbcompParams.trackname);
  fprintf('===========================================\n');

  % Other different settings, mostly for logging purposes
  opts.expFileID = defopts(opts, 'expFileID', [num2str(dim) 'D_' num2str(id)]);
  surrogateParams.datapath  = datapath;
  surrogateParams.exp_id    = opts.exp_id;
  surrogateParams.expFileID = opts.expFileID;
  surrogateParams.instance  = id;
  exp_settings.maxfunevals  = maxfunevals;
  exp_settings.dim          = dim;
  exp_settings.id           = id;
  exp_settings.trackname    = bbcompParams.trackname;

  % CMA-ES saving & resume settings
  cmaesParams.SaveFilename = eval(cmaesParams.SaveFilename);
  cmaesParams.Resume = flgresume;
  cmaesParams.counteval = loadedevals;

  % Matlab should have been called from a SCRACHDIR
  startup;

  t0 = clock;
  % Initialize random number generator
  exp_settings.seed = myeval(defopts(cmd_opts, 'seed', 'floor(sum(100 * clock()))'));
  rng(exp_settings.seed);

  %
  %
  % the computation itself
  %

  FUN = @(x) bbc_client.safeEvaluate(x, id, bbcompParams.trackname);

  surrogateParams.archive = Archive(dim);
  surrogateParams.startTime = tic;
  xstart = sprintf(['cmaesRestartPoint(surrogateOpts.archive, ', ...
                    '''NumSamples'', %d, ', ...
                    '''DistanceRatio'', 1/10, ', ...
                    '''LBound'', %s, ', ...
                    '''UBound'', %s ', ...
                    ')'], ...
                   ceil(100*sqrt(dim)), ...
                   printStructure(0.1*ones(dim, 1), 'Format', 'value'), ...
                   printStructure(0.9*ones(dim, 1), 'Format', 'value'));
  fmin = Inf;
  yeRestarts = [];
  y_evals = cell(0);
  restarts = -1;

  exp_results.evals = [];
  exp_results.restarts = [];
  exp_results.fbests = [];
  exp_results.f025 = [];
  exp_results.f050 = [];
  exp_results.f075 = [];
  exp_results.stopflags = {};
  exp_results.time = 0;
  remainingEvals = maxfunevals - loadedevals;

  % === independent RESTARTS cycle ===
  while remainingEvals > 0

    restarts = restarts + 1;
    t = tic;

    %
    % optimize bbcomp function using scmaes or bobyqa depending on budget
    %
    if maxfunevals / dim <= 15
      [x, ye, stopflag, archive, varargout] = opt_bobyqa_bbcomp(FUN, dim, ...
          remainingEvals, bobyqaParams, xstart);

      evals = bbc_client.getEvaluations();
      archive.X = zeros(evals, dim);
      archive.y = zeros(evals, 1);
      remainingEvals = maxfunevals - evals;
    else
      if (restarts == 0)
        % this is needed due to loading of interrupted CMA-ES state
        % from _cmaesvars_ log file
        thisRestartMaxFunEvals = maxfunevals;
      else
        thisRestartMaxFunEvals = remainingEvals;
      end
      [x, ye, stopflag, archive, varargout] = opt_s_cmaes_bbcomp(FUN, dim, ...
          thisRestartMaxFunEvals, cmaesParams, surrogateParams, xstart);

      remainingEvals = remainingEvals - (varargout.evals - loadedevals);
      loadedevals = 0;

      % this is needed due to loading of interrupted CMA-ES state:
      cmaesParams.counteval = 0;
      cmaesParams.Resume = false;
      % other option here is:
      %   cmaesParams.counteval = varargout.evals;
      % but it will fool surrogateManager and maybe CMA-ES as well
      % since the next restart of the CMA-ES would not start 
      % with counteval == 0
      surrogateParams.archive = archive;
    end

    % #FE restart correction
    if (fmin < Inf)
        ye(:, 1) = min([ye(:, 1) repmat(fmin, size(ye, 1), 1)], [], 2);
        ye(:, 2) = ye(:, 2) + yeRestarts(end, 2);
    end
    fmin = min([ye(:, 1); fmin]);
    yeRestarts = [yeRestarts; ye];

    elapsedTime = toc(t);
    y_evals = cat(1,y_evals,yeRestarts);

    % save results
    exp_results.evals(end+1)     = size(archive.X, 1);
    exp_results.restarts(end+1)  = restarts;
    exp_results.fbests(end+1)    = min(y_evals{end}(:,1));
    exp_results.f025(end+1)      = y_evals{end}( max([1 floor(size(y_evals{end},1)/4)]) ,1);
    exp_results.f050(end+1)      = y_evals{end}( max([1 floor(size(y_evals{end},1)/2)]) ,1);
    exp_results.f075(end+1)      = y_evals{end}( max([1 floor(3*size(y_evals{end},1)/4)]) ,1);
    exp_results.stopflags{end+1} = stopflag;
    exp_results.y_evals          = y_evals;
    exp_results.time             = exp_results.time + elapsedTime;
    exp_results.remainingEvals   = remainingEvals;

    % warn if the archive contains Inf f-values
    infYArchive = isinf(archive.y);
    if any(infYArchive)
      warning('The archive contains %d infinite function values on id = %s.', ...
               sum(infYArchive), printStructure(find(infYArchive), 'Format', 'value'))
      archive = archive.delete(infYArchive);
    end
    % MAX_ARCHIVE_LENGTH = 4000;
    % if (length(archive.y) > MAX_ARCHIVE_LENGTH)
    %   fprintf('Archive is too big. Cropping only to %d points\n', MAX_ARCHIVE_LENGTH);
    %   archive = archive.delete(1:(length(archive.y) - MAX_ARCHIVE_LENGTH));
    % end

    save(RESULTSFILE, 'exp_id', 'archive', 'exp_settings', 'exp_results', 'surrogateParams', 'cmaesParams', 'y_evals', 'bbcompParams')

  end  % === independent RESTARTS cycle ===

  % print history
  fprintf('Historical fitness values:\n');
  if maxfunevals / dim <= 15
    evals = bbc_client.getEvaluations();
    for i = 0:(evals-1)
      [~, value] = bbc_client.history(i);
      fprintf('%d: %e\n', i, value);
    end
  end

  bbc_client.cleanup();
  clear bbc_client;

  % copy the bbcomp results onto persistant storage if outside EXPPATH
  if (~isempty(OUTPUTDIR) && ~strcmpi(OUTPUTDIR, opts.exppath) && isunix)
    % compress proxy logs
    logfiles = [eval(bbcompParams.logfilepath) filesep '*_' num2str(id-1) '.log'];
    system(['rename ''s/.bzip2/.bak.bzip2/'' ' logfiles '.bzip2']);
    system(['echo ' logfiles ' | grep -q ''\*'' || bzip2 -z ' logfiles]);

    % copy the output to the final storage (if OUTPUTDIR and EXPPATH differs)
    system(['cp -pR ' OUTPUTDIR '/* ' opts.exppath '/']);
  end

  status = 0;
  return;
end

function out = parseCmdParam(name, value, defaultValue)
  if (isempty(value))
    out = defaultValue;
  elseif (ischar(value))
    out = myeval(value);
  else
    error('%s has to be string for eval()-uation', name);
  end
end

function [bbc_client, dim, maxfunevals, evals, flgresume] = init_bbc_client(bbcompParams, datapath, id)
  % initialization of the BBCOMP client
  % addpath(bbcompParams.libpath); % needed for the dynamic library

  bbc_client = BbcClientTcp(bbcompParams.proxyHostname, ...
    bbcompParams.proxyPort + id, ...
    bbcompParams.username, bbcompParams.password, ...
    bbcompParams.proxyTimeout, bbcompParams.proxyConnectTimeout, ...
    bbcompParams.maxTrials, bbcompParams.loginDelay);

  % some robustness to network failures is achived by retrying
  % initialization
  trial = 1;
  while trial < bbcompParams.maxTrials
    try
      logfilepath = eval(bbcompParams.logfilepath);
      [~, ~] = mkdir(logfilepath);
      logfiles = [logfilepath filesep '*_' num2str(id-1) '.log.bz2'];
      system(['echo ' logfiles ' | grep -q ''\*'' || bzip2 -d ' logfiles]);
      bbc_client.configure(bbcompParams.loghistory, logfilepath);
      bbc_client.safeLogin();
      bbc_client.safeSetTrack(bbcompParams.trackname);
      numProblems = bbc_client.getNumberOfProblems();

      if (id > numProblems)
        error('Input problem id is %d, but maximum number of BBCOMP problems is %d', ...
          id, numProblems);
      else
        bbc_client.safeSetProblem(id, bbcompParams.trackname);
      end

      dim = bbc_client.getDimension();
      maxfunevals = bbc_client.safeGetBudget(id, bbcompParams.trackname);

      evals = bbc_client.safeGetEvaluations(id, bbcompParams.trackname);
      if evals
        flgresume = bbcompParams.tryRecovery;
        if flgresume
          warning('%d / %d evaluations already consumed, attempting recovery.', ...
            evals, maxfunevals);
        else
          error('%d / %d evaluations already consumed, giving up.', ...
            evals, maxfunevals);
        end
      else
        flgresume = false;
      end

      break;

    catch ME
      if strcmp(ME.identifier, 'BbcClient:call')
        warning('BbcClient initialization in trial %d / %d failed.\n%s.', ...
            trial, bbcompParams.maxTrials, getReport(ME));
        pause(bbcompParams.loginDelay);
        trial = trial + 1;
      else
        rethrow(ME);
      end
    end
  end
end