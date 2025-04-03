%%%%%%%%%%%%%%%%%%%%%%%%
% PK-PD simulation
%%%%%%%%%%%%%%%%%%%%%%%%
% Load patient data
data = load('../data/patient_01.mat');
patientParam = data.PatientParam;

% Calculate effect-site concentration
time = data.Profiles.Time;
rate = data.Profiles.Rate;
conc = pk_magorian(time', rate', patientParam);

% PD model
sample = 1:30:length(time);
[TOFR_mdl, TOFC_mdl, PTC_mdl] = pd_model(conc(sample), data.DrugParam, patientParam, 'cyclic');


%%%%%%%%%%%%%%%%%%%%%
% Plot figures
%%%%%%%%%%%%%%%%%%%%%
% Initialize figure
fig = gcf; clf;
fig.Position(3:4) = [600, 500];
tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
time_min = time(sample) / 60;
xRight   = time(end)/60;

% === 1. Concentration Plot ===
nexttile;
plot(time_min, conc(sample)*1e6,'LineWidth', 2);
ylab1 = ylabel('Concentration [\muM]');
legend('Effect-site concentration', 'Location', 'best');
xlim([0 xRight]);

% === 2. TOFR ===
nexttile; box on; hold on;
% Simulation
h1 = plot(time_min, TOFR_mdl(2,:), 'LineWidth', 2);  
% Monitoring
h2 = scatter(data.TOFR(1,:)/60, data.TOFR(2,:), 'filled');  
% Monitoring (recovery)
TOFR     = rmmissing(Profiles(:, {'Time', 'TOFR'}));
TOFR_rec = TOFR(length(data.TOFR)+1:end,:);
h3 = scatter(TOFR_rec.Time/60, TOFR_rec.TOFR, 36, 'x', ...
    'MarkerEdgeColor', h2.CData, 'LineWidth', 1.5); 
ylab2 = ylabel('TOFR');
legend([h1, h2, h3], {'Simulation', 'Monitoring', 'Monitoring (recovery)'}, 'Location', 'best');
xlim([0 xRight]);
ylim([0 1]);

% === 3. TOFC ===
nexttile; box on; hold on;
% Simulation
h1 = plot(time_min, TOFC_mdl(2,:), 'LineWidth', 2);
% Monitoring
h2 = scatter(data.TOFC(1,:)/60, data.TOFC(2,:), 'filled');
% Monitoring (recovery)
TOFC     = rmmissing(Profiles(:, {'Time', 'TOFC'}));
TOFC_rec = TOFC(length(data.TOFC)+1:end, :);
h3 = scatter(TOFC_rec.Time/60, TOFC_rec.TOFC, 36, 'x', ...
    'MarkerEdgeColor', h2.CData, 'LineWidth', 1.5); 
ylab3 = ylabel('TOFC');
xlim([0 xRight]);
ylim([0 4]);

% === 4. PTC ===
nexttile; box on; hold on;
plot(time_min, PTC_mdl(2,:),'LineWidth', 2);            % Simulation
scatter(data.PTC(1,:)/60, data.PTC(2,:), 'filled');     % Monitoring
ylab4 = ylabel('PTC');
xlabel('Time [min]');
xlim([0 xRight]);
ylim([0 15]);

% === Align y-label positions ===
pos2 = get(ylab2, 'Position');
xpos = pos2(1)-2;
set(ylab1, 'Position', [xpos, ylab1.Position(2), ylab1.Position(3)]);
set(ylab2, 'Position', [xpos, ylab2.Position(2), ylab1.Position(3)]);
set(ylab3, 'Position', [xpos, ylab3.Position(2), ylab3.Position(3)]);
set(ylab4, 'Position', [xpos, ylab4.Position(2), ylab4.Position(3)]);
clear fig ylab1 ylab2 ylab3 ylab4 pos2 xpos xRight

%saveas(gcf, '../docs/images/patient_timecourse.png')
%saveas(gcf, '../docs/images/patient_timecourse.eps', 'epsc')