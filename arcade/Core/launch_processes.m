function [ procs, cfg, sesslaunchparams ] = launch_processes(cfg, varargin)

% defaults
if ~exist('cfg', 'var'); cfg = ArcadeConfig; end
if nargin == 1
    cfgPath = '';
elseif nargin == 2
    cfgPath = varargin{1};
end

% This struct can be altered by task-specific session_launch_script.m
sesslaunchparams.EyeServer_SampleMode   = false ;
sesslaunchparams.EyeServer_UniqueTmp    = false ;
sesslaunchparams.EyeServer_TransferData = true  ;
sesslaunchparams.Window_EyeServer  = 'EyeLinkServer - Untitled' ;
sesslaunchparams.Window_EchoServer = fullfile( arcaderoot , 'arcade' , ...
                                       'EchoServer' , 'EchoServer.exe' ) ;
sesslaunchparams.Position_EyeServer  = [ ] ;
sesslaunchparams.Position_EchoServer = [ ] ;
sesslaunchparams.Location_ArcadeRemote = [ ] ;
sesslaunchparams.TaskScript_Shutdown = false ;

% Task file name provided
if  ~ isempty( cfg.taskFile )
  
  % Name of task-specific session launch script
  sesslaunchname = fullfile( fileparts( cfg.taskFile ) , ...
    'session_launch_script.m' ) ;

  % Look for task-specific session launch script
  if  exist( sesslaunchname , 'file' )
    logmessage( [ 'Executing session launch script: ' , sesslaunchname ] )
    run( sesslaunchname )
  end
  
end % task file --> session launch script

% Accumulate executable file names for critical ARCADE processes in this.
% Empty string is a reference to the calling, Core process.
critical = { '' } ;

procs = {};
readyEvents = {};
% launch other processes
for iExe = 1:length(cfg.OtherExecutables)
    cmd = cfg.OtherExecutables{iExe};
    logmessage(sprintf('Starting %s', cmd))
    procs{end+1} =  processManager('id', cmd, 'command',  cmd , ...
      'printStdout' , false , 'printStderr' , false );
end

% launch control screen process, switch responds to valid options
switch  cfg.ControlScreen
  case  'MatlabControlScreen.bat'
    logmessage(sprintf('Starting %s', cfg.ControlScreen))
    
    controlScreenExePath = fullfile(arcaderoot, 'arcade', ...
        'ControlScreen', [cfg.ControlScreen ' "' cfgPath '"']);
    procs{end+1} = processManager('id', 'ControlScreen', ...
        'command',  controlScreenExePath, ...
        'workingDir', fullfile(arcaderoot, 'arcade', 'ControlScreen'), ...
        'printStdout', false, 'printStderr', false);
    controlScreenDoneEvent = IPCEvent('ControlScreenDone');
    readyEvents{end+1} = controlScreenDoneEvent.name;
  case  'makeArcadeRemote.m'
    makeArcadeRemote % The core process provides a pause button.
    cfg.ControlScreen = '' ;
end

% launch EyeServer process
if ~isempty(cfg.EyeServer)
    logmessage('Starting EyeServer')
    eyeServerExePath = fullfile(arcaderoot, 'arcade', ...
        'EyeServer', cfg.EyeServer);
    procs{end+1} = processManager('id', 'EyeServer', ...
        'command', eyeServerExePath, 'printStdout' , false , ...
        'printStderr' , false);
    readyEvents{end+1} = EyeServer.doneEventName;
    [ ~ , exe.name , exe.ext ] = fileparts ( eyeServerExePath ) ;
    critical{ end + 1 } = [ exe.name , exe.ext ] ;
end

% launch DaqServer process
if ~isempty(cfg.DaqServer)
    logmessage('Starting DaqServer')
    daqServerExePath = fullfile(arcaderoot, 'arcade', ...
        'DaqServer', cfg.DaqServer);
    procs{end+1} = processManager('id', 'DaqServer', ...
        'command', daqServerExePath , 'printStdout' , false , ...
        'printStderr' , false);
    readyEvents{end+1} = DaqServer.doneEventName;
    [ ~ , exe.name , exe.ext ] = fileparts ( daqServerExePath ) ;
    critical{ end + 1 } = [ exe.name , exe.ext ] ;
end



logmessage('Waiting for processes to start')
pause(0.5)
if ~isempty(readyEvents)
    MultipleEvents.Init(readyEvents)
    result = MultipleEvents.WaitFor(readyEvents, 1, 20000);
    assert(result == 1, 'Not all processes could be started within 20 s')
    MultipleEvents.delete()
end

% launch StimServer process last when all other windows are open to prevent 
% change of StimServer full screen mode

if ~isempty(cfg.StimServer)
    logmessage('Starting StimServer')
    stimServerExePath = fullfile(arcaderoot, 'arcade', ...
        'StimServer', cfg.StimServer);
    procs{end+1} = processManager('id', 'StimServer', ...
        'command',  stimServerExePath , 'printStdout' , false , ...
        'printStderr' , false);
    [ ~ , exe.name , exe.ext ] = fileparts ( stimServerExePath ) ;
    critical{ end + 1 } = [ exe.name , exe.ext ] ;
end


assert(IPCEvent.wait_for_event(StimServer.doneEventName, 10000), ...
       'StimServer startup failed')


