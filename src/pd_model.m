function [TOFr, TOFc, PTC] = pd_model(C, drugParam, patientParam,model)

  sz_C = length(C);
  TOFr = zeros(2, sz_C);
  TOFc = zeros(2, sz_C);
  PTC = zeros(2, sz_C);

  for k = 1:sz_C

      D = C(k);

      %%%%%%%%%%%%%%%%%%
      % TOF   
      %%%%%%%%%%%%%%%%%%
        % Presynaptic
        tof_or_ptc = 'tof';
        A0 = fun_acetylcholine_release(D, tof_or_ptc, patientParam);
        % disp(A0)
        
        if model == "nigrovic"
            twich = twich_data_nigrovic(A0, D, drugParam,patientParam);
        else
            twich = twich_data_cyclic2(A0, D, drugParam,patientParam);
        end
        % disp(twich)
    
        % TOFrate
        tofr = twich(4) / twich(1);
        % disp(tofr)
        TOFr(:,k) = [D;tofr];
                
        % TOFcount
        tofc = 0;
        for i = 1:4
    
            if twich(i) > 0.03
        
               tofc = tofc + 1;
        
            end
    
        end

        % disp(tofc)
        TOFc(:,k) = [D;tofc];

        %%%%%%%%%%%%%%%%%%%%%%
        % PTC 
        %%%%%%%%%%%%%%%%%%%%%%
        % Postsynaptic
        tof_or_ptc = 'ptc';
        A0 = fun_acetylcholine_release(D, tof_or_ptc, patientParam);

        if model == "nigrovic"
            twich = twich_data_nigrovic(A0, D, drugParam, patientParam);
        else
            twich = twich_data_cyclic(A0, D, drugParam, patientParam);
        end
        % disp(twich)
    
        % PTC
        ptc  = 0;
        for j = 1:15
    
            if twich(j) > 0.03
    
               ptc = ptc + 1;
    
            end
    
        end

        PTC(:,k) = [D;ptc];
    
        
         % disp([tofr,tofc,ptc])

  end

end

  
          
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A0 = fun_acetylcholine_release(D, tof_or_ptc, patientParam)  

    % tof or ptc
    if tof_or_ptc == "tof"
        
       p  = patientParam.Prel;   
       period = 0.5;
       count1 = 4;
    
    end
    
    if tof_or_ptc == "ptc"
        
       p  = patientParam.Prel * patientParam.Fptp;   
       period = 1.0;
       count2 = 15;
    
    end

    % calculation
    A0 = zeros(1,4);
    n_ini = 1.0;
    opts = odeset('MaxStep',5);

    if tof_or_ptc == "tof"

        for  i = 1:count1
    
            % replenishment
            [~,n_i] = ode45(@(t, n) model2(t, n, D, patientParam), [0, period], n_ini, opts);
            n_end    = n_i(end);
    
            % release
            A01  = patientParam.A01;
            Prel = patientParam.Prel;
            
            A0(i) = (A01 * p * n_end) / Prel;
            n_ini = n_end - n_end * p;
    
        end

    end

    if tof_or_ptc == "ptc"

        for  j = 1:count2
    
            % replenishment
            [~,n_i] = ode45(@(t, n) model2(t, n, D, patientParam), [0, period], n_ini, opts);
            n_end    = n_i(end);
    
            % release
            A01  = patientParam.A01;
            Prel = patientParam.Prel;
            
            A0(j) = (A01 * p * n_end) / Prel;
            n_ini = n_end - n_end * p;
    
        end

    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function dndt = model2(~,n, D, patientParam)

    % calculate time constant
    Trep0 = patientParam.Trep0;
    TrepE = patientParam.TrepE;
    rT = patientParam.rT;
    TC50 = patientParam.TC50;
    
    trep = Trep0 + TrepE * (D^rT/(D^rT+TC50^rT));

    % differential equation
    dndt = (1-n)/trep;
    
 end

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function twich = twich_data_nigrovic(A0, D, drugParam, patientParam)
 
%基準量の定義
R_base = patientParam.Rtotal;
T_base = 10^-3;
ka_base = 1 / (R_base * T_base);
kd_base = 1 / T_base;


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
      [t,y] = ode45(@(t,y) equation_nigrovic(y, D, drugParam, patientParam),[0 1], ...
                     [0;DRD0;zeros(4,1);DRO0;ORD0;A0_(i)]);
      
      
      rA = patientParam.rA;
      ARA50 = patientParam.ARA50;

      ARApeak = max(y(:,1)) * R_base;
      
      % disp(max(y(:,1)));
      twich(i) = ARApeak^rA / (ARApeak^rA + (ARA50)^rA);

    
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function twich = twich_data_cyclic2(A0, D, drugParam, patientParam, PatientParam)
 
%基準量の定義
R_base = 7.75*10^-5;
T_base = 10^-3;
ka_base = 1 / (R_base * T_base);
kd_base = 1 / T_base;


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
drugParam.kd_ = drugParam.kd / kd_base;
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
      
      
      rA = PatientParam.rA;
      R50 = PatientParam.R50;

      Rpeak = max(y(:,2)+y(:,3)+y(:,4)) * R_base;
      
      
      % disp(max(y(:,1)));
      twich(1,i) = Rpeak^rA / (Rpeak^rA + (R50)^rA);

    
end

end