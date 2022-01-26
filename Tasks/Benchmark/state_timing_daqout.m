
% 
% state_timing_daqout.m
% 
% ARCADE task file. ESI Frankfut.
% 
% Test how well ARCADE is able to time the duration of task states.
% Uses DAQ server to raise logical value on channel 1 (e.g. TDT RZ2 PortA)
% on entry to timed state, then raises logical value on channel 9 (TDT RZ2
% PortB) on exit from the timed state. A reset state then lowers the
% digital output back to zero.
% 
% The Timed -> Reset state is looped 1000 times per trial. This is because
% scheduling jitter from the OS will lead to noise in the accuracy of state
% timing.
% 
% Each trial tests a progressively larger timout value:
%   
%   Trial , Timeout (ms)
%       1 ,   1           Burn in, ignore this data
%       2 ,   1
%       3 ,   5
%       4 ,  10
%       5 ,  50
%       6 , 100
%       7 , 250
% 
% After the final trial, ARCADE shuts down.
% 
% Written by Jackson Smith - Dec 2021 - Fries Lab (ESI Frankfurt)


%%% CONSTANTS %%%

% Number of times to loop the Time -> Reset states
N = 1000 ;

% Trial number to timeout (ms) map. Give trial TrialData.currentTrial as
% the index to this vector.
TIMOUT = [ 1 , 1 , 5 , 10 , 50 , 100 , 250 ] ;

% Duration of the reset state, prior to setting digital output to daqoff
RESTIM = 50 ; % ms

% DAQ codes
daq1st = 2 ^ 0 ; %   1
daq2nd = 2 ^ 8 ; % 256
daqoff = 0     ;


%%% ARCADE MANAGEMENT %%%

% First trial, create dummy eye window so that ARCADE stops complaining
% that no events were initialised
if      TrialData.currentTrial  ==  1
  
  trackeye ( [ 0 , 0 ] , 1000 , 'dummy' ) ;
  
% Finished, quit ARCADE
elseif  TrialData.currentTrial  ==  numel( TIMOUT )
  
%   trackeye ( 'reset' ) ; % Release resources
  requestQuitSession( ) ; % Quit ARCADE
  
end % ARCADE management

% Report progress
fprintf( 'Trial %d, timeout: %dms\n' , TrialData.currentTrial , ...
  TIMOUT( TrialData.currentTrial ) )


%%% TASK STATES %%%

% Initialisation, guarantee that DAQ digital output is off
S.init = State ( 'init' ) ;
  
    % State actions
    S.init.onEntry = { @( ) DaqServer.EventMarker( daqoff ) } ;
    
    % State transition
    S.init.duration = RESTIM ; % Make sure that DAQ has time to lower dout
    S.init.nextStateAfterTimeout = 'timed' ;
    
    S.init.waitEvents = 'dummyOut' ;
    S.init.nextStateAfterEvent = 'timed';

% Timed state
S.timed = State ( 'timed' ) ;

    % State actions
    S.timed.onEntry = { @( ) DaqServer.EventMarker( daq1st ) } ;
    S.timed.onExit  = { @( ) DaqServer.EventMarker( daq2nd ) } ;

    % State transition
    S.timed.duration = TIMOUT( TrialData.currentTrial ) ;
    S.timed.nextStateAfterTimeout = 'reset' ;
  
% Reset state
S.reset = State ( 'reset' ) ;
  
    % State action
    S.reset.onExit  = { @( ) DaqServer.EventMarker( daqoff ) } ;

    % State transitions
    S.reset.duration = RESTIM ;
    S.reset.nextStateAfterTimeout = 'timed' ;

    S.reset.maxRepetitions = N ;
    S.reset.nextStateAfterMaxRepetitions = 'final' ;


%%% CREATE TRIAL %%%

createTrial ( 'init' , S.init , S.timed , S.reset ) ;

