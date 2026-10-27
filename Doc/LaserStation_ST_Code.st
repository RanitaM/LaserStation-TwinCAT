(*==============================================================================
  TwinCAT 3 - Structured Text for the station in the EPLAN "Jenoptik Funktionsmuster LCLW"
  HOW TO USE: every block below is ONE object in the PLC project.
  Create the object (name + type as written in the header), then paste the
  declaration part into the upper editor and the code part into the lower editor.
  (For GVL / DUT / ENUM the whole block goes into the single editor window.)

  Layers:   GVL_HW  = raw EtherCAT process image (AT %I* / %Q*)   <- only used with real I/O
            GVL_IO  = logic image used by the sequence            <- always used
            PRG_IO_In / PRG_IO_Out = copy HW <-> logic OR simulation (GVL_Ctrl.xSim)
            PRG_Seq = sequence + supervision
==============================================================================*)


(*------------------------------------------------------------------------------
  DUT  ST_CylIO            (Add > DUT > Structure)
------------------------------------------------------------------------------*)
TYPE ST_CylIO :
STRUCT
    xValveWork : BOOL;   // valve AS  (Arbeitsstellung = working position)
    xValveHome : BOOL;   // valve GS  (Grundstellung   = home position)
    xSensWork  : BOOL;   // sensor AS
    xSensHome  : BOOL;   // sensor GS
END_STRUCT
END_TYPE


(*------------------------------------------------------------------------------
  DUT  E_Step              (Add > DUT > Enumeration)
------------------------------------------------------------------------------*)
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Step :
(
    eInit         := 0,     // all cylinders home, everything off
    eIdle         := 10,    // wait for Start / ready
    eWaitPart     := 20,    // wait for light barrier infeed
    eInfeedFwd    := 30,    // infeed cylinder pushes part into station
    eClampFwd     := 40,    // clamp part
    eInfeedBack   := 50,    // infeed cylinder back
    eLoadJob      := 60,    // select job, enable laser, wait for Jobloaded + Lready
    eLaserRun     := 70,    // trigger laser
    eLaserWait    := 80,    // wait until marking finished
    eBlowOff      := 90,    // blow off debris (timed)
    eClampBack    := 100,   // release clamp
    eDiverter     := 110,   // set diverter (good part / reject)
    eEject        := 120,   // ejector forward (+ bypass valve for rejects)
    eEjectBack    := 130,   // ejector back
    eOutfeedWait  := 140,   // wait for light barrier outfeed
    eOutfeed      := 150,   // outfeed cylinder forward
    eOutfeedBack  := 160,   // outfeed cylinder back
    eCycleEnd     := 170,   // diverter home, count part
    eFault        := 900
) UINT;
END_TYPE


