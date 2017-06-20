classdef ECSaver < Observer
  %ECSAVER -- save evolution control object into a *.mat file
  properties
    datapath
    exp_id
    expFileID
    file
    maxArchSaveLen
  end
  
  methods
    function obj = ECSaver(params)
      obj@Observer();
      obj.datapath = defopts(params, 'datapath', '/tmp');
      obj.exp_id    = defopts(params, 'exp_id', datestr(now,'yyyy-mm-dd_HHMMSS'));
      obj.expFileID = defopts(params, 'expFileID', '');
      obj.file  = [obj.datapath filesep obj.exp_id '_eclog_' obj.expFileID];
      obj.maxArchSaveLen = defopts(params, 'maxArchSaveLen', 1e6);
    end

    function notify(obj, ec, varargin)
      % This loading is, IMHO, not necessary (bajeluk):
      % if (exist(obj.file, 'file'))
      %   eclog = load(obj.file);
      % else
      %   eclog = struct();
      % end

      eclog = struct();
      countiter = ec.cmaesState.countiter;

      eclog.ec = ec;
      if length(eclog.ec.archive.y) > obj.maxArchSaveLen
        % clear the rest of the archive when it is too large
        la = length(eclog.ec.archive.y);
        eclog.ec.archive = ec.archive.duplicate();
        eclog.ec.archive = eclog.ec.archive.delete((obj.maxArchSaveLen+1):la);
      end

      save([obj.file '_' num2str(countiter)], '-struct', 'eclog');
      if countiter > 2
        oldfilename = eval('[obj.file ''_'' num2str(countiter-2) ''.mat'']');
        if exist(oldfilename, 'file')
          delete_cmd = ['delete ' oldfilename];
          eval(delete_cmd);
        end
      end
    end
  end

end
