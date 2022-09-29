Scenario calculation for the Bhojpur Earthquake 5.1Mw on 31 July 2022
=====================================================================

============== ===================
checksum32     3_422_477_514      
date           2022-09-29T17:52:19
engine_version 3.11.5             
============== ===================

num_sites = 38423, num_levels = 1, num_rlzs = 1

Parameters
----------
=============================== ==========================================
calculation_mode                'scenario'                                
number_of_logic_tree_samples    0                                         
maximum_distance                {'default': [(1.0, 500.0), (10.0, 500.0)]}
investigation_time              None                                      
ses_per_logic_tree_path         1                                         
truncation_level                3.0                                       
rupture_mesh_spacing            5.0                                       
complex_fault_mesh_spacing      None                                      
width_of_mfd_bin                None                                      
area_source_discretization      None                                      
pointsource_distance            None                                      
ground_motion_correlation_model None                                      
minimum_intensity               {}                                        
random_seed                     113                                       
master_seed                     0                                         
ses_seed                        42                                        
=============================== ==========================================

Input files
-----------
=============== ==============================================================
Name            File                                                          
=============== ==============================================================
gsim_logic_tree `gmpe.xml <gmpe.xml>`_                                        
job_ini         `job.ini <job.ini>`_                                          
rupture_model   `earthquake_rupture_model.xml <earthquake_rupture_model.xml>`_
sites           `su_lonlat_noHeaders.csv <su_lonlat_noHeaders.csv>`_          
=============== ==============================================================

Composite source model
----------------------
====== ========================= ====
grp_id gsim                      rlzs
====== ========================= ====
0      '[CampbellBozorgnia2014]' [0] 
====== ========================= ====

Information about the tasks
---------------------------
================== ====== ======= ====== ======= =======
operation-duration counts mean    stddev min     max    
compute_gmfs       1      1.02826 nan    1.02826 1.02826
================== ====== ======= ====== ======= =======

Data transfer
-------------
============ ==== =========
task         sent received 
compute_gmfs      649.89 KB
============ ==== =========

Slowest operations
------------------
======================== ======== ========= ======
calc_12, maxmem=0.7 GB   time_sec memory_mb counts
======================== ======== ========= ======
EventBasedCalculator.run 12       14        1     
saving avg_gmf           10       0.0       1     
total compute_gmfs       1.02826  5.72656   1     
getting ruptures         0.61137  5.85156   2     
importing inputs         0.40595  4.20312   1     
saving gmfs              0.01297  0.09375   1     
aggregating hcurves      0.0      0.0       1     
======================== ======== ========= ======