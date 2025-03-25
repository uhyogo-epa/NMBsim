function [TOFr, TOFc, PTC] = pd_model(conc, drugParam, patientParam, postsyn_model)

  TOFr = zeros(2, length(conc));
  TOFc = zeros(2, length(conc));
  PTC  = zeros(2, length(conc));

  for k = 1:length(conc)

      D = conc(k);

      %%%%%%%%%%%%%%%%%%
      % TOF   
      %%%%%%%%%%%%%%%%%%
      % Presynaptic model
      A0 = acetylcholine_release(D, 'tof', patientParam);
      
      % Post synaptic model
      if postsyn_model == "nigrovic"
         twich = twich_data_nigrovic(A0, D, drugParam, patientParam);
      else
         twich = twich_data_cyclic(A0, D, drugParam, patientParam);
      end
      
      % TOFR
      TOFr(:,k) = [D; twich(4)/twich(1)];
                
      % TOFcount
      tofc = 0;
      for i = 1:4; if twich(i) > 0.03; tofc=tofc+1; end; end
      TOFc(:,k) = [D;tofc];

      %%%%%%%%%%%%%%%%%%%%%%
      % PTC
      %%%%%%%%%%%%%%%%%%%%%%
      % Presynaptic model
      A0 = acetylcholine_release(D, 'ptc', patientParam);

      % Postsynaptic model
      if postsyn_model == "nigrovic"
          twich = twich_data_nigrovic(A0, D, drugParam, patientParam);
      else
          twich = twich_data_cyclic(A0, D, drugParam, patientParam);
      end

      % PTC
      ptc  = 0;
      for i = 1:15; if twich(i)>0.03; ptc=ptc+1; end; end
      PTC(:,k) = [D;ptc];

  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Presynaptic model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function A0 = acetylcholine_release(D, tof_or_ptc, patientParam)  

    if tof_or_ptc == "tof"        
       p  = patientParam.Prel;   
       period = 0.5;
       count = 4;
    elseif tof_or_ptc == "ptc"
       p  = patientParam.Prel * patientParam.Fptp;   
       period = 1.0;
       count = 15;
    end

    % calculation
    A0 = zeros(1,count);    
    n_ini = 1.0;
    opts = odeset('MaxStep',5);

    for  i = 1:count
        % replenishment
        [~,n_i] = ode45(@(t, n) replenish_model(t, n, D, patientParam), [0, period], n_ini, opts);
        n_end    = n_i(end);

        % release
        A01  = patientParam.A01;
        Prel = patientParam.Prel;

        A0(i) = (A01 * p * n_end) / Prel;
        n_ini = n_end - n_end * p;
    end
end

function dndt = replenish_model(~,n, D, patientParam)

    % calculate time constant
    Trep0 = patientParam.Trep0;
    TrepE = patientParam.TrepE;
    rT = patientParam.rT;
    TC50 = patientParam.TC50;    
    trep = Trep0 + TrepE * (D^rT/(D^rT+TC50^rT));
    
    % differential equation
    dndt = (1-n)/trep;
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Postsynaptic model (Nigrovic)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function twich = twich_data_nigrovic(A0, D, drugParam, patientParam)
 
    % Base value for nondimensionalization
    R_base = patientParam.Rtotal;
    T_base = 10^-3;
    ka_base = 1 / (R_base * T_base);
    kd_base = 1 / T_base;
    
    % Nondimensional parameters
    Param.D_ = D / R_base;
    drugParam.kaA1_ = drugParam.kaA1 / ka_base;
    drugParam.kaA2_ = drugParam.kaA2 / ka_base;
    drugParam.kaD1_ = drugParam.kaD1 / ka_base;
    drugParam.kaD2_ = drugParam.kaD2 / ka_base;
    drugParam.kdA1_ = drugParam.kdA1 / kd_base;
    drugParam.kdA2_ = drugParam.kdA2 / kd_base;
    drugParam.kdD1_ = drugParam.kdD1 / kd_base;
    drugParam.kdD2_ = drugParam.kdD2 / kd_base;
    patientParam.Rtotal_ = patientParam.Rtotal / R_base;
    drugParam.khd_ = drugParam.khd * T_base;
    A0_ = A0 / R_base;
    
    % Calculation
    sz = length(A0);
    twich = zeros(1,sz);
    for i = 1:sz
    
        D_ = Param.D_;
        Rtotal_ = patientParam.Rtotal_;
        kaD1_ = drugParam.kaD1_;
        kaD2_ = drugParam.kaD2_;
        kdD1_ = drugParam.kdD1_;
        kdD2_ = drugParam.kdD2_;    
        DRD0 = (Rtotal_ * D_^2)/((D_ + (kdD1_ / kaD1_))*(D_ + (kdD2_ / kaD2_)));
        DRO0 = (Rtotal_ * D_ * (kdD2_ / kaD2_)) / ((D_ + (kdD1_ / kaD1_)) * (D_ + (kdD2_ / kaD2_)));
        ORD0 = (Rtotal_ * D_ * (kdD1_ / kaD1_)) / ((D_ + (kdD1_ / kaD1_)) * (D_ + (kdD2_ / kaD2_)));
    
        % opts = odeset('MaxStep',5e-3);
        [~,y] = ode45(@(t,y) equation_nigrovic(y, D, drugParam, patientParam),[0 1], ...
                      [0;DRD0;zeros(4,1);DRO0;ORD0;A0_(i)]);
    
        rA = patientParam.rA;
        ARA50 = patientParam.ARA50;   
        ARApeak = max(y(:,1)) * R_base;
        twich(i) = ARApeak^rA / (ARApeak^rA + (ARA50)^rA);    
    
    end    
