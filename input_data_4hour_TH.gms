********************************************************************************
*** SETS                                                                       *
********************************************************************************

set t                index of time periods /t1*t24/;
set t_ha(t)          index of time periods in the hour ahead horizon;
set i                index of generators /i1*i38/;
set b                index of generator blocks /b1*b3/;
set s                index of buses /s1*s2764/;
set l                index of transmission lines /l1*l3318/;
set w                index of wind generators /w1*w73/;
set r                index of solar generators /r1*r5/;
set f                index of fixed generators /f1*f440/;
set day              day counter /day1*day5/;
**set day            day counter /day1*day366/; ** full year

set from_to          lines from and to /from, to/;
set column           generator connected to bus /col/;
set wcolumn          wind connected to bus /wcol/;
set rcolumn          solar connected to bus /rcol/;
set fcolumn          fixed connected to bus /fcol/;
set iter             number of iterations /iter1*iter5/;
** set iter          number of iterations /iter1*iter366/; ** full year
set d                set of storage units /d1/;
set snopud(s)        set of buses that belong to snopud area /s1831*s1958/;

********************************************************************************
*** GENERATOR DATA                                                             *
********************************************************************************

** Locations for generating units in the transmission network
table gen_map_aux(i, column) generator map
*$call =xls2gms r = Generator_Map!e2:f40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\gmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\gmap2.inc
;

** Transformation of the previous matrix into a vector
parameter gen_map(i);
gen_map(i) = sum(column, gen_map_aux(i, column));

** Time varying generation cost curve MW block
table g_max_day(day, i, b) generator block generation limit
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Generator_CostCurve!a2:f192
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\block_max.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\block_max.inc
;

** Time varying generation capacity (forced outage information included)
table g_cap_day(day, t, i) generator capacity
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Generator_Pmax!a2:ao122
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\gcap.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\gcap.inc
;

** Time varying generation cost curve price block
table k_day(day, i, b) slope of each generator cost curve block
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Generator_CostCurve!i2:n192
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\k.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\k.inc
;

** Start-up cost of generator i
table suc_sw_aux(i, column) generator stepwise start-up cost
*$call =xls2gms r = Generator_Data!au2:av40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\start_up_sw.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\start_up_sw.inc
;

** Transformation of the previous matrix into a vector
parameter suc_sw(i);
suc_sw(i) = sum(column, suc_sw_aux(i, column));

** Time varying generation count off initial
table count_off_init_day(day, i) number of time periods each generator has been off
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Generator_InitOff!a2:am7
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux2.inc
;

** Time varying generation count on initial
table count_on_init_day(day, i) number of time periods each generator has been on
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Generator_InitOn!a2:am7
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux3.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux3.inc
;

** Fixed operating cost of each generator
table aux4(i, column)
*$call =xls2gms r = Generator_Data!j2:k40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux4.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux4.inc
;

** Transformation of the previous matrix into a vector
parameter a(i) fixed operating cost of each generator;
a(i)=sum(column, aux4(i, column));

** Generator ramp up limit
table aux5(i, column)
*$call =xls2gms r = Generator_Data!m2:n40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux5.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux5.inc
;

** Transformation of the previous matrix into a vector
parameter ramp_up(i) generator ramp-up limit;
ramp_up(i) = sum(column, aux5(i, column));

** Generator ramp down limit
table aux6(i, column)
*$call =xls2gms r = Generator_Data!p2:q40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux6.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux6.inc
;

** Transformation of the previous matrix into a vector
parameter ramp_down(i) generator ramp-down limit;
ramp_down(i) = sum(column, aux6(i, column));

** Minimum down time for each generator
table aux7(i, column)
*$call =xls2gms r = Generator_Data!s2:t40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux7.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux7.inc
;

** Transformation of the previous matrix into a vector
parameter g_down(i) generator minimum down time;
g_down(i) = sum(column, aux7(i, column));

** Minimum up time for each generator
table aux8(i, column)
*$call =xls2gms r = Generator_Data!v2:w40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux8.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux8.inc
;

** Transformation of the previous matrix into a vector
parameter g_up(i) generator minimum up time;
g_up(i) = sum(column, aux8(i, column));

