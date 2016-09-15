classdef (Sealed) SGLSessionArc < MSWindow
    % [SINGLETON CLASS] STATE ARC
    %   Loop through trials
    %   controls the movement from one trial to another
    
    % Methods/functions
    % - set max number of trials
    % - give m file (trial script) to run
    
    % - start experiment here
    % - insert pause experiment here
    % - update behavioural data (retrieve from state arc)
    
    %---------------------------------------------%
    % unknown   - Jarrod, wrote class
    % 10.4.2015 - Jarrod, added in colors (background and pause screen)
    % 10.4.2015 - Jarrod, added in event markers for pause/resume 
    %  5.7.2015 - Jarrod, added in user quit session 
    %  6.7.2015 - Jarrod, implemented a temporary fix for writing the last
    %   trial in the BHV. Until now the last trial was not written to the BHV. 
    %  6.7.2015 - Jarrod, fixed bug with max trials (number not string, and >= vs >)
    % - (JSXSpinner is a number already)
    % 13.8.2015 - Jarrod, added SGLBackground class
    % 21.4.2016 - Jarrod, added some documentation/notes

    properties (SetAccess = private)
        isRunning  = false;
        hwnd_ctrl  = [];
        hwnd_pause = [];
    end
    
    methods (Static)
        function this = launch
            persistent thisObj
            if isempty(thisObj) || ~isvalid(thisObj)
                thisObj = SGLSessionArc;
            end
            this = thisObj;
        end
    end
    
    methods (Access = private)
        function this = SGLSessionArc
        end
    end
    
    methods 
        %# Trial Loop
        function mRunSession(this) % run session 
            %** TODO: replace StimControl **
            %----------------------------------%
            %            Objects 
            CntlSrnPipe = SGLCoreCntlPipe.launch;       % get ControlScreen Pipe 
            EventServer = SGLEventMarkerServer.launch;  % eventmarkers 
            BHVstore    = SGLBehaviouralStore.launch;   % behavioural store (for CFG)
            StimControl = SGLStimServerGeneral.launch;  % provides access to general StimServer functions
            StimBckgrnd = SGLBackgroundObject.launch;   % allows images for background
            
            %----------------------------------%
            %        get Parameters 
            maxTrials       = BHVstore.cfg.MaximumNumberOfTrials;
            eventPause      = BHVstore.cfg.EventMarker.Pause;
            eventResume     = BHVstore.cfg.EventMarker.Resume;

            %----------------------------------%
            %         Set parameters 
            StimBckgrnd.backgroundColor = round(BHVstore.cfg.BackgroundRGB*255); % colours
            StimBckgrnd.pauseColor      = round(BHVstore.cfg.PauseRGB*255);
            
            StimControl.enablePD(1);    % enable use of photo-diode
            StimBckgrnd.setBackground;  % make sure background is correct color 

            % this function will be asked whether to quit the session or
            % not, after the task script has been run 
            requestQuitSession('init');
            
            % find the control screen
            % how best to handle the name 
            this.hwnd_ctrl = this.mGetGUIWindow('Control Screen');
            java.lang.Thread.sleep(20);
            %result = this.mSetActiveWindow(this.hwnd_ctrl);
            result = this.mSetForegroundWindow(this.hwnd_ctrl);
            

            %** session is running, break point ***
            % startTrial
            % time the loop time, 
            % how long does it take to make all the calls
            % from leaving the users script to calling it again 
            
            while 1
                % starting new Trial 
                % -> send start Trial Event
                % reactiontime( setmode, varargin )
                % start a tic counter at the start of a trial
                % - holds value as a persistent variable 

                % Create a new Trial
                % includes update ControlScreen
                BHVstore.mCreateTrialData; 
                % Create an instance of StateArc
                StateArc = SGLStateArc.launch;
                %---------------------------------------%
                % Run User's Task Script in separate WS 
                EditableVars = BHVstore.mGetEditableVariables;
                TrialData    = BHVstore.mGetTrialData;
                TaskFile     = BHVstore.cfg.taskFile;
                this.mEvalTrialScript(EditableVars,TrialData,TaskFile)
                % return from User's Workspace

                trialerror_tic('start'); % Start trial
                
                try
                    % try to run user's script
                    StateArc.mRunTrial; % user vars are destroyed
                catch ME
                    % turn of eye timer
                    %EyeServer = SGLEyeServer.launch;
                    % EyeServer.mPollEye(false);
                    % issue with the user's script
                    %
                    % add a kill processes here
                    % although some errors are a result
                    % the StimServer freezing and then 
                    % everything must be shut down 
                    
                    ME
                    keyboard
                end

                % trial is Done!
                % -> this is where I would send an 'EndOfTrial' trigger 
                delete(StateArc); % delete StateArc

                % read ControlScreen pipe
                msgs = CntlSrnPipe.mReadMessagePipeEmpty;
                quitSession = false;
                
                % -- Pause Requested? --
                % also allows the user to quit the current session
                if ~isempty(msgs) && any(strcmpi('pause_request',msgs))
                    % launch pause GUI 
                    EventServer.mSendEventMarker(eventPause);      % send enter Pause marker event 
                    StimBckgrnd.setPauseScreen;
                    
                    % user manually requests quit 
                    quitSession = this.mUserPauseScreen(BHVstore); % returns user request
                    
                    EventServer.mSendEventMarker(eventResume);     % send enter Pause marker event 
                    StimBckgrnd.setBackground;
                end
                
                % check if the user has requested to quit the session 
                userQuitSession = requestQuitSession('read');
                if userQuitSession
                    disp('User requested quit session.');
                end
                
                % before processing a possible quit request ...
                %   write the BHV contents
                BHVstore.tmpWriteBinaryBHV(BHVstore.currentTrial);

                % -- Quit Requested or Max Trials Reached? --
                if BHVstore.currentTrial >= maxTrials || quitSession || userQuitSession
                    delete(StimBckgrnd);
                    delete(StimControl); % important to keep track of objects
                    break;
                end
            end
        end
        %# get the hwnd to the GUI window 
        function hwnd = mGetGUIWindow(this,winName)
            hwnd = this.mFindWindow('SunAwtFrame',winName);
        end

    end
    
    methods (Static = true)
        %# Launch User's Pause Screen
        function quitSess = mUserPauseScreen(BHVstore) 
            % get the cfg from the Behavioural Store,
            % and pass working copy of CFG
            %BHVstore = SGLBehaviouralStore.launch;
            while 1
                PauseGui = PauseScreen.launch(BHVstore.cfg); % launch Pause Screen
                quitSess = PauseGui.userQuitRequest;         % get user quit request
                if quitSess, break; end;
                % only modify cfg if user selected resume 
                BHVstore.cfg = PauseGui.cfg;% retreive the cfg
                break;
            end
            
            delete(PauseGui);
            %set(0, 'currentfigure', this.hfig); % make current figure
            drawnow; % force draw
            
            % give some time to complete the draw,
            % so the pause figure is destroyed before resuming
            java.lang.Thread.sleep(20);
        end
        
        
        
        
        %# Evaluate the Trial Script provided 
        function mEvalTrialScript(EditableVars,TrialData,TaskFile) %#ok<INUSL> 

            % retrieve Editable Variables and unpack in this workspace
            SGLSessionArc.mUnpackStruct(EditableVars);
            clear EditableVars; % clear structure 
       
            %-----------------------------------%
            %        Run User's Script
            run(TaskFile); 
            %-----------------------------------%
        end
        
        %# unpack structure into callers workspace
        function mUnpackStruct(strct)
            fields = fieldnames(strct);
            for k = 1:length(fields)
                assignin('caller',fields{k},strct.(fields{k}))
            end
        end
        
