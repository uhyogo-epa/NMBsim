function D = pk_magorian(time, u, patientParam)

    % Model Parameters
    k10 = 0.0364/60;
    k12 = 0.1082/60;
    k13 = 0.0203/60;
    k21 = 0.1807/60;
    k31 = 0.0176/60;
    k41 = patientParam.ke0/60;
    k14 = 0;
    V1 = 5.96;

    k10 = 0.1/60;
    k12 = 0.21/60;
    k13 = 0.028/60;
    k21 = 0.13/60;
    k31 = 0.01/60;
    k41 = patientParam.ke0/60; %0.168/60;
    k14 = k41*0.01/60;
    V1 = 0.044 * 100;
    
    A = [-k10-k12-k13-k14 k12 k13 k14 ;k21 -k21 0 0 ;k31 0 -k31 0 ;k41 0 0 -k41];
    B = [1/V1;0;0;0];
   
    % Infusion rate considering time delay
    t_and_u = [0 time+patientParam.t_delay; 0 u];

    % PK simulation
    options = odeset('MaxStep',1);
    [~,x] = ode45(@(t,x) pk_equation(x, t_and_u, A, B, t), time, zeros(4,1), options);
    D = x(:,4)';

end

% Generic PK model equation
function dxdt = pk_equation(x,t_and_u,A,B,time)

   u_in = interp1(t_and_u(1,:),t_and_u(2,:),time,'previous');
   if isnan(u_in)
       u_in = 0;
   end
   dxdt = A*x + B*u_in ;
   
end