** Minimum power output
table aux9(i, column)
*$call =xls2gms r = Generator_Data!y2:z40
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux9.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux9.inc
;

** Transformation of the previous matrix into a vector
parameter g_min(i) generator minimum output;
g_min(i) = sum(column, aux9(i, column));

** Time varying generation count off initial
table g_0_day(day, i) generator generation at t = 0
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Generator_PInit!a2:am7
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux10.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux10.inc
;

** Generator on-off status at t = 0
parameter onoff_t0_day(day, i) on-off status at t = 0;
onoff_t0_day(day, i)$(count_on_init_day(day, i) gt 0) = 1;

** Parameter used for minimum up-time constraints
parameter L_up_min_day(day, i) used for minimum up time constraints;
L_up_min_day(day, i) =
    min(card(t), (g_up(i) - count_on_init_day(day, i))*onoff_t0_day(day, i));

** Parameter used for minimum down-time constraints
parameter L_down_min_day(day, i) used for minimum up time constraints;
L_down_min_day(day, i) =
    min(card(t), (g_down(i) - count_off_init_day(day, i))*(1 - onoff_t0_day(day, i)));


********************************************************************************
*** RICARDO COMMENTED OUT THIS CODE, IT LOADS THE ORIGINAL BPA SYSTEM MODEL    *
********************************************************************************

*table suc_sl(i,j) generator stepwise start-up hourly blocks
**$call =xls2gms r=Generator_Data!ay2:bg98 i=Input_Data.xlsx o=start_up_sl.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\start_up_sl.inc
*;

*table aux2(i,column)
*  modified here
**$call =xls2gms r=Generator_Data!d2:e318 i=Input_Data_WECC2024_BPA_year.xlsx o=aux2.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\aux2.inc
*;
*parameter
*count_off_init(i)=sum(column,aux2(i,column));

*table aux3(i,column)
*  modified here
**$call =xls2gms r=Generator_Data!g2:h318 i=Input_Data_WECC2024_BPA_year.xlsx o=aux3.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\aux3.inc
*;
*parameter count_on_init(i) number of time periods each generator has been on;
*count_on_init(i)=sum(column,aux3(i,column));

*table aux10(i,column)
*  modified here
**$call =xls2gms r=Generator_Data!ab2:ac318 i=Input_Data_WECC2024_BPA_year.xlsx o=aux10.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\aux10.inc
*;
*parameter g_0(i) generator generation at t=0;
*g_0(i)=sum(column,aux10(i,column));

********************************************************************************
*** LINE DATA                                                                  *
********************************************************************************

** Origin and destination buses for each transmission line
table line_map(l, from_to) line map
*$call =xls2gms r = Line_Map!e1:g3319
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\line_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\line_map.inc
;

** Admittance of each transmission line
table aux11(l, column)
*$call =xls2gms r = Line_Data!a1:b3319
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux11.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux11.inc
;

** Transformation of the previous matrix into a vector
parameter admittance(l) line admittance;
admittance(l) = abs(sum(column, aux11(l, column)));

** Line capacities
table aux12(l, column)
*$call =xls2gms r = Line_Data!j1:k3319
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\aux12.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux12.inc
;

** Transformation of the previous matrix into a vector
parameter l_max(l) line capacities (long-term ratings);
l_max(l) = sum(column, aux12(l, column));

** Transmission lines connected to snopud buses
table snpd_lines_aux(l, column)
$include C:\BPA_project\Test_connect_HA_ok\Data\snpd_lines.inc
;

** Transformation of the previous matrix into a vector
parameter snpd_lines_map(l) line capacities (long-term ratings);
snpd_lines_map(l) = sum(column, snpd_lines_aux(l, column));

********************************************************************************
*** DEMAND DATA                                                                *
********************************************************************************

** Time varying demand
table d_day(day, s, t) demand at bus s
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Load1!a1:aa13821
*               i = Data\BPA_fixed_load_Apr13.xlsx
*               o = Data\load1.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load1.inc
;

** Auxiliary parameter used to remove the load from islanded buses
table map_islands_aux(s, column) one-bus islands
$include C:\BPA_project\Test_connect_HA_ok\Data\map_islands.inc
;