end

function dydt = equation_nigrovic(y, D, drugParam, patientParam)
   ARA = y(1); DRD = y(2); ARD = y(3); DRA = y(4);
   ARO = y(5); ORA = y(6); DRO = y(7); ORD = y(8);
   A = y(9);
   kaA1 = drugParam.kaA1_;
   kaA2 = drugParam.kaA2_;
   kaD1 = drugParam.kaD1_;
   kaD2 = drugParam.kaD2_;
   kdA1 = drugParam.kdA1_;
   kdA2 = drugParam.kdA2_;
   kdD1 = drugParam.kdD1_;
   kdD2 = drugParam.kdD2_;
   Rtotal = patientParam.Rtotal_;
   khd    = drugParam.khd_;
   ORO = Rtotal-ARA-DRD-ARD-DRA-ARO-ORA-DRO-ORD;
   dARAdt = kaA2*ARO*A-kdA2*ARA+kaA1*ORA*A-kdA1*ARA;
   dDRDdt = kaD2*DRO*D-kdD2*DRD+kaD1*ORD*D-kdD1*DRD;
   dARDdt = kaD2*ARO*D-kdD2*ARD+kaA1*ORD*A-kdA1*ARD;
   dDRAdt = kaA2*DRO*A-kdA2*DRA+kaD1*ORA*D-kdD1*DRA;
   dAROdt = kaA1*ORO*A-kdA1*ARO+kdA2*ARA-kaA2*ARO*A+kdD2*ARD-kaD2*ARO*D;
   dORAdt = kaA2*ORO*A-kdA2*ORA+kdA1*ARA-kaA1*ORA*A+kdD1*DRA-kaD1*ORA*D;
   dDROdt = kaD1*ORO*D-kdD1*DRO+kdA2*DRA-kaA2*DRO*A+kdD2*DRD-kaD2*DRO*D;
   dORDdt = kaD2*ORO*D-kdD2*ORD+kdA1*ARD-kaA1*ORD*A+kdD1*DRD-kaD1*ORD*D;
   dAdt = kdA1*(ARA+ARD+ARO)+kdA2*(ARA+DRA+ORA)-khd*A-(kaA1+kaA2)*A*ORO-kaA1*A*(ORA+ORD)-kaA2*A*(ARO+DRO);
   dydt =[dARAdt;dDRDdt;dARDdt;dDRAdt;dAROdt;dORAdt;dDROdt;dORDdt;dAdt];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Postsynaptic model (Cyclic)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function twich = twich_data_cyclic(A0, D, drugParam, patientParam)
 
    % Base value for nondimensionalization
    R_base = 7.75*10^-5;
    T_base = 10^-3;
    ka_base = 1 / (R_base * T_base);
    kd_base = 1 / T_base;

    % Nondimensional parameters
    Param.D_ = D / R_base;
    drugParam.kaA1_ = drugParam.kaA1 / ka_base;
    drugParam.kaA2_ = drugParam.kaA2 / ka_base;
    drugParam.kaD1_ = drugParam.kaD1 / ka_base;
    drugParam.kaD2_ = drugParam.kaD2 / ka_base;
    drugParam.kdA1_ = drugParam.kdA1 / kd_base;
    drugParam.kdA2_ = drugParam.kdA2 / kd_base;
    drugParam.kdD1_ = drugParam.kdD1 / kd_base;
    drugParam.kdD2_ = drugParam.kdD2 / kd_base;
    drugParam.kaA1_ast_ = drugParam.kaA1_ast / ka_base;
    drugParam.kaA2_ast_ = drugParam.kaA2_ast / ka_base;
    drugParam.kdA1_ast_ = drugParam.kdA1_ast / kd_base;
    drugParam.kdA2_ast_ = drugParam.kdA2_ast / kd_base;
    drugParam.kd_ = drugParam.khd / kd_base;
    drugParam.kd1_ = drugParam.kd1 / kd_base;
    drugParam.kd2_ = drugParam.kd2 / kd_base;
    drugParam.ko_ = drugParam.ko / kd_base;
    drugParam.kc_ = drugParam.kc / kd_base;
    drugParam.KD1_ = drugParam.KD1 / R_base;
    drugParam.KD2_ = drugParam.KD2 / R_base;
    drugParam.KA1_ = drugParam.KA1 / R_base;
    drugParam.KA2_ = drugParam.KA2 / R_base;
    patientParam.Rtotal_ = patientParam.Rtotal / R_base;
    A0_ = A0 / R_base;
    
    % Calculation    
    sz = length(A0);
    twich = zeros(1,sz);
    for i = 1:sz
    
        D_ = Param.D_;
        KD1_ = drugParam.KD1_;
        KD2_ = drugParam.KD2_;
        KA1_ = drugParam.KA1_;
        KA2_ = drugParam.KA2_;
        del = (D_*KA1_+KD1_*KA1_)*(D_*KA2_+KD2_*KA2_);  
        DRD0 = D_^2*KA1_*KA2_/del;
        DRO0 = D_*KD2_*KA1_*KA2_/del;
        ORD0 = D_*KD1_*KA1_*KA2_/del;
    
        [~,y] = ode45(@(t,y) equation_cyclic(y, D, drugParam, patientParam),[0 1], ...
            [A0_(i);zeros(4,1);DRD0;zeros(4,1);DRO0;ORD0;0]);
       
        Rpeak = max(y(:,2)+y(:,3)+y(:,4)) * R_base;
        rA  = patientParam.rA;
        R50 = patientParam.R50;
        twich(1,i) = Rpeak^rA / (Rpeak^rA + (R50)^rA);
    end
