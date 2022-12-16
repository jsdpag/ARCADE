
function  writetxt( fnam , str , perm )
% 
% writetxt( fnam , str )
% writetxt( fnam , str , perm )
% 
% Write string str to text file fnam with ASCII encoding. Opens fnam with
% permission perm; this is optional, it's default is 'w'. Permissions 'w',
% 'a', 'W', and 'A' are allowed (see doc fopen). '.txt' file extension is
% added automatically if it is not there, so fnam does not need to have it.
% In addition, a newline is automatically added at the end of str, but only
% if there is not one already.
% 
% Jackson Smith - December 2022 - Fries Lab (ESI Frankfurt)
  
  
  %%% Input arg check %%%
  
  % Number of args
  narginchk ( 2 , 3 )
  nargoutchk( 0 , 0 )
  
  % No permission given, use default
  if  nargin < 3 , perm = 'w' ; end
  
  % Correct type of args
  checkarg( fnam , 'fnam' )
  checkarg(  str ,  'str' )
  checkarg( perm , 'perm' , 1 )
  
  % Allowable permission
  if  all( perm ~= 'wWaA' ) , error( 'perm must be w, W, a, or A.' ) , end
  
  % .txt file name extension is needed
  if  isempty(  regexp( fnam , '\.txt$' , 'once' )  )
    fnam = [ fnam , '.txt' ] ;
  end
  
  % Newline is required
  if  str( end ) ~= newline
    nl = newline ;
  else
    nl = '' ;
  end
  
  
  %%% Write text file %%%
  
  % Open a new file for writing, native byte order, UTF-8 text encoding
  [ fid , msg ] = fopen( fnam , perm , 'n' , 'US-ASCII' ) ;
  
  % Failed to open file
  if  fid == -1
    error( 'Failed to open %s.txt with perm %c: %s' , fnam , perm , msg )
  end

  % Write data to file, see how many bytes written
  nerr = fprintf( fid , '%s%c' , str , nl ) ~= numel( str ) + numel( nl ) ;

  % Close file in all cases
  if  fclose( fid ) == -1 , error( 'Failed to close %s.txt', fnam ) , end

  % Not all bytes written
  if  nerr , error( 'Incomplete write to %s.txt', fnam ) , end
  
  
end % writetxt


%%% Sub-functions %%%

% Check that input arg is a classic string, a char row vector. Optionally
% give a size.
function  checkarg( arg , nam , n )
  
  % Size not given, any size is allowed
  if  nargin < 3 , n = Inf ; end
  
  % arg is valid
  if  ischar( arg ) && isrow( arg ) && ( isinf( n ) || numel( arg ) == n )
    return
  end
  
  % arg is not valid
  error( 'Input arg %s is not valid.' , nam )
  
end % checkarg

