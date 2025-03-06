model = "nigrovic";


load('../temp/patient_04.mat');


C = 0:10*10^-6/100:10*10^-6;
[TOFr_opt, TOFc_opt, PTC_opt] = pd_model(C,drugParam,param,model);

fig = figure(i);
subplot(3,1,1);
x = C;
x1 = TOFr_f1(2,:);
y1 = TOFr_opt(2,:);
hold on
plot(x*10^6,y1,'LineWidth',1)
scatter(x1*10^6,TOFr_f1(3,:),'filled')
legend('Calculation result', 'Measurement result');
ylabel('TOFratio');
xlim([0 6]);
ylim([0 1]);

subplot(3,1,2); 
x2 = TOFc_f1(2,:);
y2 = TOFc_opt(2,:);
hold on
plot(x*10^6,y2,'LineWidth',1)
scatter(x2*10^6,TOFc_f1(3,:),'filled')
ylabel('TOFcount');
xlim([0 6]);
ylim([0 4]);

subplot(3,1,3); 
x3 = PTC_f1(2,:);
y3 = PTC_opt(2,:);
hold on
plot(x*10^6,y3,'LineWidth',1)
scatter(x3*10^6,PTC_f1(3,:),'filled')
xlabel('Concentration [μM]');
ylabel('PTC');
xlim([0 6]);
ylim([0 15]);
hold off