** Transformation of the previous matrix into a vector
parameter map_islands(s);
map_islands(s) = sum(column, map_islands_aux(s, column));

** Ignore the demand of the islanded areas
d_day(day, s, t) = d_day(day, s, t)*map_islands(s);

********************************************************************************
* UNCOMMENT BLOCKS BELOW AS NEEDED WHEN RUNNING FOR > 60 DAYS                  *
********************************************************************************

*** Time varying demand for 2nd group of days
*table d_day2(day,s,t) demand at bus s
**$call =xls2gms r=Load2!a1:aaXXXX i=BPA_fixed_load_Apr13.xlsx o=load2.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load2.inc
*;
*
*d_day(day,s,t)$(d_day2(day,s,t)>0) = d_day2(day,s,t);
*
*** Time varying demand for 3rd group of days
*table d_day3(day,s,t) demand at bus s
**$call =xls2gms r=Load3!a1:aaXXXX i=BPA_fixed_load_Apr13.xlsx o=load3.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load3.inc
*;
*
*d_day(day,s,t)$(d_day3(day,s,t)>0) = d_day3(day,s,t);
*
*** Time varying demand for 4th group of days
*table d_day4(day,s,t) demand at bus s
**$call =xls2gms r=Load4!a1:aaXXXX i=BPA_fixed_load_Apr13.xlsx o=load4.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load4.inc
*;
*
*d_day(day,s,t)$(d_day4(day,s,t)>0) = d_day4(day,s,t);
*
*** Time varying demand for 5th group of days
*table d_day5(day,s,t) demand at bus s
**$call =xls2gms r=Load5!a1:aaXXXX i=BPA_fixed_load_Apr13.xlsx o=load5.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load5.inc
*;
*
*d_day(day,s,t)$(d_day5(day,s,t)>0) = d_day5(day,s,t);
*
*** Time varying demand for 6th group of days
*table d_day6(day,s,t) demand at bus s
**$call =xls2gms r=Load6!a1:aaXXXX i=BPA_fixed_load_Apr13.xlsx o=load6.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load6.inc
*;
*
*d_day(day,s,t)$(d_day6(day,s,t)>0) = d_day6(day,s,t);