end

function dydt = equation_cyclic(y, D, drugParam, patientParam)

   A = y(1);
   ARA_ = y(2);
   ARO_ = y(3);
   ORA_ = y(4);
   ARA = y(5);
   DRD = y(6);
   ARD = y(7);
   DRA = y(8);
   ARO = y(9);
   ORA = y(10);
   DRO = y(11);
   ORD = y(12);
   RD = y(13);   
   kaA1 = drugParam.kaA1_;
   kaA2 = drugParam.kaA2_;
   kaD1 = drugParam.kaD1_;
   kaD2 = drugParam.kaD2_;
   kdA1 = drugParam.kdA1_;
   kdA2 = drugParam.kdA2_;
   kdD1 = drugParam.kdD1_;
   kdD2 = drugParam.kdD2_;
   kaA1_ = drugParam.kaA1_ast_;
   kaA2_ = drugParam.kaA2_ast_;
   kdA1_ = drugParam.kdA1_ast_;
   kdA2_ = drugParam.kdA2_ast_;
   kd = drugParam.kd_;
   kd1 = drugParam.kd1_;
   kd2 = drugParam.kd2_;
   ko = drugParam.ko_;
   kc = drugParam.kc_;
   Rtotal = patientParam.Rtotal_;   
   ORO = Rtotal-ARA_-ARO_-ORA_-ARA-DRD-ARD-DRA-ARO-ORA-DRO-ORD-RD;
   dAdt = -kd*A+(kdA1_+kdA2_)*ARA_-kaA1_*ORA_*A-kaA2_*ARO_*A+kdA1*(ARA+ARD+ARO)-kaA1*A*(ORA+ORD+ORO)+kdA2*(ARA+DRA+ORA)-kaA2*A*(ARO+DRO+ORO);
   dARA_dt = ko*ARA-(kdA1_+kdA2_)*ARA_+kaA1_*ORA_*A+kaA2_*ARO_*A-kd1*ARA_+kd2*RD;
   dARO_dt = -kc*ARO_+kdA2_*ARA_-kaA2_*ARO_*A;
   dORA_dt = -kc*ORA_+kdA1_*ARA_-kaA1_*ORA_*A;
   dARAdt = -ko*ARA+kaA1*ORA*A-kdA1*ARA+kaA2*ARO*A-kdA2*ARA;
   dDRDdt = kaD1*ORD*D-kdD1*DRD+kaD2*DRO*D-kdD2*DRD;
   dARDdt = kaA1*ORD*A-kdA1*ARD+kaD2*ARO*D-kdD2*ARD;
   dDRAdt = kaD1*ORA*D-kdD1*DRA+kaA2*DRO*A-kdA1*DRA;
   dAROdt = kaA1*ORO*A-kdA1*ARO+kdA2*ARA-kaA2*ARO*A+kdD2*ARD-kaD2*ARO*D+kc*ARO_;
   dORAdt = kaA2*ORO*A-kdA2*ORA+kdA1*ARA-kaA1*ORA*A+kdD1*DRA-kaD1*ORA*D+kc*ORA_;
   dDROdt = kaD1*ORO*D-kdD1*DRO+kdD2*DRD-kaD2*DRO*D+kdA2*DRA-kaA2*DRO*A;
   dORDdt = kaD2*ORO*D-kdD2*ORD+kdD1*DRD-kaD1*ORD*D+kdA1*ARD-kaA1*ORD*A;
   dRDdt = kd1*ARA_-kd2*RD;
   dydt =[dAdt;dARA_dt;dARO_dt;dORA_dt;dARAdt;dDRDdt;dARDdt;dDRAdt;dAROdt;dORAdt;dDROdt;dORDdt;dRDdt];
   
end
