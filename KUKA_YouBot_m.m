classdef MidModuleAssignment_KUKA_YouBot_m < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TeleoperateKUKAyouBotUIFigure  matlab.ui.Figure
        VisionSensorPanel              matlab.ui.container.Panel
        CaptureImageButton             matlab.ui.control.Button
        ConnectButton                  matlab.ui.control.Button
        MobileBaseMovementPanel        matlab.ui.container.Panel
        DirectionButtonGroup           matlab.ui.container.ButtonGroup
        ParallelLeftButton             matlab.ui.control.ToggleButton
        ParallelRightButton            matlab.ui.control.ToggleButton
        StopButton                     matlab.ui.control.ToggleButton
        TurnLeftButton                 matlab.ui.control.ToggleButton
        TurnRightButton                matlab.ui.control.ToggleButton
        BackwardButton                 matlab.ui.control.ToggleButton
        ForwardButton                  matlab.ui.control.ToggleButton
        GripperControlsPanel           matlab.ui.container.Panel
        youBotGripperSwitch            matlab.ui.control.Switch
        youBotGripperSwitchLabel       matlab.ui.control.Label
        TeleoperatingKUKAYoubotusingMATLABandCoppeliaSimLabel  matlab.ui.control.Label
        MidModuleAssignmentLabel       matlab.ui.control.Label
        Label                          matlab.ui.control.Label
        youBotArmJoint4Slider          matlab.ui.control.Slider
        youBotArmJoint4SliderLabel     matlab.ui.control.Label
        youBotArmJoint0Slider          matlab.ui.control.Slider
        youBotArmJoint0SliderLabel     matlab.ui.control.Label
        JointControlsPanel             matlab.ui.container.Panel
        youBotArmJoint3Slider          matlab.ui.control.Slider
        youBotArmJoint3SliderLabel     matlab.ui.control.Label
        youBotArmJoint1Slider          matlab.ui.control.Slider
        youBotArmJoint1SliderLabel     matlab.ui.control.Label
        youBotArmJoint2Slider          matlab.ui.control.Slider
        youBotArmJoint2SliderLabel     matlab.ui.control.Label
    end

    
    properties (Access = private)
        % declare variables that we will use as global variables to store
        % the Coppeliasim remote api object and the client. 
        cSim;
        clientID;
        youBotArmJoint0;
        youBotArmJoint1;
        youBotArmJoint2;
        youBotArmJoint3;
        youBotArmJoint4;
        rollingJoint_fr;
        rollingJoint_fl;
        rollingJoint_rr;
        rollingJoint_rl;
        cameraHandle;
    end
    
    methods (Access = private)
        % this function will establish remote connection to the Coppeliasim
        % using the remoteApi libaray. 
        function setConnectionToCoppeliaSim(app)
           client = RemoteAPIClient();
           app.cSim = client.require('sim');
        end

        function getObjectHandles(app)
            % get handles for each joints, wheels and gripper joints. 
            [~, app.youBotArmJoint0] = app.cSim.GetObjectHandle( 'youBotArmJoint0');
            [~, app.youBotArmJoint1] = app.cSim.GetObjectHandle( 'youBotArmJoint1');
            [~, app.youBotArmJoint2] = app.cSim.GetObjectHandle( 'youBotArmJoint2');
            [~, app.youBotArmJoint3] = app.cSim.GetObjectHandle( 'youBotArmJoint3');
            [~, app.youBotArmJoint4] = app.cSim.GetObjectHandle( 'youBotArmJoint4');
            [~, app.rollingJoint_fr] = app.cSim.GetObjectHandle( 'rollingJoint_fr');
            [~, app.rollingJoint_fl] = app.cSim.GetObjectHandle( 'rollingJoint_fl');
            [~, app.rollingJoint_rr] = app.cSim.GetObjectHandle( 'rollingJoint_rr');
            [~, app.rollingJoint_rl] = app.cSim.GetObjectHandle( 'rollingJoint_rl');
            [~, app.cameraHandle] = app.cSim.GetObjectHandle( 'Vision_sensor');
        end

        function sendCommandsToJoint(app, jointHandle, value)
            if app.clientID ~= -1
               % Send Commands Robot Joints
               [~] = app.cSim.SetJointTargetPosition( jointHandle, deg2rad(value));
            else
                disp("Error while Connection to CoppeliaSim");
                app.Label.Text = "Error while connection to CoppeliaSim!";
                app.Label.BackgroundColor = "1.00,0.00,0.00";
            end
        end
        
        
        function sendCommandsToGripper(app, action)
            % send signal to Object 'Rectangle7' which holds the gripper
            % controls and it's child script listen to the singal 'gripperState' and performs action 
            % of closing or opening the grippers.
           if app.clientID ~= -1
                if action == "Open"
                    [~]= app.cSim.SetInt32Signal('gripperState',1); % Opening
                else 
                    [~]= app.cSim.SetInt32Signal('gripperState',0); % Closing
                end
           else
               disp("Error while Connection to CoppeliaSim");
               app.Label.Text = "Error while connection to CoppeliaSim!";
               app.Label.BackgroundColor = "1.00,0.00,0.00";
           end
        end
        
        function setRobotMovement(app,forwBackVel,leftRightVel,rotVel)
            % Apply the desired wheel velocities:
            [~] = app.cSim.SetJointTargetVelocity( app.rollingJoint_fl, -forwBackVel-leftRightVel-rotVel);
            [~] = app.cSim.SetJointTargetVelocity( app.rollingJoint_rl, -forwBackVel+leftRightVel-rotVel);
            [~] = app.cSim.SetJointTargetVelocity( app.rollingJoint_rr, -forwBackVel-leftRightVel+rotVel);
            [~] = app.cSim.SetJointTargetVelocity( app.rollingJoint_fr, -forwBackVel+leftRightVel+rotVel);
        end
        
        function syncWithSceneObjects(app)
            if app.clientID ~= -1
                [~, position]=app.cSim.GetJointPosition(app.youBotArmJoint0);
                app.youBotArmJoint0Slider.Value= double(rad2deg(position));
                [~, position]=app.cSim.GetJointPosition(app.youBotArmJoint1);
                app.youBotArmJoint1Slider.Value= double(rad2deg(position));
                [~, position]=app.cSim.GetJointPosition(app.youBotArmJoint2);
                app.youBotArmJoint2Slider.Value= double(rad2deg(position));
                [~, position]=app.cSim.GetJointPosition(app.youBotArmJoint3);
                app.youBotArmJoint3Slider.Value= double(rad2deg(position));
                [~, position]=app.cSim.GetJointPosition(app.youBotArmJoint4);
                app.youBotArmJoint4Slider.Value= double(rad2deg(position));
                disp(app.youBotArmJoint0Slider.Value);
                disp(app.youBotArmJoint1Slider.Value);
                disp(app.youBotArmJoint2Slider.Value);
                disp(app.youBotArmJoint3Slider.Value);
                disp(app.youBotArmJoint4Slider.Value);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
           app.ConnectButton.Text = "Connect to CoppeliaSim";
           app.Label.Text = "Not connected to Coppeliasim";
           app.Label.BackgroundColor = "0.00,1.00,1.00";
           app.clientID = -1;
        end

        % Value changed function: youBotArmJoint0Slider
        function youBotArmJoint0SliderValueChanged(app, event)
            value = app.youBotArmJoint0Slider.Value;
            sendCommandsToJoint(app, app.youBotArmJoint0, value);     
        end

        % Value changed function: youBotArmJoint1Slider
        function youBotArmJoint1SliderValueChanged(app, event)
            value = app.youBotArmJoint1Slider.Value;
            sendCommandsToJoint(app, app.youBotArmJoint1, value);
        end

        % Value changed function: youBotArmJoint2Slider
        function youBotArmJoint2SliderValueChanged(app, event)
            value = app.youBotArmJoint2Slider.Value;
            sendCommandsToJoint(app, app.youBotArmJoint2, value);
        end

        % Value changed function: youBotArmJoint3Slider
        function youBotArmJoint3SliderValueChanged(app, event)
            value = app.youBotArmJoint3Slider.Value;
            sendCommandsToJoint(app, app.youBotArmJoint3, value);
        end

        % Value changed function: youBotArmJoint4Slider
        function youBotArmJoint4SliderValueChanged(app, event)
           value = app.youBotArmJoint4Slider.Value;
           sendCommandsToJoint(app, app.youBotArmJoint4, value);
        end

        % Value changed function: youBotGripperSwitch
        function youBotGripperSwitchValueChanged(app, event)
           sendCommandsToGripper(app, app.youBotGripperSwitch.Value);
        end

        % Selection changed function: DirectionButtonGroup
        function DirectionButtonGroupSelectionChanged(app, event)
            selectedButton = app.DirectionButtonGroup.SelectedObject;
            % sends commands to move the robot base
            if app.clientID ~= -1
                switch selectedButton.Text
                    case "Forward"
                        setRobotMovement(app,1,0,0);
                    case "Backward"
                        setRobotMovement(app,-1,0,0);
                    case "Turn Right"
                       setRobotMovement(app,1,0,0.7);
                    case "Turn Left"
                       setRobotMovement(app,1,0,-0.7); 
                    case "Parallel Right"
                       setRobotMovement(app,0,1,0);
                    case "Parallel Left"
                       setRobotMovement(app,0,-1,0); 
                    otherwise
                        setRobotMovement(app,0,0,0);
                 end
            else
               disp("Error while Connection to CoppeliaSim");
               app.Label.Text = "Error while connection to CoppeliaSim!";
               app.Label.BackgroundColor = "1.00,0.00,0.00";
            end
        end

        % Close request function: TeleoperateKUKAyouBotUIFigure
        function TeleoperateKUKAyouBotUIFigureCloseRequest(app, event)
            result = uiconfirm(app.TeleoperateKUKAyouBotUIFigure,'Do you want to close the app and disconnect from Coppeliasim?', 'Close request');
            if strcmpi(result,'OK')
                delete(app)
            end
            
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            if app.ConnectButton.Text == "Connect to CoppeliaSim"
                 % initialize/establish connection with Coppeliasim 
                app.Label.Text = "Connecting....";
                app.Label.BackgroundColor = "0.00,1.00,1.00";
                pause(2);
                setConnectionToCoppeliaSim(app);
                if app.clientID > -1
                    app.Label.Text = "Connected to CoppeliaSim!";
                    app.Label.BackgroundColor = "0.00,1.00,0.00";
                    app.ConnectButton.Text = "Disconnect from CoppeliaSim";
                    getObjectHandles(app);
                    syncWithSceneObjects(app);
                else 
                    app.Label.Text = "Error while connection to CoppeliaSim!";
                    app.Label.BackgroundColor = "1.00,0.00,0.00";
                end
            else
                app.cSim.Finish(-1);
                app.ConnectButton.Text = "Connect to CoppeliaSim";
                app.Label.Text = "Not connected to Coppeliasim";
                app.Label.BackgroundColor = "0.00,1.00,1.00";
            end
        end

        % Button pushed function: CaptureImageButton
        function CaptureImageButtonPushed(app, event)
           %Get Image from the vision sensor
           if app.clientID ~= -1
               [~, ~ ,img] = app.cSim.GetVisionSensorImage2( app.cameraHandle, 0);
                imshow(img);
           else
               disp("Error while Connection to CoppeliaSim");
               app.Label.Text = "Error while connection to CoppeliaSim!";
               app.Label.BackgroundColor = "1.00,0.00,0.00";
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create TeleoperateKUKAyouBotUIFigure and hide until all components are created
            app.TeleoperateKUKAyouBotUIFigure = uifigure('Visible', 'off');
            app.TeleoperateKUKAyouBotUIFigure.Position = [100 100 964 793];
            app.TeleoperateKUKAyouBotUIFigure.Name = 'Teleoperate KUKA youBot';
            app.TeleoperateKUKAyouBotUIFigure.CloseRequestFcn = createCallbackFcn(app, @TeleoperateKUKAyouBotUIFigureCloseRequest, true);
            app.TeleoperateKUKAyouBotUIFigure.Scrollable = 'on';

            % Create JointControlsPanel
            app.JointControlsPanel = uipanel(app.TeleoperateKUKAyouBotUIFigure);
            app.JointControlsPanel.Title = 'Joint Controls';
            app.JointControlsPanel.Position = [34 72 619 574];

            % Create youBotArmJoint2SliderLabel
            app.youBotArmJoint2SliderLabel = uilabel(app.JointControlsPanel);
            app.youBotArmJoint2SliderLabel.HorizontalAlignment = 'right';
            app.youBotArmJoint2SliderLabel.Position = [24 298 96 22];
            app.youBotArmJoint2SliderLabel.Text = 'youBotArmJoint2';

            % Create youBotArmJoint2Slider
            app.youBotArmJoint2Slider = uislider(app.JointControlsPanel);
            app.youBotArmJoint2Slider.Limits = [-151 146];
            app.youBotArmJoint2Slider.MajorTicks = [-250 -151 -50 0 50 100 146];
            app.youBotArmJoint2Slider.ValueChangedFcn = createCallbackFcn(app, @youBotArmJoint2SliderValueChanged, true);
            app.youBotArmJoint2Slider.Position = [70 286 498 3];

            % Create youBotArmJoint1SliderLabel
            app.youBotArmJoint1SliderLabel = uilabel(app.JointControlsPanel);
            app.youBotArmJoint1SliderLabel.HorizontalAlignment = 'right';
            app.youBotArmJoint1SliderLabel.Position = [23 403 96 22];
            app.youBotArmJoint1SliderLabel.Text = 'youBotArmJoint1';

            % Create youBotArmJoint1Slider
            app.youBotArmJoint1Slider = uislider(app.JointControlsPanel);
            app.youBotArmJoint1Slider.Limits = [-65 90];
            app.youBotArmJoint1Slider.MajorTicks = [-65 -35 -5 0 5 35 65 90];
            app.youBotArmJoint1Slider.ValueChangedFcn = createCallbackFcn(app, @youBotArmJoint1SliderValueChanged, true);
            app.youBotArmJoint1Slider.Position = [71 379 508 3];

            % Create youBotArmJoint3SliderLabel
            app.youBotArmJoint3SliderLabel = uilabel(app.JointControlsPanel);
            app.youBotArmJoint3SliderLabel.HorizontalAlignment = 'right';
            app.youBotArmJoint3SliderLabel.Position = [29 202 96 22];
            app.youBotArmJoint3SliderLabel.Text = 'youBotArmJoint3';

            % Create youBotArmJoint3Slider
            app.youBotArmJoint3Slider = uislider(app.JointControlsPanel);
            app.youBotArmJoint3Slider.Limits = [-102 102];
            app.youBotArmJoint3Slider.MajorTicks = [-102 -90 -78 -66 -54 -42 -30 -18 -6 0 6 18 30 42 54 66 78 90 102];
            app.youBotArmJoint3Slider.ValueChangedFcn = createCallbackFcn(app, @youBotArmJoint3SliderValueChanged, true);
            app.youBotArmJoint3Slider.Position = [84 189 492 3];

            % Create youBotArmJoint0SliderLabel
            app.youBotArmJoint0SliderLabel = uilabel(app.TeleoperateKUKAyouBotUIFigure);
            app.youBotArmJoint0SliderLabel.HorizontalAlignment = 'right';
            app.youBotArmJoint0SliderLabel.Position = [56 567 96 22];
            app.youBotArmJoint0SliderLabel.Text = 'youBotArmJoint0';

            % Create youBotArmJoint0Slider
            app.youBotArmJoint0Slider = uislider(app.TeleoperateKUKAyouBotUIFigure);
            app.youBotArmJoint0Slider.Limits = [-169 169];
            app.youBotArmJoint0Slider.MajorTicks = [-169 -150 -100 -50 0 50 100 150 169];
            app.youBotArmJoint0Slider.ValueChangedFcn = createCallbackFcn(app, @youBotArmJoint0SliderValueChanged, true);
            app.youBotArmJoint0Slider.Position = [106 548 508 3];

            % Create youBotArmJoint4SliderLabel
            app.youBotArmJoint4SliderLabel = uilabel(app.TeleoperateKUKAyouBotUIFigure);
            app.youBotArmJoint4SliderLabel.HorizontalAlignment = 'right';
            app.youBotArmJoint4SliderLabel.Position = [57 171 96 22];
            app.youBotArmJoint4SliderLabel.Text = 'youBotArmJoint4';

            % Create youBotArmJoint4Slider
            app.youBotArmJoint4Slider = uislider(app.TeleoperateKUKAyouBotUIFigure);
            app.youBotArmJoint4Slider.Limits = [-165 165];
            app.youBotArmJoint4Slider.MajorTicks = [-165 -143 -121 -99 -77 -55 -33 -11 0 11 33 55 77 99 121 143 165];
            app.youBotArmJoint4Slider.ValueChangedFcn = createCallbackFcn(app, @youBotArmJoint4SliderValueChanged, true);
            app.youBotArmJoint4Slider.Position = [115 154 492 3];

            % Create Label
            app.Label = uilabel(app.TeleoperateKUKAyouBotUIFigure);
            app.Label.WordWrap = 'on';
            app.Label.Position = [34 659 222 22];
            app.Label.Text = '';

            % Create MidModuleAssignmentLabel
            app.MidModuleAssignmentLabel = uilabel(app.TeleoperateKUKAyouBotUIFigure);
            app.MidModuleAssignmentLabel.HorizontalAlignment = 'center';
            app.MidModuleAssignmentLabel.FontSize = 18;
            app.MidModuleAssignmentLabel.Position = [384 712 197 23];
            app.MidModuleAssignmentLabel.Text = 'Mid Module Assignment';

            % Create TeleoperatingKUKAYoubotusingMATLABandCoppeliaSimLabel
            app.TeleoperatingKUKAYoubotusingMATLABandCoppeliaSimLabel = uilabel(app.TeleoperateKUKAyouBotUIFigure);
            app.TeleoperatingKUKAYoubotusingMATLABandCoppeliaSimLabel.HorizontalAlignment = 'center';
            app.TeleoperatingKUKAYoubotusingMATLABandCoppeliaSimLabel.Position = [273 680 420 22];
            app.TeleoperatingKUKAYoubotusingMATLABandCoppeliaSimLabel.Text = 'Teleoperating KUKA Youbot using MATLAB and CoppeliaSim.';

            % Create GripperControlsPanel
            app.GripperControlsPanel = uipanel(app.TeleoperateKUKAyouBotUIFigure);
            app.GripperControlsPanel.Title = 'Gripper Controls';
            app.GripperControlsPanel.Position = [708 538 199 107];

            % Create youBotGripperSwitchLabel
            app.youBotGripperSwitchLabel = uilabel(app.GripperControlsPanel);
            app.youBotGripperSwitchLabel.HorizontalAlignment = 'center';
            app.youBotGripperSwitchLabel.Position = [29 62 82 22];
            app.youBotGripperSwitchLabel.Text = 'youBotGripper';

            % Create youBotGripperSwitch
            app.youBotGripperSwitch = uiswitch(app.GripperControlsPanel, 'slider');
            app.youBotGripperSwitch.Items = {'Close', 'Open'};
            app.youBotGripperSwitch.ValueChangedFcn = createCallbackFcn(app, @youBotGripperSwitchValueChanged, true);
            app.youBotGripperSwitch.Position = [73 28 54 24];
            app.youBotGripperSwitch.Value = 'Open';

            % Create MobileBaseMovementPanel
            app.MobileBaseMovementPanel = uipanel(app.TeleoperateKUKAyouBotUIFigure);
            app.MobileBaseMovementPanel.Title = 'Mobile Base Movement';
            app.MobileBaseMovementPanel.Position = [708 192 199 290];

            % Create DirectionButtonGroup
            app.DirectionButtonGroup = uibuttongroup(app.MobileBaseMovementPanel);
            app.DirectionButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @DirectionButtonGroupSelectionChanged, true);
            app.DirectionButtonGroup.Title = 'Direction';
            app.DirectionButtonGroup.Position = [29 21 134 221];

            % Create ForwardButton
            app.ForwardButton = uitogglebutton(app.DirectionButtonGroup);
            app.ForwardButton.Text = 'Forward';
            app.ForwardButton.Position = [11 167 100 23];

            % Create BackwardButton
            app.BackwardButton = uitogglebutton(app.DirectionButtonGroup);
            app.BackwardButton.Text = 'Backward';
            app.BackwardButton.Position = [11 146 100 23];

            % Create TurnRightButton
            app.TurnRightButton = uitogglebutton(app.DirectionButtonGroup);
            app.TurnRightButton.Text = 'Turn Right';
            app.TurnRightButton.Position = [11 125 100 23];

            % Create TurnLeftButton
            app.TurnLeftButton = uitogglebutton(app.DirectionButtonGroup);
            app.TurnLeftButton.Text = 'Turn Left';
            app.TurnLeftButton.Position = [11 104 100 23];

            % Create StopButton
            app.StopButton = uitogglebutton(app.DirectionButtonGroup);
            app.StopButton.Text = 'Stop';
            app.StopButton.Position = [11 38 100 23];
            app.StopButton.Value = true;

            % Create ParallelRightButton
            app.ParallelRightButton = uitogglebutton(app.DirectionButtonGroup);
            app.ParallelRightButton.Text = 'Parallel Right';
            app.ParallelRightButton.Position = [12 82 100 23];

            % Create ParallelLeftButton
            app.ParallelLeftButton = uitogglebutton(app.DirectionButtonGroup);
            app.ParallelLeftButton.Text = 'Parallel Left';
            app.ParallelLeftButton.Position = [11 60 100 23];

            % Create ConnectButton
            app.ConnectButton = uibutton(app.TeleoperateKUKAyouBotUIFigure, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.BackgroundColor = [0.8 0.8 0.8];
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Position = [40 712 184 23];
            app.ConnectButton.Text = 'Connect to Coppeliasim';

            % Create VisionSensorPanel
            app.VisionSensorPanel = uipanel(app.TeleoperateKUKAyouBotUIFigure);
            app.VisionSensorPanel.Title = 'Vision Sensor';
            app.VisionSensorPanel.Position = [708 72 199 85];

            % Create CaptureImageButton
            app.CaptureImageButton = uibutton(app.VisionSensorPanel, 'push');
            app.CaptureImageButton.ButtonPushedFcn = createCallbackFcn(app, @CaptureImageButtonPushed, true);
            app.CaptureImageButton.Position = [40 21 100 23];
            app.CaptureImageButton.Text = 'Capture Image';

            % Show the figure after all components are created
            app.TeleoperateKUKAyouBotUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MidModuleAssignment_KUKA_YouBot_m

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TeleoperateKUKAyouBotUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TeleoperateKUKAyouBotUIFigure)
        end
    end
end