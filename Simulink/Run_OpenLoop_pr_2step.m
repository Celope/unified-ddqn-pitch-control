cd(fileparts(matlab.desktop.editor.getActiveFilename))
clear;
clc;
%% Path to files
FAST_InputFileName = '..\IEA3.4-RWT-OpenFAST\IEA-3.4-130-RWT.fst';
Ts = 0.35; %control timestep/0.025 OpenFAST timestep con 0.1 varia poco
TMax=800; % seconds
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
%step 0.01 Ts=0.35 T= 500,600, 1040 lf 10 aprende power(10,-3.25)               
               
particion =301;
zona = 0.09;   
step = 0.01;    
n_actions = 3;
actions = [-step*pi/180, 0, step*pi/180];
actionInfo = rlFiniteSetSpec(actions);
env = rlSimulinkEnv(mdl,agentblk,observationInfo,actionInfo);

agent = load('./agent/agente_trainPitch.mat','agent');
agent = agent.agent;
agent.SampleTime=Ts;
%% Agent options

agent.UseExplorationPolicy = 1;
agent.AgentOptions.EpsilonGreedyExploration.Epsilon = 0.025; % 0.1 Initialize epsilon in 10%
agent.AgentOptions.EpsilonGreedyExploration.EpsilonDecay= power(10,-3.25); % power(10,-3.25) = 0.0562 % 1e-5
agent.AgentOptions.LearningFrequency = 10;%200

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
    save('agent/agente_trainPitch_pr.mat','agent');
    save('agent/estadisticasPitch_pr.mat','trainingStats');
catch ME
    disp('[ERROR] Entrenamiento fallido:');
    disp(ME.message);
end

%% Evaluate
Ts = 0.025;
rate=7;
TMax=5250;
agent = load('./agent/agente_trainPitch_pr.mat','agent');
agent = agent.agent;
agent.SampleTime=Ts; 

%% Check that the final (refined) agent is loaded
ref = load('./agent/agente_trainPitch_pr.mat','agent');
assert(isequal(getLearnableParameters(getCritic(agent)), ...
               getLearnableParameters(getCritic(ref.agent))), ...
       'The loaded agent is not agente_trainPitch_pr.mat');