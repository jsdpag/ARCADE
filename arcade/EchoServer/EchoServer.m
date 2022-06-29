
classdef  EchoServer < handle
% 
% EchoServer mediates communication with the EchoServer.exe program.
% 
% 
% 

  properties (Constant, Access = private, Hidden = true)
    
    % Just one instance of EchoServer
    this = EchoServer ;
    
    % Pipe name
    pipnam = uint8( '\\.\pipe\EchoServerPipe' ) ;
    
    % Read/Write permissions - GENERIC_WRITE
    perm = uint32( hex2dec( '40000000' ) ) ;
    
  end

  properties (Access = private, Transient = true, Hidden = true)
    
    % Named pipe handle
    hPipe = libpointer;
    
    % Pipe connection status
    isConnected = false;
    
  end

  methods (Access = protected, Hidden=true)
    
    function  obj = EchoServer( )
      % Create instance of EchoServer class
    end
    
  end
  
  methods (Static)        
    
    function  Connect( )
    % Connect to EchoServer's named pipe
      
      % Local reference to the one and only EchoServer instance
      obj = EchoServer.this;
      
      % We already connected to the pipe
      if ~obj.hPipe.isNull( )
          warning('EchoServer:Connect:failed', ...
              'EchoServer connection was already established.');
          return;
      end
      
      % We need to link C language libraries for system calls
      if  ~ libisloaded( 'kernel32' )
          loadlibrary( 'kernel32' , @win_kernel32 ) ;
      end
      
      % Open named pipe with given permissions, no sharing, no special
      % security, open existing only, normal attributes, no template file.
      obj.hPipe = calllib( 'kernel32' , 'CreateFileA' , obj.pipnam , ...
        obj.perm , 0 , [ ] , 3 , 128 , [ ] ) ;
      
      % Failed to open pipe
      assert( ~ obj.hPipe.isNull( ) ) ;
      
      % Query named pipe
      result = calllib( 'kernel32' , 'GetNamedPipeInfo' , obj.hPipe , ...
        [ ] , [ ] , [ ] , [ ] ) ;
      
      % Handle error
      if  isequal( result , 0 )
          obj.hPipe = libpointer;
          error( 'EchoServer:Constructor:failed' , ...
            'Can''t connect to EchoServer pipe.\nErrorCode: %d\n' , ...
              calllib('kernel32', 'GetLastError') ) ;
      end
      
      % Everything worked
      obj.isConnected = true;
      
    end

    function  Disconnect( )
    % Disconnect EchoServer named pipe
    
      % Point to one and only instance of EchoServer
      obj = EchoServer.this;
      
      % Not connected, silently quit
      if ~ obj.isConnected , return , end
      
      % Attempt to close the handle, reset object parameters
      assert(~isequal(0, calllib('kernel32', 'CloseHandle', obj.hPipe)));
      obj.hPipe = libpointer;
      obj.isConnected = false;
      
    end

    function  isConnected = GetConnectionStatus( )
    % Retreive connection status with EchoServer
    
      isConnected = EchoServer.this.isConnected;
      
    end

    function delete()
    % Kill instance of EchoServer
    
        EchoServer.Disconnect();
        clear  EchoServer ;
        
    end
    
    function  Write( varargin )
    % Write takes identical input to sprintf, with the exception that non-
    % existant or empty input is quietly ignored. In other words, Write
    % will create a formatted string using the same kind of input as
    % sprintf. This string is then automatically cast as uint8 and piped to
    % EchoServer.exe.
    
      % s is empty, quietly return
      if  nargin == 0 || isempty( varargin{ 1 } ) , return , end
    
      % Point to only instance of EchoServer
      obj = EchoServer.this ;
      
      % Make sure that pipe is open
      if  ~ obj.isConnected
        error( 'EchoServer:Unconnected' , 'No connection to EchoServer.' );
      end
      
      % Create formatted string and cast to uint8
      s = uint8(  sprintf( varargin{ : } )  ) ;
      
      % Number of elements to write
      Ns = numel( s ) ;
      
      % Variable receives number bytes written.
      N = uint32( 0 ) ;
      
      % Write message to pipe
      [ result , ~ , ~ , N ] = calllib( 'kernel32' , 'WriteFile' , ...
        obj.hPipe , s , Ns , N , [ ] ) ;
      
      % Write error
      if  isequal( result , 0 )
        calllib( 'kernel32' , 'GetLastError' ) ;
        assert( false ) ;
      end
      
      % Failed to write entire message
      if  N ~= Ns
        error( 'Failed to write all bytes to pipe.' )
      end
      
    end
    
  end
  
end % EchoServer

