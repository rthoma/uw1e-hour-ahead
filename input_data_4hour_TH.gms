***************************************************************
*** SETS
***************************************************************

set t            index of time periods /t1*t27/;
set t_ha(t)      index of time periods in the optimization horizon for the hour-ahead framework
set i            index of generators /i1*i57/;
set b            index of generator blocks /b1*b3/;
set s            index of buses /s1*s3898/;
set l            index of transmission lines /l1*l4801/;
set w            index of wind generators /w1*w80/;
set r            index of solar generators /r1*r5/;
set f            index of fixed generators /f1*f590/;
set day          day counter /day1*day366/;

set from_to      lines from and to /from,to/;
set column       generator connected to bus /col/;
set wcolumn      wind connected to bus /wcol/;
set rcolumn      solar connected to bus /rcol/;
set fcolumn      fixed connected to bus /fcol/;
set iter         number of iterations /iter1*iter366/
set d            set of storage units /d1/;



***************************************************************
*** GENERATOR DATA
***************************************************************

table gen_map_aux(i,column) generator map
*$call =xls2gms r=Generator_Map!e2:f59 i=Input_Data_WECC2024_BPA2.xlsx o=gmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\gmap2.inc
;
parameter gen_map(i);
gen_map(i)=sum(column,gen_map_aux(i,column));

* time varying generation cost curve MW block
table g_max_day(day,i,b) generator block generation limit
*$call =xls2gms r=Generator_CostCurve!a2:f20864 i=Input_Data_WECC2024_BPA2.xlsx o=block_max.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\block_max.inc
;

* time varying generation capacity (forced outage information included)
table g_cap_day(day,t,i) generator capacity
*$call =xls2gms r=Generator_Pmax!a2:bh8786 i=Input_Data_WECC2024_BPA2.xlsx o=gcap.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\gcap.inc
;

* time varying generation cost curve price block
table k_day(day,i,b) slope of each generator cost curve block
*$call =xls2gms r=Generator_CostCurve!i2:n20864 i=Input_Data_WECC2024_BPA2.xlsx o=k.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\k.inc
;

table suc_sw_aux(i,column) generator stepwise start-up cost
*$call =xls2gms r=Generator_Data!au2:av59 i=Input_Data_WECC2024_BPA2.xlsx o=start_up_sw.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\start_up_sw.inc
;

parameter suc_sw(i);
suc_sw(i)=sum(column,suc_sw_aux(i,column));

*table suc_sl(i,j) generator stepwise start-up hourly blocks
*$call =xls2gms r=Generator_Data!ay2:bg98 i=Input_Data.xlsx o=start_up_sl.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\start_up_sl.inc
*;

* time varying generation count off initial
table count_off_init_day(day,i) number of time periods each generator has been off
*$call =xls2gms r=Generator_InitOff!a2:bf368 i=Input_Data_WECC2024_BPA2.xlsx o=aux2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux2.inc
;

*table aux2(i,column)
*  modified here
*$call =xls2gms r=Generator_Data!d2:e318 i=Input_Data_WECC2024_BPA_year.xlsx o=aux2.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\aux2.inc
*;
*parameter
*count_off_init(i)=sum(column,aux2(i,column));

* time varying generation count off initial
table count_on_init_day(day,i) number of time periods each generator has been on
*$call =xls2gms r=Generator_InitOn!a2:bf368 i=Input_Data_WECC2024_BPA2.xlsx o=aux3.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux3.inc
;

*table aux3(i,column)
*  modified here
*$call =xls2gms r=Generator_Data!g2:h318 i=Input_Data_WECC2024_BPA_year.xlsx o=aux3.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\aux3.inc
*;
*parameter count_on_init(i) number of time periods each generator has been on;
*count_on_init(i)=sum(column,aux3(i,column));

table aux4(i,column)
*$call =xls2gms r=Generator_Data!j2:k59 i=Input_Data_WECC2024_BPA2.xlsx o=aux4.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux4.inc
;
parameter a(i) fixed operating cost of each generator;
a(i)=sum(column,aux4(i,column));

table aux5(i,column)
*$call =xls2gms r=Generator_Data!m2:n59 i=Input_Data_WECC2024_BPA2.xlsx o=aux5.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux5.inc
;
parameter ramp_up(i) generator ramp-up limit;
ramp_up(i)=sum(column,aux5(i,column));

