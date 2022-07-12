
% 
% Test onlinefigure by simulating incoming behavioural, spiking, and LFP
% data on a trial by trial basis. There are two trial conditions. Each data
% modality will modulate as a function of the condition.
% 
% Written by Jackson Smith - Juli 2022 - Fries Lab (ESI Frankfurt)
% 

%% Make GIF in present working directory?

MAKE_GIF = false ;

if  MAKE_GIF
  
  answer = questdlg( [ 'Make ', ...
    fullfile( pwd , 'onlinefigure.gif' ), '?' ] , ...
      'onlinefigure sim' , 'Yes' , 'No' , 'Yes' ) ;
  
  if  strcmp( answer , 'No' ) , MAKE_GIF = false ; end
  
end

%%  Simulation parameters

% Make sure that ARCADE library is visible
add_arcade_to_path

% Total number of conditions
N.cond = 2 ;

% Number of stimulus values tested
N.stim = 7 ;

% Trials per stimulus value, per condition
N.trials = 100 ;

% Total number of trials
N.total = N.cond * N.stim * N.trials ;

% Milliseconds per trial
N.ms = 1000 ;

% Name the conditions
PARAMS.condnam = arrayfun( @( x ) num2str( x ) , 1 : N.cond , ...
  'UniformOutput' , false ) ;

% Stimulus x-axis scaling. This can be either 'linear' or 'log'.
PARAMS.xscale = 'linear' ;

% Sampling rate in Hertz
PARAMS.Fs = 1000 ;

% X-axis values for { condition 1 , condition 2 }. This may be considered
% the stimulus values that are tested. They will be identical in both
% conditions.
switch  PARAMS.xscale
  case  'linear' , PARAMS.xval = 1 : N.stim ;
  case     'log' , PARAMS.xval = 10 .^ ( ( 1 : N.stim ) ./ 3 ) ;
end

% Copy value set, once per condition and return as 1 x 2 cell array
PARAMS.xval = repmat( { PARAMS.xval } , 1 , 2 ) ;

  % Range of stimulus values
  xrng = PARAMS.xval{ 1 }( [ 1 , end ] ) ;
  
  % Apply log10 scaling if necessary
  if  strcmp( PARAMS.xscale , 'log' ) , xrng = log10( xrng ) ; end
  
  % Difference i.e. span of stim values
  xdif = diff( xrng ) ;
  
% NaN vector, same size as xval
PARAMS.xnan = cellfun( @( c ) nan( size( c ) ) , PARAMS.xval , ...
  'UniformOutput' , false ) ;

% Performance (percent correct) in { condition 1 , condition 2 }. Each
% vector specifies a logistic function with parameters [ chance , max
% performance above chance , slope , threshold ]. Better performance is
% seen on condition 1.
PARAMS.performance = ...
  { [ 15 , 95 - 15 , 12 / xdif , 0.4 * diff( xrng ) + xrng( 1 ) ] , ...
    [ 15 , 95 - 15 ,  8 / xdif , 0.6 * diff( xrng ) + xrng( 1 ) ] } ;

% Reaction time will simply be the inverse shape. Parameters are now
% [ min RT , max RT above min , slope , threshold ].
PARAMS.reaction_time = ...
  { [ 100 , 400 , -12 / xdif , 0.4 * diff( xrng ) + xrng( 1 ) ] , ...
    [ 100 , 400 , - 8 / xdif , 0.6 * diff( xrng ) + xrng( 1 ) ] } ;
  
% Firing rate parameters for { condition 1 , condition 2 }. Each vector
% gives the following [ baseline rate , peak rate above baseline ,
% exponential time constant , latency ], where the time constant gives the
% decay rate of an initial transient response. Rates in spk/s, constant and
% latency in ms. Exponential decay rate mu applied by exp( -time / mu ).
PARAMS.rate = { [ 10 , 100 - 10 , 80 , 30 ] , [ 10 , 80 - 10 , 40 , 40 ] };

% LFP peak frequency for { condition 1 , condition 2 }. LFP is a pure
% sinusoid embedded in gaussian white noise.
PARAMS.freq = { 60 , 40 } ;

