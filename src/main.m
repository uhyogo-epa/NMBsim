%%%%%%%%%%%%%%%%%%%%%%%%
% PD model simulation
%%%%%%%%%%%%%%%%%%%%%%%%
% Load patient data
data = load('../data/patient_01.mat');
patientParam = data.PatientParam;
drugParam    = data.DrugParam;

% PD model
conc = (0:1/10:6) * 10^-6;
[TOFR_mdl, TOFC_mdl, PTC_mdl] = pd_model(conc, drugParam, patientParam, 'nigrovic');


%%%%%%%%%%%%%%%%%%%%%%%%
% Plot figure
%%%%%%%%%%%%%%%%%%%%%%%%
%TOFR
clf;
subplot(3,1,1);
hold on
plot(TOFR_mdl(1,:)*10^6, TOFR_mdl(2,:),'LineWidth',1) %Simulation        
scatter(data.TOFR(3,:)*10^6, data.TOFR(2,:),'filled') %Monitoring
legend('Simulation', 'Monitoring');
ylabel('TOFR');
xlim([0 6]);
ylim([0 1]);

% Plot TOFC
subplot(3,1,2); 
hold on
plot(TOFC_mdl(1,:)*10^6, TOFC_mdl(2,:),'LineWidth',1) %Simulation        
scatter(data.TOFC(3,:)*10^6, data.TOFC(2,:),'filled') %Monitoring
ylabel('TOFC');
xlim([0 6]);
ylim([0 4]);

% Plot PTC
subplot(3,1,3); 
hold on
plot(PTC_mdl(1,:)*10^6, PTC_mdl(2,:),'LineWidth',1) %Simulation        
scatter(data.PTC(3,:)*10^6, data.PTC(2,:),'filled') %Monitoring
xlabel('Concentration [μM]');
ylabel('PTC');
xlim([0 6]);
ylim([0 15]);
hold off