table aux6(i,column)
*$call =xls2gms r=Generator_Data!p2:q59 i=Input_Data_WECC2024_BPA2.xlsx o=aux6.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux6.inc
;
parameter ramp_down(i) generator ramp-down limit;
ramp_down(i)=sum(column,aux6(i,column));

table aux7(i,column)
*$call =xls2gms r=Generator_Data!s2:t59 i=Input_Data_WECC2024_BPA2.xlsx o=aux7.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux7.inc
;
parameter g_down(i) generator minimum down time;
g_down(i)=sum(column,aux7(i,column));

table aux8(i,column)
*$call =xls2gms r=Generator_Data!v2:w59 i=Input_Data_WECC2024_BPA2.xlsx o=aux8.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux8.inc
;
parameter g_up(i) generator minimum up time;
g_up(i)=sum(column,aux8(i,column));

table aux9(i,column)
*$call =xls2gms r=Generator_Data!y2:z59 i=Input_Data_WECC2024_BPA2.xlsx o=aux9.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux9.inc
;
parameter g_min(i) generator minimum output;
g_min(i)=sum(column,aux9(i,column));

* time varying generation count off initial
table g_0_day(day,i) generator generation at t=0
*$call =xls2gms r=Generator_PInit!a2:bf368 i=Input_Data_WECC2024_BPA2.xlsx o=aux10.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux10.inc
;

*table aux10(i,column)
*  modified here
*$call =xls2gms r=Generator_Data!ab2:ac318 i=Input_Data_WECC2024_BPA_year.xlsx o=aux10.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\aux10.inc
*;
*parameter g_0(i) generator generation at t=0;
*g_0(i)=sum(column,aux10(i,column));

parameter onoff_t0_day(day,i) on-off status at t=0;
onoff_t0_day(day,i)$(count_on_init_day(day,i) gt 0) = 1;

parameter L_up_min_day(day,i) used for minimum up time constraints;
L_up_min_day(day,i) = min(card(t), (g_up(i)-count_on_init_day(day,i))*onoff_t0_day(day,i));

parameter L_down_min_day(day,i) used for minimum up time constraints;
L_down_min_day(day,i) = min(card(t), (g_down(i)-count_off_init_day(day,i))*(1-onoff_t0_day(day,i)));

scalar M number of hours a unit can be on or off /2600/;

***************************************************************
*** LINE DATA
***************************************************************

table line_map(l,from_to) line map
*$call =xls2gms r=Line_Map!e1:g4802 i=Input_Data_WECC2024_BPA2.xlsx o=line_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\line_map.inc
;

table aux11(l,column)
*$call =xls2gms r=Line_Data!a1:b4802 i=Input_Data_WECC2024_BPA2.xlsx o=aux11.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux11.inc
;
parameter admittance(l) line admittance;
admittance(l)=abs(sum(column,aux11(l,column)));

table aux12(l,column)
*$call =xls2gms r=Line_Data!j1:k4802 i=Input_Data_WECC2024_BPA2.xlsx o=aux12.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\aux12_new_modif.inc
;
parameter l_max(l) line capacities (long-term ratings);
l_max(l)=sum(column,aux12(l,column));

table snpd_lines_aux(l,column)
$include C:\BPA_project\Test_connect_HA_ok\Data\snpd_lines.inc
;
parameter snpd_lines_map(l) line capacities (long-term ratings);
snpd_lines_map(l)=sum(column,snpd_lines_aux(l,column));



***************************************************************
*** DEMAND DATA
***************************************************************

*table d_1(s_1,t) demand at bus s - part 1
*modified here
*$call =xls2gms r=Load_Active_Part_1!a27:y10027 i=Input_Data_WECC2024_BPA_year.xlsx o=load_part_1.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load_part_1.inc
*;

*table d_2(s_2,t) demand at bus s - part 2
*modified here
*$call =xls2gms r=Load_Active_Part_2!a27:y7573 i=Input_Data_WECC2024_BPA_year.xlsx o=load_part_2.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\load_part_2.inc
*;

*parameter d(t,s) demand at bus s;
*d(t,s)=sum(s_1$(ord(s)=ord(s_1)),d_1(s_1,t))+sum(s_2$(ord(s)=ord(s_2)+10000),d_2(s_2,t));

