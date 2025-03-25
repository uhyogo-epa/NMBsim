%%%%%%%%%%%%%%%%%%%%%%%%
% PK-PD simulation
%%%%%%%%%%%%%%%%%%%%%%%%
% Load patient data
data = load('../data/patient_01.mat');
patientParam = data.PatientParam;

% Calculate effect-site concentration
time = data.InfusionRate(1,:);
rate = data.InfusionRate(2,:);
conc = pk_magorian(time, rate, patientParam);

% PD model
sample = 1:100:length(time);
[TOFR_mdl, TOFC_mdl, PTC_mdl] = pd_model(conc(sample), data.DrugParam, patientParam, 'cyclic');


%%%%%%%%%%%%%%%%%%%%%
% Plot figures
%%%%%%%%%%%%%%%%%%%%%
fig = gcf; clf;
fig.Position(3:4) = [800,600];
hold on
subplot(4,1,1);
scatter(time(sample), conc(sample))
ylabel('Concentration [M]')
legend('Effect-site concentration')
hold off

% TOFR
subplot(4,1,2);
hold on
scatter(time(sample),  TOFR_mdl(2,:),'LineWidth',1)  %Simulation        
scatter(data.TOFR(1,:),data.TOFR(2,:),'filled') %Monitoring
legend('Simulation', 'Monitoring');
ylabel('TOFR');
%xlim([0 6]);
ylim([0 1]);

% TOFC
subplot(4,1,3); 
hold on
scatter(time(sample), TOFC_mdl(2,:),'LineWidth',1)  %Simulation        
scatter(data.TOFC(1,:),data.TOFC(2,:),'filled') %Monitoring
ylabel('TOFC');
%xlim([0 10000]);
ylim([0 4]);

% PTC
subplot(4,1,4); 
hold on
scatter(time(sample), PTC_mdl(2,:),'LineWidth',1)  %Simulation        
scatter(data.PTC(1,:),data.PTC(2,:),'filled') %Monitoring
xlabel('Time [s]');
ylabel('PTC');
%xlim([0 6]);
ylim([0 15]);
hold off