(*------------------------------------------------------------------------------
  GVL  GVL_HW              (Add > Global Variable List)
  Hardware image. Link these in the I/O tree (see guide). EPLAN address in comment.
------------------------------------------------------------------------------*)
{attribute 'qualified_only'}
VAR_GLOBAL
    //---------------- EL1809 +MP-6K10 (cabinet inputs)
    xMaintPressureOK   AT %I* : BOOL;   // E0.0  Wartungseinheit: Druckschalter (TRUE = pressure ok)
    xEStopPressed      AT %I* : BOOL;   // E0.1  Not-Halt betaetigt           (TRUE = pressed)
    //---------------- EL2809 +MP-6K20 (cabinet outputs)
    xMaintVent         AT %Q* : BOOL;   // A0.0  Wartungseinheit: Entlueften  (TRUE = vent)
    xLaserEnable       AT %Q* : BOOL;   // A0.1  LaserEnable
    //---------------- EL1809 +LS-7K10 (CW controller inputs)
    xCW_Lready         AT %I* : BOOL;   // E50.0 CW: Lready
    xCW_JobLoaded      AT %I* : BOOL;   // E50.1 CW: Jobloaded
    xCW_MarkBusy       AT %I* : BOOL;   // E50.2 CW: MarkInProgress
    //---------------- EL2809 +LS-7K20 (CW controller outputs)
    xCW_Trig           AT %Q* : BOOL;   // A50.0 CW: Ltrig
    xCW_Job0           AT %Q* : BOOL;   // A50.1 CW: Job bit 0
    xCW_Job1           AT %Q* : BOOL;   // A50.2 CW: Job bit 1
    xCW_Job2           AT %Q* : BOOL;   // A50.3 CW: Job bit 2
    xCW_Job3           AT %Q* : BOOL;   // A50.4 CW: Job bit 3
    xCW_STO            AT %Q* : BOOL;   // A50.5 CW: STO  (ASSUMPTION: TRUE = STO released / enabled)
    //---------------- EP1018-0001 +MS-9K1
    xSnsEjector_AS     AT %I* : BOOL;   // E1050.0
    xSnsEjector_GS     AT %I* : BOOL;   // E1050.1
    xSnsClamp_AS       AT %I* : BOOL;   // E1050.2
    xSnsClamp_GS       AT %I* : BOOL;   // E1050.3
    xSnsDiverter_AS    AT %I* : BOOL;   // E1050.4
    xSnsDiverter_GS    AT %I* : BOOL;   // E1050.5
    //---------------- EP1018-0001 +MS-9K2
    xSnsInfeed_AS      AT %I* : BOOL;   // E1051.0
    xSnsInfeed_GS      AT %I* : BOOL;   // E1051.1
    xSnsOutfeed_AS     AT %I* : BOOL;   // E1051.2
    xSnsOutfeed_GS     AT %I* : BOOL;   // E1051.3
    //---------------- EP1018-0001 +MS-9K3
    xLS_Infeed         AT %I* : BOOL;   // E1052.0 Lichtschranke Einlauf   (TRUE = part present)
    xServoIn_Latched   AT %I* : BOOL;   // E1052.1 Servo Einlauf eingerastet
    xServoIn_AS        AT %I* : BOOL;   // E1052.2
    xServoIn_GS        AT %I* : BOOL;   // E1052.3
    xLS_Outfeed        AT %I* : BOOL;   // E1052.4 Lichtschranke Auslauf   (TRUE = part present)
    xServoOut_Latched  AT %I* : BOOL;   // E1052.5 Servo Auslauf eingerastet
    xServoOut_AS       AT %I* : BOOL;   // E1052.6
    xServoOut_GS       AT %I* : BOOL;   // E1052.7
    //---------------- EP2028-0001 +MS-10K1
    xValveEjector_AS   AT %Q* : BOOL;   // A1050.0
    xValveEjector_GS   AT %Q* : BOOL;   // A1050.1
    xValveClamp_AS     AT %Q* : BOOL;   // A1050.2
    xValveClamp_GS     AT %Q* : BOOL;   // A1050.3
    xValveDiverter_AS  AT %Q* : BOOL;   // A1050.4
    xValveDiverter_GS  AT %Q* : BOOL;   // A1050.5
    //---------------- EP2028-0001 +MS-10K2
    xValveInfeed_AS    AT %Q* : BOOL;   // A1051.0
    xValveInfeed_GS    AT %Q* : BOOL;   // A1051.1
    xValveOutfeed_AS   AT %Q* : BOOL;   // A1051.2
    xValveOutfeed_GS   AT %Q* : BOOL;   // A1051.3
    xValveBlow_AS      AT %Q* : BOOL;   // A1051.4 Ausblasen
    xValveBlow_GS      AT %Q* : BOOL;   // A1051.5
    xValveBypass_AS    AT %Q* : BOOL;   // A1051.6 Auswurf Bypass
    xValveBypass_GS    AT %Q* : BOOL;   // A1051.7
END_VAR


(*------------------------------------------------------------------------------
  GVL  GVL_IO              (logic image, NO hardware addresses)
------------------------------------------------------------------------------*)
{attribute 'qualified_only'}
VAR_GLOBAL
    // inputs
    xPressureOK, xEStop             : BOOL;
    xLS_Infeed, xLS_Outfeed         : BOOL;
    xServoInLatched, xServoInAS, xServoInGS     : BOOL;
    xServoOutLatched, xServoOutAS, xServoOutGS  : BOOL;
    xCW_Lready, xCW_JobLoaded, xCW_MarkBusy     : BOOL;
    // cylinders (valves = outputs, sensors = inputs)
    stInfeed, stOutfeed, stEjector, stClamp, stDiverter : ST_CylIO;
    // outputs
    xVent, xLaserEnable, xCW_Trig, xCW_STO      : BOOL;
    nCW_Job                                     : USINT;   // job number 0..15
    xBlowAS, xBlowGS, xBypassAS, xBypassGS      : BOOL;