********************************************************************************
* RICARDO COMMENTED OUT THIS CODE, NOT SURE WHY (I'VE GROUP IT TOGETHER)       *
********************************************************************************

*RICARDO TURNED THIS OFF, NOT SURE WHY
*table d_1(s_1,t) demand at bus s - part 1
*modified here
**$call =xls2gms r=Load_Active_Part_1!a27:y10027 i=Input_Data_WECC2024_BPA_year.xlsx o=load_part_1.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load_part_1.inc
*;
*
*table d_2(s_2,t) demand at bus s - part 2
*modified here
**$call =xls2gms r=Load_Active_Part_2!a27:y7573 i=Input_Data_WECC2024_BPA_year.xlsx o=load_part_2.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load_part_2.inc
*;
*
*parameter d(t,s) demand at bus s;
*d(t,s)=sum(s_1$(ord(s)=ord(s_1)),d_1(s_1,t))+sum(s_2$(ord(s)=ord(s_2)+10000),d_2(s_2,t));

********************************************************************************
*** WIND DATA                                                                  *
********************************************************************************

** Locations of the wind power plants
table win_map_aux(w, wcolumn) wind map
*$call =xls2gms r = Wind!e1:f74
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\wmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\wmap2.inc
;

** Transformation of the previous matrix into a vector
parameter win_map(w);
win_map(w) = sum(wcolumn, win_map_aux(w, wcolumn));

** Time varying wind
table wind_deterministic_day(day, t, w) wind data
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Wind!h1:ce121
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\wind_deterministic.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\wind_deterministic.inc
;

********************************************************************************
*** COMMENTED THIS OUT TO MAKE THE WIND CONSISTENT WITH THE SOLAR AND LOAD     *
********************************************************************************

**** RYAN'S NOTES -160621-
**** THIS ONLY CAPTURES 4 DAYS, DAY 2 THROUGH DAY 5
**** LOOKS LIKE AN ERROR TO ME
**** CONFIRM THAT THIS MAKES SENSE
**** THIS IS TOTALLY INCONSISTENT WITH THE SOLAR DATA
**** SWITCHING PARAMETER DEFINITION TO BE CONSISTENT WITH SOLAR AND LOAD

*table wind_deterministic_day(day,t,w) wind data
**$call =xls2gms r = Sheet1!a1:ce97
**               i = C:\BPA_project\Test_connect_HA_ok\Data\wind_hour_ahead.xls
**               o = C:\BPA_project\Test_connect_HA_ok\Data\wind_hour_ahead_aux.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\wind_hour_ahead_aux.inc
*;

********************************************************************************
*** SOLAR DATA                                                                 *
********************************************************************************

** Locations of the solar plants
table sol_map_aux(r, rcolumn) solar map
*$call =xls2gms r = Solar!e1:f6
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\rmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\rmap2.inc
;

** Transformation of the previous matrix into a vector
parameter sol_map(r);
sol_map(r) = sum(rcolumn, sol_map_aux(r, rcolumn));

** Time varying solar
*This call is appropriate for analyzing 5 days
table sol_deterministic_day(day, t, r) solar data
*$call =xls2gms r = Solar!h1:o121
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\solar_deterministic.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\solar_deterministic.inc
;

********************************************************************************
*** FIXED GENERATION DATA                                                      *
********************************************************************************

** Locations of the fixed generators
table fix_map_aux(f, fcolumn) fixed map
*$call =xls2gms r = Fixed!e1:f441
*               i = Data\Input_Data_WECC2024_BPA_Apr13.xlsx
*               o = Data\fmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\fmap2.inc
;

** Transformation of the previous matrix into a vector
parameter fix_map(f);
fix_map(f) = sum(fcolumn, fix_map_aux(f, fcolumn));

** Time varying fixed dispatch
table fix_deterministic_day(day, f, t) fixed data
*This call is appropriate for analyzing 5 days
*$call =xls2gms r = Fixed!a1:aa2201
*               i = Data\BPA_fixed_load_Apr13.xlsx
*               o = Data\fixed_deterministic.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\fixed_deterministic.inc
;

********************************************************************************
*** STORAGE DATA (NEGOTIATION PROTOCOL AND INFORMATION ABOUT UNITS)            *
********************************************************************************

** Locations of the energy storage systems (ESS)
table storage_map_aux(d, column) map energy storage - bus
*$call =xls2gms r = map_storage!a2:b22
*               i = ES_data.xlsx
*               o = Data\storage_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\storage_map.inc
;

** Area labels for energy storage systems
table area_name_storage(d, column)
*$call =xls2gms r = map_storage!d2:e22
*               i = ES_data.xlsx
*               o = Data\area_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\area_map.inc
;

** Zone labels for energy storage systems
table zone_name_storage(d, column)
*$call =xls2gms r = map_storage!g2:h22
*               i = ES_data.xlsx
*               o = Data\zone_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\zone_map.inc
;

parameter storage_map(d);
storage_map(d) = sum(column, storage_map_aux(d, column));

parameter storage_area(d);
storage_area(d) = sum(column, area_name_storage(d, column));

parameter storage_zone(d);
storage_zone(d) = sum(column, zone_name_storage(d, column));

** ES maximum power rating
parameter ES_power_max(d) /
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\ES_power_max.csv
$offdelim
/;

** ES maximum energy rating
parameter Emax(d) /
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\Emax.csv
$offdelim
/;

** Initial energy state-of-charge
parameter E_initial(d) /
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\E_initial.csv
$offdelim
/;

** Final energy state-of-charge
parameter E_final(d) /
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\E_final.csv
$offdelim
/;

** Charging efficiency of the energy storage devices
parameter alef_ch(d) /
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\Efficiency.csv
$offdelim
/;

** We assume that the charging and discharging efficiencies are identical
parameters alef_dis(d);
alef_dis(d) = alef_ch(d);

ES_power_max(d) = ES_power_max(d) / s_base;
Emax(d) = Emax(d) / s_base;
E_initial(d) = E_initial(d) / s_base;
E_final(d) = E_final(d) / s_base;

********************************************************************************
*** POWER INJECTIONS FROM THE DAY-AHEAD FRAMEWORK                              *
*** 1 stands for the day in which we simulate the hour-ahead                   *
*** 2 stands for the next day                                                  *
*** They should be updated when changing the day in which we perform the opt.  *
********************************************************************************

table injection_DA_1(d, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\DA_injections1.csv
$offdelim
;

table injection_DA_2(d, t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\DA_injections2.csv
$offdelim
;

********************************************************************************
*** INITIAL CONDITIONS FROM PREVIOUS SIMULATIONS (t > 1)                       *
********************************************************************************

** Generation level in the previous period
table g_0_previous_aux(i, column) generator generation at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\g_0_previous_aux2.inc
;

** Transformation of the previous matrix into a vector
parameter g_0_previous(i);
g_0_previous(i) = sum(column, g_0_previous_aux(i, column));

** On-off status in the previous period
table onoff_t0_previous_aux(i, column) on-off status at the previous period of the previous considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\onoff_t0_previous_aux2.inc
;

** Transformation of the previous matrix into a vector
parameter onoff_t0_previous(i);
onoff_t0_previous(i) = sum(column, onoff_t0_previous_aux(i, column));

** On-off status in the previous period
table onoff_t1_previous_aux(i, column) on-off status at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\onoff_t1_previous_aux2.inc
;

** Transformation of the previous matrix into a vector
parameter onoff_t1_previous(i);
onoff_t1_previous(i) = sum(column, onoff_t1_previous_aux(i, column));

** Up time in the previous period
table count_on_init_previous_aux(i, column) num hours on at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\count_on_init_previous_aux2.inc
;

** Transformation of the previous matrix into a vector
parameter count_on_init_previous(i);
count_on_init_previous(i) = sum(column, count_on_init_previous_aux(i, column));

** Down time in the previous period
table count_off_init_previous_aux(i, column) num hours off at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\count_off_init_previous_aux2.inc
;

** Transformation of the previous matrix into a vector
parameter count_off_init_previous(i);
count_off_init_previous(i) = sum(column, count_off_init_previous_aux(i, column));

** Transformation of the previous matrix into a vector
** count_on_init_aux(i)  -- number of hours unit has been on at the previous
**                          period of the considered optimization horizon
** count_off_init_aux(i) -- number of hours unit has been off at the previous
**                          period of the considered optimization horizon

parameter count_on_init_aux(i);
count_on_init_aux(i)$(onoff_t1_previous(i) eq 0) = 1;

count_on_init_aux(i)$((onoff_t1_previous(i) eq onoff_t0_previous(i)) and
                      (onoff_t1_previous(i) eq 1)) = count_on_init_previous(i) + 1;

count_on_init_aux(i)$((onoff_t1_previous(i) ne onoff_t0_previous(i)) and
                      (onoff_t1_previous(i) eq 1)) = 1;

parameter count_off_init_aux(i);
count_off_init_aux(i)$((onoff_t1_previous(i) eq onoff_t0_previous(i)) and
                       (onoff_t1_previous(i) eq 0)) = count_off_init_previous(i) + 1;

count_off_init_aux(i)$((onoff_t1_previous(i) ne onoff_t0_previous(i)) and
                       (onoff_t1_previous(i) eq 0)) = 1;

count_off_init_aux(i)$(onoff_t1_previous(i) eq 1) = 0;


********************************************************************************
*** SCALARS                                                                    *
********************************************************************************

** We assume a VoRS equal to 20 $/MWh
**
** The power base is equal to 100 MW
**
** We consider a 4 hour optimization horizon (could be 6 hr, 8hr, etc.)
**
** Parameter counter is always equal to 2 because the Day Number N starts in 0
** and we want the information related to the second day of the data from excel

scalars penalty_pf    penalty factor /2000/
        VoRS          value of wind spillage /20/
        s_base        base power /100/
        counter       counter /2/
        N_iter        number of iterations /2/
        horizon       optimization horizon /4/
        M             number of hours a unit can be on or off /2600/
;

scalar N /
$include C:\BPA_project\Test_connect_HA_ok\Data\Day_number.csv
/;

scalar hour /
$include C:\BPA_project\Test_connect_HA_ok\Data\Hour_number.csv
/;

t_ha(t)$((ord(t) ge hour) and (ord(t) lt hour+horizon) and (ord(t) le 24)) = yes;

parameter g_max(i, b),
          g_cap(t, i),
          k(i, b),
          g_0(i),
          onoff_t0(i),
          L_up_min(i),
          L_down_min(i),
          demand(s, t),
          wind_deterministic(t, w),
          sol_deterministic(t, r),
          fix_deterministic(f, t);

ramp_up(i) = ramp_up(i) / s_base;
ramp_down(i) = ramp_down(i) / s_base;
g_min(i) = g_min(i) / s_base;
l_max(l) = l_max(l) / s_base;
VoRS = VoRS * s_base;

parameter action_aux(t, s),
          action(t, d),
          minimum_load_aux(t, s),
          maximum_load_aux(t, s),
          minimum_load(t, d),
          maximum_load(t, d);

alias(t, tt);
alias(day, dayd);

** RYAN NOTE -160621-
** LOOK AT THIS LOGIC AND FIGURE OUT WHAT TO CHANGE WHEN THE TIME HORIZON SHRINKS

loop(day$(ord(day) eq N+counter),

    g_max(i, b) = g_max_day(day, i, b)/s_base;
    k(i, b) = k_day(day, i, b)*s_base;

** If hour is less than or equal to 24, we read the data as presented in the
** excel file or inc files for day (N+counter)

    demand(s, t)$(t_ha(t) and (ord(t) le 24)) =
        d_day(day, s, t)/s_base + sum(d$(storage_map(d) eq ord(s)), injection_DA_1(d, t));

    sol_deterministic(t, r)$(t_ha(t) and (ord(t) le 24)) =
        sol_deterministic_day(day, t, r)/s_base;

    fix_deterministic(f, t)$(t_ha(t) and (ord(t) le 24)) =
        abs(fix_deterministic_day(day, f, t))/s_base;

    wind_deterministic(t, w)$(t_ha(t) and (ord(t) le 24)) =
        wind_deterministic_day(day, t, w)/s_base;

** If hour is greater than 24, we read the data as presented in the
** excel file or inc files for day (N+counter+1)

*    demand(s, t)$(t_ha(t) and (ord(t) gt 24)) =
*        sum((tt, dayd)$((ord(dayd) eq N+counter+1) and (ord(tt) eq ord(t)-24)),
*            d_day(dayd, s, tt)/s_base + sum(d$(storage_map(d) eq ord(s)), injection_DA_2(d, tt)));
*            
*    sol_deterministic(t, r)$(t_ha(t) and (ord(t) gt 24)) =
*        sum((tt, dayd)$((ord(dayd) eq N+counter+1) and (ord(tt) eq ord(t)-24)),
*            sol_deterministic_day(dayd, tt, r)/s_base);
*            
*    fix_deterministic(f, t)$(t_ha(t) and (ord(t) gt 24)) =
*        sum((tt, dayd)$((ord(dayd) eq N+counter+1) and (ord(tt) eq ord(t)-24)),
*            abs(fix_deterministic_day(dayd, f, tt))/s_base);
*            
*    wind_deterministic(t, w)$(t_ha(t) and (ord(t) gt 24)) =
*        sum((tt, dayd)$((ord(dayd) eq N+counter+1) and (ord(tt) eq ord(t)-24)),
*            wind_deterministic_day(dayd, tt, w)/s_base);

** If hour is equal to 1 and the day is the first one, ie, N+counter equal to 2
** We read the initial conditions from the day-ahead stage

    if((hour eq 1) and (N+counter eq 2),
        g_0(i) = g_0_day(day, i)/s_base;
        onoff_t0(i) = onoff_t0_day(day, i);
        L_up_min(i) = L_up_min_day(day, i);
        L_down_min(i) = L_down_min_day(day, i);
        count_on_init_aux(i) = count_on_init_day(day, i);
        count_off_init_aux(i) = count_off_init_day(day, i);

** For the remaining hours and days, we read the conditions from the previous
** optimization horizon

    elseif hour gt 1,
        g_0(i) = g_0_previous(i);
        onoff_t0(i) = onoff_t1_previous(i);
        L_up_min(i) = min(card(t), (g_up(i) - count_on_init_aux(i))*onoff_t1_previous(i));
        L_down_min(i) = min(card(t), (g_down(i) - count_off_init_aux(i))*(1 - onoff_t1_previous(i)));
    );
);

display t_ha, demand;