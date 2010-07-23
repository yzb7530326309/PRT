classdef prtClassMap < prtClass
 %prtClassMap  Maximum a Posteriori classifier
 % 
 %    CLASSIFIER = prtClassMap returns a Maximum a Posteriori classifier
 %
 %    CLASSIFIER = prtClassMap(PROPERTY1, VALUE1, ...) constructs a
 %    prtClassMAP object CLASSIFIER with properties as specified by
 %    PROPERTY/VALUE pairs.
 %
 %    A prtClassMap object inherits all properties from the abstract class
 %    prtClass. In addition is has the following property:
 %
 %    rvs    - A multivariate normal random variable. This property must be of
 %             type prtRvMvn. This property describes the mean and covariance
 %             matrix required for Maximum a Posteriori classification. It is
 %             writable, or can be set using the Train method.
 %
 %    A prtClassMap object inherits the TRAIN and RUN methods from prtClass.
 %  
 %    See also prtClass, prtClass.train, prtClass.run, prtClass.plot, prtClass.plotDecision, prtRvMvn
 
    properties (SetAccess=private)
        % Required by prtAction
        name = 'Maximum a Posteriori'
        nameAbbreviation = 'MAP'
        isSupervised = true;
        
        % Required by prtClass
        isNativeMary = true;
    end
    
    properties
        % General Classifier Properties
        rvs = prtRvMvn; % prtRv Objects (will be repmated as needed)
    end
    
    methods
        % Constructor
        function Obj = prtClassMap(varargin)
            % Allow for string, value pairs
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
        end
        % Set function
        function Obj = set.rvs(Obj,val)
            if(~ isa(val, 'prtRvMvn'))
                error('prtClassMAP:rvs','Rvs parameter must be of class prtRvMvn');
            else
                Obj.rvs = val;
            end
        end
    end
    
    methods (Access = protected)
        
        function Obj = trainAction(Obj,DataSet)
            % Repmat the rv objects to get one for each class
            Obj.rvs = repmat(Obj.rvs(:), (DataSet.nClasses - length(Obj.rvs)+1),1);
            Obj.rvs = Obj.rvs(1:DataSet.nClasses);

            % Get the ML estimates of the RV parameters for each class
            for iY = 1:DataSet.nClasses
                Obj.rvs(iY) = mle(Obj.rvs(iY), DataSet.getObservationsByClassInd(iY));
            end
        end
        
        function DataSet = runAction(Obj,DataSet)
            
            logLikelihoods = zeros(DataSet.nObservations, length(Obj.rvs));
            for iY = 1:length(Obj.rvs)
                logLikelihoods(:,iY) = logPdf(Obj.rvs(iY), DataSet.getObservations());
            end

            % Change to posterior probabilities and package everything up in a
            % prtDataSet
            DataSet = prtDataSetClass(exp(bsxfun(@minus, logLikelihoods, prtUtilSumExp(logLikelihoods.').')));
            DataSet.UserData.logLikelihoods = logLikelihoods;
        end
        
    end
    
end