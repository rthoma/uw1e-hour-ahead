********************************************************************************
*** CONGESTION RELIEF PROBLEM. DAY-AHEAD SCHEDULE                              *
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


$include input_data_4hour_TH.gms

table g_bis2(i,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\gbis.csv
$offdelim
;

table glin_bis2A(i,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\glin_bisA.csv
$offdelim
;

table glin_bis2B(i,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\glin_bisB.csv
$offdelim
;

table glin_bis2C(i,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\glin_bisC.csv
$offdelim
;

table slack_wind_bis2(w,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\slackwindbis.csv
$offdelim
;

table slack_solar_bis2(r,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\slacksolarbis.csv
$offdelim
;

table slack_fixed_bis2(f,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\slackfixedbis.csv
$offdelim
;

table powerflowUC2(l,t)
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
M_cong_aux(t, l)$(abs(powerflowUC2(l, t)) - l_max(l) ge 0) = 1;
M_cong(t)$(sum(l, M_cong_aux(t, l)) gt 0) = 1;

********************************************************************************
*** DECLARATION OF FREE VARIABLES, POSITIVE VARIABLES, BINARY VARIABLES        *
********************************************************************************


variables
        obj                objective function of the unit commitment
        pf(t, l)           power flow
        theta(t, s)        voltage angles
;


positive variables
        ch_total(t, d)                  power extracted at the bus where device d is located           
        dis_total(t, d)                 power injected at the bus where device d in located     
        deltag_plus(t, i)               positive deviation for g                                
        deltag_minus(t, i)              negative deviation for g                                
        deltag_lin_plus(t, i, b)        positive deviation for g_lin                            
        deltag_lin_minus(t, i, b)       negative deviation for g_lin                            
        slack_wind_plus(t, w)           positive deviation for wind power spillage              
        slack_wind_minus(t, w)          negative deviation for wind power spillage              
        slack_solar_plus(t, r)          positive deviation for solar power spillage             
        slack_solar_minus(t, r)         negative deviation for solar power spillage             
        slack_fixed_plus(t, f)          positive deviation for fixed power spillage             
        slack_fixed_minus(t, f)         negative deviation for fixed power spillage             
        soc(t, d)                       energy state of charge                                  
;


** The binary variable v_ch(t, d) prevents charging and discharging
** in the same time period
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
        min_updown_1(t, i)               Initial statuses
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
        ramp_limit_min_1(i)              ramp down constraint t=1
        ramp_limit_max_1(i)              ramp up constraint t=1
        line_flow(t, l)                  power flow
        line_capacity_min(t, l)          maximum power flow limits
        line_capacity_max(t, l)          minimum power flow limits
        power_balance(t, s)              power balance equation
        voltage_angles_min(t, s)         minimum voltage phase angle limits
        voltage_angles_max(t, s)         maximum voltage phase angle limits
        eq_storage_init(t, d)            initial energy storage state of charge trajectory
        eq_storage(t, d)                 energy storage state of charge trajectory
        ch_total_limit(t, d)             maximum ES charging
        dis_total_limit(t, d)            maximum ES discharging
        soc_limit(t, d)                  maximum ES state of charge
        eq_soc_final(t, d)               final ES state of charge
;


alias (t, tt);


********************************************************************************
*** DEFINITION OF CONSTRAINTS FOR BOTH MODELS                                  *
********************************************************************************

** The objective function comprises the commitment statuses which can be modified
** in this stage and all deviations from the power output of conventional generators,
** solar spillage, wind spillage, and fixed spillage. Also we incorporate the charging
** and discharging quantities.
cost..
    obj =e= sum((t, i)$(t_ha(t)), suc_sw(i)*y(t, i) + a(i)*v(t, i)
                        + sum(b, (deltag_lin_plus(t, i, b) + deltag_lin_minus(t, i, b))*k(i, b)))
          + sum((t, r)$(t_ha(t)), slack_solar_plus(t, r) + slack_solar_minus(t, r)) * penalty_pf
          + sum((t, w)$(t_ha(t)), slack_wind_plus(t, w) + slack_wind_minus(t, w)) * penalty_pf
          + sum((f, t)$(t_ha(t)), slack_fixed_plus(t, f) + slack_fixed_minus(t, f)) * penalty_pf
          + sum((t, d)$(t_ha(t)), ch_total(t, d) + dis_total(t, d)) * 100
*         + sum((l, t)$(t_ha(t)), slack_flow(l, t)) * 100000000
;

** Binary logic between start-up, shutdown, and commitment variables for
** periods greater than the current hour
bin_set1(t, i)$(t_ha(t) and ord(t) gt hour)..
        y(t, i) - z(t, i) =e= v(t, i) - v(t-1, i);

** Binary logic between start-up, shutdown, and commitment variables for
** the first period of the optimization horizon
bin_set10(t, i)$(t_ha(t) and ord(t) = hour)..
        y(t, i) - z(t, i) =e= v(t, i) - onoff_t0(i);

** Relation between start-up and shudown variables in order to avoid simultaneous actions
bin_set2(t, i)$(t_ha(t))..
        y(t, i) + z(t, i) =l= 1;

** Initial conditions for the minimum up and down time constraints
min_updown_1(t, i)$(t_ha(t) and L_up_min(i) + L_down_min(i) gt 0 and ord(t) le L_up_min(i) + L_down_min(i))..
        v(t, i) =e= onoff_t0(i);

** Minimum up time constraints for the rest of the periods
min_updown_2(t, i)$(t_ha(t) and ord(t) gt L_up_min(i))..
        sum(tt$(ord(tt) ge ord(t) - g_up(i) + 1 and ord(tt) le ord(t)), y(tt, i)) =l= v(t, i);

** Minimum down time constraints for the rest of the periods
min_updown_3(t, i)$(t_ha(t) and ord(t) gt L_down_min(i))..
        sum(tt$(ord(tt) ge ord(t) - g_down(i) + 1 and ord(tt) le ord(t)), z(tt, i)) =l= 1 - v(t, i);

** Definition of the power output as the summation of the power output of each of the blocks
gen_sum(t, i)$(t_ha(t))..
        gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i) =e=
                sum(b, glin_bis(t, i, b) + deltag_lin_plus(t, i, b) - deltag_lin_minus(t, i, b));

** Minimum bound for the power output of conventional thermal units
gen_min(t, i)$(t_ha(t))..
        gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i) =g= g_min(i) * v(t, i);

** Maximum bounds for the power output of each of the blocks of the conventional thermal units
block_output(t, i, b)$(t_ha(t))..
        glin_bis(t, i, b) + deltag_lin_plus(t, i, b) - deltag_lin_minus(t, i, b) =l= g_max(i, b) * v(t, i);

** Ramp down constraints for periods greater than 1
ramp_limit_min(t, i)$(t_ha(t) and ord(t) gt 1)..
        -ramp_down(i) =l= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i))
                        - (gbis(t-1, i) + deltag_plus(t-1, i) - deltag_minus(t-1, i));

** Ramp up constraints for periods greater than 1
ramp_limit_max(t, i)$(t_ha(t) and ord(t) gt 1)..
        ramp_up(i) =g= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i))
                     - (gbis(t-1, i) + deltag_plus(t-1, i) - deltag_minus(t-1, i));

** Ramp down constraints for the initial period
ramp_limit_min_1(t, i)$(t_ha(t) and ord(t) eq hour)..
        -ramp_down(i) =l= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i)) - g_0(i);

