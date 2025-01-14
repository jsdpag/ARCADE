function runCore(varargin)
% RUNCORE - Start ARCADE 
%
%   runCore([pathToCfg])
%
% INPUT
% -----
%   pathToCfg : optional path to a file with a valid ARCADE configuration,
%               e.g. resulting from a previous session, ArcadeConfig.save 
%               or the configuration GUI (MainScreen).
%               If runCore is called without an input argument, the
%               MainScreen GUI will be opened to configure the session.
%
% runCore starts all enabled ARCADE submodules (EyeServer, ...),
% initializes storing the behavioral data and runs the user's task script
% for each trial, until a quit condition is fullfilled.
%
% For more information, see <a href="matlab:doc('arcade')">the ARCADE guide</a>.
%
% See also ArcadeConfig, launch_processes, createTrial, SGLStateArc

run(fullfile(fileparts(mfilename('fullpath')), '..', 'add_arcade_to_path.m'))

print_header(mfilename, varargin{:})

%--------------------------%
% turn on all warnings
warning('on','all');
% turn off some known warnings
warning('off','MATLAB:RMDIR:RemovedFromPath');
% some notation I used that should be fixed
warning('off','MATLAB:mir_warning_unrecognized_pragma');
%--------------------------%
initialWorkingDirectory = pwd;
cd(fileparts(mfilename('fullpath')));

sessionLogFolder = fullfile(arcaderoot, 'sessionLog');
if ~exist(sessionLogFolder, 'dir') == 7
    assert(dos(['md ' sessionLogFolder]))
end

%% Configure session
if nargin == 0

    cd(fullfile(arcaderoot, 'Tasks'))

    % launch Main Screen
    MSgui = MainScreen.launch;

    if ~ishghandle(MSgui.hfig)
        delete(MSgui)
        fclose('all');
        exit
    end

    cfg = ArcadeConfig(MSgui.cfg); % get cfg file
    cfg.taskFile = MSgui.taskFile;

    % close main screen
    delete(MSgui);
    drawnow()

else
    logmessage(sprintf('Using predefined configuration file\n         %s', varargin{:}))
    cfg = ArcadeConfig(load(varargin{1}));
    if isempty(cfg.taskFile)
        cd(fullfile(arcaderoot, 'Tasks'))
        [filename, pathname] = uigetfile('*.m', 'Pick a MATLAB Taskscript');
        if filename == 0; return; end
        cfg.taskFile = fullfile(pathname, filename);
        cd(initialWorkingDirectory)
    end
end
if isempty(cfg.rng)
    cfg.rng = rng('shuffle', 'twister');
else
    logmessage(...
        sprintf('Using predefined random number generator (method=%s, seed=%d)', ...
        cfg.rng.Type, cfg.rng.Seed))
    rng(cfg.rng.Seed, cfg.rng.Type);
end

%% Initialize folders
[foldersCreated, cfg] = handle_folders(cfg);
if ~foldersCreated
    logmessage('Cancelling session')
    exit
end

% save cfg and associated files in backup folder
logmessage(sprintf('Storing session configuration and associated files in\n         %s', cfg.filepaths.Session))
save_config(cfg)


%% Initialize Servers
evtFile = fullfile(cfg.filepaths.Behaviour, [cfg.sessionName '.evt']);
eventServer = SGLEventMarkerServer.launch(evtFile);

% asynchronously launch subprocesses
[ processes , cfg , sesslaunchparams ] = launch_processes(cfg, ...
    fullfile(cfg.filepaths.Backup, [cfg.sessionName '_cfg.mat']));

cleanup = onCleanup(@() cleanup_function(cfg, processes,sesslaunchparams));

%% Run session
cd(fileparts(cfg.taskFile));

% Launch Behavioural Data Store
BHVstore = SGLBehaviouralStore.launch(cfg);
% Launch a Session
SESSArc  = SGLSessionArc.launch;
% Start Session
logmessage('Starting Session')
SESSArc.mStart;

%% End session

logmessage('Closing ARCADE');

end


function cleanup_function(cfg, procs, sesslaunchparams)

% Request task script shutdown tasks?
if  sesslaunchparams.TaskScript_Shutdown
  
  % Try to find global variable containing shutdown tasks
  global  ARCADE_TASK_SCRIPT_SHUTDOWN
  
  % Not empty, is cell array, contains function handles
  if  ~ isempty( ARCADE_TASK_SCRIPT_SHUTDOWN )  &&  ...
         iscell( ARCADE_TASK_SCRIPT_SHUTDOWN )  &&  ...
      all( cellfun( @( f ) isa( f , 'function_handle' ) , ...
                 ARCADE_TASK_SCRIPT_SHUTDOWN ) )
    
    % Shutdown tasks without crashing
    for f = ARCADE_TASK_SCRIPT_SHUTDOWN( : )'
      try  f{ 1 }( ) ; catch , end
    end
    
  end
end % task script shutdown

% quit eye server
if ~isempty(cfg.EyeServer)
    trackeye('reset')
    if  sesslaunchparams.EyeServer_TransferData
      eyeFile = fullfile(cfg.filepaths.Behaviour,[cfg.sessionName '.edf']);
      EyeServer.Stop(eyeFile)
      waitForFileEvt = IPCEvent('EyeServerDone');
      logmessage('Waiting for eye data transfer')
      result = waitForFileEvt.waitForTrigger(43200000);
      if ~result
          warning('Could not transfer eye data')
      end
    else
      EyeServer.Stop( )
    end
end

% quit control screen
IPCEvent.set_event('ControlScreenDone')

% Close StimServer pipe
if ~isempty(cfg.StimServer)
    StimServer.delete()
end

% Close DaqServer pipe
if ~isempty(cfg.DaqServer)
    DaqServer.delete();
end

% close TrialData pipe
if ~isempty(cfg.ControlScreen)
    SGLTrialDataPipe.delete()
% makeArcadeRemote.m might have been used
else
  % Check for remote
  f = findobj( 'Type' , 'figure' , 'Tag' , 'remote' ) ;
  % Not empty, issue a close request
  if  ~ isempty( f ) , close( f ) , end
end

% Close EchoServer pipe
try
  EchoServer.Disconnect( ) ;
catch
  warning( 'Failed to disconnect EchoServer' )
end

% kill subprocesses
cellfun(@(x) x.stop(), procs)


BHVstore = SGLBehaviouralStore.launch();
BHVstore.mCloseFile;
BHVstore.mESIRead;
delete(BHVstore);

eventServer = SGLEventMarkerServer.launch();
delete(eventServer)

% Make sure that multi-media timers released
[ BE , ms ] = timeBEPeriod ;
if  BE == 'b' , timeBEPeriod( 'e' , ms ) ; end

logmessage('Quitting session');




% fclose('all'); % close all open files

end

















