classdef HillClimbingObliqueSplit < RandomSplit
% HillClimbingObliqueSplit starts with a random hyperplane (or with some
% good axis parallel hyperplane) and deterministically perturbates
% the hyperplane's direction in each axis to maximize the split gain. Once
% no improvement is possible, performs a number of random jumps as an
% attempt to escape local maxima. If some random jump succeeds,
% deterministic perturbation is performed again.
  
  properties
    split_X1 % X with intercept
    split_nQuantize % quantization of tresholds 
                    %   0 - all tresholds for one dimension or perturbation
                    %   1, 2, 3, ... number of linearly distributed 
                    %   tresholds per dimension or perturbation
    split_nRandomPerturbations % number of random perturbations
    split_remainHyp % number of remaining hyperplanes available to test 
                    % (according to split_maxHyp property)
  end

  methods
    function obj = HillClimbingObliqueSplit(options)
      obj = obj@RandomSplit(options);
      obj.split_nQuantize = defopts(options, 'split_nQuantize', 0);
      obj.split_nRandomPerturbations = defopts(options, 'split_nRandomPerturbations', 10);
    end
    
    function obj = reset(obj, X, y)
    % sets new transformed input
      obj = reset@RandomSplit(obj, X, y);
      obj.split_X1 = generateFeatures(obj.split_X, 'linear', true, true);
    end

    function best = get(obj, splitGain)
    % returns the split with max splitGain
      best = obj.splitCandidate;
      if obj.split_allEqual
        return
      end
      [nData, dim] = size(obj.split_X);
      % get number of remaining splits
      obj.split_remainHyp = obj.getMaxHyp(nData, dim);
      for iRepeats = 1:obj.split_nRepeats
        if iRepeats == 1
          [candidate, obj] = obj.getAxisHyperplane(splitGain);
        else
          [candidate, obj] = obj.getRandomHyperplane(splitGain);
        end
        [candidate, obj] = obj.hillClimb(splitGain, candidate);
        if candidate.gain > best.gain
          best = candidate;
        end
      end
    end
  end
  
  methods (Access = private)
    function [best, obj] = getAxisHyperplane(obj, splitGain)
    % get axis paralel hyperplane
      best = obj.splitCandidate;
      trans = obj.split_transformation;
      [~, d] = size(obj.split_X);
      % dimension loop
      % search dimensions in random order due to the limited number of 
      % hyperplanes
      for feature = randperm(d)
        if obj.split_remainHyp > 0
          featureSelector = (1:d == feature)';
          values = obj.split_X(:, feature)';
          tresholds = obj.calcTresholds(values, d);
          % calculate gain for each treshold in random order due to the
          % limited number of hyperplanes
          for treshold = tresholds(randperm(numel(tresholds)))
            if obj.split_remainHyp > 0
              candidate = obj.splitCandidate;
              candidate.splitter = @(X)...
                transformApply(X, trans) * featureSelector <= treshold;
              [candidate.gain, candidate.leftID, candidate.rightID] = splitGain.get(candidate.splitter);
              candidate.feature = feature;
              candidate.treshold = treshold;
              if candidate.gain > best.gain
                best = candidate;
              end
              obj.split_remainHyp = obj.split_remainHyp - 1;
            end
          end % treshold
        end
      end % dimension
      
      % successful splits
      if best.gain > -Inf
        best.H = [zeros(1, d), -best.treshold]';
        best.H(best.feature) = 1;
      elseif obj.split_remainHyp > 0
        % axis splitting not successful, try random hyperplane
        [best, obj] = obj.getRandomHyperplane(splitGain);
      end
    end
    
    function [candidate, obj] = getRandomHyperplane(obj, splitGain)
    % get hyperplane at random
      [~, d] = size(obj.split_X);
      H = tan(rand(1, d+1)' * pi - pi/2);
      candidate = obj.getSplit(splitGain, H);
      candidate.H = H;
      obj.split_remainHyp = obj.split_remainHyp - 1;
    end
    
    function [best, obj] = hillClimb(obj, splitGain, best)
    % OC1 Hill Climbing
      d = size(obj.split_X, 2);
      pStag = 0.1;
      pMove = pStag;
      J = obj.split_nRandomPerturbations;
      while J > 0 && obj.split_remainHyp > 0
        improvement = true;
        while improvement && obj.split_remainHyp > 0
          improvement = false;
          % search dimensions in random order due to the limited number of 
          % hyperplanes
          for feature = randperm(d+1)
          % perturbation for a single coefficient
            [candidate, obj] = obj.deterministicPerturb(splitGain, best, feature);
            if candidate.gain > best.gain
              best = candidate;
              pMove = pStag;
              improvement = true;
            elseif candidate.gain == best.gain
              if rand() < pMove
                best = candidate;
                pMove = pMove - 0.1 * pStag;
              end
            end
          end
        end
        while J > 0 && obj.split_remainHyp > 0
          % random perturbation
          [candidate, obj] = obj.randomPerturb(splitGain, best);
          if candidate.gain > best.gain
            best = candidate;
            break;
          end
          J = J - 1;
        end
      end
    end
    
    function [best, obj] = deterministicPerturb(obj, splitGain, best, feature)
    % create candidate using deterministic perturbation
      V = obj.split_X1 * best.H;
      U = (best.H(feature) * obj.split_X1(:, feature) - V) ...
        ./ obj.split_X1(:, feature);
      H = best.H;
      values = U';
      dim = size(obj.split_X1, 2);
      % calculate tresholds
      tresholds = obj.calcTresholds(values, dim);
      % calculate gains for each treshold
      % search tresholds in random order due to the limited number of 
      % hyperplanes
      for treshold = tresholds(randperm(numel(tresholds)))
        if obj.split_remainHyp > 0
          if isinf(treshold) || isnan(treshold)
            continue
          end
          H(feature) = treshold;
          candidate = obj.getSplit(splitGain, H);
          if candidate.gain > best.gain
            best = candidate;
          end
          obj.split_remainHyp = obj.split_remainHyp - 1;
        end
      end
    end
    
    function [best, obj] = randomPerturb(obj, splitGain, best)
    % create candidate using random perturbation
      if obj.split_remainHyp > 0
        r = randn(size(best.H));
        r = max(-pi/2, r);
        r = min(pi/2, r);
        r = tan(r);
        H = best.H + r;
        best = obj.getSplit(splitGain, H);
        obj.split_remainHyp = obj.split_remainHyp - 1;
      end
    end
    
    function candidate = getSplit(obj, splitGain, H)
      candidate = obj.splitCandidate;
      candidate.splitter = obj.createSplitter(@(X) ...
        generateFeatures(X, 'linear', true, true) * H);
      [candidate.gain, candidate.leftID, candidate.rightID] = splitGain.get(candidate.splitter);
      candidate.H = H;
    end
  end
end