* time varying demand
table d_day(day,s,t) demand at bus s
*modified here
*$call =xls2gms r=Load1!a1:aa237779 i=BPA_fixed_load2.xlsx o=load1.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load1.inc
;

table d_day2(day,s,t) demand at bus s
*$call =xls2gms r=Load2!a1:aa237779 i=BPA_fixed_load2.xlsx o=load2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load2.inc
;

d_day(day,s,t)$(d_day2(day,s,t)>0)=  d_day2(day,s,t);

table d_day3(day,s,t) demand at bus s
*$call =xls2gms r=Load3!a1:aa237779 i=BPA_fixed_load2.xlsx o=load3.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load3.inc
;

d_day(day,s,t)$(d_day3(day,s,t)>0)=  d_day3(day,s,t);

table d_day4(day,s,t) demand at bus s
*$call =xls2gms r=Load4!a1:aa237779 i=BPA_fixed_load2.xlsx o=load4.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load4.inc
;

d_day(day,s,t)$(d_day4(day,s,t)>0)=  d_day4(day,s,t);

table d_day5(day,s,t) demand at bus s
*$call =xls2gms r=Load5!a1:aa237779 i=BPA_fixed_load2.xlsx o=load5.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load5.inc
;

d_day(day,s,t)$(d_day5(day,s,t)>0)=  d_day5(day,s,t);

table d_day6(day,s,t) demand at bus s
*$call =xls2gms r=Load6!a1:aa237779 i=BPA_fixed_load2.xlsx o=load6.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\load6.inc
;

d_day(day,s,t)$(d_day6(day,s,t)>0)=  d_day6(day,s,t);

***************************************************************
*** WIND DATA in the Day-Ahead
***************************************************************

table win_map_aux(w,wcolumn) wind map
*$call =xls2gms r=Wind!e1:f81 i=Input_Data_WECC2024_BPA2.xlsx o=wmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\wmap2.inc
;

parameter win_map(w);
win_map(w)=sum(wcolumn,win_map_aux(w,wcolumn));

* time varying wind
*table wind_deterministic_day(day,t,w) wind data
*  modified here
*$call =xls2gms r=Wind!h1:cl8785 i=Input_Data_WECC2024_BPA2.xlsx o=wind_deterministic.inc
*$include C:\BPA_project\Test_connect_HA_ok\Data\wind_deterministic.inc
*;

***************************************************************
*** WIND DATA in the Hour-Ahead
***************************************************************

table wind_deterministic_day(day,t,w) wind data
*$call =xls2gms r=Sheet1!a1:ce97 i=C:\BPA_project\Test_connect_HA_ok\Data\wind_hour_ahead.xls o=C:\BPA_project\Test_connect_HA_ok\Data\wind_hour_ahead_aux.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\wind_hour_ahead_aux.inc
;

***************************************************************
*** Solar DATA
***************************************************************

table sol_map_aux(r,rcolumn) solar map
*$call =xls2gms r=Solar!e1:f6 i=Input_Data_WECC2024_BPA2.xlsx o=rmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\rmap2.inc
;

parameter sol_map(r);
sol_map(r)=sum(rcolumn,sol_map_aux(r,rcolumn));

* time varying solar
table sol_deterministic_day(day,t,r) solar data
*  modified here
*$call =xls2gms r=Solar!h1:o8785 i=Input_Data_WECC2024_BPA2.xlsx o=solar_deterministic.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\solar_deterministic.inc
;

********************************************************************************
*** Fixed DATA
********************************************************************************

table fix_map_aux(f,fcolumn) fixed map
*$call =xls2gms r=Fixed!e1:f591 i=Input_Data_WECC2024_BPA2.xlsx o=fmap2.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\fmap2.inc
;

parameter fix_map(f);
fix_map(f)=sum(fcolumn,fix_map_aux(f,fcolumn));

* time varying fixed dispatch
table fix_deterministic_day(day,f,t) fixed data
*  modified here
*$call =xls2gms r=Fixed!a1:aa215941 i=BPA_fixed_load2.xlsx o=fixed_deterministic.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\fixed_deterministic_new.inc
*;

********************************************************************************
*** STORAGE DATA (NEGOTIATION PROTOCOL AND INFORMATION ABOUT UNITS)
********************************************************************************

