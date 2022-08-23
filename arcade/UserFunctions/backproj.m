
function  P = backproj( x , deg , orientation )
% 
% P = backproj( x , deg )
% P = backproj( x , deg , orientation )
% 
% Implements part of the back-projection technique by Fiorani et al. 2014.
% Double vector x with length N is rotated by deg degrees and projected
% onto N x N plane P. The output can be combined with data at other
% rotations to map the position of a visual receptive field. Both x and deg
% must be real-valued, finite, numerical types; they will be cast to double
% if they are not already.
% 
% Conceptually, backproj does the following. Let f( i , j ) = x( i ) for
% all i and j in 1 : N. In other words, let f( i , j ) be an image drawn in
% a standard Cartesian coordinate system. As i increases along the x-axis,
% the intensity value of the image matches the value of x( i ) at all
% positions on the y-axis. Thus, the image is N by N pixels, and each row
% of pixels is identical. The image is then rotated, counter-clockwise,
% around the central point of the image by deg degrees. The rotated image
% is cropped in a N x N box spanning all (i,j) where i and j are in 1 : N,
% inclusive. Empty space that falls outside of the rotated image is defined
% to have a value of zero. The resulting image is considered to be the back
% projection of x at a rotation of deg, and it is returned in P.
% 
% Optional input argument 'orientation' defines how the back-projection is
% stored in matrix P. P(1,1) always corresponds to the lower-left corner of
% the rotated-cropped image. If orientation is 'xy' then the x-axis of the
% image's Cartesion coordinate system increases with rows of P, and the
% y-axis increases with columns; 'xy' is used by default. If orientation is
% 'yx' then the y-axis increases with rows of P, and the x-axis increases
% with columns. Similarly, '-yx' has the y-axis decreasing along rows of P,
% and the x-axis increasing across columns. The last option '-yx' returns P
% in a format that can be fed directly into functions image( ) and
% imagesc( ). The other options may be more intuitive to different users.
% 
% Reference
% 
%   Fiorani M, Azzi JC, Soares JG, Gattass R. Automatic mapping of visual
%     cortex receptive fields: a fast and precise algorithm. J Neurosci
%     Methods. 2014 Jan 15;221:112-26. doi: 10.1016/j.jneumeth.2013.09.012.
% 
% Written by Jackson Smith - August 2022 - Fries Lab (ESI Frankfurt)
% 
  
  
  %%% Input argument checking %%%
  
  % Number of in/out args
   narginchk( 2 , 3 )
  nargoutchk( 0 , 1 )
  
  % Numeric validity testing
    x = checknum(   'x' , x   ) ;
  deg = checknum( 'deg' , deg ) ;
  
  % Default value of arg 'orientation'
  if  nargin < 3 , orientation = 'xy' ; end
  
  % Check that orientation is a string
  if  ~ ( isrow( orientation ) && ischar( orientation ) )
    
    error( 'orientation must be a char row vector i.e. a string.' )
    
  % Check for valid strings
  elseif  ~ any( strcmp( orientation , { 'xy' , 'yx' , '-yx' } ) )
    
    error( 'orientation must be ''xy'', ''yx'', or ''-yx''.' )
    
  end % orientation validity
  
  
  %%% Back-projection %%%
  
  % Number of elements in x
  N = numel( x ) ;
  
  % Half number of elements
  hN = N / 2 ;
  
  % N is odd
  if  mod( N , 2 )
    
    % Round up to get middle index value
    hN = ceil( hN ) ;
    
  % N is even
  else
    
    % Add half to get value between first and second halves of x
    hN = hN + 0.5 ;
    
  end % hN rounding
  
  % Convert from degrees to radians
  rad = deg * pi / 180 ;
  
  % Create coordinate vectors centred on the middle of the input image, the
  % one that will be rotated
  X = ( 1 : N )' - hN ;
  Y = ( 1 : N )  - hN ;
  
  % Compute the mapping from input image pixels (in linear indices of x) to
  % each pixel of the output image. I is an N by N matrix, and each element
  % corresponds to one pixel of the output image. It's value is the index
  % of the mapped value from x.
  I = round( cos( rad ) * X  +  sin( rad ) * Y  +  hN ) ;
  
  % Find all valid indices
  V = I >= 1 & I <= N ;
  
  % Initialise projected image
  P = zeros( N ) ;
  
  % Map values from x to create the back-projection. Leave zeros where
  % indices are not valid.
  P( V ) = x( I( V ) ) ;
  
  % Apply desired orientation of the back projection data in matrix P
  switch  orientation
    
    % X-axis increases across rows, y-axis across columns. Aready done.
    case   'xy'
      
      % No action required
      
    % Y-axis increases across rows, x-axis across columns. Transpose.
    case   'yx' , P = P' ;
      
    % Y-axis decreases across rows. Transpose and flip along 1st dimension.
    case  '-yx' , P = flipud( P' ) ;
      
    % Programming error
    otherwise , error( 'Programming error detected. Blame Jackson.' )
      
  end % data orientation in matrix
  
  
end % backproj


%%% Sub-function %%%

% Checks the validity of numeric input argument
function  value = checknum( name , value )
  
  % Valid value
  if isnumeric( value ) && all( isfinite( value ) ) && isreal( value ) ...
      && isvector( value )
    
    % Cast value to double if it is not already
    if  ~ isa( value , 'double' ) , value = double( value ) ; end
    
  % Illegal value
  else
    
    error( '%s must be finite, real, and numeric vector.' , name )
    
  end % validity
  
end % checknum