% Sample the performance and reaction time, we'll get the expected value
% from a logistic function. datplot can return a handle to its own
% implementation of this, which it uses to fit empirical data in some of
% the pre-set plots.
PARAMS.logistic = @( C , x ) C( 1 )  +  C( 2 ) ./ ...
  ( 1 + exp( - C( 3 ) .* ( x - C( 4 ) ) ) ) ;

  % Apply log10 scaling to input values if required
  if  strcmp( PARAMS.xscale , 'log' )
    PARAMS.logistic = @( C , x ) PARAMS.logistic( C , log10( x ) ) ;
  end


%% Set up online plots

% Trials are grouped according to condition numbers 1 and 2. So use these
% numbers as the trial group id's
gid = 1 : 2 ;

% Make a time series vector, in milliseconds
time = 1 : N.ms ;

% Make a frequency vector from 0 up to the Nyquist frequency. Sampling
% frequency is 1000Hz.
freq = ( 0 : N.ms - 1 )  .*  ( PARAMS.Fs ./ N.ms ) ;

  % Locate the frequencies we don't want to plot
  fplot = freq == 0  |  freq > 80 ;
  
  % Keep only plotted parts
  freq( fplot ) = [ ] ;

% Make a new onlinefigure and have it saved to test_onlinefigure.fig on
% closing
ofig = onlinefigure( 'test_onlinefigure' ) ;

% Make figure a bit wider
ofig.fig.Position( 3 ) = ( 1 + 1 / 3 )  .*  ofig.fig.Position( 3 ) ;

% Performance and reaction time plots. Each element contains:
%   { plot type , subplot index , fupdate , ffit , scaling }
for  PAR = { {  'performance' , 1 , @fupdate_perf , @ffit_perf } , ...
             { 'reactiontime' , 4 , @fupdate_perf , @ffit_rt   } }

  % Give meaningful names to plot parameters
  [ ptyp , sind , fupdate , ffit ] = PAR{ 1 }{ : };
  
  % Create empty performance plot
  ax = ofig.subplot( 2 , 3 , sind ) ;
  
  % Plot specific formatting
  switch  ptyp
    case   'performance' , ylabel( '% correct' ) , ylim( [ 0 , 100 ] )
    case  'reactiontime' , ylabel( 'Avg RT (ms)' ) , xlabel( 'Stim value' )
  end

  % Conditions
  for  i = 1 : N.cond

    % Point to values for this condition
    c = PARAMS.condnam{ i } ;
    xval = PARAMS.xval{ i } ; xnan = PARAMS.xnan{ i } ;

    % Empirical error bars with selection and un-selection parameters
    H = errorbar( ax , xval , xnan , xnan , 'LineStyle' , 'none' , ...
      'Marker' , 'none' , 'Tag' , 'error' ) ;
    SEL = { 'Color' , ax.ColorOrder( 1 , : ) / 2 , 'LineWidth' , 1 } ;
    UNS = { 'Color' , [ 0.6 , 0.6 , 0.6 ] , 'LineWidth' , 0.5 } ;

    % Empirical data points with selection and un-selection parameters
    H = [ H , scatter( ax , xval , xnan , 'Tag' , 'data' , ...
      'UserData' , ptyp ) ] ;
    SEL = { SEL , { 'MarkerEdgeColor' , ax.ColorOrder( 1 , : ) / 2 , ...
      'MarkerFaceColor' , ax.ColorOrder( 1 , : ) , 'LineWidth' , 1 } } ;
    UNS = { UNS , { 'MarkerEdgeColor' , [ 0.6 , 0.6 , 0.6 ] , ...
      'MarkerFaceColor' , [ 0.6 , 0.6 , 0.6 ] , 'LineWidth' , 0.5 } } ;

    % Group's id
    id = [ ptyp , c ] ;

    % Initialise internal state data
    data = Welford( 1 , N.stim ) ;

    % Add new graphics group
    ofig.addgroup( id , c , data , H , fupdate )

    % Bind selection/un-selection parameters to these graphics objects
    ofig.bindparam( id ,   'seldata' , SEL{ : } )
    ofig.bindparam( id , 'unseldata' , UNS{ : } )

    % Define x-axis values for fitted curve
    xval = xval( 1 ) : diff( xval( [ 1 , end ] ) ) / 1e3 : xval( end ) ;
    xnan = nan( size( xval ) ) ;
    
    % Create threshold markers for x and y axis, and labels
    H = [ plot( ax , nan( 2 , 2 ) , nan( 2 , 2 ) , 'k--' ) ; 
          text( ax , nan( 1 , 2 ) , nan( 1 , 2 ) , { '' , '' } , ...
            'FontName' , 'Arial' , 'VerticalAlignment' , 'bottom' ) ]' ;
    
      % Tag them
      H( 1 ).Tag = 'xthreshold' ;  H( 3 ).Tag = 'xthlabel' ;
      H( 2 ).Tag = 'ythreshold' ;  H( 4 ).Tag = 'ythlabel' ;
      
      % Selection/Unselection params
      SEL = repmat( { { 'Visible' , 'on'  } } , size( H ) ) ;
      UNS = repmat( { { 'Visible' , 'off' } } , size( H ) ) ;
    
    % Create fitted function line
    H = [ H , plot( ax , xval , xnan , 'Tag' , 'curve' ) ] ;
    SEL = [ SEL , {{ 'Color', ax.ColorOrder( 1 , : ), 'LineWidth' , 1 }} ];
    UNS = [ UNS , {{ 'Color', [ 0.6 , 0.6 , 0.6 ], 'LineWidth', 0.5 }} ];

    % Bind fitted function to data, and selection params to fit objects
    ofig.bindfit( id , H , ffit )
    ofig.bindparam( id ,   'selfit' , SEL{ : } )
    ofig.bindparam( id , 'unselfit' , UNS{ : } )

  end % cond