% connect to StimServer
if ~isempty(cfg.StimServer)
    logmessage('Connect to StimServer')
    
    % There is sometimes a startup error where StimServer.GetFrameRate
    % leads to a crash. It is possible that StimServer.Connect( ) is
    % executed without successfully linking to the named pipe. One possible
    % solution is to simply disconnect and reconnect. Try this several
    % times before issuing an error.
    
    % Attempts
    for  i = 1 : 10
      
      % Connect to named pipe
      StimServer.Connect( ) ;
      
      % Do not crash startup sequence unintentionally
      try
        
        % Query StimServer.exe via named pipe
        logmessage(sprintf('FrameRate = %3.0f', StimServer.GetFrameRate));
        
        % Success, break the for loop
        break
        
      % StimServer.GetFrameRate failed
      catch
        
        % That was the last attempt, issue an error
        if  i == 10
          error( [ 'Failed to connect to StimServer\n' , ...
                   'Possibly due to failure when opening named pipe.' ] )
        end
        
        % Disconnect
        StimServer.Disconnect( ) ;
        
        % Breif wait, 100ms
        sleep( 100 ) ;
        
      end % try StimServer.GetFrameRate
    end % attempt StimServer.GetFrameRate
    
end % connect to StimServer

% connect to DaqServer
if ~isempty(cfg.DaqServer)
    logmessage('Connect to DaqServer')
    DaqServer.Connect();
end

% connect to EyeServer
if ~isempty(cfg.EyeServer)
    logmessage('Connect to EyeServer')
    EyeServer.Connect();
    
    % Session launch script was executed, and it defined the struct
    % sesslaunchparams with field .EyeServer_SampleMode
    if  sesslaunchparams.EyeServer_SampleMode
      
      logmessage( 'Enabling EyeServer Sample Mode' )
      EyeServer.SetSampleMode( ) ;
      
    end % EyeServer sample mode
    
    % Session launch script was executed, and it defined the struct
    % sesslaunchparams with field .EyeServer_UniqueTmp
    if  sesslaunchparams.EyeServer_UniqueTmp
      
      edfnam = [ 'tmp' , cfg.Session , '.edf' ] ;
      
    % Default
    else , edfnam = 'tmp.edf' ;
      
    end % EyeLink file name
    
    logmessage( sprintf( 'EyeLink HostPC saving to %s' , edfnam ) )
    EyeServer.Start( edfnam )
    
end

% connect to ControlScreen
if ~isempty(cfg.ControlScreen)
    logmessage('Connect to ControlScreen')
    SGLTrialDataPipe.Open()
    IPCEvent.set_event('ControlScreenDone')
end

% Launch and connect to EchoServer
echstr = fullfile( arcaderoot, 'arcade', 'EchoServer', 'EchoServer.exe' ) ;
if  exist( echstr , 'file' )
  
  % Launch process in background, copy all output to a session-specific log
  % file
  echstr = ...
    [ 'start ', echstr, ' ', cfg.filepaths.Session, filesep, 'echo.txt' ] ;
  if  system( echstr ) ~= 0
    error( 'Failed to launch EchoServer.exe' )
  end
  
  % Give EchoServer.exe time to create the pipe
  sleep( 100 ) ;
  
  % Open write end of communications pipe
  EchoServer.Connect( ) ;
  
end % EchoServer

% At this point, we have opened up all sub-processes. Now find and disable
% all Matlab timers that were set up by processManager, because these lead
% to a ~10% increase in the duration of any timer e.g. when calling
% WaitForEvents with a positive timeout value.
for  t = cellfun( @( p ) p.pollTimer , procs )
  if  isvalid( t )
    stop( t )
  end
end

% Find process identifiers of critical ARCADE processes
apriority ( 'initialisation' , critical )

% Starting ARCADE remote location is requested
f = findobj( 'Type' , 'figure' , 'Tag' , 'remote' ) ;

if  ~ isempty( sesslaunchparams.Location_ArcadeRemote )  &&  ...
    ~ isempty( f )
  
  % Root graphics object
  g = groot ;
  
  % Handle horizontal position for different locations
  switch  lower( sesslaunchparams.Location_ArcadeRemote )
    case  { 'east' , 'northeast' , 'southeast' }
      f.OuterPosition( 1 ) = g.ScreenSize( 3 ) - f.OuterPosition( 3 ) ;
    case  { 'west' , 'northwest' , 'southwest' }
      f.OuterPosition( 1 ) = 1 ;
    case  { 'north' , 'south' }
      f.OuterPosition( 1 ) = ...
        g.ScreenSize( 3 ) / 2  -  f.OuterPosition( 3 ) / 2 ;
  end
  
  % Handle vertical position for different locations
  switch  lower( sesslaunchparams.Location_ArcadeRemote )
    case  { 'north' , 'northeast' , 'northwest' }
      f.OuterPosition( 2 ) = g.ScreenSize( 4 ) - f.OuterPosition( 4 ) ;
    case  { 'south' , 'southeast' , 'southwest' }
      f.OuterPosition( 2 ) = 1 ;
    case  { 'west' , 'east' }
      f.OuterPosition( 2 ) = ...
        g.ScreenSize( 4 ) / 2  -  f.OuterPosition( 4 ) / 2 ;
  end

end % ARCADE remote starting location

% Build cell arrays of window titles and starting window positions. But
% only for windows that must be moved using Win32.
WIN = { sesslaunchparams.Window_EyeServer  ;
        sesslaunchparams.Window_EchoServer } ;
POS = { sesslaunchparams.Position_EyeServer  ;
        sesslaunchparams.Position_EchoServer } ;
      
% Get rid of empty cells
i = cellfun( @isempty , POS ) ;  WIN( i ) = [ ] ;  POS( i ) = [ ] ;

% Move windows to new positions
i = ~ cellfun( @( w , p ) winpos( w , p ) , WIN , POS ) ;

  % Report any failures
  cellfun( @( w ) fprintf( 'Failed to move window %s\n' , w ) , WIN( i ) );
