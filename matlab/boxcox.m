function [bct, bclambda] = boxcox(varargin)
%BOXCOX transforms non-normally distributed data to normally distributed data.
%
%   [TRANSDAT, LAMBDA] = boxcox(DATA) transforms the data vector DATA using
%   the Box-Cox Transformation method into the vector TRANSDAT.  It also
%   calculates the transformation parameter LAMBDA.  DATA must be positive.
%   The Box-Cox Transformation is the family of power transformation:
%
%      DATA(LAMBDA) = ((DATA^LAMBDA) - 1) / LAMBDA;     if LAMBDA ~= 0,
%
%   or
%
%      DATA(LAMBDA) = log(DATA);                        if LAMBDA == 0.
%
%   Here, 'log' is the natural logarithm (log base e).  The algorithm calls
%   for finding the LAMBDA value that maximizes the Log-Likelihood Function
%   (LLF).  The search is conducted using FMINSEARCH.
%
%   TRANSDAT = boxcox(LAMBDA, DATA) transforms the data vector DATA using
%   a certain specified LAMBDA for the Box-Cox Transformation.  This syntax
%   does not find the optimum LAMBDA that maximizes the LLF.  DATA must be
%   positive.
%
%   Example:
%
%        load disney.mat
%        % Look at the non-NaN data only
%        X = dis_CLOSE(~isnan(dis_CLOSE));
%        [Xbc, lambdabc] = boxcox(X);
%        hist(Xbc);
%
%   See also FMINSEARCH.

%   Copyright 1995-2013 The MathWorks, Inc.


    % Input checks.
    switch nargin

        case 1
            x = varargin{1};
            stdlambdas=[-3,-2,-1,-0.5,0,0.25,0.5,1,2,3,4];
        case 2
            x = varargin{1};
            stdlambdas=varargin{2};
    end
    % Syntax:  BCT = boxcox(DATA);
    % Find the maximum log-likelihood lambda and compute the transform

    % Get the data vector.
    
    if ~isvector(x)
        error('finance:ftseries:ftseries_boxcox',':InputMustBeVector');
    end
    if any(x <= 0)
        error('finance:ftseries:ftseries_boxcox',':DataMustBePositive');
    end
        
    % Find the lambda that minimizes of the Log-Likelihood function;
    % FMINSEARCH is used here so that we don't need to provide a set
    % of boundary initial conditions.  We only need a number as the
    % starting point of search.

    objectiveFun = @(l) logLikelihood(l,x);
    options = optimset('MaxFunEvals', 2000, 'Display', 'off');
    bclambda = fminsearch(objectiveFun, 0, options);
    
    % get closest std lambda
    diff=abs(stdlambdas-bclambda);
    [mindiff,minindex]=min(diff);
    closeststdlambda=stdlambdas(minindex);
    bclambda=closeststdlambda;
    % Generate the transformed data using the optimal lambda.
    bct = bcTransform(bclambda,x);
        
    
%     case 2
%         
%         % Syntax:  BCT = boxcox(LAMBDA, DATA);
%         % Compute the transform for a given lambda
%         
%         % Get the lambda and data vectors.
%         lambda = varargin{1};
%         x = varargin{2};
%         
%         bct = bcTransform(lambda,x);
%         
%     otherwise
%         
%         error(message('finance:ftseries:ftseries_boxcox:TooManyInputArguments'));
        


function llf = logLikelihood(lambda,x)
% Compute the log likelihood function for a given lambda and x

% Get the length of the data vector.
n = length(x);

% Transform data using a particular lambda.
xhat = bcTransform(lambda,x);

% The algorithm calls for maximizing the LLF; however, since we
% have only functions that minimize, the LLF is negated so that we
% can minimize the function instead of maximixing it to find the
% optimum lambda.
llf = -(n/2) .* log(std(xhat, 1, 1)' .^ 2) + (lambda-1)*(sum(log(x)));
llf = -llf;




