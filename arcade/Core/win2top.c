
/*  top = win2top( title )
 *  
 *  Finds window with title matching char array 'title' and brings it to
 *  the front of all other windows. That is, it goes to the top of the Z
 *  order. top is non-zero on success.
 *    
 *  If title is empty then the function simply returns empty.
 *  If the window title is not found then 0 will be returned.
 *  
 *  This function is specific to Windows.
 *
 *  Compile with >> mex -R2018a win2top.c
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
  #define  NARGIN   1
  #define  NARGOUT  1
  
  // Input argument index in prhs
  #define  TIT  0

  // Size of character buffer
  #define  BUFNUM  4096


/*** MACRO block ***/


/*** win2top( ) main function ***/

void  mexFunction ( int nlhs ,       mxArray ** plhs ,
                    int nrhs , const mxArray ** prhs )
{ 
  
  
  /** Function input/output argument check **/
  
  // Wrong number of input arguments
  if  ( nrhs != NARGIN )
    mexErrMsgIdAndTxt( "ARCADE:win2top:nargin" , "%d input arguments "
      "expected." , NARGIN ) ;
  
  // Too many output arguments
  if  ( nlhs > NARGOUT )
    mexErrMsgIdAndTxt( "ARCADE:win2top:nargout" , "More than %d output "
      "argument requested." , NARGOUT ) ;
  
  // Empty input argument(s)
  if  ( mxIsEmpty( prhs[ TIT ] ) )
  {
    plhs[ 0 ] = mxCreateLogicalMatrix( 0 , 0 ) ;
    return ;
  }
  
  // title is a char array
  if  ( !mxIsChar( prhs[ TIT ] ) )  
    mexErrMsgIdAndTxt( "ARCADE:win2top:title" , 
                       "title must be a char array." ) ;
  
  
  /** Bring named window globally forwards **/
  
  // Allocate character buffer
  char  tit[ BUFNUM ] ;
  
  // Window handle of named window
  HWND  win = NULL ;
  
  // Create rep logical scalar initialised to false
  plhs[ 0 ] = mxCreateLogicalScalar( 0 ) ;
  
  // Point to logical value
  mxLogical * res = mxGetLogicals( plhs[ 0 ] ) ;
  
  // Window title is too big for buffer
  if  ( mxGetNumberOfElements( prhs[ TIT ] ) + 1  >  BUFNUM )
    mexErrMsgIdAndTxt( "ARCADE:win2top:strnum" , "title string exceeds "
      "buffer size %d." , BUFNUM ) ;

  // Convert to C style string
  if  ( mxGetString( prhs[ TIT ] , tit , BUFNUM ) )
    mexErrMsgIdAndTxt( "ARCADE:win2top:getstr" , 
                       "Failed to get title string." ) ;

  // Locate named window, quiely ignore if not found
  if  ( ( win = FindWindowA( NULL , tit ) ) == NULL )  return ;

  // Attempt to put named window on top of all others
  res[ 0 ] = SetForegroundWindow( win ) ;
  
} // end win2top( )

