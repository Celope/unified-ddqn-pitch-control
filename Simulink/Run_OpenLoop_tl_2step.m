cd(fileparts(matlab.desktop.editor.getActiveFilename))
clear;
clc;
%% Path to files
FAST_InputFileName = '..\IEA3.4-RWT-OpenFAST\IEA-3.4-130-RWT.fst';
Ts = 0.35; %control timestep/0.025 OpenFAST timestep con 0.1 varia poco
TMax=5100; % seconds
rate=7;
%% Simulink configuration
mdl = 'OpenLoop_2step';
agentblk = [mdl '/RL Agent'];
open_system(mdl); 
rng('default')

%% Create RL enviroment
n_states = 5; % [wind_speed,power_error, w_error
% , current_pitch, rotor_speed]
observationInfo = rlNumericSpec([n_states 1],'LowerLimit', ...
            -inf*ones(n_states,1),'UpperLimit',inf*ones(n_states,1));
                %Ts: 0.35   Ts: 0.35   %Ts: 0.35-5100   %Ts: 0.35   0.35       0.375-5100  0.5      0.5       0.5
                %Lf  40     Lf  40     %Lf  40    		%Lf  40     40         40          200      200       200
particion =301; %0.08-376   0.1-301    %0.1-301   	    0.0750-401  0.1-301    0.08-376    0.1-301  0.125-241 0.125-241  0.04-751 0.06-501 0.09-334 0.0625-481
zona = 0.09;    %0.07       0.09       %0.09       	    0.07        0.09       0.07        0.09     0.1       0.1  
step = 0.01;    %0.008      0.005      %0.01      	    0.0125      0.0250     0.04        0.05     0.0625    0.125   
n_actions = 3;
actions = [-step*pi/180, 0, step*pi/180];
actionInfo = rlFiniteSetSpec(actions);
env = rlSimulinkEnv(mdl,agentblk,observationInfo,actionInfo);

%% Create RL-DDQN agent
nI = observationInfo.Dimension(1);  %Number of inputs                      
nO = numel(actionInfo.Elements); %Number o
% f outputs
hidden_1 = 64; %64
hidden_2 = 128;%128
dnn = [
    featureInputLayer(nI,'Normalization','none','Name','state')
    fullyConnectedLayer(hidden_1,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(hidden_2,'Name','fc2')
    reluLayer('Name','relu2')
    fullyConnectedLayer(nO,'Name','fc3')];
dnn = dlnetwork(dnn);
summary(dnn)

criticOptions = rlRepresentationOptions('LearnRate',0.001,'GradientThreshold',1,'L2RegularizationFactor',1e-4);
%Op Lr= 0.0005 y 0.0001, L2 = 1e-2 %Mejora con reward function
critic = rlQValueRepresentation(dnn,observationInfo,actionInfo,'Observation',{'state'},criticOptions);
agentOpts = rlDQNAgentOptions(...
    'SampleTime',Ts,... 
    'UseDoubleDQN',true,...
    'TargetSmoothFactor',1e-2,...% 1e-2
    'TargetUpdateFrequency',20,... % 50
    'DiscountFactor',0.99,...       % 0.99
    'ExperienceBufferLength',1e6,... % 1e6
    'MiniBatchSize',128); %  128

agent = rlDQNAgent(critic,agentOpts);

agent.AgentOptions.EpsilonGreedyExploration.EpsilonDecay = 0.01;
agent.AgentOptions.EpsilonGreedyExploration.Epsilon = 0.1;
agent.AgentOptions.EpsilonGreedyExploration.EpsilonMin = 0.01;
agent.AgentOptions.LearningFrequency = 40;%200, 40 

agent.ExperienceBuffer=rlPrioritizedReplayMemory(observationInfo,actionInfo);
agent.AgentOptions.InfoToSave.ExperienceBuffer=true;
agent.AgentOptions.InfoToSave.Optimizer=true;
agent.AgentOptions.InfoToSave.PolicyState=true;
agent.AgentOptions.InfoToSave.Target=true;

%q = getValue(getCritic(agent), {rand(observationInfo.Dimension(1), 1)});
%% RL training configuration


maxepisodes = 1; %non-episodic task 
maxsteps = ceil((TMax/maxepisodes)/Ts);
trainingOpts = rlTrainingOptions(...
'MaxEpisodes',maxepisodes, ...
'MaxStepsPerEpisode',maxsteps, ...
'Verbose',true);
% ,...;
% 'StopTrainingCriteria','EvaluationStatistic', ...
% 'StopTrainingValue',1); %directory to save the agent

% agent evaluator
evl = rlEvaluator(...
EvaluationFrequency=50, ...
NumEpisodes=5);
%% Train agent
try
    trainingStats = train(agent, env, trainingOpts, Evaluator=evl);
    disp('[INFO] Entrenamiento completado.');
    if ~exist('agent','dir')
        mkdir('agent');
    end
    save('agent/agente_trainPitch.mat','agent');
    save('agent/estadisticasPitch.mat','trainingStats');
catch ME
    disp('[ERROR] Entrenamiento fallido:');
    disp(ME.message);
end

%%
%  Evaluate
%agent = load('../agents/agent_policy_transfer.mat','saved_agent');
rate=7;
Ts = 0.025; %Ts of OPENFAST
TMax=5500;
agent = load('./agent/agente_trainPitch.mat','agent');
agent = agent.agent;
agent.SampleTime=Ts; 
% agent.SampleTime=Ts; 
