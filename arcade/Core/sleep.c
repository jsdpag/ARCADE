
/*  sleep( ms )
 *  
 *  Direct call to system kernel to pause the current process for ms
 *  milliseconds. If ms is 0 (zero) then the function returns immediately.
 *  Silently returns immediately if ms is empty (e.g. [ ]) or negative.
 *  
 *  MEX wrapper function for Windows system call Sleep( ). Note that the
 *  behaviour when ms <= 0 is different from the system call.
 *  
 *  See: https://docs.microsoft.com/en-us/windows/win32/api/synchapi/
 *    nf-synchapi-sleep
 *  
 *  Use in combination with timeBEPeriod to get higher-resolution timers.
 *  
 *  Written by Jackson Smith - Dec 2021 - Fries Lab (ESI Frankfurt)
 */



/*** Include block ***/

  // Matlab APIs
  #include  "mex.h"
  #include  "matrix.h"

  // OS API
  #include  <Windows.h>


/*** Define block ***/

  // Required number of input args
  #define  NARGIN  1
  
  // Minimum value of ms
  #define  MSMINV  0


/*** hptime main function ***/

void  mexFunction ( int nlhs ,       mxArray ** plhs ,
                    int nrhs , const mxArray ** prhs )
{
  
  /* Input arg check */
  
  // Required number of input args
  if  ( nrhs != NARGIN )
    mexErrMsgIdAndTxt ( "sleep:nargin" , "need %d input args" , NARGIN ) ;
  
  // No output args provided
  if  ( nlhs != 0 )
    mexErrMsgIdAndTxt ( "sleep:nargout" , "need 0 output args" ) ;
  
  // Input arg is empty, silently return immediately
  if  ( mxIsEmpty( prhs[ 0 ] ) )  return ;

  // Input arg must be scalar
  if  ( !mxIsScalar( prhs[ 0 ] ) )
    mexErrMsgIdAndTxt ( "sleep:scalar" , "ms not scalar" ) ;
  
  // Input must be real-valued
  if  ( mxIsComplex( prhs[ 0 ] ) )
    mexErrMsgIdAndTxt ( "sleep:complex" , "ms is complex value" ) ;

  // ms must be type double
  if  ( !mxIsDouble( prhs[ 0 ] ) )
    mexErrMsgIdAndTxt ( "sleep:mstype" , "ms is not double" ) ;

  // Copy value of ms
  double  ms = mxGetScalar ( prhs[ 0 ] ) ;
  
  // Undefined very large value or NaN
  if  ( !mxIsFinite( ms ) )
    mexErrMsgIdAndTxt ( "sleep:notfinite" , "ms is not finite" ) ;
  
  // ms is less than or equal to the minimum value, return immediately
  if  ( ms  <=  MSMINV )  return ;
  
  
  /* Execute pause if sleep duration is non-zero and finite */
  
  Sleep( ms ) ;
  
  
} // end sleep