%{
        % move this to a separate static class
        % use it for finding variable, objects, etc 
        %# find name of class
        function objStr = mGetWSVariable(varname)
            w = evalin('caller','whos');
            varClass = {w.class}';
            varName  = {w.name}';
            obj_idx  = find(strcmp(varClass,varname));
            % ensure there is one and only one instance of StateArc
            if numel(obj_idx)==0
                disp('Failed to find an instance of StateArc');
            elseif numel(obj_idx)>1
                disp('Found more than one instance of StateArc');
            end
            objStr = varName{obj_idx};
        end
        %}
        %# delete class
       % function mDeleteObject(objname)
       %     evalin('caller',[objname,'.delete']);
       % end
        
    end
    
    
    methods
        %# public start 
        function mStart(this)
            if ~this.isRunning
                this.mRunSession;
            else
                disp('WARNING: SESSION ARC already Running...');
            end
        end
        
        %function pause(this)
        %end
    end
    
end


% function RunUserTaskScript(TrialData,retEVFcn,TaskScript)
% 
% 
% retEVFcn();
% clear retEVFcn;
% 
% whos
% 
% run(TaskScript);
% objName = this.getWSVariable('StateArc');
% eval([objName,'.runTrial;']);
% 
% % cleanup after trial
% this.deleteObject(objName);
% 
% 
% end



%{
w = whos;
varClass = {w.class}';
varName  = {w.name}';
obj_idx  = find(strcmp(varClass,'StateArc'));
% ensure there is one and only one insatnce of StateArc
if numel(obj_idx)==0
    disp('Failed to find an instance of StateArc');
elseif numel(obj_idx)>1
    disp('Found more than one instance of StateArc'); 
end
toc(t)

eval([varName{obj_idx},'.runTrial;']);
  
    

% either SessionArc calls StateArc
% or user does, state arc must be a singleton 
% 

w = whos;
varClass = {w.class}';
varName  = {w.name}';
obj_idx  = find(strcmp(varClass,'StateArc'));
% ensure there is one and only one insatnce of StateArc
if numel()==0
    disp('Failed to find an instance of StateArc');
elseif numel()>1
    disp('Found more than one instance of StateArc'); 
end
(varName{obj_idx}).runTrial;

%mc = ?StateArc
%findobj(

%W = findobj('-property','states')
%}