end % performance / RT plots


% Create new axes for average firing rate
ax = ofig.subplot( 2 , 3 , 2 : 3 , 'Tag' , 'rate' ) ;

% Formatting
xlim( time( [ 1 , end ] ) )
ylabel( 'Firing rate (spk/s)' )
xlabel( 'Time (ms)' )

% Symmetric, Gaussian convolution kernel with 10ms time constant
k = normpdf( -50 : +50 , 0 , 10 ) ; k = k ./ sum( k ) ;

% Conditions
for  i = 1 : N.cond , c = PARAMS.condnam{ i } ;
  
  % Error bars
  H = patch( ax , [ time , flip( time ) ] , ...
    nan( size( [ time , time ] ) ) , ...
      ax.ColorOrder( 1 , : ) , 'FaceAlpha' , 0.6 , 'EdgeColor' , 'none',...
        'Tag' , 'error' ) ;
  SEL = { 'Visible' , 'on' } ;
  UNS = { 'Visible' , 'off' } ;
  
  % Smoothed, average firing rate line
  H = [ H , plot( ax , time , nan( size( time ) ) , 'UserData' , k , ...
    'Tag' , 'data' ) ] ;
  SEL = { SEL , { 'Color' , ax.ColorOrder( 1 , : ) , 'LineWidth' , 1 } } ;
  UNS = { UNS , { 'Color' , [ 0.6 , 0.6 , 0.6 ] , 'LineWidth' , 0.5 } } ;
  
  % Group's id & initialised state data
  id = [ 'rate' , c ] ;
  data = Welford( size( time ) ) ;
  
  % Add new graphics group with selection params
  ofig.addgroup( id , c , data , H , @fupdate_series )
  ofig.bindparam( id ,   'seldata' , SEL{ : } )
  ofig.bindparam( id , 'unseldata' , UNS{ : } )
  
end % cond


% Create new axes for average LFP power
ax = ofig.subplot( 2 , 3 , 5 : 6 ) ;

% Formatting
xlim( freq( [ 1 , end ] ) )
ylabel( 'LFP Power' )
xlabel( 'Frequency (Hz)' )

% Define fit frequencies
fithz = freq( 1 ) : diff( freq( [ 1 , end ] ) ) / 1e3 : freq( end ) ;

