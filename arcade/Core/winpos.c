
/*  rep = winpos( title , position )
 *  
 *  Finds window with title matching char array 'title' and repositions it
 *  to position. position is a double vector with values [ x , y , w , h ]
 *  in pixels giving the distance of the left (x) and top (y) of the window
 *  from the top-left corner of the screen, and the window's new width (w)
 *  and height (h). The current window location/size is used for any value
 *  of position that is negative. rep is non-zero if the window was
 *  repositioned.
 *    
 *  If title or position is empty then the function simply returns empty.
 *  If the window title is not found then 0 will be returned.
 *  
 *  This function is specific to Windows.
 *
 *  Compile with >> mex -R2018a winpos.c
 *  
 *  Written by Jackson Smith - Dec 2022 - Fries Lab (ESI Frankfurt)
 */


/*** Include block ***/

  // Matlab APIs
  #include       "mex.h"
  #include    "matrix.h"

  // OS API
  #include   <windows.h>


/*** Define block ***/

  // Number of arguments
  #define  NARGIN   2
  #define  NARGOUT  1
  
  // Input argument index in prhs
  #define  TIT  0
  #define  POS  1
  
  // Number of elements required by position
  #define  POSNUM  4

  // position index of each value
  #define  POS_X  0
  #define  POS_Y  1
  #define  POS_W  2
  #define  POS_H  3

  // Size of character buffer
  #define  BUFNUM  4096


/*** MACRO block ***/
  
  /* Fetch new window position value into variable v from column c of
     position. Return result of expression cur if position is negative. */
  #define  GETPOS( p , v , cur )  v = pos[ p ] < 0 ? cur : pos[ p ] ;


/*** winpos( ) main function ***/

void  mexFunction ( int nlhs ,       mxArray ** plhs ,
                    int nrhs , const mxArray ** prhs )
{ 
  
  
  /** Function input/output argument check **/
  
  // Wrong number of input arguments
  if  ( nrhs != NARGIN )
    mexErrMsgIdAndTxt( "ARCADE:winpos:nargin" , "%d input arguments "
      "expected." , NARGIN ) ;
  
  // Too many output arguments
  if  ( nlhs > NARGOUT )
    mexErrMsgIdAndTxt( "ARCADE:winpos:nargout" , "More than %d output "
      "argument requested." , NARGOUT ) ;
  
  // Empty input argument(s)
  if  ( mxIsEmpty( prhs[ TIT ] )  ||  mxIsEmpty( prhs[ POS ] ) )
  {
    plhs[ 0 ] = mxCreateLogicalMatrix( 0 , 0 ) ;
    return ;
  }
  
  // title is a char array
  if  ( !mxIsChar( prhs[ TIT ] ) )  
    mexErrMsgIdAndTxt( "ARCADE:winpos:title" , 
                       "title must be a char array." ) ;
  
  // position is double array
  if  ( !mxIsDouble( prhs[ POS ] ) )
    mexErrMsgIdAndTxt( "ARCADE:winpos:positiondouble" , 
                       "position must be a double array." ) ;
  
  // position is real valued
  if  ( mxIsComplex( prhs[ POS ] ) )
    mexErrMsgIdAndTxt( "ARCADE:winpos:positionreal" , 
                       "position must have real values." ) ;
  
  // position check size
  if ( mxGetNumberOfElements( prhs[ POS ] ) != POSNUM )
    mexErrMsgIdAndTxt( "ARCADE:winpos:positionsize" , "position must have "
      "%d elements." , POSNUM ) ;
  
  // Pointer to values inside position
  mxDouble * pos = mxGetDoubles( prhs[ POS ] ) ;
  
  // Generic index
  mwIndex  i = POSNUM ;
  
  // Values of position. Checks value of i in while then decrements.
  while  ( i-- )
    if  ( !mxIsFinite( pos[ i ] ) )
      mexErrMsgIdAndTxt( "ARCADE:winpos:positionfinite" , 
                         "position must have finite values." ) ;
  
  
  /** Reposition named windows **/
  
  // Allocate character buffer
  char  tit[ BUFNUM ] ;
  
  // Window handle of named window
  HWND  win = NULL ;
  
  // Allocate a Windows RECT structure to fish out current size/position
  RECT  r ;
  
  // Variables for accessing/casting new location and size of window
  int  x , y , w , h ;
  
  // Create rep logical scalar initialised to false
  plhs[ 0 ] = mxCreateLogicalScalar( 0 ) ;
  
  // Point to logical value
  mxLogical * res = mxGetLogicals( plhs[ 0 ] ) ;
  
  // Window title is too big for buffer
  if  ( mxGetNumberOfElements( prhs[ TIT ] ) + 1  >  BUFNUM )
    mexErrMsgIdAndTxt( "ARCADE:winpos:strnum" , "title string exceeds "
      "buffer size %d." , BUFNUM ) ;

  // Convert to C style string
  if  ( mxGetString( prhs[ TIT ] , tit , BUFNUM ) )
    mexErrMsgIdAndTxt( "ARCADE:winpos:getstr" , 
                       "Failed to get title string." ) ;

  // Locate named window, quiely ignore if not found
  if  ( ( win = FindWindowA( NULL , tit ) ) == NULL )  return ;

  // Current window position, quietly ignore if not found
  if  ( !GetWindowRect( win , &r ) )  return ;

  // Fetch new window location and size
  GETPOS( POS_X , x , r.left                )
  GETPOS( POS_Y , y , r.top                 )
  GETPOS( POS_W , w , r.right  - r.left + 1 )
  GETPOS( POS_H , h , r.bottom - r.top  + 1 )

  // Attempt to re-position and re-paint the named window
  res[ 0 ] = MoveWindow( win , x , y , w , h , TRUE ) ;
  
} // end winpos( )

