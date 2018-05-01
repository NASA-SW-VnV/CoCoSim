classdef (InferiorClasses = {? matlab.graphics.axis.Axes, ? matlab.ui.control.UIAxes}) tf < numlti
   %TF  Construct transfer function or convert to transfer function.
   %
   %  Construction:
   %    SYS = TF(NUM,DEN) creates a continuous-time transfer function SYS with
   %    numerator NUM and denominator DEN. SYS is an object of type TF when
   %    NUM,DEN are numeric arrays, of type GENSS when NUM,DEN depend on tunable
   %    parameters (see REALP and GENMAT), and of type USS when NUM,DEN are
   %    uncertain (requires Robust Control Toolbox).
   %
   %    SYS = TF(NUM,DEN,TS) creates a discrete-time transfer function with
   %    sample time TS (set TS=-1 if the sample time is undetermined).
   %
   %    S = TF('s') specifies the transfer function H(s) = s (Laplace variable).
   %    Z = TF('z',TS) specifies H(z) = z with sample time TS.
   %    You can then specify transfer functions directly as expressions in S
   %    or Z, for example,
   %       s = tf('s');  H = exp(-s)*(s+1)/(s^2+3*s+1)
   %
   %    SYS = TF creates an empty TF object.
   %    SYS = TF(M) specifies a static gain matrix M.
   %
   %    You can set additional model properties by using name/value pairs.
   %    For example,
   %       sys = tf(1,[1 2 5],0.1,'Variable','q','IODelay',3)
   %    also sets the variable and transport delay. Type "properties(tf)"
   %    for a complete list of model properties, and type
   %       help tf.<PropertyName>
   %    for help on a particular property. For example, "help tf.Variable"
   %    provides information about the "Variable" property.
   %
   %    By default, transfer functions are displayed as functions of 's' or 'z'.
   %    Alternatively, you can use the variable 'p' in continuous time and the
   %    variables 'z^-1', 'q', or 'q^-1' in discrete time by modifying the
   %    "Variable" property.
   %
   %  Data format:
   %    For SISO models, NUM and DEN are row vectors listing the numerator
   %    and denominator coefficients in descending powers of s,p,z,q or in
   %    ascending powers of z^-1 (DSP convention). For example,
   %       sys = tf([1 2],[1 0 10])
   %    specifies the transfer function (s+2)/(s^2+10) while
   %       sys = tf([1 2],[1 5 10],0.1,'Variable','z^-1')
   %    specifies (1 + 2 z^-1)/(1 + 5 z^-1 + 10 z^-2).
   %
   %    For MIMO models with NY outputs and NU inputs, NUM and DEN are
   %    NY-by-NU cell arrays of row vectors where NUM{i,j} and DEN{i,j}
   %    specify the transfer function from input j to output i. For example,
   %       H = tf( {-5 ; [1 -5 6]} , {[1 -1] ; [1 1 0]})
   %    specifies the two-output, one-input transfer function
   %       [     -5 /(s-1)      ]
   %       [ (s^2-5s+6)/(s^2+s) ]
   %
   %  Arrays of transfer functions:
   %    You can create arrays of transfer functions by using ND cell arrays
   %    for NUM and DEN above. For example, if NUM and DEN are cell arrays
   %    of size [NY NU 3 4], then
   %       SYS = TF(NUM,DEN)
   %    creates the 3-by-4 array of transfer functions
   %       SYS(:,:,k,m) = TF(NUM(:,:,k,m),DEN(:,:,k,m)),  k=1:3,  m=1:4.
   %    Each of these transfer functions has NY outputs and NU inputs.
   %
   %    To pre-allocate an array of zero transfer functions with NY outputs
   %    and NU inputs, use the syntax
   %       SYS = TF(ZEROS([NY NU k1 k2...])) .
   %
   %  Conversion:
   %    SYS = TF(SYS) converts any dynamic system SYS to the transfer function
   %    representation. The resulting SYS is always of class TF.
   %
   %  See also TF/EXP, FILT, TFDATA, ZPK, SS, FRD, GENSS, USS, DYNAMICSYSTEM.
   
