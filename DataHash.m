
function Hash = DataHash(Data, varargin)
% #ok<*CHARTEN>

if nargin == 0
   R = Version_L;
   
   if nargout == 0
      disp(R);
   else
      Hash = R;
   end
   
   return;
end

[Method, OutFormat, isFile, isBin, Data] = ParseInput(Data, varargin{:});

try
   Engine = java.security.MessageDigest.getInstance(Method);
   
catch ME  % Handle errors during initializing the engine:
   if ~usejava('jvm')
      Error_L('needJava', 'DataHash needs Java.');
   end
   Error_L('BadInput2', 'Invalid hashing algorithm: [%s]. %s', ...
      Method, ME.message);
end

if isFile
   [FID, Msg] = fopen(Data, 'r');        % Open the file
   if FID < 0
      Error_L('BadFile', ['Cannot open file: %s', char(10), '%s'], Data, Msg);
   end
   
   % Read file in chunks to save memory and Java heap space:
   Chunk = 1e6;          % Fastest for 1e6 on Win7/64, HDD
   Count = Chunk;        % Dummy value to satisfy WHILE condition
   while Count == Chunk
      [Data, Count] = fread(FID, Chunk, '*uint8');
      if Count ~= 0      % Avoid error for empty file
         Engine.update(Data);
      end
   end
   fclose(FID);
      
elseif isBin             % Contents of an elementary array, type tested already:
   if ~isempty(Data)     % Engine.update fails for empty input!
      if isnumeric(Data)
         if isreal(Data)
            Engine.update(typecast(Data(:), 'uint8'));
         else
            Engine.update(typecast(real(Data(:)), 'uint8'));
            Engine.update(typecast(imag(Data(:)), 'uint8'));
         end
      elseif islogical(Data)               % TYPECAST cannot handle LOGICAL
         Engine.update(typecast(uint8(Data(:)), 'uint8'));
      elseif ischar(Data)                  % TYPECAST cannot handle CHAR
         Engine.update(typecast(uint16(Data(:)), 'uint8'));
      elseif myIsString(Data)
         if isscalar(Data)
            Engine.update(typecast(uint16(Data{1}), 'uint8'));
         else
            Error_L('BadBinData', 'Bin type requires scalar string.');
         end
      else  % This should have been caught above!
         Error_L('BadBinData', 'Data type not handled: %s', class(Data));
      end
   end
else                 % Array with type:
   Engine = CoreHash(Data, Engine);
end

Hash = typecast(Engine.digest, 'uint8');
   
switch OutFormat
   case 'hex'
      Hash = sprintf('%.2x', double(Hash));
   case 'HEX'
      Hash = sprintf('%.2X', double(Hash));
   case 'double'
      Hash = double(reshape(Hash, 1, []));
   case 'uint8'
      Hash = reshape(Hash, 1, []);
   case 'short'
      Hash = fBase64_enc(double(Hash), 0);
   case 'base64'
      Hash = fBase64_enc(double(Hash), 1);
      
   otherwise
      Error_L('BadOutFormat', ...
         '[Opt.Format] must be: HEX, hex, uint8, double, base64.');
end

end

% ******************************************************************************
function Engine = CoreHash(Data, Engine)

% Consider the type and dimensions of the array to distinguish arrays with the
% same data, but different shape: [0 x 0] and [0 x 1], [1,2] and [1;2],
% DOUBLE(0) and SINGLE([0,0]):
% <  v016: [class, size, data]. BUG! 0 and zeros(1,1,0) had the same hash!
% >= v016: [class, ndims, size, data]
Engine.update([uint8(class(Data)), ...
              typecast(uint64([ndims(Data), size(Data)]), 'uint8')]);
           
if issparse(Data)                    % Sparse arrays to struct:
   [S.Index1, S.Index2, S.Value] = find(Data);
   Engine                        = CoreHash(S, Engine);
elseif isstruct(Data)                % Hash for all array elements and fields:
   F = sort(fieldnames(Data));       % Ignore order of fields
   for iField = 1:length(F)          % Loop over fields
      aField = F{iField};
      Engine.update(uint8(aField));
      for iS = 1:numel(Data)         % Loop over elements of struct array
         Engine = CoreHash(Data(iS).(aField), Engine);
      end
   end
elseif iscell(Data)                  % Get hash for all cell elements:
   for iS = 1:numel(Data)
      Engine = CoreHash(Data{iS}, Engine);
   end
elseif isempty(Data)                 % Nothing to do
elseif isnumeric(Data)
   if isreal(Data)
      Engine.update(typecast(Data(:), 'uint8'));
   else
      Engine.update(typecast(real(Data(:)), 'uint8'));
      Engine.update(typecast(imag(Data(:)), 'uint8'));
   end
