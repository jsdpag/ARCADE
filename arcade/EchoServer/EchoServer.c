
/*
  EchoServer.exe [logpath]
  
  Creates named pipe \\.pipe\EchoServerPipe then waits for input. Assumes that
  all data in pipe is UTF-8. Casts to char & prints to command prompt window.
  Looks for NULL (zero, 0) terminated strings; each string is printed
  separately. Hence a partial write/read from the pipe that does not contain
  a NULL character will not print until a NULL byte has been writen/read.
  
  If optional command line argument is a valid path/file name then writes
  are also streamed to 
*/


//*** INCLUDE BLOCK ***//

// C standard
#include  <stdio.h>

// OS
#include  <Windows.h>


//*** DEFINE BLOCK ***//

// Pipe's name
#define  PIPNAM  "\\\\.\\pipe\\EchoServerPipe"

// In and Out buffer size in bytes
#define  PIPBUFSIZ  65536

// Int value returned by program on completion
#define  SUCCESS  0
#define  FAILURE  1

// Print error message and return fail code
#define  errmsg( s )  { \
                        printf( s "\nError: %d\n" , GetLastError( ) ) ; \
                        CloseHandle( h ) ; \
                        fclose( f ) ; \
                        printf( "Press any key to end ...\n" ) ; \
                        getchar( ) ; \
                        return FAILURE ; \
                      }


//*** MAIN - EchoServer.exe ***//

int  main( int argc , char * argv[ ] )
{
  
  // Say who I am
  printf( "EchoServer\n" ) ;
  
  // Only one optional input arg allowed
  if  ( argc > 2 )
  {
    printf( "Only one [optional] regular file name input arg allowed.\n" ) ;
    return  FAILURE ;
  }
  
  // FILE pointer, in case we copy piped input to a text file
  FILE * f = NULL ;
  
  // This process is the server, so create the pipe with
  HANDLE  h = CreateNamedPipe( PIPNAM , PIPE_ACCESS_INBOUND , PIPE_TYPE_BYTE ,
    1 , PIPBUFSIZ , PIPBUFSIZ , 0 , NULL ) ;
  
  // Failed to create pipe
  if  ( h == INVALID_HANDLE_VALUE )
    errmsg( "CreateNamedPipe returned invalid handle." )
  else
    printf( "Created named pipe %s\n" , PIPNAM ) ;
  
  // File name provided as optional input arg
  if  ( argc == 2  &&  ( f = fopen( argv[ 1 ] , "w" ) ) == NULL )
    errmsg( "Failed to open text file." )
  else if ( f != NULL )
    printf( "Opened regular file %s with file stream @ %p\n" , argv[ 1 ] , f ) ;
  
  // Wait until client opens pipe as well
  if  ( !ConnectNamedPipe( h , NULL ) )
    errmsg( "Failed to connect pipe." )
  else
    printf( "Client connected to write end of pipe.\n" ) ;
  
  // Allocate read buffer, variable that receives number of bytes read,
  // and return value from ReadFile.
  char  buf[ PIPBUFSIZ ] ;
  DWORD  Nr = 0 ;
  BOOL  ret = 0 ;
  
  // Read loop
  while  ( ret = ReadFile( h , buf , PIPBUFSIZ , &Nr , NULL ) )
  {
    
    // Pass string onto standard output i.e. the command prompt window
    if  ( Nr > fwrite( buf , sizeof( char ) , Nr , stdout ) )
      errmsg( "fwrite failed on pipe." )
    
    // File opened, copy input to file
    if  ( f != NULL  &&  Nr > fwrite( buf , sizeof( char ) , Nr , f ) )
      errmsg( "fwrite failed on regular file." )
    
  } // read loop
  
  if  ( GetLastError( ) !=  ERROR_BROKEN_PIPE )
    errmsg( "ReadFile error, NOT pipe write handle closed" )
  
  // Complete, release the pipe
  CloseHandle( h ) ;
  
  // And any opened file
  if  ( f != NULL )  fclose( f ) ;
  
  // Done!
  return SUCCESS ;
  
} // main

