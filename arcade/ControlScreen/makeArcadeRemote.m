
function  makeArcadeRemote
% 
% makeArcadeRemote
% 
% If the session's ArcadeConfig ControlScreen property is set to empty,
% then the session will default to providing a minimalist user interface.
% It will contain a 'Pause' button; that is all. This will be created and
% maintained by the Matlab process that executes runCore. It will not
% create a separate Matlab process, which is done to execute
% runControlScreen.m.
% 
  
  
  % Create figure as a container for the remote
  fig = figure( 'MenuBar' , 'none' , 'ToolBar', 'none' , ...
    'DockControls' , 'off' , 'NumberTitle' , 'off' , 'Tag' , 'remote' , ...
      'CloseRequestFcn' , '' , 'Visible' , 'off' ) ;
  
  
  % Create 'Pause' button
  pb = uicontrol( fig , 'Style' , 'pushbutton' , 'String' , 'Pause' , ...
    'FontSize' , 11 , 'Visible' , 'off' ) ;
  
  % Use default vertical position as the margin size
  margins = pb.Position( 1 : 2 ) ;
  
  % Extend width and height of button
  pb.Position( 3 : 4 ) = [ 3 , 1.5 ] .* pb.Position( 3 : 4 ) ;
  
  % Make a handle to the Win32 event PauseCoreRequested which is detected
  % by the SGLSessionArc to pause the session.
  pauseCoreEvt = IPCEvent( 'PauseCoreRequested' ) ;
  
  % The action of the pause button is to trigger the pause event
  pb.Callback = @( ~ , ~ ) pauseCoreEvt.trigger( ) ;
  
  
  % Compute height and width of remote
  w = pb.Position( 3 ) + 2 * margins( 1 ) ;
  h = pb.Position( 4 ) + 2 * margins( 2 ) ;
  
  % Apply new width and height without moving the top-left corner of the
  % figure
  fig.Position = ...
    [ fig.Position( 3 : 4 ) - [ w , h ] + fig.Position( 1 : 2 ) , w , h ] ;
  
  % Show everything
  set( [ fig , pb ] , 'Visible' , 'on' )
  
  
end % makeArcadeRemote