** Ramp up constraints for the initial period
ramp_limit_max_1(t, i)$(t_ha(t) and ord(t) eq hour)..
        ramp_up(i) =g= (gbis(t, i) + deltag_plus(t, i) - deltag_minus(t, i)) - g_0(i);

** Nodal power balance equations including the power output of conventional thermal units
** fixed generation, solar generation, wind generation, in and out flows, and the nodal demand
** Now we also incorporate the injections from the ES devices

power_balance(t, s)$(t_ha(t))..
    demand(s, t) + sum(d$(storage_map(d) eq ord(s)), ch_total(t, d) - dis_total(t, d)) =e=
          sum(i$(gen_map(i) = ord(s)),
                 gbis(t, i)
               + deltag_plus(t, i)
               - deltag_minus(t, i))
        + sum(f$(fix_map(f) = ord(s)),
                 fix_deterministic(f, t)
               - slack_fixed_bis(f, t)
               - slack_fixed_plus(t, f)
               + slack_fixed_minus(t,f))
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
*-slack_flow(l,t)

** Transmission capacity constraints
line_capacity_max(t, l)$(t_ha(t))..
        pf(t, l) =l= l_max(l);
*+slack_flow(l,t)

** Minimum voltage phase angle limits
voltage_angles_min(t, s)$(t_ha(t))..
        theta(t, s) =g= -pi;

** Maximum voltage phase angle limits
voltage_angles_max(t, s)$(t_ha(t))..
        theta(t, s) =l= pi;

