set startTime 68334898000
#59116346000
#54935198000
#57621401000
set endTime   69007875000
#59135558000
#59680651000  
#54954410000
set vcdName rnnext_MODEL0_8_false
set vcdFile /scratch/andrire/RNNASIP/sourcecode/Basic_Kernels/vcd/$vcdName.vcd.gz
#/scratch/andrire/RNNASIP/sourcecode/Basic_Kernels/vcd/rnnext_new_MODEL5_8_false.vcd.gz
set targetFrequency 380
set vcdFrequency 50.5

set scalingFactor [expr $vcdFrequency/$targetFrequency]

#in ps
set_power -reset
set_powerup_analysis -reset
set_dynamic_power_simulation -reset
#report_power -rail_analysis_format VS -outfile ./reports/power//${DESIGNNAME}_core.rpt
set_power_output_dir -reset
set_power_output_dir ./reports/power/
read_activity_file -reset
read_activity_file -scale_duration $scalingFactor -format VCD -scope /tb_pulp/i_dut/soc_domain_i/pulp_soc_i/fc_subsystem_i/FC_CORE/lFC_CORE -start $startTime -end $endTime -block {} $vcdFile
set_power -reset
set_powerup_analysis -reset
set_dynamic_power_simulation -reset

report_power -outfile ${DESIGNNAME}_$vcdName.rpt -sort total -hierarchy all
echo "Power simulation configuration" > tmp
echo [concat "hostname: " [exec hostname]] >> tmp
echo "Netlist" >> tmp
ls -lah out/$DESIGNNAME.v >> tmp
echo "startTime = \t $startTime" >> tmp
echo "endTime = \t $endTime" >> tmp
echo "vcdFile = " >> tmp
ls -lah $vcdFile >> tmp
echo "targetFrequency = \t $targetFrequency" >> tmp
echo "vcdFrequency = \t $vcdFrequency" >> tmp
echo "scalingFactor = \t $scalingFactor" >> tmp
exec cat ./reports/power/${DESIGNNAME}_$vcdName.rpt >>  tmp
mv tmp ./reports/power/${DESIGNNAME}_$vcdName.rpt

cat ./reports/power/${DESIGNNAME}_$vcdName.rpt | grep _i | grep -v "/"
cat ./reports/power/${DESIGNNAME}_$vcdName.rpt | grep "Total Internal Power" | tail -n1
cat ./reports/power/${DESIGNNAME}_$vcdName.rpt | grep "Total Switching Power" | tail -n1
cat ./reports/power/${DESIGNNAME}_$vcdName.rpt | grep "Total Leakage Power" | tail -n1
cat ./reports/power/${DESIGNNAME}_$vcdName.rpt | grep "Total Power" | tail -n1
