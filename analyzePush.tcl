     # Written By Hoodean Malekzedeh                                                                 #
# Code to perform pushover analysis by avoidance of numerical divergence#
                                                                     #
set tol 1.e-5;									# minimum tolerance of convergence test. the algorith may decrease increase this value  to enhance convergence
set logFileID [open $dataDir/logPushover.txt w+];						# a file in which information about the analysis procedure are printed
set algoList "ModifiedNewton KrylovNewton";		# the desired list of algorithms; broyden and BFGS may lead to unacceptable values in static analysis

set incr1 $incr
set tol1 $tol

set numAlgos [llength $algoList]
constraints Transformation
numberer RCM
system UmfPack
test NormDispIncr $tol 100
analysis Static
set failureFlag 0
set endDisp 0


for {set iDrift 0} {$iDrift < [llength $targetDriftList]} {incr iDrift} {
	set targetDrift [lindex $targetDriftList $iDrift]
	set targetDisp [expr $targetDrift*$HBuilding]
	set curD [nodeDisp $roofNode $pushDir]
	set deltaD [expr $targetDisp - $curD]
	set nSteps [expr int(abs($deltaD)/$incr1)]
	algorithm NewtonLineSearch 0.65
	integrator DisplacementControl $roofNode $pushDir [expr abs($deltaD)/$deltaD*$incr]

	puts $logFileID "#################################################################################"
	puts $logFileID "building height= $HBuilding,  targetDrift= $targetDrift,  targetDisp= $targetDisp"
	puts $logFileID "#################################################################################"

	puts $logFileID "\n\n###########################################################################"
	puts $logFileID "Running: algorithm: NewtonLineSearch, incr=$incr1, curDisp= $curD, deltaDisp= $deltaD"

	puts "########################################################"
	puts "building height= $HBuilding,  targetDrift= $targetDrift,  targetDisp= $targetDisp"
	puts "########################################################"

	puts "\n\n########################################################"
	puts "Running: algorithm: NewtonLineSearch, incr=$incr1, curDisp= $curD, deltaDisp= $deltaD"

	set ok [analyze $nSteps]
	set curD [nodeDisp $roofNode $pushDir]
	set deltaD [expr $targetDisp-$curD]
	set iTry 1

	while {[expr abs($deltaD)] > $incr} {
		integrator DisplacementControl $roofNode $pushDir [expr abs($deltaD)/$deltaD*$incr1]
		if {$iTry <= $numAlgos} {
			set algo [lindex $algoList [expr $iTry-1]]

			puts $logFileID "\n\n######################################################################################"
			puts $logFileID "Running: algorithm:[lindex $algo 0], incr=$incr1, curDisp= $curD, deltaDisp= $deltaD"

			puts "\n\n######################################################################################"
			puts "Running:	algorithm:[lindex $algo 0], incr=$incr1, curDisp= $curD, deltaDisp= $deltaD"

			test NormDispIncr $tol1 30
			eval "algorithm $algo"
			set nSteps [expr int(10.*$incr/$incr1)]
			set ok [analyze $nSteps]
			if {$ok == 0} {
				set curD [nodeDisp $roofNode $pushDir]
				set deltaD [expr $targetDisp-$curD]
				set nSteps [expr int(abs($deltaD)/$incr)]
				set ok [analyze $nSteps $incr]
				set incr1 $incr
				set tol1 $tol
				set iTry 0
			}
		} else {
			set iTry 0
			set incr1 [expr $incr1/3.]
			set tol1 [expr $tol1*3.]
			if {[expr $incr1/$incr] < 1.e-5} {
				set failureFlag 1
				break
			}
		}
		incr iTry
		set curD [nodeDisp $roofNode $pushDir]
		set deltaD [expr $targetDisp-$curD]
	}
	set endDisp [nodeDisp $roofNode 1]
	if {$failureFlag == 0} {
		puts "\n================ Analysis Completed ================"
		puts $logFileID "\n================ Analysis Completed ================"
	} else {
		puts "\n!!!!!!!!!!!!!!!!!!!!!!!!!! Analysis Interrupted !!!!!!!!!!!!!!!!!!!!!!!!!!"
		puts $logFileID "\n!!!!!!!!!!!!!!!!!!!!!!!!!! Analysis Interrupted !!!!!!!!!!!!!!!!!!!!!!!!!!"
	}
	puts "\nendDisp= $endDisp"
	puts $logFileID "\nendDisp= $endDisp"
}

# wipe