END_VAR


(*------------------------------------------------------------------------------
  GVL  GVL_Ctrl            (operator / HMI / simulation variables - use these in the Watch window)
------------------------------------------------------------------------------*)
{attribute 'qualified_only'}
VAR_GLOBAL
    xStart  : BOOL;              // start automatic cycle (rising edge, stays active until Stop)
    xStop   : BOOL;              // stop after current cycle
    xReset  : BOOL;              // acknowledge fault (rising edge)
    xReject : BOOL;              // TRUE = next part is a reject (diverter + bypass)
    nJobNo  : USINT := 1;        // laser job number 1..15

    xSim            : BOOL := TRUE;    // TRUE = simulate all I/O (offline); FALSE = real hardware
    xSimEStop       : BOOL;            // simulate E-stop pressed
    xSimPressureOK  : BOOL := TRUE;    // simulate air pressure ok
    xSimPartIn      : BOOL;            // put a part at infeed light barrier
    xSimPartOut     : BOOL;            // (set automatically when ejector pushed the part)
END_VAR


(*------------------------------------------------------------------------------
  FUNCTION_BLOCK  FB_Cylinder      generic double-acting cylinder with 2 valves + 2 sensors
------------------------------------------------------------------------------*)
FUNCTION_BLOCK FB_Cylinder
VAR_INPUT
    xCmdWork   : BOOL;               // TRUE = go to AS, FALSE = go to GS
    xEnable    : BOOL;               // FALSE = both valves off
    xReset     : BOOL;               // acknowledge fault
    xSensWork  : BOOL;
    xSensHome  : BOOL;
    tTimeout   : TIME := T#3S;
END_VAR
VAR_OUTPUT
    xValveWork : BOOL;
    xValveHome : BOOL;
    xInWork    : BOOL;
    xInHome    : BOOL;
    xFault     : BOOL;
END_VAR
VAR
    fbTimeout  : TON;
    xMoving    : BOOL;
END_VAR

// ----------------------- code -----------------------
xInWork := xSensWork AND NOT xSensHome;
xInHome := xSensHome AND NOT xSensWork;

IF xReset THEN
    xFault := FALSE;
END_IF

IF NOT xEnable OR xFault THEN
    xValveWork := FALSE;
    xValveHome := FALSE;
ELSIF xCmdWork THEN
    xValveWork := TRUE;
    xValveHome := FALSE;
ELSE
    xValveWork := FALSE;
    xValveHome := TRUE;
END_IF

// travel-time / sensor plausibility supervision (also catches "both sensors active")
xMoving := (xValveWork AND NOT xInWork) OR (xValveHome AND NOT xInHome);
fbTimeout(IN := xMoving AND NOT xFault, PT := tTimeout);
IF fbTimeout.Q THEN
    xFault := TRUE;
END_IF


(*------------------------------------------------------------------------------
  FUNCTION_BLOCK  FB_CylinderSim   simulates the sensors of one cylinder
------------------------------------------------------------------------------*)
FUNCTION_BLOCK FB_CylinderSim
VAR_INPUT
    xValveWork : BOOL;
    xValveHome : BOOL;
    tMoveTime  : TIME := T#500MS;
END_VAR
VAR_OUTPUT
    xSensWork  : BOOL;
    xSensHome  : BOOL := TRUE;       // power-up position = home
END_VAR
VAR
    fbToWork   : TON;
    fbToHome   : TON;
END_VAR

// ----------------------- code -----------------------
fbToWork(IN := xValveWork AND NOT xValveHome, PT := tMoveTime);
fbToHome(IN := xValveHome AND NOT xValveWork, PT := tMoveTime);

IF xValveWork AND NOT xValveHome THEN xSensHome := FALSE; END_IF
IF xValveHome AND NOT xValveWork THEN xSensWork := FALSE; END_IF
IF fbToWork.Q THEN xSensWork := TRUE; END_IF
IF fbToHome.Q THEN xSensHome := TRUE; END_IF


