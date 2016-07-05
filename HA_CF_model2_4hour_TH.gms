********************************************************************************
*** HA_CF_model2_4hour_TH.gms                                                  *
***                                                                            *
*** STAGE 3 OF THE CONGESTION RELIEF PROBLEM IN THE HOUR-AHEAD FRAMEWORK       *
********************************************************************************

$onempty
$offlisting
$offupper
$Offsymlist
$offsymxref
$offuellist
$offuelxref

option limrow = 0,
       limcol = 0,
       solprint = off,
       sysout = off
;

********************************************************************************
*** READING INPUT DATA                                                         *
********************************************************************************

$include C:\BPA_project\Test_connect_HA_ok\input_data_4hour_TH.gms

table g_bis2(i, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\gbis.csv
$offdelim
;

table glin_bis2A(i, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\glin_bisA.csv
$offdelim
;

table glin_bis2B(i, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\glin_bisB.csv
$offdelim
;

table glin_bis2C(i, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\glin_bisC.csv
$offdelim
;

table slack_wind_bis2(w, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\slackwindbis.csv
$offdelim
;

table slack_solar_bis2(r, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\slacksolarbis.csv
$offdelim
;

table slack_fixed_bis2(f, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\slackfixedbis.csv
$offdelim
;

table powerflowUC2(l, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\powerflow.csv
$offdelim
;

parameter
        glin_bis(t, i, b)            generator block outputs in the pre-contingency state
        slack_solar_bis(r, t)        solar spillage in the pre-contingency state
        slack_wind_bis(w, t)         wind spillage in the pre-contingency state
        slack_fixed_bis(f, t)        fixed spillage in the pre-contingency state
        gbis(t, i)                   power output of generators in the pre-contingency state
        M_cong_aux(t, l)             parameter that is equal to 1 if the line l at period t is congested and 0 otherwise 
        M_cong(t)                    parameter that is equal to 1 if there is at least one line congested in period t
;
        
gbis(t, i) = g_bis2(i, t);
glin_bis(t, i, 'b1') = glin_bis2A(i, t);
glin_bis(t, i, 'b2') = glin_bis2B(i, t);
glin_bis(t, i, 'b3') = glin_bis2C(i, t);
slack_wind_bis(w, t) = slack_wind_bis2(w, t);
slack_solar_bis(r, t) = slack_solar_bis2(r, t);
slack_fixed_bis(f, t) = slack_fixed_bis2(f, t);
M_cong_aux(t, l)$(abs(powerflowUC2(l, t)) - l_max(l) eq 0) = 1;
M_cong(t)$(sum(l, M_cong_aux(t, l)) gt 0) = 1;

********************************************************************************
*** AVAILABILITY BOUNDS                                                        *
********************************************************************************

** We read the input data from DEPO: schedule and prices for each of the actions
** that TEPO can do

table ch_DEPO(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\ch_DEPO.csv
$offdelim
;

table dis_DEPO(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\dis_DEPO.csv
$offdelim
;

table C_ch(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\C_ch.csv
$offdelim
;

table C_dis(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\C_dis.csv
$offdelim
;

table C_SC(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\C_SC.csv
$offdelim
;

table C_SD(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\C_SD.csv
$offdelim
;

table P_ch(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\P_ch.csv
$offdelim
;

table P_dis(d, t)
$ondelim
$include C:\BPA_project\Test_connect_DA_new_ok\Data\P_dis.csv
$offdelim
;

** We define and compute the bounds used in the current model for the ES devices
parameters Bound_ch(t, d),
           Bound_dis(t, d),
           Bound_SD(t, d),
           Bound_SC(t, d)
;

Bound_ch(t, d) = (ES_power_max(d)*s_base - ch_DEPO(d, t))$(ch_DEPO(d, t) gt 0)
               + (ES_power_max(d)*s_base)$(dis_DEPO(d, t) gt 0)
               + (ES_power_max(d)*s_base)$((dis_DEPO(d, t) eq 0) and (ch_DEPO(d, t) eq 0));

Bound_dis(t, d) = (ES_power_max(d)*s_base)$(ch_DEPO(d, t) gt 0)
                + (ES_power_max(d)*s_base - dis_DEPO(d, t))$(dis_DEPO(d, t) gt 0)
                + (ES_power_max(d)*s_base)$((dis_DEPO(d, t) eq 0) and (ch_DEPO(d,t) eq 0));

Bound_SD(t, d) = (0)$(ch_DEPO(d, t) gt 0)
               + (dis_DEPO(d, t))$(dis_DEPO(d, t) gt 0)
               + (0)$((dis_DEPO(d, t) eq 0) and (ch_DEPO(d, t) eq 0));

Bound_SC(t, d) = (ch_DEPO(d, t))$(ch_DEPO(d, t) gt 0)
               + (0)$(dis_DEPO(d, t) gt 0)
               + (0)$((dis_DEPO(d, t) eq 0) and (ch_DEPO(d, t) eq 0));

Bound_ch(t, d) = Bound_ch(t, d) / s_base;
Bound_dis(t, d) = Bound_dis(t, d) / s_base;
Bound_SD(t, d) = Bound_SD(t, d) / s_base;
Bound_SC(t, d) = Bound_SC(t, d) / s_base;
ch_DEPO(d, t) = ch_DEPO(d, t) / s_base;
dis_DEPO(d, t) = dis_DEPO(d, t) / s_base;
C_ch(d, t) = C_ch(d, t) * s_base;
C_dis(d, t) = C_dis(d, t) * s_base;
C_SC(d, t) = C_SC(d, t) * s_base;
C_SD(d, t) = C_SD(d, t) * s_base;
P_ch(d, t) = P_ch(d, t) * s_base;
P_dis(d, t) = P_dis(d, t) * s_base;

********************************************************************************
*** DECLARATION OF FREE VARIABLES, POSITIVE VARIABLES, BINARY VARIABLES        *
********************************************************************************


variables
        obj                objective function of the unit commitment
        pf(t, l)           power flow
        theta(t, s)        voltage angles
;

positive variables
        ch_total(t, d)                   power extracted at the bus where device d is located
        dis_total(t, d)                  power extracted at the bus where device d in located
        deltag_plus(t, i)                positive deviation for g
        deltag_minus(t, i)               negative deviation for g
        deltag_lin_plus(t, i, b)         positive deviation for g_lin
        deltag_lin_minus(t, i, b)        negative deviation for g_lin
        slack_wind_plus(t, w)            positive deviation for wind power spillage
        slack_wind_minus(t, w)           negative deviation for wind power spillage
        slack_solar_plus(t, r)           positive deviation for solar power spillage
        slack_solar_minus(t, r)          negative deviation for solar power spillage
        slack_fixed_plus(t, f)           positive deviation for fixed power spillage
        slack_fixed_minus(t, f)          negative deviation for fixed power spillage
        slack_pbal(s, t)                 relaxation of the nodal power balance equation just in case it is infeasible
        ch_TEPO_SD(t, d)                 stop discharging
        dis_TEPO_SC(t, d)                stop charging
        ch_TEPO(t, d)                    charging from tepo
        dis_TEPO(t, d)                   discharging from tepo
        soc(t, d)                        energy storage state of charge                                                  
;


binary variables
         v(t, i)           commitment variable
         y(t, i)           start up variable
         z(t, i)           shut down variable
         v_ch(t, d)        binary variable associated with the charge of ES device d in period t
;


equations
        cost                             objective function
        bin_set1(t, i)                   binary logic constraint 1
        bin_set10(t, i)                  binary logic constraint 1_2
        bin_set2(t, i)                   binary logic constraint 2
        min_updown_1(t, i)               initial statuses
        min_updown_2(t, i)               minimum up time constraint
        min_updown_3(t, i)               minimum down time constraint
        slack_wind_constr(t, w)          maximum wind spillage constraint
        slack_solar_constr(t, r)         maximum solar spillage constraint
        slack_fixed_constr(t, f)         maximum fixed spillage constraint
        slack_wind_constr2(t, w)         minimum wind spillage constraint
        slack_solar_constr2(t, r)        minimum solar spillage constraint
        slack_fixed_constr2(t, f)        minimum fixed spillage constraint
        gen_sum(t, i)                    summation over all blocks
        gen_min(t, i)                    minimum power output of generators
        block_output(t, i, b)            maximum power output of each block
        ramp_limit_min(t, i)             ramp down constraint
        ramp_limit_max(t, i)             ramp up constraint
        ramp_limit_min_1(i)              ramp down constraint t = 1
        ramp_limit_max_1(i)              ramp up constraint t = 1
        line_flow(t, l)                  power flow
        line_capacity_min(t, l)          maximum power flow limits
        line_capacity_max(t, l)          minimum power flow limits
        power_balance(t, s)              power balance equation
        voltage_angles_min(t, s)         minimum voltage phase angle limits
        voltage_angles_max(t, s)         maximum voltage phase angle limits
        eq_storage_init(t, d)            initial energy storage state of charge trajectory
        eq_storage(t, d)                 energy storage state of charge trajectory in periods greater than 1
        eq_ch_total(t, d)                definition of the contributions for the total charge of ES
        eq_dis_total(t, d)               definitiion of the contributions for the total discharge of ES
        ch_SD_limit(t, d)                stop discharging limit
        dis_SC_limit(t, d)               stop charging limit
        ch_TEPO_limit(t, d)              charging from tepo limit
        dis_TEPO_limit(t, d)             discharging from tepo limit
        soc_limit(t, d)                  energy state of charge limit
        eq_soc_final(t, d)               final energy state of charge                                             
;


alias (t, tt);


********************************************************************************
*** DEFINITION OF CONSTRAINTS FOR BOTH MODELS                                  *
********************************************************************************

** The objective function is the same as the one used in the stage 2 but we
** include the costs for charging/dicharging in the same direction as DEPO, costs
** of charging/discharging in the opposite direction as DEPO, and costs of stop
** charging/discharging

cost..
    obj =e= sum((t, i)$(t_ha(t)), suc_sw(i)*y(t, i) + a(i)*v(t, i)
                + sum(b, (deltag_lin_plus(t, i, b) + deltag_lin_minus(t, i, b))*k(i, b)))
          + sum((t, r)$(t_ha(t)), slack_solar_plus(t, r) + slack_solar_minus(t, r)) * penalty_pf
          + sum((t, w)$(t_ha(t)), slack_wind_plus(t, w) + slack_wind_minus(t, w)) * penalty_pf
          + sum((f, t)$(t_ha(t)), slack_fixed_plus(t, f) + slack_fixed_minus(t, f)) * penalty_pf
          + sum((t, d)$(t_ha(t) and (ch_DEPO(d, t) ge 0)), ch_TEPO(t, d)*C_ch(d, t))
          + sum((t, d)$(t_ha(t) and (dis_DEPO(d, t) ge 0)), dis_TEPO(t, d)*C_dis(d, t))
          + sum((t, d)$(t_ha(t) and (ch_DEPO(d, t) gt 0)), dis_TEPO_SC(t, d)*C_SC(d, t))
          + sum((t, d)$(t_ha(t) and (dis_DEPO(d, t) gt 0)), ch_TEPO_SD(t, d)*C_SD(d, t))
          + sum((t, d)$(t_ha(t) and (dis_DEPO(d, t) gt 0)), ch_TEPO(t, d)*P_ch(d, t))
          + sum((t, d)$(t_ha(t) and (ch_DEPO(d, t) gt 0)), dis_TEPO(t, d)*P_dis(d, t))
          + sum((s, t)$(t_ha(t)), slack_pbal(s, t)) * 100000000
;

** Binary logic between start-up, shutdown, and commitment variables for
** periods greater than 1
bin_set1(t, i)$(t_ha(t) and (ord(t) gt hour))..
         y(t, i) - z(t, i) =e= v(t, i) - v(t-1, i);

** Binary logic between start-up, shutdown, and commitment variables for
** the first period of the optimization horizon
bin_set10(t, i)$(t_ha(t) and (ord(t) = hour))..
         y(t, i) - z(t, i) =e= v(t, i) - onoff_t0(i);

** Relation between start-up and shudown variables in order to avoid simultaneous actions
bin_set2(t, i)$(t_ha(t))..
         y(t, i) + z(t, i) =l= 1;

** Initial conditions for the minimum up and down time constraints
min_updown_1(t, i)$(t_ha(t) and (L_up_min(i) + L_down_min(i) gt 0) and (ord(t) le L_up_min(i) + L_down_min(i)))..
         v(t, i) =e= onoff_t0(i);

** Minimum up time constraints for the rest of the periods
min_updown_2(t, i)$(t_ha(t) and (ord(t) gt L_up_min(i)))..
         sum(tt$((ord(tt) ge ord(t) - g_up(i) + 1) and (ord(tt) le ord(t))), y(tt, i)) =l= v(t, i);

** Minimum down time constraints for the rest of the periods
min_updown_3(t, i)$(t_ha(t) and (ord(t) gt L_down_min(i)))..
         sum(tt$((ord(tt) ge ord(t) - g_down(i) + 1) and (ord(tt) le ord(t))), z(tt, i)) =l= 1 - v(t, i);

** Definition of the power output as the summation of the power output of each of the blocks
gen_sum(t, i)$(t_ha(t))..
         gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i) =e=
                 sum(b, glin_bis(t, i, b) + deltag_lin_plus(t, i, b) - deltag_lin_minus(t, i, b));

** Minimum bound for the power output of conventional thermal units
gen_min(t, i)$(t_ha(t))..
         gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i) =g= g_min(i)*v(t, i);

** Maximum bounds for the power output of each of the blocks of the conventional thermal units
block_output(t, i, b)$(t_ha(t))..
         glin_bis(t, i, b) + deltag_lin_plus(t, i, b) - deltag_lin_minus(t, i, b) =l= g_max(i, b)*v(t, i);

** Ramp down constraints for periods greater than 1
ramp_limit_min(t, i)$(t_ha(t) and (ord(t) gt 1))..
         -ramp_down(i) =l= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i))
                         - (gbis(t-1, i) + deltag_plus(t-1, i) - deltag_minus(t-1, i));

** Ramp up constraints for periods greater than 1
ramp_limit_max(t, i)$(t_ha(t) and (ord(t) gt 1))..
         ramp_up(i) =g= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i))
                      - (gbis(t-1, i) + deltag_plus(t-1, i) - deltag_minus(t-1, i));

** Ramp down constraints for the initial period
ramp_limit_min_1(t, i)$(t_ha(t) and (ord(t) eq hour))..
         -ramp_down(i) =l= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i)) - g_0(i);

** Ramp up constraints for the initial period
ramp_limit_max_1(t, i)$(t_ha(t) and (ord(t) eq hour))..
         ramp_up(i) =g= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i)) - g_0(i);

** Nodal power balance equations including the power output of conventional thermal units
** fixed generation, solar generation, wind generation, in and out flows, and the nodal demand
** Now we also incorporate the injections from the ES devices

power_balance(t, s)$(t_ha(t))..
    demand(s, t) + sum(d$(storage_map(d) eq ord(s)), ch_total(t, d) - dis_total(t, d)) - slack_pbal(s, t) =e=
          sum(i$(gen_map(i) = ord(s)),
              gbis(t, i)
            + deltag_plus(t, i)
            - deltag_minus(t, i))
        + sum(f$(fix_map(f) = ord(s)),
              fix_deterministic(f, t)
            - slack_fixed_bis(f, t)
            - slack_fixed_plus(t, f)
            + slack_fixed_minus(t, f))
        + sum(r$(sol_map(r) = ord(s)),
              sol_deterministic(t, r)
            - slack_solar_bis(r, t)
            - slack_solar_plus(t, r)
            + slack_solar_minus(t, r))
        + sum(w$(win_map(w) = ord(s)),
              wind_deterministic(t, w)
            - slack_wind_bis(w, t)
            - slack_wind_plus(t, w)
            + slack_wind_minus(t, w))
        - sum(l$(line_map(l, 'from') = ord(s)), pf(t, l))
        + sum(l$(line_map(l, 'to') = ord(s)), pf(t, l))
;

** Definition of the power flow of each line in terms of the voltage phase angles
line_flow(t, l)$(t_ha(t))..
        pf(t, l) =e= admittance(l)*(sum(s$(line_map(l, 'from') = ord(s)), theta(t, s))
                                  - sum(s$(line_map(l, 'to') = ord(s)), theta(t, s)));

** Transmission capacity constraints
line_capacity_min(t, l)$(t_ha(t))..
        pf(t, l) =g= -l_max(l);

** Transmission capacity constraints
line_capacity_max(t, l)$(t_ha(t))..
        pf(t, l) =l= l_max(l);

** Minimum voltage phase angle limits
voltage_angles_min(t, s)$(t_ha(t))..
        theta(t, s) =g= -pi;

** Maximum voltage phase angle limits
voltage_angles_max(t,s)$(t_ha(t))..
        theta(t, s) =l= pi;

** Maximum spillage for solar generation
slack_solar_constr(t, r)$(t_ha(t))..
        sol_deterministic(t, r) =g= slack_solar_bis(r, t) + slack_solar_plus(t, r) - slack_solar_minus(t, r);

** Maximum spillage for wind generation
slack_wind_constr(t, w)$(t_ha(t))..
        wind_deterministic(t, w) =g= slack_wind_bis(w, t) + slack_wind_plus(t, w) - slack_wind_minus(t, w);

** Maximum spillage for fixed generation
slack_fixed_constr(t, f)$(t_ha(t))..
        fix_deterministic(f, t) =g= slack_fixed_bis(f, t) + slack_fixed_plus(t, f) - slack_fixed_minus(t, f);

** Minimum spillage for solar generation
slack_solar_constr2(t, r)$(t_ha(t))..
        slack_solar_bis(r, t) + slack_solar_plus(t, r) - slack_solar_minus(t, r) =g= 0;

** Minimum spillage for wind generation
slack_wind_constr2(t, w)$(t_ha(t))..
        slack_wind_bis(w, t) + slack_wind_plus(t, w) - slack_wind_minus(t, w) =g= 0;

** Minimum spillage for fixed generation
slack_fixed_constr2(t, f)$(t_ha(t))..
        slack_fixed_bis(f, t) + slack_fixed_plus(t, f) - slack_fixed_minus(t, f) =g= 0;

** Initial energy storage state of charge trajectory
eq_storage_init(t, d)$(t_ha(t) and (ord(t) eq hour))..
        soc(t, d) =e= E_initial(d) + ch_total(t, d)*alef_ch(d) - dis_total(t, d)/alef_dis(d);

** Energy storage state of charge trajectory in periods greater than the starting hour
eq_storage(t, d)$(t_ha(t) and (ord(t) gt hour))..
        soc(t, d) =e= soc(t-1, d) + ch_total(t, d)*alef_ch(d) - dis_total(t, d)/alef_dis(d);

** Definition of the total charge of ES
eq_ch_total(t, d)$(t_ha(t))..
        ch_total(t, d) =e= ch_DEPO(d, t) + ch_TEPO_SD(t, d) + ch_TEPO(t, d);

** Definition of the total discharge of ES
eq_dis_total(t, d)$(t_ha(t))..
        dis_total(t, d) =e= dis_DEPO(d, t) + dis_TEPO_SC(t, d) + dis_TEPO(t, d);

** Stop discharging limit
ch_SD_limit(t, d)$(t_ha(t))..
        ch_TEPO_SD(t, d) =l= Bound_SD(t, d);

** Stop charging limit
dis_SC_limit(t, d)$(t_ha(t))..
        dis_TEPO_SC(t, d) =l= Bound_SC(t, d);

** TEPO charging limit
ch_TEPO_limit(t, d)$(t_ha(t))..
        ch_TEPO(t, d) =l= Bound_ch(t, d);

** TEPO discharging limit
dis_TEPO_limit(t, d)$(t_ha(t))..
        dis_TEPO(t, d) =l= Bound_dis(t, d);
    
** ES energy state of charge limit
soc_limit(t, d)$(t_ha(t))..
        soc(t, d) =l= Emax(d);

** Final energy state of charge
eq_soc_final(t, d)$(t_ha(t) and (ord(t) eq card(t)))..
        soc(t, d) =e= E_final(d);

model CR /all/;

********************************************************************************
*** OPTIONS FOR THE SIMULATIONS: TIME LIMITATION, GAP, NUMBER OF THREADS,      *
*** INITIALIZATION, ...                                                        *
********************************************************************************

option reslim = 1000000;
option optcr = 0.01;
option threads = 1;

* option Savepoint = 1;
* option optca = 0;

********************************************************************************
*** SOLVING THE CONGESTION RELIEF PROBLEM FOR THE HOUR-AHEAD OPERATION         *
********************************************************************************

solve CR using mip minimizing obj;

********************************************************************************
*** COMPUTATION OF THE PARAMETERS WHICH ARE PASSED ON TO THE DEPO              *
********************************************************************************

** We compute again the total injections/extractions from the ES
FILE output1 /'C:\BPA_project\Test_connect_HA_ok\Data\pext_2round.csv'/;
put output1
put "** Power extracted in the second round**"/;
loop(t$(t_ha(t)),
    put ",", t.tl:0:0,
);
put /;
loop(d,
    put d.tl:0:0,","
    loop(t$((ord(t) ge hour) and (ord(t) lt hour+horizon-1) and (ord(t) lt card(t))),
        put (ch_total.l(t, d) - dis_total.l(t, d)):0:6, ","        
);
loop(t$(t_ha(t) and ((ord(t) eq hour+horizon-1) or (ord(t) eq card(t)))),
    put (ch_total.l(t, d) - dis_total.l(t, d)):0:6,
);
put /;
);

*table p_ext2(d,t)
*$ondelim
*$include C:\BPA_project\Test_connect_HA_ok\Data\pext_2round.csv
*$offdelim
*;

parameter p_ext2(d, t);
p_ext2(d, t) = ch_total.l(t, d) - dis_total.l(t, d);

** Computation of the minimum and maximum net load injections
loop((s, d)$(storage_map(d) eq ord(s)),
    minimum_load_aux(t, s)$(t_ha(t) and ((ch_total.l(t, d) - dis_total.l(t, d)) gt 0)) =
        (demand(s, t) + (ch_total.l(t, d) - dis_total.l(t, d)))*s_base + eps;
    minimum_load_aux(t, s)$(t_ha(t) and ((ch_total.l(t, d) - dis_total.l(t, d)) lt 0)) =
        (demand(s, t) - ES_power_max(d))*s_base + eps; 
    minimum_load_aux(t, s)$(t_ha(t) and ((ch_total.l(t, d) - dis_total.l(t, d)) eq 0)) =
        demand(s, t)*s_base + eps;
);

loop((s, d)$(storage_map(d) eq ord(s)),
    maximum_load_aux(t, s)$(t_ha(t) and ((ch_total.l(t, d) - dis_total.l(t, d)) gt 0)) =
        (demand(s, t) + ES_power_max(d))*s_base + eps;
    maximum_load_aux(t, s)$(t_ha(t) and ((ch_total.l(t, d) - dis_total.l(t, d)) lt 0)) =
        (demand(s, t) + (ch_total.l(t, d) - dis_total.l(t, d)) )*s_base + eps;
    maximum_load_aux(t, s)$(t_ha(t) and ((ch_total.l(t, d) - dis_total.l(t, d)) eq 0)) =
        demand(s, t)*s_base + eps;
);

loop((s, d)$(storage_map(d) eq ord(s)),
    minimum_load(t, d) = minimum_load_aux(t, s);
    maximum_load(t, d) = maximum_load_aux(t, s);
);

********************************************************************************
*** OUTPUT FILES FROM TEPO-UW TO TEPO-1E                                       *
********************************************************************************

OPTIONS decimals = 6;

FILE Minimum_load_output /'C:\BPA_project\Test_connect_HA_ok\Data\Minimum_load.csv'/;
PUT Minimum_load_output;
PUT_UTILITIES 'ren' / 'C:\BPA_project\Test_connect_HA_ok\Data\Minimum_load_D':0 N:1:0 '_H':0 hour:2:0 '.csv':0;

put "** MINIMUM LOAD AT BUSES WHERE STORAGE UNITS ARE LOCATED **"/;

loop(t$(t_ha(t)),
    put ",", t.tl:0:0,
);
put /;
loop(d,
    put d.tl:0:0, ","
    loop(t$((ord(t) ge hour) and (ord(t) lt hour+horizon-1) and (ord(t) lt card(t))),
        put (minimum_load(t, d)):0:3, ","
);
loop(t$(t_ha(t) and ((ord(t) eq hour+horizon-1) or (ord(t) eq card(t)))),
    put (minimum_load(t, d)):0:3,
);
put /;
);

FILE Maximum_load_output /'C:\BPA_project\Test_connect_HA_ok\Data\Maximum_load.csv'/;
PUT Maximum_load_output;
PUT_UTILITIES 'ren' / 'C:\BPA_project\Test_connect_HA_ok\Data\Maximum_load_D':0 N:1:0 '_H':0 hour:2:0 '.csv':0;

put "** MAXIMUM LOAD AT BUSES WHERE STORAGE UNITS ARE LOCATED **"/;
loop(t$(t_ha(t)),
    put ",",t.tl:0:0,
);
put /;
loop(d,
    put d.tl:0:0,","
    loop(t$((ord(t) ge hour) and (ord(t) lt hour+horizon-1) and (ord(t) lt card(t))),
        put (maximum_load(t,d)):0:3, ","
);
loop(t$(t_ha(t) and ((ord(t) eq hour+horizon-1) or (ord(t) eq card(t))))
    put (maximum_load(t,d)):0:3,
);
put /;
);


parameter power_flow_out(t, l),
          mst,
          sst,
          time_elapsed,
          M_cong_aux(t, l),
          M_cong_snpd_aux(t, l),
          slack_out(s, t)
;


time_elapsed = timeElapsed;
M_cong_aux(t, l)$(abs(pf.l(t, l)) - l_max(l) ge 0) = 1 + eps;
M_cong_snpd_aux(t, l)$((abs(pf.l(t, l)) - l_max(l) ge 0) and (snpd_lines_map(l) eq 1)) = 1 + eps;
mst = CR.modelstat;
sst = CR.solvestat;
power_flow_out(t, l) = pf.l(t, l)*s_base + eps;
slack_out(s, t) = slack_pbal.l(s, t)*s_base + eps;


execute_unload "cr2_ha_day2_hour24.gdx"
    power_flow_out,
    mst,
    sst,
    M_cong_snpd_aux,
    time_elapsed,
    M_cong_aux,
    slack_out;


display soc.l;