table storage_map_aux(d,column) map energy storage - bus
*$call =xls2gms r=map_storage!a2:b22 i=ES_data.xlsx o=storage_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\storage_map.inc
;

table area_name_storage(d,column)
*$call =xls2gms r=map_storage!d2:e22 i=ES_data.xlsx o=area_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\area_map.inc
;

table zone_name_storage(d,column)
*$call =xls2gms r=map_storage!g2:h22 i=ES_data.xlsx o=zone_map.inc
$include C:\BPA_project\Test_connect_HA_ok\Data\zone_map.inc
;

Parameter storage_map(d),storage_area(d),storage_zone(d);

storage_map(d)=sum(column,storage_map_aux(d,column));
storage_area(d)=sum(column,area_name_storage(d,column));
storage_zone(d)=sum(column,zone_name_storage(d,column));

********************************************************************************
*** POWER INJECTIONS FROM THE DAY-AHEAD FRAMEWORK
*** 1 stands for the day in which we simulate the hour-ahead
*** 2 stands for the next day
*** They should be updated when changing the day in which we perform the opt.
********************************************************************************

table injection_DA_1(d,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\DA_injections1.csv
$offdelim
;

table injection_DA_2(d,t)
$ondelim
$include C:\BPA_project\Test_connect_HA_ok\Data\DA_injections2.csv
$offdelim
;

********************************************************************************
*** INITIAL CONDITIONS FROM PREVIOUS SIMULATIONS (t > 1)
********************************************************************************

table g_0_previous_aux(i,column) generator generation at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\g_0_previous_aux2.inc
;

parameter g_0_previous(i);
g_0_previous(i)=sum(column,g_0_previous_aux(i,column));

table onoff_t0_previous_aux(i,column) on-off status at the previous period of the previous considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\onoff_t0_previous_aux2.inc
;

parameter onoff_t0_previous(i);
onoff_t0_previous(i)=sum(column,onoff_t0_previous_aux(i,column));

table onoff_t1_previous_aux(i,column) on-off status at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\onoff_t1_previous_aux2.inc
;

parameter onoff_t1_previous(i);
onoff_t1_previous(i)=sum(column,onoff_t1_previous_aux(i,column));

table count_on_init_previous_aux(i,column) number of hours unit has been on at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\count_on_init_previous_aux2.inc
;

parameter count_on_init_previous(i);
count_on_init_previous(i)=sum(column,count_on_init_previous_aux(i,column));

table count_off_init_previous_aux(i,column) number of hours unit has been off at the previous period of the considered optimization horizon
$include C:\BPA_project\Test_connect_HA_ok\Data\count_off_init_previous_aux2.inc
;

parameter count_off_init_previous(i);
count_off_init_previous(i)=sum(column,count_off_init_previous_aux(i,column));



parameter count_on_init_aux(i) number of hours unit has been on at the previous period of the considered optimization horizon;
parameter count_off_init_aux(i) number of hours unit has been off at the previous period of the considered optimization horizon;

count_on_init_aux(i)$(onoff_t1_previous(i) eq onoff_t0_previous(i) and onoff_t1_previous(i) eq 1 )= count_on_init_previous(i)+1;
count_on_init_aux(i)$(onoff_t1_previous(i) ne onoff_t0_previous(i) and onoff_t1_previous(i) eq 1 )= 1;
count_off_init_aux(i)$(onoff_t1_previous(i) eq onoff_t0_previous(i) and onoff_t1_previous(i) eq 0 )= count_off_init_previous(i)+1;
count_off_init_aux(i)$(onoff_t1_previous(i) ne onoff_t0_previous(i) and onoff_t1_previous(i) eq 0 )= 1;
count_off_init_aux(i)$(onoff_t1_previous(i) eq 1 )= 0;
count_on_init_aux(i)$(onoff_t1_previous(i) eq 0 )= 1;

********************************************************************************
********************************************************************************

scalar penalty_pf /2000/;


scalars

** We assume a VoRS equal to 20 $/MWh
         VoRS            value of wind spillage /20/

** The power base is equal to 100 MW
         s_base          base power /100/

** Parameter counter is always equal to 2 because the Day Number N starts in 0
** and we want the information related to the second day of the data from excel
         counter         counter /2/

         N_iter          number of iterations /2/

** The optimization horizon is assumed equal to 4 hours because the short-term
** forecast would be updated every 4 hours. However we can consider a different
** horizon: one, six, eight hours...
         horizon         optimization horizon    /4/
;

scalar N /
$include C:\BPA_project\Test_connect_HA_ok\Data\Day_number.csv
/;

scalar hour /
$include C:\BPA_project\Test_connect_HA_ok\Data\Hour_number.csv
/;



t_ha(t)$(ord(t) ge hour and ord(t) lt (hour+horizon))=yes;

parameter g_max(i,b),g_cap(t,i),k(i,b),g_0(i),onoff_t0(i),L_up_min(i),L_down_min(i),demand(s,t),wind_deterministic(t,w),sol_deterministic(t,r),fix_deterministic(f,t);

ramp_up(i)=ramp_up(i)/s_base;
ramp_down(i)=ramp_down(i)/s_base;
g_min(i)=g_min(i)/s_base;
l_max(l)=l_max(l)/s_base;
VoRS = VoRS * s_base;

Parameter action_aux(t,s),action(t,d),minimum_load_aux(t,s), maximum_load_aux(t,s) , minimum_load(t,d), maximum_load(t,d);


alias(t,tt);
alias(day,dayd);

loop(day$(ord(day) eq N+counter),

g_max(i,b)=g_max_day(day,i,b)/s_base ;
k(i,b)= k_day(day,i,b)*s_base ;

** If hour is less than or equal to 24, we read the data as presented in the
** excel file or inc files for day (N+counter)
demand(s,t)$(t_ha(t) and ord(t) le 24)=d_day(day,s,t)/s_base +sum(d$(storage_map(d) eq ord(s)),injection_DA_1(d,t))   ;
sol_deterministic(t,r)$(t_ha(t) and ord(t) le 24)=sol_deterministic_day(day,t,r)/s_base;
fix_deterministic(f,t)$(t_ha(t) and ord(t) le 24)=abs(fix_deterministic_day(day,f,t))/s_base;
wind_deterministic(t,w)$(t_ha(t) and ord(t) le 24)=wind_deterministic_day(day,t,w)/s_base;

** If hour is greater than 24, we read the data as presented in the
** excel file or inc files for day (N+counter+1)
demand(s,t)$(t_ha(t) and ord(t) gt 24)=sum((tt,dayd)$(ord(dayd) eq N+counter+1 and ord(tt) eq ord(t) -24), d_day(dayd,s,tt)/s_base +sum(d$(storage_map(d) eq ord(s)),injection_DA_2(d,tt))   );
sol_deterministic(t,r)$(t_ha(t) and ord(t) gt 24)=sum((tt,dayd)$(ord(dayd) eq N+counter+1 and ord(tt) eq ord(t) -24), sol_deterministic_day(dayd,tt,r)/s_base );
fix_deterministic(f,t)$(t_ha(t) and ord(t) gt 24)=sum((tt,dayd)$(ord(dayd) eq N+counter+1 and ord(tt) eq ord(t) -24), abs(fix_deterministic_day(dayd,f,tt))/s_base );
wind_deterministic(t,w)$(t_ha(t) and ord(t) gt 24)=sum((tt,dayd)$(ord(dayd) eq N+counter+1 and ord(tt) eq ord(t) -24), wind_deterministic_day(dayd,tt,w)/s_base );

** If hour is equal to 1 and the day is the first one, ie, N+counter equal to 2
** We read the initial conditions from the day-ahead stage
if(hour eq 1 and (N+counter) eq 2,
g_0(i)=g_0_day(day,i)/s_base;
onoff_t0(i)=onoff_t0_day(day,i);
L_up_min(i)=L_up_min_day(day,i);
L_down_min(i)=L_down_min_day(day,i);
count_on_init_aux(i)=count_on_init_day(day,i);
count_off_init_aux(i)=count_off_init_day(day,i);

** For the remaining hours and days, we read the conditions from the previous
** optimization horizon
elseif hour gt 1,

g_0(i)=g_0_previous(i);
onoff_t0(i)= onoff_t1_previous(i);
L_up_min(i) = min(card(t), (g_up(i)-count_on_init_aux(i))*onoff_t1_previous(i));
L_down_min(i) = min(card(t), (g_down(i)-count_off_init_aux(i))*(1-onoff_t1_previous(i)));
);


);


display t_ha, demand;