% Conditions
for  i = 1 : N.cond , c = PARAMS.condnam{ i } ;
  
  % Error bars
  H = patch( ax , [ freq , flip( freq ) ] , ...
    nan( size( [ freq , freq ] ) ) , ...
      ax.ColorOrder( 1 , : ) , 'FaceAlpha' , 0.6 , 'EdgeColor' , 'none',...
        'Tag' , 'error' ) ;
  SEL = { 'Visible' , 'on' } ;
  UNS = { 'Visible' , 'off' } ;
  
  % Smoothed, average firing rate line
  H = [ H , plot( ax , freq , nan( size( freq ) ) , 'Tag' , 'data' ) ] ;
  SEL = { SEL , { 'Color' , ax.ColorOrder( 1 , : ) , 'LineWidth' , 1.5 } };
  UNS = { UNS , { 'Color' , [ 0.6 , 0.6 , 0.6 ] , 'LineWidth' , 0.5 } } ;
  
  % Group's id & initialised state data
  id = [ 'power' , c ] ;
  data = Welford( size( freq ) ) ;
  
  % Add new graphics group with selection params
  ofig.addgroup( id , c , data , H , @fupdate_series )
  ofig.bindparam( id ,   'seldata' , SEL{ : } )
  ofig.bindparam( id , 'unseldata' , UNS{ : } )
  
  % Create a line that shows the best-fit Gaussian
  H = plot( ax , fithz , nan( size( fithz ) ) , 'k' , 'LineWidth' , 0.5 ) ;
  SEL = { 'Visible' , 'on'  } ;
  UNS = { 'Visible' , 'off' } ;
  
  % Bind fitted function to data, and selection params to fit objects
  ofig.bindfit( id , H , @ffit_power )
  ofig.bindparam( id ,   'selfit' , SEL )
  ofig.bindparam( id , 'unselfit' , UNS )
  
end % cond

% Initialise plot formatting by selecting one condition's graphics objects
ofig.select( 'set' , PARAMS.condnam{ 1 } )


%% Run simulation

% Use default random number generator seed so that we get the same result
% every time
rng( 'default' )

% Create 'deck of cards' for trials. Each element represents one trial.
% First, create deck for trial condition. Condition 1 is in row 1, cond 2
% in row 2. Columns are different stimulus conditions. dim 3 is the
% repetition of trials per stim value and trial condition.
deck.cond = repmat( [ 1 ; 2 ] , 1 , N.stim , N.trials ) ;

% Same again for stimulus values. First, build matrix indexing condition
% across rows, and stim value across columns.
deck.stim = cat( 1 , PARAMS.xval{ : } ) ;

  % Then create trial repetitions
  deck.stim = repmat( deck.stim , 1 , 1 , N.trials ) ;

% Here, we shuffle the deck by creating a linear index from 1 to the total
% number of trials
i = randperm( N.total ) ;

  % Apply the same shuffling to the cond and stim deck so that they are in
  % register
  deck.cond = deck.cond( i ) ;
  deck.stim = deck.stim( i ) ;