** Maximum spillage for solar generation
slack_solar_constr(t, r)$(t_ha(t))..
        sol_deterministic(t, r) =g=
                  slack_solar_bis(r, t)
                + slack_solar_plus(t, r)
                - slack_solar_minus(t, r);

** Minimum spillage for wind generation
slack_wind_constr(t, w)$(t_ha(t))..
        wind_deterministic(t, w) =g=
                  slack_wind_bis(w, t)
                + slack_wind_plus(t, w)
                - slack_wind_minus(t, w);

** Minimum spillage for fixed generation
slack_fixed_constr(t, f)$(t_ha(t))..
        fix_deterministic(f, t) =g= slack_fixed_bis(f, t) + slack_fixed_plus(t, f) - slack_fixed_minus(t, f);

** Maximum spillage for solar generation
slack_solar_constr2(t, r)$(t_ha(t))..
        slack_solar_bis(r, t) + slack_solar_plus(t, r) - slack_solar_minus(t, r) =g= 0;

** Minimum spillage for wind generation
slack_wind_constr2(t, w)$(t_ha(t))..
        slack_wind_bis(w, t) + slack_wind_plus(t, w) - slack_wind_minus(t, w) =g= 0;

** Minimum spillage for fixed generation
slack_fixed_constr2(t, f)$(t_ha(t))..
        slack_fixed_bis(f, t) + slack_fixed_plus(t, f) - slack_fixed_minus(t, f) =g= 0;

** Initial energy storage state of charge trajectory
eq_storage_init(t, d)$(t_ha(t) and ord(t) eq hour)..
        soc(t, d) =e= E_initial(d) + ch_total(t, d)*alef_ch(d) - dis_total(t, d)/alef_dis(d);

** Energy storage state of charge trajectory in periods greater than 1
eq_storage(t, d)$(t_ha(t) and ord(t) gt hour)..
        soc(t, d) =e= soc(t-1, d) + ch_total(t, d)*alef_ch(d) - dis_total(t, d)/alef_dis(d);

** ES charging limit
ch_total_limit(t, d)$(t_ha(t))..
        ch_total(t, d) =l= ES_power_max(d)*v_ch(t, d);

** ES discharging limit
dis_total_limit(t, d)$(t_ha(t))..
        dis_total(t, d) =l= ES_power_max(d)*(1 - v_ch(t, d));

** ES energy state of charge limit
soc_limit(t,d)$(t_ha(t))..
        soc(t, d) =l= Emax(d);

** Final energy state of charge
eq_soc_final(t, d)$(t_ha(t) and ord(t) eq card(t))..
        soc(t, d) =e= E_final(d);

model CR /all/;

********************************************************************************
** OPTIONS FOR THE SIMULATIONS: TIME LIMITATION, GAP, NUMBER OF THREADS,
** INITIALIZATION, ...
********************************************************************************

option reslim = 1000000;
option optcr = 0.0;
option threads = 1;

* option Savepoint = 1;
* option optca = 0;

********************************************************************************
** SOLVING THE CONGESTION RELIEF PROBLEM FOR THE HOUR-AHEAD OPERATION
********************************************************************************

solve CR using mip minimizing obj;

********************************************************************************
** COMPUTATION OF THE CONGESTION FORECAST WHICH IS PASSED ON TO THE DEPO
********************************************************************************

** We write in a file the power extracted based on the charge and discharge
** from the ES device
FILE output6 /'C:\BPA_project\Test_connect_HA_ok\Data\pext.csv'/;
put output6
put "** Power extracted **"/;
loop(t$(t_ha(t)),
    put ",", t.tl:0:0,
);
put /;
loop(d,
    put d.tl:0:0,","
    loop(t$(ord(t) ge hour and ord(t) lt hour + horizon - 1 and ord(t) lt card(t)),
        put (ch_total.l(t, d) - dis_total.l(t, d)):0:4, ","
);
loop(t$(t_ha(t) and (ord(t) eq hour + horizon - 1 or ord(t) eq card(t))),
    put (ch_total.l(t, d) - dis_total.l(t, d)):0:4,
);
put /;
);

*<<<<<<<< DA_CF_model version

*table p_ext2(d,t)
*$ondelim
*$include C:\BPA_project\Test_connect_DA_new_ok\Data\pext.csv
*$offdelim
*;

*========