%   Author(s): P. Gahinet
%   Copyright 1986-2012 The MathWorks, Inc.
   
   % Add static method to be included for compiler
   %#function ltipack.utValidateTs
   %#function tf.loadobj
   %#function tf.make
   %#function tf.convert

   % Public properties with restricted value
   properties (Access = public, Dependent)
      % Numerator coefficients (cell array of row vectors).
      %
      % The "Numerator" property stores the transfer function numerator(s).
      % For SISO transfer functions, set "Numerator" to the row vector of
      % numerator coefficients. For all variables but 'z^-1' and 'q^-1',
      % the vector [1 2 3] is interpreted as the polynomial s^2+2s+3. For
      % the 'z^-1' and 'q^-1' variables, [1 2 3] is interpreted as the
      % polynomial 1 + 2 z^-1 + 3 z^-2.
      %
      % For MIMO transfer functions with Ny outputs and Nu inputs, set
      % "Numerator" to the Ny-by-Nu cell array of numerator coefficients
      % for each I/O pair. For example,
      %    num = {[1 0] , 1     ; 3 , [1 2 3]}
      %    den = {[1 2] , [1 1] ; 1 , [5 2]  }
      %    H = tf(num,den)
      % specifies the two-input, two-output transfer function:
      %    [ s/(s+2)            1/(s+1)  ]
      %    [ 3/1       (s^2+2s+3)/(5s+2) ]
      Numerator
      % Denominator coefficients (cell array of row vectors).
      %
      % Counterpart of "Numerator" for the denominator coefficients, type
      % "help tf.Numerator" for details.
      Denominator
      % Transfer function variable (string, default = 's' or 'z').
      %
      % You can set this property to either 's' or 'p' in continuous time,
      % and to 'z', 'q', 'z^-1', or 'q^-1' in discrete time. Note that s and p 
      % are equivalent and so are z and q.
      % 
      % The "Variable" setting is reflected in the display and also affects
      % the discrete-time interpretation of the num,den vectors. For 
      % Variable='z' or 'q', the vector [1 2 3] is interpreted as z^2 + 2 z + 3 
      % (descending powers of z). For Variable='z^-1' or 'q^-1', however, 
      % [1 2 3] is interpreted as 1 + 2 z^-1 + 3 z^-2 (ascending powers of z^-1).
      Variable
      % Transport delays (numeric array, default = all zeros).
      %
      % The "IODelay" property specifies a separate time delay for each 
      % I/O pair. For continuous-time systems, specify I/O delays in
      % the time unit stored in the "TimeUnit" property. For discrete-
      % time systems, specify I/O delays as integer multiples of the
      % sampling period "Ts", for example, IODelay=2 to mean a delay
      % of two sampling periods.
      %
      % For MIMO transfer functions with Ny outputs and Nu inputs, set 
      % "IODelay" to a Ny-by-Nu matrix. You can also set this property to 
      % a scalar value to apply the same delay to all I/O pairs.
      %
      % Example: sys.IODelay = [0 , 1.2 ; 0.5 , 0] specifies nonzero
      % transport delays from input 1 to output 2 and from input 2 to
      % output 1.
      IODelay
   end

   properties (Access = protected)
      % Storage for Variable property
      Variable_  % type = string
   end
   
   % OBSOLETE PROPERTIES
   properties (Access = public, Dependent, Hidden)
      % Obsolete property, shortened to IODelay.
      ioDelayMatrix
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = inferiorTypes()
         T = {'pidstd','pid','pidstd2','pid2'};
      end
      
      function boo = isClosed(op)
         boo = ~strcmp(op,'connect');
      end
      
      function T = toClosed(~)
         % Convert to SS for CONNECT (TF is impractical/dangerous)
         T = 'ss';
      end
      
      function A = getAttributes(A)
         % Override default attributes
         A.Structured = false;
         A.FRD = false;
      end
            
      function T = toStructured(uflag)
         if uflag
            T = 'uss';
         else
            T = 'genss';
         end
      end
      
      function T = toFRD(~)
         T = 'frd';
      end
      
   end
   
   
   methods
      
      function sys = tf(varargin)
         ni = nargin;
         % Handle conversion TF(SYS) where SYS is a TF or LTIBLOCK.TF object
         if ni>0 && (isa(varargin{1},'tf') || isa(varargin{1},'ltiblock.tf'))
            sys0 = varargin{1};
            if isa(sys0,'tf')  % Optimization for SYS of class @tf
               sys = sys0;
            else
               sys = copyMetaData(sys0,tf_(sys0));
            end
            return
         end
                  
         % Trap the syntax TF('s',...) or TF('z',Ts,...)
         % RE: Do not support TF('z^-1') or TF('q^-1') because we can't make 
         %     (1/z)+(1/z)^2 minimal
         if ni>0 && ischar(varargin{1}) && any(strcmp(varargin{1},{'s' 'p' 'z' 'q'}))
            var = varargin{1};
            if ni>1 && isnumeric(varargin{2})
               Ts = varargin{2};   varargin = varargin(3:end);
               if xor(Ts==0,any(var=='sp'))
                  error(message('Control:ltiobject:setVariableProperty'))
               end
            else
               if any(var=='zq')
                  Ts = -1;
               else
                  Ts = 0;
               end
               varargin = varargin(2:end);
            end
            if any(var=='pq')
               varargin = [{'Variable' var} varargin];
            end
            ni = 3+length(varargin);
            varargin = [{[1 0] [0 1] Ts} varargin];
         end
          
         % Dissect input list
         DataInputs = 0;
         LtiInput = 0;
         PVStart = ni+1;
         for ct=1:ni
            nextarg = varargin{ct};
            if isa(nextarg,'struct') || isa(nextarg,'lti')
               LtiInput = ct;   PVStart = ct+1;   break
            elseif ischar(nextarg)
               PVStart = ct;   break
            else
               DataInputs = DataInputs+1;
            end
         end
         
         % Handle bad calls
         if PVStart==1
            if ni==1
               % Bad conversion
               error(message('Control:ltiobject:construct3','tf'))
            elseif ni>0
               error(message('Control:general:InvalidSyntaxForCommand','tf','tf'))
            end
         elseif DataInputs>3
            error(message('Control:general:InvalidSyntaxForCommand','tf','tf'))
         end
         
         % Process numerical data
         try
            switch DataInputs
               case 0
                  if ni
                     error(message('Control:general:InvalidSyntaxForCommand','tf','tf'))
                  else
                     num = {};  den = {};
                  end
                  
               case 1
                  % Gain matrix
                  nummat = varargin{1};
                  if ~isnumeric(nummat)
                     error(message('Control:ltiobject:construct2','tf'))
                  end
                  if isempty(nummat)
                     num = cell(size(nummat));
                  else
                     nummat = double(full(nummat));
                     num = num2cell(nummat);
                  end
                  den = cell(size(nummat));
                  den(:) = {1};
                  % Optimization for fast pre-allocation
                  CheckData = ~all(isfinite(nummat(:)));
                  
               otherwise
                  % NUM and DEN specified
                  num = checkNumDenData(varargin{1},'N');
                  den = checkNumDenData(varargin{2},'D');
                  CheckData = true;
            end
            
            % Sample time
            if DataInputs==3
               % Discrete SS
               Ts = ltipack.utValidateTs(varargin{3});
            else
               Ts = 0;
            end
         catch ME
            throw(ME)
         end
            
         % Determine I/O and array size
         if ni>0
            Ny = size(num,1);
            Nu = size(num,2);
            ArraySize = ltipack.getLTIArraySize(2,num,den);
            if isempty(ArraySize)
               error(message('Control:ltiobject:tf1'))
            end
         else
            Ny = 0;  Nu = 0;  ArraySize = [1 1];
         end
         Nsys = prod(ArraySize);
         sys.IOSize_ = [Ny Nu];
            
         % Create @tfdata object array
         % RE: Inlined for optimal speed
         if Nsys==1
            Data = ltipack.tfdata(num,den,Ts);
         else
            Data = ltipack.tfdata.array(ArraySize);
            Delay = ltipack.utDelayStruct(Ny,Nu,false);
            for ct=1:Nsys
               Data(ct).num = num(:,:,min(ct,end));
               Data(ct).den = den(:,:,min(ct,end));
               Data(ct).Ts = Ts;
               Data(ct).Delay = Delay;
            end
         end
         sys.Data_ = Data;
         
         % Process additional settings and validate system
         % Note: Skip when just constructing empty instance for efficiency
         if ni>0
            try
               % User-defined properties
               Settings = cell(1,0);
               if LtiInput
                  % Properties inherited from other system
                  arg = varargin{LtiInput};
                  if isa(arg,'lti')
                     arg = getSettings(arg);
                  end
                  if isfield(arg,'FrequencyUnit')
                     arg = rmfield(arg,'FrequencyUnit');
                  end
                  Settings = [Settings , lti.struct2pv(arg)];
               end
               Settings = [Settings , varargin(:,PVStart:ni)];
               
               % Apply settings
               if ~isempty(Settings)
                  sys = fastSet(sys,Settings{:});
               end
               
               % Consistency check
               if CheckData || ~isempty(Settings)
                  sys = checkConsistency(sys);
               end
               
               % Issue warning if system is complex
               if DataInputs>1 && ~isreal(sys)
                  warning(message('Control:ltiobject:TFComplex'))
               end
            catch ME
               throw(ME)
            end
         end
      end
      
      function Value = get.Numerator(sys)
         % GET method for num property
         Data = sys.Data_;
         Value = cell([sys.IOSize_ size(Data)]);
         for ct=1:numel(Data)
            Value(:,:,ct) = Data(ct).num;
         end
      end
      
      function Value = get.Denominator(sys)
         % GET method for den property
         Data = sys.Data_;
         Value = cell([sys.IOSize_ size(Data)]);
         for ct=1:numel(Data)
            Value(:,:,ct) = Data(ct).den;
         end
      end
      
      function sys = set.Numerator(sys,Value)
         % SET method for num property
         Value = checkNumDenData(Value,'N');
         % Check compatibility of RHS with model array sizes
         Data = ltipack.utCheckAssignValueSize(sys.Data_,Value,2);
         sv = size(Value);
         if isequal(sv(1:2),sys.IOSize_)
            % No change in I/O size
            for ct=1:numel(Data)
               Data(ct).num = Value(:,:,min(ct,end));
               if sys.CrossValidation_
                  Data(ct) = checkData(Data(ct));  % Quick validation
               end
            end
            sys.Data_ = Data;
            if sys.CrossValidation_
               sys = formatNumDen(sys);
            end
         else
            % I/O size changes
            for ct=1:numel(Data)
               Data(ct).num = Value(:,:,min(ct,end));
            end
            sys.Data_ = Data;
            if sys.CrossValidation_
               % Note: Full validation needed when I/O size changes, e.g., in
               % sys = tf(1,[1 2 3]); sys.num = {1 2;3 4};
               sys = checkConsistency(sys);
            end
         end
      end
      
      function sys = set.Denominator(sys,Value)
         % SET method for den property
         % Note: Limited checking because setting DEN only cannot change I/O size
         Value = checkNumDenData(Value,'D');
         Data = ltipack.utCheckAssignValueSize(sys.Data_,Value,2);
         for ct=1:numel(Data)
            Data(ct).den = Value(:,:,min(ct,end));
            if sys.CrossValidation_
               Data(ct) = checkData(Data(ct));
            end
         end
         sys.Data_ = Data;
         if sys.CrossValidation_
            sys = formatNumDen(sys);
         end
      end
      
      function Value = get.Variable(sys)
         % GET method for Variable property
         Value = sys.Variable_;
         if isempty(Value)
            if getTs_(sys)==0
               Value = 's';
            else
               Value = 'z';
            end
         end
      end
      
      function sys = set.Variable(sys,Value)
         % SET method for Variable property
         if ~(isa(Value,'char') && any(strcmp(Value,{'s';'p';'z';'z^-1';'q';'q^-1'})))
            error(message('Control:ltiobject:setVariableProperty'))
         elseif sys.CrossValidation_
            % Check consistency with Ts
            Value = ltipack.checkVariable(sys,Value);
         end
         sys.Variable_ = Value;
         % Drop trailing zeros when switching to z^-1 or q^-1, e.g., in tf([1 2 0],[1 0 0])
         if ~isempty(Value) && sys.CrossValidation_ && strcmp(Value(end),'1')
            sys = formatNumDen(sys);
         end
      end
      
      function Value = get.IODelay(sys)
         % GET method for IODelay property
         Value = getIODelay(sys);
      end
      
      function Value = get.ioDelayMatrix(sys)
         Value = getIODelay(sys);
      end
      
      function sys = set.IODelay(sys,Value)
         % SET method for IODelay property
         sys = setIODelay(sys,Value);
      end
      
      function sys = set.ioDelayMatrix(sys,Value)
         % SET method for ioDelayMatrix property
         sys = setIODelay(sys,Value);
      end
      
   end
   
   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)

      function displaySize(~,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         if length(sizes)==2
            disp(getString(message('Control:ltiobject:SizeTF1',ny,nu)))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            disp(getString(message('Control:ltiobject:SizeTF2',ArrayDims(1:end-1),ny,nu)))
         end
      end
      
      function sys = setTs_(sys,Ts)
         % Implementation of @SingleRateSystem:setTs_
         sys = setTs_@lti(sys,Ts);
         % Check Ts/Variable compatibility
         if sys.CrossValidation_
            sys.Variable_ = ltipack.checkVariable(sys,sys.Variable_);
         end
      end
      
   end
   
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      %% MODEL CHARACTERISTICS
      function sys = checkDataConsistency(sys)
         % Cross validation of system data. Extends @lti implementation
         % Generic data validation
         sys = checkDataConsistency@lti(sys);
         
         % Check Variable/Ts compatibility
         sys.Variable_ = ltipack.checkVariable(sys,sys.Variable_);
            
         % Pad NUM and DEN with zeros based on variable in use
         sys = formatNumDen(sys);
      end

      %% BINARY OPERATIONS
      function boo = hasSimpleInverse_(sys)
         boo = all(iosize(sys)==1);
      end
      
      function [sys1,sys2] = matchAttributes(sys1,sys2)
         % Enforces matching attributes in binary operations (e.g.,
         % sample time, variable,...). This function can be overloaded
         % by subclasses.
         [sys1,sys2] = matchAttributes@lti(sys1,sys2);
         % Match Variables
         [sys1,sys2] = ltipack.matchVariable(sys1,sys2);
      end      

      function [sys1,SingularFlag] = feedback_(sys1,sys2,indu,indy,sign)
         % Overloaded to warn or force conversion to SS when internal delays arise
         [sys1,sys2] = matchArraySize(sys1,sys2);
         [sys1,sys2] = matchAttributes(sys1,sys2);
         try
            Data1 = sys1.Data_;  Data2 = sys2.Data_;  
            SingularFlag = false;  DelayFlag = false;
            for ct=1:numel(Data1)
               [Data1(ct),sf,df] = feedback(Data1(ct),Data2(ct),indu,indy,sign);
               SingularFlag = SingularFlag || sf;
               DelayFlag = DelayFlag || df;
            end
            sys1.Data_ = Data1;
            sys1.SamplingGrid_ = ...
               ltipack.SamplingGrid.merge(sys1.SamplingGrid_,sys2.SamplingGrid_);
            if DelayFlag
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys1 = trimNumDen(sys1);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               % Convert to state-space if internal delays needed to represent result
               [sys1,SingularFlag] = feedback_(ss(sys1),ss(sys2),indu,indy,sign);
            else
               throw(ME)
            end
         end
      end
            
      function [sys1,SingularFlag] = lft_(sys1,sys2,indu1,indy1,indu2,indy2)
         % Overloaded to warn or force conversion to SS when internal delays arise
         [sys1,sys2] = matchArraySize(sys1,sys2);
         [sys1,sys2] = matchAttributes(sys1,sys2);
         try
            Data1 = sys1.Data_;  Data2 = sys2.Data_;  
            SingularFlag = false;  DelayFlag = false;
            for ct=1:numel(Data1)
               [Data1(ct),sf,df] = lft(Data1(ct),Data2(ct),indu1,indy1,indu2,indy2);
               SingularFlag = SingularFlag || sf;
               DelayFlag = DelayFlag || df;
            end
            sys1.Data_ = Data1;
            sys1.SamplingGrid_ = ...
               ltipack.SamplingGrid.merge(sys1.SamplingGrid_,sys2.SamplingGrid_);
            if DelayFlag
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys1 = trimNumDen(sys1);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               % Convert to state-space if internal delays needed to represent result
               [sys1,SingularFlag] = lft_(ss(sys1),ss(sys2),indu1,indy1,indu2,indy2);
            else
               throw(ME)
            end
         end
      end
      
      function sys1 = plus_(sys1,sys2)
         % Overloaded to warn or force conversion to SS when internal delays arise
         [sys1,sys2] = matchArraySize(sys1,sys2);
         [sys1,sys2] = matchAttributes(sys1,sys2);
         try
            Data1 = sys1.Data_;  Data2 = sys2.Data_;  WarnFlag = false;
            for ct=1:numel(Data1)
               [Data1(ct),delay2zFlag] = plus(Data1(ct),Data2(ct));
               WarnFlag = WarnFlag || delay2zFlag;
            end
            sys1.Data_ = Data1;
            sys1.SamplingGrid_ = ...
               ltipack.SamplingGrid.merge(sys1.SamplingGrid_,sys2.SamplingGrid_);
            if WarnFlag
               % Issue single warning
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys1 = trimNumDen(sys1);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               % Convert to state-space if internal delays needed to represent result
               sys1 = plus_(ss(sys1),ss(sys2));
            else
               throw(ME)
            end
         end
      end
      
      function sys1 = mtimes_(sys1,sys2,ScalarFlags)
         % Overloaded to warn or force conversion to SS when internal delays arise
         [sys1,sys2] = matchArraySize(sys1,sys2);
         [sys1,sys2] = matchAttributes(sys1,sys2);
         try
            Data1 = sys1.Data_;  Data2 = sys2.Data_;  WarnFlag = false;
            for ct=1:numel(Data1)
               [Data1(ct),delay2zFlag] = mtimes(Data1(ct),Data2(ct),ScalarFlags);
               WarnFlag = WarnFlag || delay2zFlag;
            end
            sys1.Data_ = Data1;
            sys1.SamplingGrid_ = ...
               ltipack.SamplingGrid.merge(sys1.SamplingGrid_,sys2.SamplingGrid_);
            if WarnFlag
               % Issue single warning
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys1 = trimNumDen(sys1);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               % Convert to state-space if internal delays needed to represent result
               sys1 = mtimes_(ss(sys1),ss(sys2),ScalarFlags);
            else
               throw(ME)
            end
         end
      end
      
      function sys1 = times_(sys1,sys2,ScalarFlags)
         % Overloaded to clean up leading.training zeros
         sys1 = times_@ltipack.SystemArray(sys1,sys2,ScalarFlags);
         sys1 = trimNumDen(sys1);
      end
      
      function [sys1,SingularFlag] = mldivide_(sys1,sys2)
         % Overloaded to warn or force conversion to SS when internal delays arise
         [sys1,sys2] = matchArraySize(sys1,sys2);
         [sys1,sys2] = matchAttributes(sys1,sys2);
         try
            Data1 = sys1.Data_;  Data2 = sys2.Data_;  
            SingularFlag = false;  DelayFlag = false;
            for ct=1:numel(Data1)
               [Data1(ct),sf,df] = mldivide(Data1(ct),Data2(ct));
               SingularFlag = SingularFlag || sf;
               DelayFlag = DelayFlag || df;
            end
            sys1.Data_ = Data1;
            sys1.SamplingGrid_ = ...
               ltipack.SamplingGrid.merge(sys1.SamplingGrid_,sys2.SamplingGrid_);
            if DelayFlag
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys1 = trimNumDen(sys1);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               [sys1,SingularFlag] = mldivide_(ss(sys1),ss(sys2));
            else
               throw(ME)
            end
         end
      end
      
      function [sys1,SingularFlag] = mrdivide_(sys1,sys2)
         % Overloaded to warn or force conversion to SS when internal delays arise
         [sys1,sys2] = matchArraySize(sys1,sys2);
         [sys1,sys2] = matchAttributes(sys1,sys2);
         try
            Data1 = sys1.Data_;  Data2 = sys2.Data_;  
            SingularFlag = false;  DelayFlag = false;
            for ct=1:numel(Data1)
               [Data1(ct),sf,df] = mrdivide(Data1(ct),Data2(ct));
               SingularFlag = SingularFlag || sf;
               DelayFlag = DelayFlag || df;
            end
            sys1.Data_ = Data1;
            sys1.SamplingGrid_ = ...
               ltipack.SamplingGrid.merge(sys1.SamplingGrid_,sys2.SamplingGrid_);
            if DelayFlag
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys1 = trimNumDen(sys1);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               [sys1,SingularFlag] = mrdivide_(ss(sys1),ss(sys2));
            else
               throw(ME)
            end
         end
      end

      
      %% INDEXING
      function sys = indexref_(sys,indrow,indcol,ArrayIndices)
         % Implements sys(indices)
         sys = indexref_@ltipack.SystemArray(sys,indrow,indcol,ArrayIndices);
         % g400213: reset variable if resulting TF array is empty
         if isempty(sys.Data_)
            sys.Variable_ = [];
         end
      end
            
      function sys = indexasgn_(sys,indices,rhs,ioSize,ArrayMask)
         % Data management in SYS(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.

         % Construct template initial value for new entries in system array
         n = cell(ioSize); n(:) = {0};
         d = cell(ioSize); d(:) = {1};
         D0 = ltipack.tfdata(n,d,getTs_(sys));
         % Update data
         sys.Data_ = ltipack.reassignData(sys.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
         % g400213: reset variable if resulting TF array is empty
         if isempty(sys.Data_)
            sys.Variable_ = [];
         end
      end
      
      function sys = indexdel_(sys,indices)
         % Data management in SYS(indices) = [].
         sys = indexdel_@ltipack.SystemArray(sys,indices);
         if isempty(sys.Data_)
            sys.Variable_ = [];
         end
      end
      
      %% TRANSFORMATIONS
      function [sys,icmap] = absorbDelay_(sys)
         % Maps delays to poles in discrete time
         [sys,icmap] = absorbDelay_@ltipack.SystemArray(sys);
         % Remove trailing zeros for z^-1,q^-1 variables
         sys = trimNumDen(sys);
      end
      
      function [sys,SingularFlag] = mpower_(sys,k)
         % Overloaded to warn or force conversion to SS when internal delays arise
         try
            Data = sys.Data_;  SingularFlag = false;  Delay2zFlag = false;
            for ct=1:numel(Data)
               [Data(ct),sf,df] = mpower(Data(ct),k);
               SingularFlag = SingularFlag || sf;
               Delay2zFlag = Delay2zFlag || df;
            end
            sys.Data_ = Data;
            if Delay2zFlag
               warning(message('Control:ltiobject:UseSSforInternalDelay'))
            end
            % Remove trailing zeros for z^-1,q^-1 variables
            sys = trimNumDen(sys);
         catch ME
            if strcmp(ME.identifier,'Control:combination:InternalDelaysConvert2SS')
               % Convert to state-space if internal delays needed to represent result
               [sys,SingularFlag] = mpower_(ss(sys),k);
            else
               throw(ME)
            end
         end
      end
      
      function [sys,varargout] = c2d_(sys,Ts,options)
         % Data management for C2D
         [sys,varargout{1:nargout-1}] = c2d_@ltipack.SystemArray(sys,Ts,options);
         sys.Variable_ = [];  % reset to default ('z')
      end
      
      function [sys,varargout] = d2c_(sys,options)
         % Data management for D2C
         [sys,varargout{1:nargout-1}] = d2c_@ltipack.SystemArray(sys,options);
         sys.Variable_ = [];  % reset to default ('s')
      end
      
      function sys = balred_(sys,orders,BalData,Options)
         % Specialization to TF models
         % Compute reduced model in state space
         % Note: Only supports input and output delays
         rsys = balred_(ss(sys),orders,BalData,Options);
         % Convert back to TF
         rsys = tf(rsys);
         % Transfer data to preserve metadata
         sys.Data_ = rsys.Data_;
      end

      
   end
   
   %% PROTECTED METHODS
   methods (Access=protected)
   
      function S = getSettings(sys)
         % Gets values of public LTI properties. Needed to support tf(num,den,LTI)
         S = getSettings@lti(sys);
         S.IODelay = sys.IODelay;
      end
        
      function var = getVariable_(sys)
         % Generic access to Variable
         var = sys.Variable;
      end

   end   
   
   %% PRIVATE METHODS
   methods (Access=private)
      
      function sys = formatNumDen(sys)
         % Pads NUM and DEN with zeros and trims extra leading/trailing zeros
         % based on variable in use
         RightFlag = ~isempty(strfind(sys.Variable_,'1'));
         qVar = strcmp(sys.Variable_,'q');
         qWarn = false;
         Data = sys.Data_;
         for ct=1:numel(Data)
            [Data(ct).num,Data(ct).den,NeedsPad] = ...
               ltipack.tfdata.utFormatNumDen(Data(ct).num,Data(ct).den,RightFlag);
            qWarn = qWarn || (qVar && NeedsPad);  % see below
         end
         sys.Data_ = Data;
         % Starting in R2009a, q means z rather than z^-1
         if qWarn
            warning(message('Control:ltiobject:qChange'))
         end
      end

      function sys = trimNumDen(sys)
         % Trims extra trailing zeros in NUM,DEN for the z^-1,q^-1 variables.
         if ~isempty(strfind(sys.Variable_,'1'))
            Data = sys.Data_;
            for ct=1:numel(Data)
               [Data(ct).num,Data(ct).den] = ...
                  ltipack.tfdata.utTrimNumDen(Data(ct).num,Data(ct).den,true);
            end
            sys.Data_ = Data;
         end
      end

   end
   
   %% STATIC METHODS
   methods(Static, Hidden)
      
      sys = loadobj(s)
            
      function sys = make(D,IOSize)
         % Constructs TF model from ltipack.tfdata instance
         sys = tf;
         sys.Data_ = D;
         if nargin>1
            sys.IOSize_ = IOSize;  % support for empty model arrays
         else
            sys.IOSize_ = iosize(D(1));
         end
      end
      
      function sys = convert(X)
         % Safe conversion to TF.
         %   X = TF.CONVERT(X) safely converts the variable X to TF even when
         %   X is a static model (in which case TF(X) returns a GENSS or USS 
         %   model rather than a TF model). This method is used in indexed 
         %   assignments and conversions from ltiblock.tf to TF.
         if isnumeric(X) || isa(X,'StaticModel')
            % Work around tf(GENMAT) yielding a GENSS
            sys = tf(double(X));
         elseif isa(X,'DynamicSystem')
            sys = tf(X);
         else
            error(message('Control:transformation:tf4',class(X)))
         end
      end
      
   end
     
end
