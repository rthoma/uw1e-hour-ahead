********************************************************************************
*** HA_UC_model2_4hour_TH.gms                                                  *
***                                                                            *
*** STAGE 4 OF THE CONGESTION RELIEF PROBLEM IN THE HOUR-AHEAD FRAMEWORK       *
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

** We assume that the total injections/extractions from ES are accepted by DEPO
** In the general case, DEPO would provide a slightly different schedule or not

$include C:\BPA_project\Test_connect_HA_ok\input_data_4hour_TH.gms

table p_ext2(d, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\pext_2round.csv
$offdelim
;

********************************************************************************
*** DECLARATION OF FREE VARIABLES, POSITIVE VARIABLES, BINARY VARIABLES        *
********************************************************************************


variables
        obj                     objective function of the unit commitment
        pf(t, l)                power flow
        theta(t, s)             voltage angles
        g(t, i)                 power output of generators
;


positive variables
        g_lin(t, i, b)          generator block outputs
        slack_solar(r, t)       solar spillage
        slack_wind(w, t)        wind spillage
        slack_fixed(f, t)       fixed spillage
        slack_flow(l, t)        transmission capacity slack variables
        slack_pbal(s, t)        power balance equation slack variables
;


binary variables
        v(t, i)                 commitment variable
        y(t, i)                 start up variable
        z(t, i)                 shut down variable
;


equations
        cost                            objective function
        bin_set1(t, i)                  binary logic constraint 1
        bin_set10(t, i)                 binary logic constraint 1_2
        bin_set2(t, i)                  binary logic constraint 2
        min_updown_1(t, i)              Initial statuses
        min_updown_2(t, i)              minimum up time constraint
        min_updown_3(t, i)              minimum down time constraint
        slack_wind_constr(t, w)         maximum wind spillage constraint
        slack_solar_constr(t, r)        maximum solar spillage constraint
        slack_fixed_constr(t, f)        maximum fixed spillage constraint
        gen_sum(t, i)                   summation over all blocks
        gen_min(t, i)                   minimum power output of generators
        block_output(t, i, b)           maximum power output of each block
        ramp_limit_min(t, i)            ramp down constraint
        ramp_limit_max(t, i)            ramp up constraint
        ramp_limit_min_1(t, i)          ramp down constraint t=1
        ramp_limit_max_1(t, i)          ramp up constraint t=1
        line_flow(t, l)                 power flow
        line_capacity_min(t, l)         maximum power flow limits
        line_capacity_max(t, l)         minimum power flow limits
        power_balance(t, s)             power balance equation
        voltage_angles_min(t, s)        minimum voltage phase angle limits
        voltage_angles_max(t, s)        maximum voltage phase angle limits
;

** We duplicate the set t, which is going to be needed in the minimum up and
** down time constraints

alias (t, tt);

********************************************************************************
*** DEFINITION OF CONSTRAINTS FOR BOTH MODELS                                  *
********************************************************************************

** The formulation is the same as in stage 1 but we now include the
** transmission capacity constraints

cost..
    obj =e= sum((t, i)$(t_ha(t)), suc_sw(i)*y(t, i) + a(i)*v(t, i) + sum(b, g_lin(t, i, b)*k(i, b)))
          + sum((t, r)$(t_ha(t)), slack_solar(r, t)) * VoRS
          + sum((t, w)$(t_ha(t)), slack_wind(w, t)) * VoRS
          + sum((f, t)$(t_ha(t)), slack_fixed(f, t)) * 100000000
*         + sum((t, s)$(t_ha(t)), slack_pbal(s, t)) * 100000000
          + sum((l, t)$(t_ha(t)), slack_flow(l, t)) * 100000000
;

** Binary logic between start-up, shutdown, and commitment variables for
** periods greater than the starting hour

bin_set1(t, i)$(t_ha(t) and (ord(t) gt hour))..
        y(t, i) - z(t, i) =e= v(t, i) - v(t-1, i);

** Binary logic between start-up, shutdown, and commitment variables for
** the first period of the optimization horizon

bin_set10(t, i)$(t_ha(t) and (ord(t) eq hour))..
        y(t, i) - z(t, i) =e= v(t, i) - onoff_t0(i);

** Relation between start-up and shudown variables in order to avoid simultaneous actions
bin_set2(t, i)$(t_ha(t))..
        y(t, i) + z(t, i) =l= 1;

** Definition of the power output as the summation of the power output of each of the blocks
gen_sum(t, i)$(t_ha(t))..
        g(t, i) =e= sum(b, g_lin(t, i, b));

** Minimum bound for the power output of conventional thermal units
gen_min(t, i)$(t_ha(t))..
        g(t, i) =g= g_min(i)*v(t, i);

** Maximum bounds for the power output of each of the blocks of the conventional thermal units
block_output(t, i, b)$(t_ha(t))..
        g_lin(t, i, b) =l= g_max(i, b)*v(t, i);

** Initial conditions for the minimum up and down time constraints
min_updown_1(t, i)$(t_ha(t) and (L_up_min(i) + L_down_min(i) gt 0)
                            and (ord(t) le L_up_min(i) + L_down_min(i)))..
                                    v(t, i) =e= onoff_t0(i);

** Minimum up time constraints for the rest of the periods
min_updown_2(t, i)$(t_ha(t) and (ord(t) gt L_up_min(i)))..
        sum(tt$((ord(tt) ge ord(t) - g_up(i) + 1)
                 and (ord(tt) le ord(t))), y(tt, i)) =l= v(t, i);

** Minimum down time constraints for the rest of the periods
min_updown_3(t, i)$(t_ha(t) and (ord(t) gt L_down_min(i)))..
        sum(tt$((ord(tt) ge ord(t) - g_down(i) + 1)
                 and (ord(tt) le ord(t))), z(tt, i)) =l= 1 - v(t, i);

** Ramp down constraints for periods greater than the current hour
ramp_limit_min(t, i)$(t_ha(t) and (ord(t) gt hour))..
        -ramp_down(i) =l= g(t, i) - g(t-1, i);

** Ramp up constraints for periods greater than the current hour
ramp_limit_max(t, i)$(t_ha(t) and (ord(t) gt hour))..
        ramp_up(i) =g= g(t, i) - g(t-1, i);

** Ramp down constraints for the initial period
ramp_limit_min_1(t, i)$(t_ha(t) and (ord(t) eq hour))..
        -ramp_down(i) =l= g(t, i) - g_0(i);

** Ramp up constraints for the initial period
ramp_limit_max_1(t, i)$(t_ha(t) and (ord(t) eq hour))..
        ramp_up(i) =g= g(t, i) - g_0(i);

** Nodal power balance constraint
power_balance(t, s)$(t_ha(t))..
*   demand(s, t) + sum(d$(storage_map(d) eq ord(s)), p_ext2(d, t)) - slack_pbal(s, t) =e=
    demand(s, t) + sum(d$(storage_map(d) eq ord(s)), p_ext2(d, t)) =e=
          sum(i$(gen_map(i) = ord(s)), g(t, i))
        + sum(f$(fix_map(f) = ord(s)), fix_deterministic(f, t) - slack_fixed(f, t))
        + sum(r$(sol_map(r) = ord(s)), sol_deterministic(t, r) - slack_solar(r, t))
        + sum(w$(win_map(w) = ord(s)), wind_deterministic(t, w) - slack_wind(w, t))
        - sum(l$(line_map(l, 'from') = ord(s)), pf(t, l))
        + sum(l$(line_map(l, 'to') = ord(s)), pf(t, l))
;

** Definition of the power flow of each line in terms of the voltage phase angles
line_flow(t, l)$(t_ha(t))..
    pf(t, l) =e= admittance(l)*(sum(s$(line_map(l, 'from') = ord(s)), theta(t, s))
                              - sum(s$(line_map(l, 'to') = ord(s)), theta(t, s)));

* Transmission capacity constraints
line_capacity_min(t, l)$(t_ha(t))..
        pf(t, l) =g= -l_max(l) - slack_flow(l, t);

* Transmission capacity constraints
line_capacity_max(t, l)$(t_ha(t))..
        pf(t, l) =l= l_max(l) + slack_flow(l, t);

** Minimum voltage phase angle limits
voltage_angles_min(t, s)$(t_ha(t))..
        theta(t, s) =g= -pi;

** Maximum voltage phase angle limits
voltage_angles_max(t, s)$(t_ha(t))..
        theta(t, s) =l= pi;

** Maximum spillage for solar generation
slack_solar_constr(t, r)$(t_ha(t))..
        sol_deterministic(t, r) =g= slack_solar(r, t);

** Maximum spillage for wind generation
slack_wind_constr(t, w)$(t_ha(t))..
        wind_deterministic(t, w) =g= slack_wind(w, t);

** Maximum spillage for fixed generation
slack_fixed_constr(t, f)$(t_ha(t))..
        fix_deterministic(f, t) =g= slack_fixed(f, t);

model TEPO_UC /all/;

********************************************************************************
** OPTIONS FOR THE SIMULATIONS: TIME LIMITATION, GAP, NUMBER OF THREADS,       *
** INITIALIZATION                                                              *
********************************************************************************

option reslim = 1000000;
option optcr = 0.01;
option threads = 1;

* option Savepoint = 1;
* option optca = 0;

********************************************************************************
** SOLVING THE UC PROBLEM FOR THE HOUR-AHEAD OPERATION                         *
********************************************************************************

** Defintion of parameters that we want to output

parameter total_cost,
          generation_cost,
          time_elapsed,
          M_cong_aux(t, l),
          M_cong_snpd_aux(t, l),
          flow_cong_output(l, t),
          mst,
          sst,
          power_flow_out(t, l),
          power_output_out(t, i),
          slack_solar_out(t, r),
          slack_wind_out(t, w),
          slack_fixed_out(t, f),
          slack_solar_out_total,
          slack_wind_out_total,
          slack_fixed_out_total;

** Solve the minimization problem by using mixed-integer linear programming
solve TEPO_UC using mip minimizing obj;

total_cost = obj.L;

generation_cost = sum((t, i)$(t_ha(t)), suc_sw(i)*y.l(t, i) + a(i)*v.l(t, i)
                + sum(b, g_lin.l(t, i, b)*k(i, b))) + eps;

time_elapsed = timeElapsed;

M_cong_aux(t, l)$(t_ha(t) and (abs(pf.l(t, l)) - l_max(l) ge 0)) = 1 + eps;

M_cong_snpd_aux(t, l)$(t_ha(t) and (abs(pf.l(t, l)) - l_max(l) ge 0)
                               and (snpd_lines_map(l) eq 1)) = 1 + eps;

flow_cong_output(l, t)$(t_ha(t) and (M_cong_aux(t, l) eq 1)) = 0 + eps;

flow_cong_output(l, t)$(t_ha(t) and (M_cong_aux(t, l) ne 0)) = pf.l(t, l)*s_base + eps;

mst = TEPO_UC.modelstat;

sst = TEPO_UC.solvestat;

power_flow_out(t, l)$(t_ha(t)) = pf.l(t, l)*s_base + eps;

power_output_out(t, i)$(t_ha(t)) = g.l(t, i)*s_base + eps;

slack_solar_out(t, r)$(t_ha(t)) = slack_solar.l(r, t)*s_base + eps;

slack_wind_out(t, w)$(t_ha(t)) = slack_wind.l(w, t)*s_base + eps;

slack_fixed_out(t, f)$(t_ha(t)) = slack_fixed.l(f, t)*s_base + eps;

slack_solar_out_total = sum((r, t)$(t_ha(t)), slack_solar.l(r, t))*s_base + eps;

slack_wind_out_total = sum((w, t)$(t_ha(t)), slack_wind.l(w, t))*s_base + eps;

slack_fixed_out_total = sum((f, t)$(t_ha(t)), slack_fixed.l(f, t))*s_base + eps;

** Output of results in a gdx file
execute_unload "C:\BPA_project\Test_connect_HA_ok\uc_ha_day2_hour24_constrained_relieved.gdx"
    slack_solar_out_total,
    slack_wind_out_total,
    slack_fixed_out_total,
    slack_solar_out,
    slack_wind_out,
    slack_fixed_out,
    power_flow_out,
    power_output_out,
    mst,
    sst,
    total_cost,
    M_cong_snpd_aux,
    generation_cost,
    time_elapsed,
    M_cong_aux,
    flow_cong_output;

********************************************************************************
*** OUTPUT FILES TO COMPUTE THE INITIAL CONDITIONS FOR NEXT WINDOW             *
********************************************************************************

FILE output_init1 /'C:\BPA_project\Test_connect_HA_ok\Data\g_0_previous_aux2.inc'/;
put output_init1
put "** Power output at the first period **"/;
loop(column,
    put "      ", column.tl:0:0,
);
put /;
loop(i,
    put i.tl:0:0, "   "
    loop(column,
        put (g.l('t1', i)):0:4, "   "
);
put /;
);

FILE output_init2 /'C:\BPA_project\Test_connect_HA_ok\Data\count_on_init_previous_aux2.inc'/;
put output_init2
put "** number of hours unit has been on at the previous period of the considered optimization horizond **"/;
loop(column,
    put "      ", column.tl:0:0,
);
put /;
loop(i,
    put i.tl:0:0, "   "
    loop(column,
        put (count_on_init_aux(i)):0:4, "   "
);
put /;
);

FILE output_init3 /'C:\BPA_project\Test_connect_HA_ok\Data\count_off_init_previous_aux2.inc'/;
put output_init3
put "** number of hours unit has been off at the previous period of the considered optimization horizon **"/;
loop(column,
    put "      ", column.tl:0:0,
);
put /;
loop(i,
    put i.tl:0:0, "   "
    loop(column,
        put (count_off_init_aux(i)):0:4, "   "
);
put /;
);

FILE output_init4 /'C:\BPA_project\Test_connect_HA_ok\Data\onoff_t0_previous_aux2.inc'/;
put output_init4
put "** on-off status at the previous period of the previous considered optimization horizon **"/;
loop(column,
    put "      ", column.tl:0:0,
);
put /;
loop(i,
    put i.tl:0:0, "   "
    loop(column,
        put (onoff_t0(i)):0:4, "   "
);
put /;
);

FILE output_init5 /'C:\BPA_project\Test_connect_HA_ok\Data\onoff_t1_previous_aux2.inc'/;
put output_init5
put "** on-off status at the previous period of the considered optimization horizon **"/;
loop(column,
    put "      ", column.tl:0:0,
);
put /;
loop(i,
    put i.tl:0:0, "   "
    loop(column,
        put (v.l('t1', i)):0:4, "   "
);
put /;
);