% Trials
for  i = 1 : N.total
  
  % Get the trial's condition. This functions as the grouping id, so we'll
  % call it ...
  gid = deck.cond( i ) ;
  
  % Stimulus value on this trial. Call it x to refer to its meaning in the
  % behaviour plots.
  x = deck.stim( i ) ;
  
  % Generate behavioural response %
  
  % Get behaviour coefficients on this trial. Trial condition i.e. grouping
  % id will also serve as a linear index into the .performance cell array.
  C = PARAMS.performance{ gid } ;
  
  % We now have the expected percentage of a correct response at this
  % stimulus value. Scale down to a probability.
  E = PARAMS.logistic( C , x ) ./ 100 ;
  
  % Randomly sample the behavioural outcome
  if  rand  <=  E
    behav = 'c' ; % Signals a correct trial
  else
    behav = 'f' ; % Signals a  failed trial
  end
  
  % onlineplot group id for performance in this condition
  id = [ 'performance' , PARAMS.condnam{ gid } ] ;
  
  % Update the performance plot for this condition
  ofig.update( id , x , behav == 'c' )
  
  % Find best fitting curve
  ofig.fit( id )
  
  % Generate reaction time %
    
  % Only generate/accumulate RT on correct trials
  if  behav  ==  'c'
    
    % RT coefficients
    C = PARAMS.reaction_time{ gid } ;

    % Expected value of the RT at this stim value
    E = PARAMS.logistic( C , x ) ;

    % We'll make the RT variance conditional on the expected value by
    V = ( E ./ 4 ) .^ 2 ;

    % RT will be modelled as a lognormal distrubition. The mean and variance
    % of the associated normal distribution (log transform of lognormal
    % distributed value) is ...
     mu = log( E .^ 2 ./ sqrt( V + E .^ 2 ) ) ;
    sig = sqrt( log( V ./ E .^ 2 + 1 ) ) ;
    
    % Sample reaction time from lognormal distribution
    rt = exp( sig .* randn  +  mu ) ;
    
    % Update onlineplot group id for reaction time in this condition
    id = [ 'reactiontime' , PARAMS.condnam{ gid } ] ;
    ofig.update( id , x , rt )
    ofig.fit( id )
    
  end % RT
  
  % Firing rate %
  
  % Get firing rate parameters for this trial condition
  C = PARAMS.rate{ gid } ;
  
  % Map named variables to corresponding parameter values
  baseline = C( 1 ) ;
      peak = C( 2 ) ;
  timconst = C( 3 ) ;
   latency = C( 4 ) ;
  
  % Expected firing rate at each time point. First, the baseline.
  E = repmat( baseline , 1 , N.ms ) ;
  
  % Find time points from the beginning of the transient response, onwards
  t = time >= latency ;
  
  % Add the exponentially decaying transient response component on top of
  % the baseline rate
  E( t ) = E( t )  +  peak .* exp( - ( time( t ) - latency ) ./ timconst );
  
  % Expected valus is in spikes per second. Convert this to the probability
  % that a spike will occur in any given time bin.
  E = E  ./  PARAMS.Fs ;
  
  % Generate binary spike train. We won't worry about refractory periods.
  % Just use a naive Poisson neurone.
  spk = rand( 1 , N.ms )  <=  E ;
  
  % Average spikes per bin will be computed by default. So normalise by
  % time bin width to get spike rate.
  spk = spk  .*  PARAMS.Fs ;
  
  % Update firing rate onlineplot elements for this condition
  id = [ 'rate' , PARAMS.condnam{ gid } ] ;
  ofig.update( id , [ ] , spk )
  ofig.fit( id )
  
  % Show trial number in title
  title( findobj( ofig.fig , 'Type' , 'axes' , 'Tag' , 'rate' ) , ...
    sprintf( 'Trial %d of %d, Condition %d' , i , N.total , gid ) )
  
  % LFP power %
  
  % LFP frequency for this trial condition. In cycles/second. Convert unit
  % to cycles / millisecond.
  C = PARAMS.freq{ gid } ./ 1000 ;
  
  % Generate LFP as the sum of a sinusoid with randomised phase embedded
  % in Gaussian white noise
  lfp = sin( 2 * pi * C .* time  +  rand * 2 * pi )  +  ...
    10 .* randn( 1 , N.ms ) ;
  
  % Quick power spectrum computation
  y = abs( fft( lfp .* hanning( N.ms )' ) ) .^ 2 ./ N.ms ;
  
  % Eliminate un-plotted parts of the spectrum
  y( fplot ) = [ ] ;
  
  % Update LFP power onlineplot elements for this condition
  id = [ 'power' , PARAMS.condnam{ gid } ] ;
  ofig.update( id , [ ] , y )
  ofig.fit( id )
  
  % Finished %
  
  % Our last job is to select onlineplot elements in this condition set.
  % Calls drawnow to update figure's appearance.
  ofig.select( 'set' , PARAMS.condnam{ gid } )
  
  % GIF %
  
  % Do not make GIF
  if  ~ MAKE_GIF , continue , end
  
  % Convert figure to image
  frame = getframe( ofig.fig ) ;
  image = frame2im( frame ) ;
  
  % Data conversion for export to GIF
  [ A , map ] = rgb2ind( image , 256 ) ;
  
  % Export next image to GIF file
  if  i == 1
    imwrite( A , map , 'onlinefigure.gif' , 'gif' , 'LoopCount' , Inf , ...
      'DelayTime' , 1 / 4.0 ) ;
  else
    imwrite( A , map , 'onlinefigure.gif' , 'gif' , 'WriteMode' , ...
      'append' , 'DelayTime' , 1 / 4.0 ) ;
  end
  
end % trials


%%% Update and fit functions %%%

% index is stimulus value. newdata is 1 or 0 for correct or failed, or the
% reaction time. Scales values by the .UserData value of hdata.
function  data = fupdate_perf( hdata , data , index , newdata )
  
  % Locate graphics objects by data they represent
   herr = findobj( hdata , 'Tag' , 'error' ) ;
  hdata = findobj( hdata , 'Tag' ,  'data' ) ;
  
  % Get a copy of the x-axis values i.e. the stimulus values
  xval = hdata.XData ;
  
  % Locate stimulus value
  i = xval == index ;
  
  % Update Welford array
  data( i ) = data( i ) + newdata ;
  
  % Data type specific scaling factor and error bars
  switch  hdata.UserData
    case   'performance' , scaling = 100 ; err = data( i ).binpci ;
    case  'reactiontime' , scaling =   1 ; err = data( i ).sem    ;
  end
  
  % Update plots
  hdata.YData( i ) = scaling .* data( i ).avg ;
   herr.YData( i ) = hdata.YData( i ) ;
   herr.YNegativeDelta( i ) = scaling .* err ;
   herr.YPositiveDelta( i ) = herr.YNegativeDelta( i ) ;
  
end % fupdate_performance


% Fit psychometric curve to performance data. Least-squares non-linear
% regression.
function  ffit_perf( hfit , hdata , data )
  
  % Define function.
  % Coefficients c = [ guess rate , lapse rate , slope , centre ].
  fun = @( c , x )  c( 1 )  +  ( 100 - c( 1 ) - c( 2 ) ) ./ ...
    ( 1 + exp( -c( 3 ) .* ( x - c( 4 ) ) ) ) ;
  
  % Lower and upper bounds on coefficients
  bounds = { [ 0 , 0 , -Inf , -Inf ] , [ 100 , 100 , +Inf , +Inf ] } ; 
  
  % Execute fit
  ffit_generic( hfit , hdata , data , '%c' , 5 , fun , bounds )
  
end % ffit_perf


% Fit logistic curve to Avg RT data. Least-squares non-linear regression.
function  ffit_rt( hfit , hdata , data )
  
  % Define function.
  % Coefficients c = [ baseline , amplitude , slope , centre ].
  fun = @( c , x )  c( 1 )  +  c( 2 ) ./ ...
    ( 1 + exp( -c( 3 ) .* ( x - c( 4 ) ) ) ) ;
  
  % No bounds
  bounds = { [] , [] } ;
  
  % Execute fit
	ffit_generic( hfit , hdata , data , 'rt' , 3 , fun , bounds )
  
end % ffit_perf


% Generic logistic curve fitting. Assumes 1 x 4 coefficients, and that
% coefficients 3 and 4 are the slope and centre.
function  ffit_generic( hfit , hdata , data , type , n , fun , bounds )
  
  % If count is too low then quit
  if  any( data.count < n ) , return , end
  
  % Locate performance data graphics
  hdata = findobj( hdata , 'Tag' ,  'data' ) ;
  
  % Extract x and y coordinates of data
  x = hdata.XData ;
  y = hdata.YData ;
  
  % Number of data points
  n = numel( x ) ;
  
  % Initialise coefficients
  c0 = zeros( 1 , 4 ) ;
  
  % Set baseline to minimum observed value
  c0( 1 ) = min( y ) ;
  
  % Coefficient 2 has a different meaning for % correct vs RT
  switch  type
    case  '%c' , c0( 2 ) = 100 - max( y ) ; % lapse rate
    case  'rt' , c0( 2 ) = max( y ) - c0( 1 ) ; % amplitude
  end
  
  % Use slope of linear regression line as a starting guess
  b = [ ones( n , 1 ) , x( : ) ]  \  y( : ) ;
  
  % Heuristic decision, reduce magnitude of linear slope
  c0( 3 ) = b( 2 ) / 10 ;
  
  % Get middle x-axis value
  if  mod( numel( x ) , 2 )
    c0( 4 ) = x( ceil( n / 2 ) ) ;
  else
    c0( 4 ) = mean( x( n / 2 + [ 0 , 1 ] ) ) ;
  end
  
  % Disable lsqcurvefit verbosity
  opt = optimoptions( 'lsqcurvefit' , 'Display' , 'off' ) ;
  
  % Best fit
  c = lsqcurvefit( fun , c0 , x , y , bounds{ : } , opt ) ; 
  
  % Locate different elements
  hcurve = findobj( hfit , 'Tag' , 'curve'      ) ;
  hxthr  = findobj( hfit , 'Tag' , 'xthreshold' ) ;
  hxlab  = findobj( hfit , 'Tag' , 'xthlabel'   ) ;
  hythr  = findobj( hfit , 'Tag' , 'ythreshold' ) ;
  hylab  = findobj( hfit , 'Tag' , 'ythlabel'   ) ;
  
  % Draw best fit line
  hcurve.YData( : ) = fun( c , hcurve.XData ) ;
  
  % Locate the threshold value i.e. x-axis position
  hxthr.XData( : ) = c( 4 ) ;
  hythr.XData( : ) = [ hcurve.XData( 1 ) , c( 4 ) ] ;
  
  % Locate the performance at threshold
  hxthr.YData( : ) = [ 0 , fun( c , c( 4 ) ) ] ;
  hythr.YData( : ) = hxthr.YData( 2 ) ;
  
  % Make threshold labels
  hxlab.String = sprintf( '%.2f' , c( 4 ) ) ;
  hylab.String = sprintf( '%.2f' , hxthr.YData( 2 ) ) ;
  
  % Position labels
  hxlab.Position( 1 : 2 ) = [ c( 4 ) , 0 ] ;
  hylab.Position( 1 : 2 ) = [ hcurve.XData( 1 ) , hxthr.YData( 2 ) ] ;
  
end % ffit_perf


% Used to update empirical time or frequency series. If hdata.UserData
% contains a vector then that is used to convolve the data before
% presentation.
function  data = fupdate_series( hdata , data , ~ , newdata )
  
  % Locate graphics objects by data they represent
   herr = findobj( hdata , 'Tag' , 'error' ) ;
  hdata = findobj( hdata , 'Tag' ,  'data' ) ;
  
  % Accumulate new data at max resolution
  data = data + newdata ;
  
  % New average
  avg = data.avg ;
  
  % Compute standard error of the mean
  sem = data.sem ;
  
  % Convolution kernel given
  if  ~ isempty( hdata.UserData ) , kern = hdata.UserData ;
    
    % Apply conv kernel
    avg = conv( avg , kern , 'same' ) ;
    sem = conv( sem , kern , 'same' ) ;
  
  end % scale / conv
  
  % Update avg value plot
  hdata.YData( : ) = avg ;
  
  % Update error bars
  herr.YData( : ) = max( 0 , [ avg - sem , flip( avg + sem ) ] ) ;
  
  % Parent axis
  ax = hdata.Parent ;
  
  % Find all objects in this axis tagged 'data'
  hdata = findobj( ax , 'Tag' , 'data' ) ;
  
  % Concatenate all YData vectors
  y = get( hdata , 'YData' ) ;
  y = [ y{ : } ] ;
  
  % Set axis y-limits to global min and max
  ylim( ax , [ min( y ) , max( y ) ] )
  
end % fupdate_series


% Fit Gaussian to LFP power spectrum, least-squares nonlinear regression
function  ffit_power( hfit , hdata , data )
  
  % Quit unless enough trials accumulated
  if  data( 1 ).count < 5 , return , end
  
  % Locate graphics objects showing average
  hdata = findobj( hdata , 'Tag' ,  'data' ) ;
  
  % Get the x and y axis data
  x = hdata.XData ;
  y = hdata.YData ;
  
  % Define fitted function. c is [ baseline , amplitude , centre , width ].
  fun = @( c , x ) c( 1 ) + ...
    c( 2 ) .* exp( -( x - c( 3 ) ) .^ 2 ./ ( 2 .* c( 4 ) .^ 2 ) ) ;
  
  % Initialise coefficients
  c0 = zeros( 1 , 4 ) ;
  
  % Baseline is min observed value
  c0( 1 ) = min( y ) ;
  
  % Find max value and its index
  [ vmax , imax ] = max( y ) ;
  
  % Amplitude is max value minus baseline
  c0( 2 ) = vmax - c0( 1 ) ;
  
  % Centre is the location of the peak
  c0( 3 ) = x( imax ) ;
  
  % Width is the RMS of the weighted average of the difference from peak
  c0( 4 ) = sqrt(  sum( y .* ( x - c0( 3 ) ) .^ 2 )  ./  sum( y )  ) ;
  
  % Heuristic decision, reduce starting width by order of magnitude
  c0( 4 ) = c0( 4 ) / 10 ;
  
  % Define some bounds on coefs
  lb = [    0 ,        0 , -Inf ,    0 ] ;
  ub = [ vmax , 2 * vmax , +Inf , +Inf ] ;
  
  % Disable lsqcurvefit verbosity
  opt = optimoptions( 'lsqcurvefit' , 'Display' , 'off' ) ;
  
  % Best fit
  c = lsqcurvefit( fun , c0 , x , y , lb , ub , opt ) ;
  
  % Evaluate best fit Gaussian at all frequencies
  hfit.YData( : ) = fun( c , hfit.XData ) ;
  
end % ffit_power

