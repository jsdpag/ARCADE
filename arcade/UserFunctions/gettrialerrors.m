
function  err = gettrialerrors( retmap , cfg )
% 
% err = gettrialerrors
% map = gettrialerrors( retmap )
% map = gettrialerrors( retmap , cfg )
% 
% Returns 2 x 9 cell array of trial error labels (top row) and integer
% codes (bottom row). Each column encodes a separate trial error. Strings
% in the top row are the same as the labels specified in the ARCADE
% configuration window's Trial Error Legend section.
% 
% If all trial error legend strings are valid MATLAB field names, then a
% name to value mapping can be returned in map if scalar logical retmap is
% true. map is a struct. Each field is a trial error label containing a
% scalar, numeric error code between 1 and 9. retmap is optional and
% defaults to false if it is missing or empty [ ].
% 
% Also optional is ArcadeConfig object cfg. If omitted or empty then this
% is obtained from the ARCADE session's SGLBehaviouralStore using
% retrieveConfig. Give cfg as an input argument for offline testing.
% 
  
  % Check input
  if  nargin < 1  ||  isempty( retmap )
    
    retmap = false ;
    
  elseif  ~ isscalar( retmap )  ||  ~ islogical( retmap )
    
    error( 'retmap must be a scalar logical' )
    
  end % check input
  
  % Get session ArcadeConfig object
  if  nargin < 2  ||  isempty( cfg )
    
    % Not an input argument, look for this in the SGLBehaviouralStore
    cfg = retrieveConfig ;
    
  % cfg is an input argument, is it the right type?
  elseif  ~ isa( cfg , 'ArcadeConfig' )
    
    error( 'cfg must be from ArcadeConfig class' )
    
  end % get cfg
  
  % Point to trial error legend
  leg = cfg.TrialErrorLegend ;
  
  % Output cell array
  err = cell( 2 , 9 ) ;
  
  % Error codes , field name
  for  e = 1 : 9
    
    % Retrieve legend string
    err{ 1 , e } = leg{ e + 1 } ;
    
    % Store code
    err{ 2 , e } = e ;
    
  end % err codes
  
  % Done
  if  ~ retmap , return , end
  
  % Find labels that are not valid MATLAB variable/field names
  i = ~ cellfun( @isvarname , err( 1 , : ) ) ;
  
  % Invalid names found
  if  any( i )
    
    error( 'Trial Error labels not valid field names: ''%s''' , ...
      strjoin( err( 1 , i ) , ''' , ''' ) )
    
  end % invalid names
  
  % Return name to value mapping
  err = struct( err{ : } ) ;
  
end % gettrialerrors

