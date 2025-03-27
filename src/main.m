%%%%%%%%%%%%%%%%%%%%%%%%
% PD model simulation
%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:1

    % Load patient data
    data = load(sprintf('../data/patient_%02d.mat', i));
    patientParam = data.PatientParam;
    drugParam    = data.DrugParam;
    
    % PD model
    conc = (0:1/20:8) * 10^-6;
    [TOFR_mdl, TOFC_mdl, PTC_mdl] = pd_model(conc, drugParam, patientParam, 'cyclic');    
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % Plot figure
    %%%%%%%%%%%%%%%%%%%%%%%%
    clf;
    tiledlayout(3,1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % TOFR
    nexttile;
    hold on
    plot(TOFR_mdl(1,:)*1e6, TOFR_mdl(2,:), 'LineWidth', 1); % Simulation
    scatter(data.TOFR(3,:)*1e6, data.TOFR(2,:), 'filled');  % Monitoring
    ylab1 = ylabel('TOFR'); pos1 = get(ylab1, 'Position');
    xlim([0 8]);
    ylim([0 1]);
    legend('Simulation', 'Monitoring');
    
    % TOFC
    nexttile;
    hold on
    plot(TOFC_mdl(1,:)*1e6, TOFC_mdl(2,:), 'LineWidth', 1);
    scatter(data.TOFC(3,:)*1e6, data.TOFC(2,:), 'filled');
    ylab2 = ylabel('TOFC'); pos2 = get(ylab2, 'Position');
    xlim([0 8]);
    ylim([0 4]);
    set(ylab2, 'Position', [pos1(1), pos2(2), pos2(3)]) % Align Y-axis label
    
    % PTC
    nexttile;
    hold on
    plot(PTC_mdl(1,:)*1e6, PTC_mdl(2,:), 'LineWidth', 1);
    scatter(data.PTC(3,:)*1e6, data.PTC(2,:), 'filled');
    ylab3 = ylabel('PTC'); pos3 = get(ylab3, 'Position');
    xlabel('Concentration [\muM]');
    xlim([0 8]);
    ylim([0 15]);
    set(ylab3, 'Position', [pos1(1), pos3(2), pos3(3)]) % Align Y-axis label
    clear ylab1 ylab2 ylab3 pos1 pos2 pos3

    %saveas(gcf, sprintf('../docs/images/patient_%02d.png', i))

end