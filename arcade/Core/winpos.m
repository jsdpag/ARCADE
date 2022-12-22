
% 
% rep = winpos( title , position )
% 
% Finds window with title matching char array 'title' and repositions it
% to position. position is a double vector with values [ x , y , w , h ]
% in pixels giving the distance of the left (x) and top (y) of the window
% from the top-left corner of the screen, and the window's new width (w)
% and height (h). The current window location/size is used for any value
% of position that is negative. rep is non-zero if the window was
% repositioned.
%   
% If title or position is empty then the function simply returns empty.
% If the window title is not found then 0 will be returned.
% 