$ontext
table p_ext2(d,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\pext.csv
$offdelim
;
$offtext

*parameter p_ext2(d,t);
*p_ext2(d,t) = (p_ext_plus.l(t,d) - p_ext_minus.l(t,d));

*>>>>>>>> HA_CF_model old version

** We define the actions based on the power extracted
loop((s, d)$(storage_map(d) eq ord(s)),
    action_aux(t, s)$(t_ha(t) and (M_cong(t) eq 1)
                      and ((ch_total.l(t, d) - dis_total.l(t, d)) gt 0)) = 1 + eps;
    action_aux(t, s)$(t_ha(t) and (M_cong(t) eq 1)
                      and ((ch_total.l(t, d) - dis_total.l(t, d)) lt 0)) = -1 + eps;
    action_aux(t, s)$(t_ha(t) and (M_cong(t) eq 1)
                      and ((ch_total.l(t, d) - dis_total.l(t, d)) eq 0)) = 0 + eps;
);

loop((s, d)$(storage_map(d) eq ord(s)),
    action(t, d) = action_aux(t, s);
);

display soc.l, ch_total.l, dis_total.l;

********************************************************************************
** OUTPUT FILES FROM TEPO-UW TO TEPO-1E
********************************************************************************

OPTIONS decimals = 6;

FILE ES_information_output /'C:\BPA_project\Test_connect_HA_ok\Data\ES_information.csv'/;
PUT ES_information_output;

put "** MAP ENERGY STORAGE - BUS, AREA, ZONE **"/;
put "** AREA = 122 ----> BPA AREA "/;
put "** ZONE = 468 ----> SNOPUD ZONE "/;
put "BUS,AREA,ZONE",
put /;
loop(d,
    put d.tl:0:0, ","
    put (storage_map(d)):0:0, ",", (storage_area(d)):0:0, ",", (storage_zone(d)):0:0,
    put /;
);


FILE Action_output /'C:\BPA_project\Test_connect_HA_ok\Data\Action.csv'/;
put Action_output
PUT_UTILITIES 'ren' / 'Action_D':0 N:1:0 '_H':0 hour:2:0 '.csv':0;

put "** ACTION REQUIRED FOR THE CONGESTION RELIEF **"/;
loop(t$(t_ha(t)),
    put ",", t.tl:0:0,
);
put /;
loop(d,
    put d.tl:0:0, ","
    loop(t$(ord(t) ge hour and ord(t) lt hour + horizon - 1 and ord(t) lt card(t)),
        put (action(t, d)):0:0, ","
);
loop(t$(t_ha(t) and (ord(t) eq hour + horizon - 1 or ord(t) eq card(t))),
    put (action(t, d)):0:0,
);
put /;
);


FILE Load_forecast_output /'C:\BPA_project\Test_connect_HA_ok\Data\Load_forecast.csv'/;
PUT Load_forecast_output;
PUT_UTILITIES 'ren' / 'Load_forecast_D':0 N:1:0 '_H':0 hour:2:0 '.csv':0;

put "** LOAD FORECAST (+ injections from DA) AT BUSES WHERE THE STORAGE DEVICES ARE LOCATED **"/;
loop(t$(t_ha(t)),
    put ",", t.tl:0:0,
);
put /;
loop(d,
    put d.tl:0:0, ","
    loop(t$(ord(t) ge hour and ord(t) lt hour + horizon - 1 and ord(t) lt card(t)),
        put (sum(s$(storage_map(d) eq ord(s)), demand(s, t)*s_base)):0:3, ","
);
loop(t$(t_ha(t) and (ord(t) eq hour + horizon - 1 or ord(t) eq card(t))),
    put (sum(s$(storage_map(d) eq ord(s)), demand(s, t)*s_base)):0:3,
);
put /;
);

parameter power_flow_out(t, l),
          mst,
          sst,
          time_elapsed,
          M_cong_aux(t, l),
          M_cong_snpd_aux(t, l)
;

time_elapsed = timeElapsed;
M_cong_aux(t, l)$(abs(pf.l(t, l)) - l_max(l) ge 0) = 1 + eps;
M_cong_snpd_aux(t, l)$(abs(pf.l(t, l)) - l_max(l) ge 0 and snpd_lines_map(l) eq 1) = 1 + eps;
mst = CR.modelstat;
sst = CR.solvestat;
power_flow_out(t, l) = pf.l(t, l)*s_base + eps;

execute_unload "C:\BPA_project\Test_connect_HA_ok\Data\cr_ha_day2_hour24.gdx"
        power_flow_out,
        mst,
        sst,
        M_cong_snpd_aux,
        time_elapsed,
        M_cong_aux
;