(*------------------------------------------------------------------------------
  FUNCTION_BLOCK  FB_CwSim         simulates the CW laser controller handshake
------------------------------------------------------------------------------*)
FUNCTION_BLOCK FB_CwSim
VAR_INPUT
    xEnable      : BOOL;
    xTrig        : BOOL;
    nJob         : USINT;
END_VAR
VAR_OUTPUT
    xReady       : BOOL;
    xJobLoaded   : BOOL;
    xBusy        : BOOL;
END_VAR
VAR
    fbLoad       : TON;
    fbMark       : TON;
    rTrig        : R_TRIG;
    xRun         : BOOL;
END_VAR

// ----------------------- code -----------------------
xReady := xEnable;
fbLoad(IN := xEnable AND (nJob > 0), PT := T#300MS);
xJobLoaded := fbLoad.Q;

rTrig(CLK := xTrig AND xReady AND xJobLoaded);
IF rTrig.Q THEN
    xRun := TRUE;
END_IF
fbMark(IN := xRun, PT := T#2S);          // marking takes 2 s
IF fbMark.Q THEN
    xRun := FALSE;
END_IF
xBusy := xRun;


(*------------------------------------------------------------------------------
  PROGRAM  PRG_IO_In
------------------------------------------------------------------------------*)
PROGRAM PRG_IO_In
VAR
    fbSimInfeed, fbSimOutfeed, fbSimEjector, fbSimClamp, fbSimDiverter : FB_CylinderSim;
    fbSimCW : FB_CwSim;
END_VAR

// ----------------------- code -----------------------
IF GVL_Ctrl.xSim THEN
    //================ SIMULATION =================
    fbSimInfeed(  xValveWork := GVL_IO.stInfeed.xValveWork,   xValveHome := GVL_IO.stInfeed.xValveHome,
                  xSensWork => GVL_IO.stInfeed.xSensWork,     xSensHome => GVL_IO.stInfeed.xSensHome);
    fbSimOutfeed( xValveWork := GVL_IO.stOutfeed.xValveWork,  xValveHome := GVL_IO.stOutfeed.xValveHome,
                  xSensWork => GVL_IO.stOutfeed.xSensWork,    xSensHome => GVL_IO.stOutfeed.xSensHome);
    fbSimEjector( xValveWork := GVL_IO.stEjector.xValveWork,  xValveHome := GVL_IO.stEjector.xValveHome,
                  xSensWork => GVL_IO.stEjector.xSensWork,    xSensHome => GVL_IO.stEjector.xSensHome);
    fbSimClamp(   xValveWork := GVL_IO.stClamp.xValveWork,    xValveHome := GVL_IO.stClamp.xValveHome,
                  xSensWork => GVL_IO.stClamp.xSensWork,      xSensHome => GVL_IO.stClamp.xSensHome);
    fbSimDiverter(xValveWork := GVL_IO.stDiverter.xValveWork, xValveHome := GVL_IO.stDiverter.xValveHome,
                  xSensWork => GVL_IO.stDiverter.xSensWork,   xSensHome => GVL_IO.stDiverter.xSensHome);

    fbSimCW(xEnable := GVL_IO.xLaserEnable AND GVL_IO.xCW_STO,
            xTrig   := GVL_IO.xCW_Trig,
            nJob    := GVL_IO.nCW_Job,
            xReady  => GVL_IO.xCW_Lready,
            xJobLoaded => GVL_IO.xCW_JobLoaded,
            xBusy   => GVL_IO.xCW_MarkBusy);

    // part handling: part leaves the infeed barrier when infeed cylinder pushed it;
    // part appears at outfeed barrier after the ejector pushed a GOOD part (no bypass),
    // and disappears when the outfeed cylinder took it.
    IF GVL_IO.stInfeed.xSensWork THEN
        GVL_Ctrl.xSimPartIn := FALSE;
    END_IF
    IF GVL_IO.stEjector.xSensWork AND NOT GVL_IO.xBypassAS THEN
        GVL_Ctrl.xSimPartOut := TRUE;
    ELSIF GVL_IO.stOutfeed.xSensWork THEN
        GVL_Ctrl.xSimPartOut := FALSE;
    END_IF

    GVL_IO.xEStop          := GVL_Ctrl.xSimEStop;
    GVL_IO.xPressureOK     := GVL_Ctrl.xSimPressureOK;
    GVL_IO.xLS_Infeed      := GVL_Ctrl.xSimPartIn;
    GVL_IO.xLS_Outfeed     := GVL_Ctrl.xSimPartOut;
    GVL_IO.xServoInLatched := TRUE;   GVL_IO.xServoInAS  := FALSE;  GVL_IO.xServoInGS  := TRUE;
    GVL_IO.xServoOutLatched:= TRUE;   GVL_IO.xServoOutAS := FALSE;  GVL_IO.xServoOutGS := TRUE;
ELSE
    //================ REAL HARDWARE =================
    GVL_IO.xPressureOK     := GVL_HW.xMaintPressureOK;
    GVL_IO.xEStop          := GVL_HW.xEStopPressed;
    GVL_IO.xLS_Infeed      := GVL_HW.xLS_Infeed;
    GVL_IO.xLS_Outfeed     := GVL_HW.xLS_Outfeed;
    GVL_IO.xServoInLatched := GVL_HW.xServoIn_Latched;
    GVL_IO.xServoInAS      := GVL_HW.xServoIn_AS;
    GVL_IO.xServoInGS      := GVL_HW.xServoIn_GS;
    GVL_IO.xServoOutLatched:= GVL_HW.xServoOut_Latched;
    GVL_IO.xServoOutAS     := GVL_HW.xServoOut_AS;
    GVL_IO.xServoOutGS     := GVL_HW.xServoOut_GS;
    GVL_IO.xCW_Lready      := GVL_HW.xCW_Lready;
    GVL_IO.xCW_JobLoaded   := GVL_HW.xCW_JobLoaded;
    GVL_IO.xCW_MarkBusy    := GVL_HW.xCW_MarkBusy;

    GVL_IO.stInfeed.xSensWork   := GVL_HW.xSnsInfeed_AS;    GVL_IO.stInfeed.xSensHome   := GVL_HW.xSnsInfeed_GS;
    GVL_IO.stOutfeed.xSensWork  := GVL_HW.xSnsOutfeed_AS;   GVL_IO.stOutfeed.xSensHome  := GVL_HW.xSnsOutfeed_GS;
    GVL_IO.stEjector.xSensWork  := GVL_HW.xSnsEjector_AS;   GVL_IO.stEjector.xSensHome  := GVL_HW.xSnsEjector_GS;
    GVL_IO.stClamp.xSensWork    := GVL_HW.xSnsClamp_AS;     GVL_IO.stClamp.xSensHome    := GVL_HW.xSnsClamp_GS;
    GVL_IO.stDiverter.xSensWork := GVL_HW.xSnsDiverter_AS;  GVL_IO.stDiverter.xSensHome := GVL_HW.xSnsDiverter_GS;
END_IF


(*------------------------------------------------------------------------------
  PROGRAM  PRG_IO_Out
------------------------------------------------------------------------------*)
PROGRAM PRG_IO_Out
VAR
END_VAR

// ----------------------- code -----------------------
IF GVL_Ctrl.xSim THEN
    // simulation: keep every real output OFF
    GVL_HW.xMaintVent := FALSE;       GVL_HW.xLaserEnable := FALSE;
    GVL_HW.xCW_Trig := FALSE;         GVL_HW.xCW_STO := FALSE;
    GVL_HW.xCW_Job0 := FALSE;  GVL_HW.xCW_Job1 := FALSE;  GVL_HW.xCW_Job2 := FALSE;  GVL_HW.xCW_Job3 := FALSE;
    GVL_HW.xValveInfeed_AS := FALSE;   GVL_HW.xValveInfeed_GS := FALSE;
    GVL_HW.xValveOutfeed_AS := FALSE;  GVL_HW.xValveOutfeed_GS := FALSE;
    GVL_HW.xValveEjector_AS := FALSE;  GVL_HW.xValveEjector_GS := FALSE;
    GVL_HW.xValveClamp_AS := FALSE;    GVL_HW.xValveClamp_GS := FALSE;
    GVL_HW.xValveDiverter_AS := FALSE; GVL_HW.xValveDiverter_GS := FALSE;
    GVL_HW.xValveBlow_AS := FALSE;     GVL_HW.xValveBlow_GS := FALSE;
    GVL_HW.xValveBypass_AS := FALSE;   GVL_HW.xValveBypass_GS := FALSE;
ELSE
    GVL_HW.xMaintVent   := GVL_IO.xVent;
    GVL_HW.xLaserEnable := GVL_IO.xLaserEnable;
    GVL_HW.xCW_Trig     := GVL_IO.xCW_Trig;
    GVL_HW.xCW_STO      := GVL_IO.xCW_STO;
    GVL_HW.xCW_Job0     := (GVL_IO.nCW_Job AND 16#01) <> 0;
    GVL_HW.xCW_Job1     := (GVL_IO.nCW_Job AND 16#02) <> 0;
    GVL_HW.xCW_Job2     := (GVL_IO.nCW_Job AND 16#04) <> 0;
    GVL_HW.xCW_Job3     := (GVL_IO.nCW_Job AND 16#08) <> 0;

    GVL_HW.xValveInfeed_AS   := GVL_IO.stInfeed.xValveWork;    GVL_HW.xValveInfeed_GS   := GVL_IO.stInfeed.xValveHome;
    GVL_HW.xValveOutfeed_AS  := GVL_IO.stOutfeed.xValveWork;   GVL_HW.xValveOutfeed_GS  := GVL_IO.stOutfeed.xValveHome;
    GVL_HW.xValveEjector_AS  := GVL_IO.stEjector.xValveWork;   GVL_HW.xValveEjector_GS  := GVL_IO.stEjector.xValveHome;
    GVL_HW.xValveClamp_AS    := GVL_IO.stClamp.xValveWork;     GVL_HW.xValveClamp_GS    := GVL_IO.stClamp.xValveHome;
    GVL_HW.xValveDiverter_AS := GVL_IO.stDiverter.xValveWork;  GVL_HW.xValveDiverter_GS := GVL_IO.stDiverter.xValveHome;
    GVL_HW.xValveBlow_AS     := GVL_IO.xBlowAS;                GVL_HW.xValveBlow_GS     := GVL_IO.xBlowGS;
    GVL_HW.xValveBypass_AS   := GVL_IO.xBypassAS;              GVL_HW.xValveBypass_GS   := GVL_IO.xBypassGS;
END_IF


(*------------------------------------------------------------------------------
  PROGRAM  PRG_Seq        sequence + supervision
------------------------------------------------------------------------------*)
PROGRAM PRG_Seq
VAR
    eStep, ePrevStep : E_Step := E_Step.eInit;
    nFaultCode       : UINT;        // 1=E-stop 2=no air 3=cylinder fault 4=step timeout
    nPartCount       : UDINT;
    bRejectPart      : BOOL;
    xAutoRun         : BOOL;
    xReady           : BOOL;
    xEnableCyl       : BOOL;

    // cylinder commands (TRUE = working position AS, FALSE = home GS) - persistent
    xInfeedWork, xClampWork, xEjectWork, xDivertWork, xOutfeedWork : BOOL;
    // momentary commands (cleared every scan, set by the active step)
    xBlow, xBypass, xLaserOn, xTrig : BOOL;

    fbInfeed, fbOutfeed, fbEjector, fbClamp, fbDiverter : FB_Cylinder;
    rStart, rReset   : R_TRIG;
    fbPart           : TON;
    fbBlowTime       : TON;
    fbStepTO         : TON;
    tStepTimeout     : TIME := T#30S;
    tBlow            : TIME := T#1S;
    tPartDebounce    : TIME := T#200MS;
END_VAR

// ----------------------- code -----------------------
rStart(CLK := GVL_Ctrl.xStart);
rReset(CLK := GVL_Ctrl.xReset);
IF rStart.Q THEN xAutoRun := TRUE;  END_IF
IF GVL_Ctrl.xStop THEN xAutoRun := FALSE; END_IF

// momentary outputs default to OFF every scan
xBlow := FALSE;  xBypass := FALSE;  xLaserOn := FALSE;  xTrig := FALSE;

xReady := GVL_IO.xPressureOK AND NOT GVL_IO.xEStop
          AND GVL_IO.xServoInLatched AND GVL_IO.xServoOutLatched;
xEnableCyl := (eStep <> E_Step.eFault) AND NOT GVL_IO.xEStop AND GVL_IO.xPressureOK;

// ---- cylinders (called first so that feedback is current for the transitions)
fbInfeed(  xCmdWork := xInfeedWork,  xEnable := xEnableCyl, xReset := rReset.Q,
           xSensWork := GVL_IO.stInfeed.xSensWork,   xSensHome := GVL_IO.stInfeed.xSensHome,
           xValveWork => GVL_IO.stInfeed.xValveWork, xValveHome => GVL_IO.stInfeed.xValveHome);
fbOutfeed( xCmdWork := xOutfeedWork, xEnable := xEnableCyl, xReset := rReset.Q,
           xSensWork := GVL_IO.stOutfeed.xSensWork,   xSensHome := GVL_IO.stOutfeed.xSensHome,
           xValveWork => GVL_IO.stOutfeed.xValveWork, xValveHome => GVL_IO.stOutfeed.xValveHome);
fbEjector( xCmdWork := xEjectWork,   xEnable := xEnableCyl, xReset := rReset.Q,
           xSensWork := GVL_IO.stEjector.xSensWork,   xSensHome := GVL_IO.stEjector.xSensHome,
           xValveWork => GVL_IO.stEjector.xValveWork, xValveHome => GVL_IO.stEjector.xValveHome);
fbClamp(   xCmdWork := xClampWork,   xEnable := xEnableCyl, xReset := rReset.Q,
           xSensWork := GVL_IO.stClamp.xSensWork,   xSensHome := GVL_IO.stClamp.xSensHome,
           xValveWork => GVL_IO.stClamp.xValveWork, xValveHome => GVL_IO.stClamp.xValveHome);
fbDiverter(xCmdWork := xDivertWork,  xEnable := xEnableCyl, xReset := rReset.Q,
           xSensWork := GVL_IO.stDiverter.xSensWork,   xSensHome := GVL_IO.stDiverter.xSensHome,
           xValveWork => GVL_IO.stDiverter.xValveWork, xValveHome => GVL_IO.stDiverter.xValveHome);

// ---- step timeout (restarts whenever the step changes)
fbStepTO(IN := (eStep = ePrevStep) AND (eStep <> E_Step.eIdle) AND (eStep <> E_Step.eWaitPart)
               AND (eStep <> E_Step.eFault),
         PT := tStepTimeout);
ePrevStep := eStep;

// ---- supervision
IF eStep <> E_Step.eFault THEN
    IF GVL_IO.xEStop THEN
        nFaultCode := 1;  eStep := E_Step.eFault;
    ELSIF NOT GVL_IO.xPressureOK THEN
        nFaultCode := 2;  eStep := E_Step.eFault;
    ELSIF fbInfeed.xFault OR fbOutfeed.xFault OR fbEjector.xFault OR fbClamp.xFault OR fbDiverter.xFault THEN
        nFaultCode := 3;  eStep := E_Step.eFault;
    ELSIF fbStepTO.Q THEN
        nFaultCode := 4;  eStep := E_Step.eFault;
    END_IF
END_IF

// ---- sequence
fbPart(IN := GVL_IO.xLS_Infeed, PT := tPartDebounce);
fbBlowTime(IN := (eStep = E_Step.eBlowOff), PT := tBlow);

CASE eStep OF

    E_Step.eInit:
        xInfeedWork := FALSE;  xClampWork := FALSE;  xEjectWork := FALSE;
        xDivertWork := FALSE;  xOutfeedWork := FALSE;
        IF fbInfeed.xInHome AND fbOutfeed.xInHome AND fbEjector.xInHome
           AND fbClamp.xInHome AND fbDiverter.xInHome THEN
            eStep := E_Step.eIdle;
        END_IF

    E_Step.eIdle:
        IF xAutoRun AND xReady THEN
            eStep := E_Step.eWaitPart;
        END_IF

    E_Step.eWaitPart:
        IF NOT xAutoRun THEN
            eStep := E_Step.eIdle;
        ELSIF fbPart.Q THEN
            bRejectPart := GVL_Ctrl.xReject;      // latch quality decision for this part
            eStep := E_Step.eInfeedFwd;
        END_IF

    E_Step.eInfeedFwd:
        xInfeedWork := TRUE;
        IF fbInfeed.xInWork THEN eStep := E_Step.eClampFwd; END_IF

    E_Step.eClampFwd:
        xClampWork := TRUE;
        IF fbClamp.xInWork THEN eStep := E_Step.eInfeedBack; END_IF

    E_Step.eInfeedBack:
        xInfeedWork := FALSE;
        IF fbInfeed.xInHome THEN eStep := E_Step.eLoadJob; END_IF

    E_Step.eLoadJob:
        xLaserOn := TRUE;                          // LaserEnable + STO release + job select
        IF GVL_IO.xCW_JobLoaded AND GVL_IO.xCW_Lready THEN
            eStep := E_Step.eLaserRun;
        END_IF

    E_Step.eLaserRun:
        xLaserOn := TRUE;  xTrig := TRUE;
        IF GVL_IO.xCW_MarkBusy THEN eStep := E_Step.eLaserWait; END_IF

    E_Step.eLaserWait:
        xLaserOn := TRUE;  xTrig := TRUE;
        IF NOT GVL_IO.xCW_MarkBusy THEN eStep := E_Step.eBlowOff; END_IF

    E_Step.eBlowOff:
        xBlow := TRUE;
        IF fbBlowTime.Q THEN eStep := E_Step.eClampBack; END_IF

    E_Step.eClampBack:
        xClampWork := FALSE;
        IF fbClamp.xInHome THEN eStep := E_Step.eDiverter; END_IF

    E_Step.eDiverter:
        xDivertWork := bRejectPart;                // work = reject path, home = good path
        IF (bRejectPart AND fbDiverter.xInWork) OR (NOT bRejectPart AND fbDiverter.xInHome) THEN
            eStep := E_Step.eEject;
        END_IF

    E_Step.eEject:
        xEjectWork := TRUE;
        xBypass := bRejectPart;                    // bypass valve only for rejects
        IF fbEjector.xInWork THEN eStep := E_Step.eEjectBack; END_IF

    E_Step.eEjectBack:
        xEjectWork := FALSE;
        xBypass := bRejectPart;
        IF fbEjector.xInHome THEN
            IF bRejectPart THEN
                eStep := E_Step.eCycleEnd;         // reject left through bypass
            ELSE
                eStep := E_Step.eOutfeedWait;
            END_IF
        END_IF

    E_Step.eOutfeedWait:
        IF GVL_IO.xLS_Outfeed THEN eStep := E_Step.eOutfeed; END_IF

    E_Step.eOutfeed:
        xOutfeedWork := TRUE;
        IF fbOutfeed.xInWork THEN eStep := E_Step.eOutfeedBack; END_IF

    E_Step.eOutfeedBack:
        xOutfeedWork := FALSE;
        IF fbOutfeed.xInHome THEN eStep := E_Step.eCycleEnd; END_IF

    E_Step.eCycleEnd:
        xDivertWork := FALSE;
        IF fbDiverter.xInHome THEN
            nPartCount := nPartCount + 1;
            eStep := E_Step.eIdle;
        END_IF

    E_Step.eFault:
        xAutoRun := FALSE;
        IF rReset.Q AND NOT GVL_IO.xEStop AND GVL_IO.xPressureOK THEN
            nFaultCode := 0;
            eStep := E_Step.eInit;
        END_IF

END_CASE

// ---- write logic outputs
GVL_IO.xVent        := GVL_IO.xEStop;                       // vent maintenance unit on E-stop
GVL_IO.xLaserEnable := xLaserOn AND xEnableCyl;
GVL_IO.xCW_STO      := xLaserOn AND xEnableCyl;             // ASSUMPTION: TRUE = STO released
GVL_IO.xCW_Trig     := xTrig    AND xEnableCyl;
IF xLaserOn THEN GVL_IO.nCW_Job := GVL_Ctrl.nJobNo; ELSE GVL_IO.nCW_Job := 0; END_IF
GVL_IO.xBlowAS      := xBlow   AND xEnableCyl;
GVL_IO.xBlowGS      := xEnableCyl AND NOT xBlow;
GVL_IO.xBypassAS    := xBypass AND xEnableCyl;
GVL_IO.xBypassGS    := xEnableCyl AND NOT xBypass;


(*------------------------------------------------------------------------------
  PROGRAM  MAIN            (call order matters)
------------------------------------------------------------------------------*)
PROGRAM MAIN
VAR
END_VAR

// ----------------------- code -----------------------
PRG_IO_In();
PRG_Seq();
PRG_IO_Out();
