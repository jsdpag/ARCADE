
% 
% Test Welford's online algorithm for calculating variance. As described
% here:
% 
%   https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Welford's_online_algorithm
% 
% See references:
% 
%   Welford, B. P. (1962). "Note on a method for calculating corrected sums of squares and products". Technometrics. 4 (3): 419–420. doi:10.2307/1266577. JSTOR 1266577.
%   Donald E. Knuth (1998). The Art of Computer Programming, volume 2: Seminumerical Algorithms, 3rd edn., p. 232. Boston: Addison-Wesley.
%   Chan, Tony F.; Golub, Gene H.; LeVeque, Randall J. (1983). "Algorithms for computing the sample variance: Analysis and recommendations" (PDF). The American Statistician. 37 (3): 242–247. doi:10.1080/00031305.1983.10483115. JSTOR 2683386.
%   Ling, Robert F. (1974). "Comparison of Several Algorithms for Computing Sample Means and Variances". Journal of the American Statistical Association. 69 (348): 859–866. doi:10.2307/2286154. JSTOR 2286154.
% 


%% Compute Welford's vs sample mean and variance

% Number of data points
N = 1e4 ;

% Data
x = randn( N , 1 ) ;

% Accumulate sample mean and variance
sm = zeros( N , 1 ) ;
sv = zeros( N , 1 ) ;

% Accumulate Welford's mean and variance
  wm = zeros( N , 1 ) ;
  wv = zeros( N , 1 ) ;

  % Initialise
  wm( 1 ) = x( 1 ) ;

% Initialise Welford's variables

  % Sum across data
  S = x( 1 ) ;
  
  % Mean at n-1
  m_nm1 = S ;
  
  % Sum-of-squares of differences from mean at n-1
  M_nm1 = 0 ;
  
% Calculate sample and online mean & variance

  % Samples 2 to N
  for  n = 2 : N

    % Sample mean and variance
    sm( n ) = mean( x( 1 : n ) ) ;
    sv( n ) =  var( x( 1 : n ) ) ;
    
    % Update running sum
    S = S + x( n ) ;
    
    % Current mean
    m_n = S ./ n ;
    
    % Current sum of squared differences
    M_n = M_nm1  +  ( x( n ) - m_nm1 ) .* ( x( n ) - m_n ) ;
    
    % Store current online mean and var
    wm( n ) = m_n ;
    wv( n ) = M_n ./ ( n - 1 ) ;
    
    % Update mean and sum-of-squares at n-1
    m_nm1 = m_n ;
    M_nm1 = M_n ;

  end % samples

  
%% Plot data

figure
h = plot( ( 1 : N )' , [ sm , wm ] ) ;
h( 1 ).LineWidth = 5 ;
h( 2 ).LineWidth = 2 ;
title( 'Means' )

figure
h = plot( ( 1 : N )' , [ sv , wv ] ) ;
h( 1 ).LineWidth = 5 ;
h( 2 ).LineWidth = 2 ;
title( 'Variances' )

