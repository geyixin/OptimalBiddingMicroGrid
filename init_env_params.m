NBlocks = 24;                   % No of bidding blocks in a day
NDays = 300;                    % No of days of training data
NEpisodes = 1500;               % No of episodes of training proposed
min_bid_p = 1;                  % Min Bid price
max_bid_p = 5;                  % Max Bid price
min_bid_q = 0;                  % Min Bid quantity
max_bid_q = 30;                 % Max bid quantity
bat_eff_init = 0.8;             % Combined Effiency of the battery and inverter
bat_eff_final = 0.2;
bat_eff_lifetime = 5000;
bat_cap = 20;                   % Battery Capacity
bat_charge_rate = 2.5;          % Battery charge or discharge capability / hour
bat_charge_min = 0.2*bat_cap;   % Minimum soc in the battery
alpha = 0.2;                    % Learning rate
gamma = 1;                      % discount factor
epsilon = 0.2;                  % Exploration rate
grid_rate = 6;                  % Grid power unit rate
bid_p = 0.8*grid_rate;          % Fixed bid rate - 80% of grid rate

n_hid = 18;                     % Number of hidden layer units
update_freq = 100;

w1 = randn(6,n_hid);
b1 = randn(n_hid,1);
w2 = randn(n_hid,1);
b2 = randn(1,1);

numOfVars = 22;                 % Num of State and Action features
tetha=randn(numOfVars,1);

%% Importing data for training the agent

demand_a = xlsread('Demand Data_Hourly')./1000; % Actual Demand
demand_a = demand_a(:,5:28);    % Remove time information

solar_a = xlsread('solar_hourly')./1000;              % Actual Solar Production
solar_a = (reshape(solar_a(:,4),24,365))';

acp_a = readtable('ACP_Hourly2.xlsx');
acp_a = (reshape(cellfun(@str2num,acp_a.ACP)./1000,24,365))';   % Actual Area Control Prices

max_acp = max(max(acp_a));

%% Generating demand prediction samples from normal distribution around imported data
avg_demand = mean(demand_a,1);
min_demand = min(min(demand_a));
max_demand = max(max(demand_a));
std_demand = avg_demand*0.05;           % Std Dev of 5 percent of average in that block
demand_pred = (ones(size(demand_a))*diag(avg_demand)+randn(size(demand_a)))*diag(std_demand);

demand_pred(demand_pred<min_demand)=min_demand;
demand_pred(demand_pred>max_demand)=max_demand;
demand_norm=demand_pred./max_demand;
demand_norm_a=demand_a./max_demand;

%% Generating solar production prediction samples from normal distribution around imported data
avg_solar = mean(solar_a,1);
min_solar = min(min(solar_a));
max_solar = max(max(solar_a));        
std_solar = avg_solar*0.05;           % Std Dev of 5 percent of average in that block
solar_pred = (ones(size(solar_a))*diag(avg_solar)+randn(size(solar_a)))*diag(std_solar);

solar_pred(solar_pred<min_solar)=min_solar;
solar_pred(solar_pred>max_solar)=max_solar;
solar_norm=solar_pred./max_solar;
solar_norm_a=solar_a./max_solar;

%% Storing the parameters into convenient structures
bat_params = struct('bat_eff_init',bat_eff_init,'bat_eff_final',bat_eff_final,'bat_eff_lifetime',bat_eff_lifetime,'bat_cap',bat_cap,'bat_charge_rate',bat_charge_rate,'bat_charge_min',bat_charge_min);
env_params = struct('gamma',gamma,'NBlocks',NBlocks,'NDays',NDays,'NEpisodes',NEpisodes,'min_bid_p',min_bid_p,'max_bid_p',max_bid_p,'min_bid_q',min_bid_q,'max_bid_q',max_bid_q,'grid_rate',grid_rate,'bid_p',bid_p);
[env_params(:).bat_params] = bat_params;

weights = struct('w1',w1,'w2',w2,'b1',b1,'b2',b2);
agent_params = struct('alpha',alpha,'epsilon',epsilon,'update_freq',update_freq,'n_hid',n_hid);
[agent_params(:).weights] = weights;
[agent_params(:).target_weights] = weights;

energy_data = struct('demand_a',demand_a,'solar_a',solar_a,'acp_a',acp_a,'max_acp',max_acp,'demand_pred',demand_pred,'solar_pred',solar_pred,'demand_norm',demand_norm,'demand_norm_a',demand_norm_a,'solar_norm',solar_norm,'solar_norm_a',solar_norm_a);