elseif islogical(Data)               % TYPECAST cannot handle LOGICAL
   Engine.update(typecast(uint8(Data(:)), 'uint8'));
elseif ischar(Data)                  % TYPECAST cannot handle CHAR
   Engine.update(typecast(uint16(Data(:)), 'uint8'));
elseif myIsString(Data)              % [19-May-2018] String class in >= R2016b
   classUint8 = uint8([117, 105, 110, 116, 49, 54]);  % 'uint16'
   for iS = 1:numel(Data)
      % Emulate without recursion: Engine = CoreHash(uint16(Data{iS}), Engine)
      aString = uint16(Data{iS});
      Engine.update([classUint8, ...
         typecast(uint64([ndims(aString), size(aString)]), 'uint8')]);
      if ~isempty(aString)
         Engine.update(typecast(uint16(aString), 'uint8'));
      end
   end
   
elseif isa(Data, 'function_handle')
   Engine = CoreHash(ConvertFuncHandle(Data), Engine);
elseif (isobject(Data) || isjava(Data)) && ismethod(class(Data), 'hashCode')
   Engine = CoreHash(char(Data.hashCode), Engine);
else  % Most likely a user-defined object:
   try
      BasicData = ConvertObject(Data);
   catch ME
      error(['JSimon:', mfilename, ':BadDataType'], ...
         '%s: Cannot create elementary array for type: %s\n  %s', ...
         mfilename, class(Data), ME.message);
   end
   
   try
      Engine = CoreHash(BasicData, Engine);
   catch ME
      if strcmpi(ME.identifier, 'MATLAB:recursionLimit')
         ME = MException(['JSimon:', mfilename, ':RecursiveType'], ...
            '%s: Cannot create hash for recursive data type: %s', ...
            mfilename, class(Data));
      end
      throw(ME);
   end
end

end

function [Method, OutFormat, isFile, isBin, Data] = ParseInput(Data, varargin)

% Default options: -------------------------------------------------------------
Method    = 'MD5';
OutFormat = 'hex';
isFile    = false;
isBin     = false;

% Check number and type of inputs: ---------------------------------------------
nOpt = nargin - 1;
Opt  = varargin;
if nOpt == 1 && isa(Opt{1}, 'struct')   % Old style Options as struct:
   Opt  = struct2cell(Opt{1});
   nOpt = numel(Opt);
end

for iOpt = 1:nOpt
   aOpt = Opt{iOpt};
   if ~ischar(aOpt)
      Error_L('BadInputType', '[Opt] must be a struct or chars.');
   end
   
   switch lower(aOpt)
      case 'file'             % Data contains the file name:
         isFile = true;
      case {'bin', 'binary'}  % Just the contents of the data:
         if (isnumeric(Data) || ischar(Data) || islogical(Data) || ...
               myIsString(Data)) == 0 || issparse(Data)
            Error_L('BadDataType', ['[Bin] input needs data type: ', ...
               'numeric, CHAR, LOGICAL, STRING.']);
         end
         isBin = true;
      case 'array'
         isBin = false;      % Is the default already
      case {'asc', 'ascii'}  % 8-bit part of MATLAB CHAR or STRING:
         isBin = true;
         if ischar(Data)
            Data  = uint8(Data);
         elseif myIsString(Data) && numel(Data) == 1
            Data  = uint8(char(Data));
         else
            Error_L('BadDataType', ...
               'ASCII method: Data must be a CHAR or scalar STRING.');
         end
      case 'hex'
         if aOpt(1) == 'H'
            OutFormat = 'HEX';
         else
            OutFormat = 'hex';
         end
      case {'double', 'uint8', 'short', 'base64'}
         OutFormat = lower(aOpt);
      otherwise  % Guess that this is the method:
         Method = upper(aOpt);
   end
end

end

function DataBin = ConvertObject(DataObj)
% Convert a user-defined object to a binary stream. There cannot be a unique
% solution, so this part is left for the user...

try    % Perhaps a direct conversion is implemented:
   DataBin = uint8(DataObj);
   
   % Matt Raum had this excellent idea - unfortunately this function is
   % undocumented and might not be supported in te future:
   % DataBin = getByteStreamFromArray(DataObj);
   
catch  % Or perhaps this is better:
   WarnS   = warning('off', 'MATLAB:structOnObject');
   DataBin = struct(DataObj);
   warning(WarnS);
end

end

% ******************************************************************************
function Out = fBase64_enc(In, doPad)
% Encode numeric vector of UINT8 values to base64 string.

B64 = org.apache.commons.codec.binary.Base64;
Out = char(B64.encode(In)).';
if ~doPad
   Out(Out == '=') = [];
end
end 