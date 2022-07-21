
classdef  onlinefigure < handle
% 
% onlinefigure
% 
% For convenient grouping and handling of online plots.
% 
% Written by Jackson Smith - July 2022 - Fries Lab (ESI Frankfurt)
% 
  

  properties
    
    % Figure handle. Note that the UserData property is reserved.
    fig
    
    % File name. onlinefigure and its figure are saved here.
    fnam
    
    % Struct vector containing all groups
    grp
    
  end
  
  
  methods
    
    function  f = onlinefigure( fnam , varargin )
    %  
    % f = onlinefigure( fnam , ... )
    % 
    % Create a new onlinefigure object and return its handle. By default,
    % the figure and its data will be saved to fnam, unless this is empty.
    % Any optional arguments that follow include valid input to the
    % figure( ) function.
    % 
        
      % fnam is not a string
      if  ~( isrow( fnam ) && ischar( fnam ) )
        error( 'fnam must be a char row vector i.e. a string' )  
      end
      
      % Assign file name
      f.fnam = fnam ;
      
      % Create the figure
      f.fig = figure( varargin{ : } , 'UserData' , f ) ;
      
      % The figure should try to save itself before closing
      f.fig.CloseRequestFcn = @( h , ~ ) onlinefigure.closerequest( f ) ;
      
    end
    
    function  delete( f )
    % 
    % Makes sure that associated figure is saved before destroying
    % onlinefigure handle.
    % 
      
      % The figure still exists, so close/save it first
      if  ishandle( f.fig ) , close( f.fig ) , end
      
    end
    
    function  ax = subplot( f , varargin )
    % 
    % Creates a sub-plot in the object's figure. Accepts the same input
    % arguments as subplot( ), but includes the 'Parent',f.fig Name/Value
    % pair. The applies default parameters to the new axes. Returns new
    % axes handle.
    % 
      
      % Create new axes as subplot in f.fig
      ax = subplot( varargin{ : } , 'Parent' , f.fig ) ;
      
      % Apply formatting
      onlinefigure.defaultaxes( ax )
      
    end
    
    function  g = findgrp( f , id , type )
    % 
    % Return logical vector that locates the group with identifier id in
    % the struct vector f.grp. Optional third arg says whether id is the
    % 'group' identifer or the 'set' identifer.
    % 
      
      % Check optional input arg
      if  nargin < 3
        type = 'group' ;
      end
      
      % Fetch identifier from each group of appropriate type
      switch  type
        case  'group' , identifiers = { f.grp.id  } ;
        case    'set' , identifiers = { f.grp.set } ;
        otherwise , error( 'Programming error, blame Jackson.' )
      end
      
      % Generate logical index
      g = strcmp( id , identifiers ) ;
      
      % Nothing found, id is somehow invalid
      if  ~ any( g )
        
        error( 'No group found with id %s.' , id )
        
      % There should only be one group if type is 'group', otherwise there
      % is a programming error
      elseif  strcmp( type , 'group' )  &&  sum( g ) ~= 1
        
        error( 'Found multiple groups with id %s' , id )
        
      end % err check
      
    end
    
    function  id = getid( f , type )
    % 
    % Return the unique set of identifiers. String type says what for what
    % kind, either 'group' or 'set'.
    % 
      
      % Get all identifiers across groups
      switch  type
        case  'group' , id = { f.grp.id  } ;
        case    'set' , id = { f.grp.set } ;
        otherwise , error( 'Not a valid type of identifier.' )
      end
      
      % Return unique, ordered set
      id = unique( id ) ;
      
    end
    
    function  chkrow( f , g )
    % 
    % Check that the fields of the group specified by index g are all row
    % vectors. This is needed so that values can be easily concatenated
    % across groups. If a field is not a row vector then it is reshaped
    % into one; elements are reshaped in the usual column-major order.
    % 
      
      % Basic input check
      if  ( isnumeric( g ) && ~isscalar( g ) )  ||  ...
          ( islogical( g ) && sum( g ) > 1 )
        
        error( 'Index g must specify a single group.' )
        
      end % in check
      
      % Field names
      for  N = fieldnames( f.grp )' , n = N{ 1 } ;
        
        % Field is empty, skip
        if  isempty( f.grp( g ).( n ) )
          
          continue
          
        % Not a row vector
        elseif  ~ isrow( f.grp( g ).( n ) )
          
          % Reshape into a row
          f.grp( g ).( n ) = f.grp( g ).( n )( : )' ;
          
        end % check field
      end % Field names
    end
    
    function  buttondownfcn( f , d , group , set )
    % 
    % Generic ButtonDownFcn callback for grouped graphics objects. Allows
    % user to select a set of objects (left-click) or a single group (right
    % click). Passes in event data d as well as the group and set ID of the
    % group that the clicked graphics object belongs to.
    % 
      
      % Left-click, select set. Otherwise, select group.
      if  d.Button == 1
        f.select( 'set' , set ) ;
      else
        f.select( 'group' , group )
      end
      
    end
    
    function  addgroup( f , grpid , setid , data , hdata , fupdate )
    % 
    % Add a new group. Must have a unique group id.
    % 
      
      % Basic error check of input
      if  ~ iscellstr( { grpid , setid } )
        
        error( 'id and set must be strings.' )
        
      elseif  ~ isgraphics( hdata )
        
        error( 'hdata must be an array of graphics objects.' )
        
      elseif  ~ isa( fupdate , 'function_handle' )
        
        error( 'fupdate must be a function handle.' )
        
      end
      
      % grp parameter is still empty
      if  isempty( f.grp )
        
        % Initialise it
        f.grp = onlinefigure.groupstruct ;
        
        % Initialise group linear index
        g = 1 ;
        
      % Has this group id been used already?
      elseif  any( strcmp( grpid , { f.grp.id } ) )
        
        error( 'Group id %s already in use.' , grpid )
        
      % Everything is fine, get next position in group struct vector
      else , g = numel( f.grp ) + 1 ;
      end
      
      % Store new group data, note that a struct row vector of size 1 x N
      % is created by default using this syntax. This is essential in the
      % selection function which must concatenate data across groups.
      % Initialise (un)selection parameter cell array.
      f.grp( g ).id = grpid ;
      f.grp( g ).set = setid ;
      f.grp( g ).data = data ;
      f.grp( g ).hdata = hdata ;
      f.grp( g ).fupdate = fupdate ;
      f.grp( g ).seldata = repmat( { {} } , size( hdata ) ) ;
      f.grp( g ).unseldata = f.grp( g ).seldata ;
      
      % Guarantee that new fields are row vectors
      f.chkrow( g )
      
      % Create ButtonDownFcn callback
      cb = @( ~ , d ) f.buttondownfcn( d , grpid , setid ) ;
      
      % Assign this to all graphics objects
      set( hdata , 'ButtonDownFcn' , cb )
      
    end
    
    function  rmgroup( f , id )
    % 
    % Remove a group
    % 
      
      % Basic error check of input
      if  ~ iscellstr( { id } )
        error( 'id must be a string.' )
      end
      
      % Locate it
      g = f.findgrp( id ) ;
      
      % Kill group
      f.grp( g ) = [ ] ;
      
    end
    
    function  bindfit( f , id , hfit , ffit )
    % 
    % Associate graphics objects and a fitting function to an existing
    % group.
    % 
      
      % Basic error check
      if  ~ iscellstr( { id } )
        
        error( 'id must be a string.' )
        
      elseif  ~ isgraphics( hfit )
        
        error( 'hfit must be an array of graphics objects' )
        
      elseif  ~ isa( ffit , 'function_handle' )
        
        error( 'ffit must be a function handle' )
        
      end
      
      % Locate group
      g = f.findgrp( id ) ;
      
      % Bind fitting function and graphics. Initialise (un)selection
      % parameter cell arrays.
      f.grp( g ).hfit = hfit ;
      f.grp( g ).ffit = ffit ;
      f.grp( g ).selfit = repmat( { {} } , size( hfit ) ) ;
      f.grp( g ).unselfit = f.grp( g ).selfit ;
      
      % Check that new fields are row vectors
      f.chkrow( g )
      
      % Copy ButtonDownFcn from data graphics object(s)
      set( hfit , 'ButtonDownFcn' , f.grp( g ).hdata( 1 ).ButtonDownFcn )
      
    end
    
    function  bindparam( f , id , type , varargin )
    % 
    % Bind parameters to a set of graphics objects belonging to group id.
    % type must be one of: 'seldata', 'unseldata', 'selfit', 'unselfit' to
    % specify whether the parameters are applied during 'sel'ection or the
    % 'unsel'ection of graphics objects representing the empirical 'dat'a
    % or the 'fit'ted function. All remaining input args must be cell
    % arrays of Name/Value pairs for each object in the corresponding hdata
    % or hfit graphics array.
    % 
      
      % Basic error check
      if  ~ iscellstr( { id , type } )
        error( 'id and type must be strings.' )
      end
      
      % Locate group
      g = f.findgrp( id ) ;
      
      % Handle type of binding
      switch  type
        
        % (Un)selection of empirical data
        case  { 'seldata' , 'unseldata' } , h = 'hdata' ; 
          
        % (Un)selection of fitted function
        case  { 'selfit' , 'unselfit' } , h = 'hfit' ;
          
        otherwise , error( 'type %s is invalid.' , type )
          
      end % type of binding
      
      % Check that there is input arg for each graphics object
      if  numel( f.grp( g ).( h ) ) ~= numel( varargin )
        
        error( 'Requires one set of parameters for each graphics object.' )
        
      % Must all be cell arrays
      elseif  ~ all( cellfun( @iscell , varargin ) )
        
        error( 'Each parameter set must be a cell array.' )
        
      end % par set check
      
      % Store Parameter/Value sets
      f.grp( g ).( type ) = varargin ;
      
      % Check that new field is row vector
      f.chkrow( g )
      
    end
    
    function  select( f , type , val )
    % 
    % Select either a single group or an entire set of groups. This means
    % that the 'selected' parameters are applied to the groups' graphics
    % objects and that those objects are brought into the foreground.
    % Meanwhile, the 'unselected' parameters are applied to all other
    % graphics objects, which fall into the background.
    % 
    % type must be 'group' or 'set'. val is then the corresponding
    % identifier.
    % 
    % Note, executes drawnow before returning.
    % 
      
      % Basic error check
      if  ~ iscellstr( { type , val } )
        error( 'type and val must be strings.' )
      end
      
      % Find groups with this identifier
      selgrp = f.findgrp( val , type ) ;
      
      % Nothing selected
      if  ~ any( selgrp )
        error( 'There are no groups with %s id %s.' , type , val )
      end
      
      % Tell user which group is selected in window title bar
      f.fig.Name = sprintf( '%s = %s' , type , val ) ;
      
      % Selected / un-selected groups
      for  G = { { selgrp , 'sel' } , { ~selgrp , 'unsel' } }
        
        % Give meaningful names to group(s') index and type of selection
        [ g , seltyp ] = G{ 1 }{ : } ;
        
        % Type of data. Empirical or fitted functions.
        for  DATTYP = { 'data' , 'fit' } , dattyp = DATTYP{ 1 } ;
          
          % Make field names for graphics objects and their parameters
          h = [ 'h' , dattyp ] ;  p = [ seltyp , dattyp ] ;
          
          % Now retrieve these things, across groups
          h = [ f.grp( g ).( h ) ] ;
          p = [ f.grp( g ).( p ) ] ;
          
          % Graphics objects, apply new parameters
          for  i = 1 : numel( h )
            
            % Only do it if parameter set is not empty
            if  ~ isempty( p{ i } ) , set( h( i ) , p{ i }{ : } ) ; end
          
          end % apply new parameters
          
          % Continue to next data type if these are un-selected groups.
          % Because the next step is to bring selected objects to the
          % foreground.
          if  strcmp( seltyp , 'unsel' ) , continue , end
          
          % Find the unique set of parent axes across all graphics objects
          AX = unique( [ h.Parent ] ) ;
          
          % And make a copy of their Children graphics object vectors
          C = { AX.Children } ;
          
          % Once again, cycle through graphics objects
          for  i = 1 : numel( h )
            
            % Identify parent
            ax = AX == h( i ).Parent ;
            
            % Find everything but the graphics object
            c = C{ ax } ~= h( i ) ;
            
            % Put graphics object at the top of that list i.e. draw it on
            % top of everything else
            C{ ax }( : ) = [ h( i ) ; C{ ax }( c ) ] ;
            
          end % graphics objects
          
          % Now assign new Child ordering to each graphics object
          for  i = 1 : numel( AX ) , AX( i ).Children( : ) = C{ i } ; end
          
        end % type of data
      end % selected/un-selected
      
      % Done updates, show them
      drawnow
      
    end
    
    function  update( f , id , index , newdata )
    % 
    % Update empirical data and graphics objects of group with identifier
    % id using the given index and any new data that should be accumulated.
    % Uses the group's fupdate function.
    % 
      
      % Locate group
      g = f.findgrp( id ) ;
      
      % Point to empirical data graphics objects and current state of
      % empirical data.
      hdata = f.grp( g ).hdata ;
       data = f.grp( g ).data  ;
      
      % Apply group's empirical update function.
      data = f.grp( g ).fupdate( hdata , data , index , newdata ) ;
      
      % Store updated data
      f.grp( g ).data = data ;
      
    end
    
    function  fit( f , id )
    % 
    % Fit function to empirical data of group with identifier id.
    % 
      
      % Locate group
      g = f.findgrp( id ) ;
      
      % Point to empirical data graphics objects, state of empirical data,
      % and function fit graphics objects.
      hdata = f.grp( g ).hdata ;
       data = f.grp( g ).data  ;
       hfit = f.grp( g ).hfit  ;
      
      % Nothing bound to fitting function fields, quit now
      if  isempty( hfit ) , return , end
      
      % Apply fitting function
      f.grp( g ).ffit( hfit , hdata , data ) ;
      
    end
    
  end
  
  
  methods ( Static )
    
    function  closerequest( f )
    % 
    % Defines closing behaviour of figure. f is an onlinefigure. Provide
    % this in an anonymous function to conform to callback input arg
    % format.
    % 
      
      % This behaviour should only happen once. If the figure is opened
      % later, then it should close with the default function.
      f.fig.CloseRequestFcn = 'closereq' ;
      
      % Save the associated figure in the specified place
      if  ~ isempty( f.fnam ) , savefig( f.fig , f.fnam , 'compact' ) , end
      
      % Now destroy the figure
      delete( f.fig )
      
      % And the onlinefigure object
      delete( f )
      
    end
    
    function  defaultaxes( ax )
    % 
    % defaultaxes( ax )
    % 
    % Apply default parameters to axes with handle ax. If ax not provided
    % then gca is used.
    % 
      
      if  nargin < 1 , ax = gca ; end
      
      % Default axes parameters. Each column is a name/value pair, name in
      % row 1 and parameter value in row 2.
      DEFPAR = {  'TickDir' , 'out' ;
                  'TickLen' , [ 0.02 , 0.02 ] ;
                'LineWidth' , 1.0 ;
                   'XColor' , 'k' ;
                   'YColor' , 'k' ;
                   'ZColor' , 'k' ;
                 'XLimSpec' , 'tight' ;
                 'XLimMode' , 'auto' ;
                 'YLimSpec' , 'tight' ;
                 'YLimMode' , 'auto' ;
                 'ZLimSpec' , 'tight' ;
                 'ZLimMode' , 'auto' ;
                 'NextPlot' , 'add' ;
                      'Box' , 'off' ;
                 'FontSize' , 10 ;
               'FontWeight' , 'normal' ;
                 'FontName' , 'Arial' }' ;

      % Axis label parameters
      AXIPAR = { 'FontSize' , 11 , 'FontWeight' , 'normal' , ...
        'FontName' , 'Arial' , 'Color' , 'k' } ;
      
      % Apply default axes parameters
      set( ax , DEFPAR{ : } )

      % Axis labels
      for  I = { 'Title' , 'XLabel' , 'YLabel' , 'ZLabel' } , i = I{ 1 } ;

        % Apply default label parameters
        set( ax.( i ) , AXIPAR{ : } )

      end % labels
      
    end
    
    function  s = groupstruct
    % 
    % s = groupstruct
    % 
    % Generate a scalar instance of a struct used to store data for an
    % onlinefigure group. A group consists of a set of graphics object
    % handles that represent empirical data, and another set that represent
    % a fitted function, along with an internal store of data, a function
    % to update that data and the empirical objects, a function to fit the
    % data, and parameters for all graphics objects when selected or
    % unselected.
    % 
    % Fields:
    % 
    %   id - Group identifier, this is mandatory.
    %   set - Set identifier. Multiple groups can be added to the same set.
    %   data - Data used to keep track of the state of empirical data.
    %   hdata - Handles to graphics objects that plot empirical data.
    %   hfit - Handles to graphics objects that plot a fit to the data.
    %   fupdate - Function handle that updates .data and .hdata. Function
    %     must have form data = fupdate( hdata , data , index , newdata ).
    %   ffit - Function handle that updates .hfit. Must have form
    %     ffit( hfit , hdata , data ).
    %   seldata - Sets of parameter name and value pairs that are applied
    %     to each object in .hdata when the group is selected.
    %   unseldata - Like seldata, but when group is un-selected.
    %   selfit - Like seldata, but for objects in .hfit.
    %   unselfit - Like unseldata, but for .hfit.
    % 
      
      % Field names
      s = { 'id', 'set', 'data', 'hdata', 'hfit', 'fupdate', 'ffit', ...
        'seldata', 'unseldata', 'selfit', 'unselfit' } ;
      
      % Add layer of empty cells
      s = [ s ; cell( size( s ) ) ] ;
      
      % Make and return struct
      s = struct( s{ : } ) ;
      
    end
    
  end
  
  
end % onlinefigure

