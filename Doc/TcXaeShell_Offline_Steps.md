# TwinCAT 3 (TcXaeShell) – building and testing the project offline

## 0. What the EPLAN contains
The PDF (90 pages, Jenoptik "Funktionsmuster LCLW") is the electrical plan of a laser station. It has **no written process description**, so the sequence in `PRG_Seq` is my interpretation of the I/O. Please compare it with your assignment text and adjust.

Controller: Beckhoff C6015 IPC, EtherCAT. I/O used by the PLC:

| EtherCAT device (BMK) | Type | Signals (EPLAN address) |
|---|---|---|
| +MP-6K1 / 6K10 / 6K20 | EK1100 / EL1809 / EL2809 | E0.0 pressure switch, E0.1 E-stop pressed; A0.0 vent, A0.1 LaserEnable |
| +LS-7K1 / 7K10 / 7K20 | EK1100 / EL1809 / EL2809 | E50.0 Lready, E50.1 Jobloaded, E50.2 MarkInProgress; A50.0 Ltrig, A50.1-A50.4 Job bits, A50.5 STO |
| +MS-9K1 | EP1018-0001 | E1050.0-.5 sensors Ejector AS/GS, Clamp AS/GS, Diverter AS/GS |
| +MS-9K2 | EP1018-0001 | E1051.0-.3 sensors Infeed AS/GS, Outfeed AS/GS |
| +MS-9K3 | EP1018-0001 | E1052.0 LS infeed, .1-.3 servo-in latched/AS/GS, .4 LS outfeed, .5-.7 servo-out latched/AS/GS |
| +MS-10K1 | EP2028-0001 | A1050.0-.5 valves Ejector, Clamp, Diverter (AS/GS each) |
| +MS-10K2 | EP2028-0001 | A1051.0-.3 valves Infeed, Outfeed; .4/.5 Blow-off; .6/.7 Eject-bypass |

AS = Arbeitsstellung (working position), GS = Grundstellung (home position).
The servo drives (AX5206, 11M1/11M2) are not used by this PLC code; only their latched/end-position signals are read.

## 1. Assumptions you must verify
- E-stop input `E0.1` is TRUE when the E-stop is pressed (name "Not-Halt betätigt").
- Light barriers are TRUE when a part is present; pressure switch is TRUE when air is OK.
- `A0.0` "Entlüften" = TRUE vents the maintenance unit (done on E-stop).
- `A50.5` "STO": TRUE = STO released (laser allowed). If your drive uses the opposite logic, invert it in `GVL_IO`/`PRG_IO_Out`.
- Blow-off and bypass use AS valve for "on" and GS = NOT AS (double-solenoid pair).
- Process: infeed → clamp → laser marking (job select, Ltrig, wait MarkInProgress) → blow-off → release → diverter (reject via bypass) → eject → outfeed.

## 2. Create the project in TcXaeShell
1. Start **TcXaeShell** (run as administrator is not required for engineering).
2. **File → New → Project → TwinCAT Projects → TwinCAT XAE Project (XML format)**. Name: `LaserStation`.
3. In the Solution Explorer click **SYSTEM** → in the toolbar choose the target **`<Local>`** (offline: no real device needed).
4. Right-click **PLC → Add New Item… → Standard PLC Project**, name `PlcLaser`. This creates `MAIN`, `GVLs`, `DUTs`, `POUs`.
5. Add objects (right-click the folder → **Add**):
   - **DUTs**: `ST_CylIO` (Structure), `E_Step` (Enumeration)
   - **GVLs**: `GVL_HW`, `GVL_IO`, `GVL_Ctrl` (Global Variable List)
   - **POUs**: `FB_Cylinder`, `FB_CylinderSim`, `FB_CwSim` (Function Block, ST) and `PRG_IO_In`, `PRG_IO_Out`, `PRG_Seq` (Program, ST)
   - `MAIN` already exists (Program, ST) – replace its content.
6. Paste the code blocks from `LaserStation_ST_Code.st` into the objects (declaration part above, code part below the separator line of the editor).
7. **Build → Build Solution** (F7). Expect 0 errors. Warnings about unlinked `AT %I*` variables are normal while no hardware is linked.

## 3. Hardware tree (optional offline, needed for real machine)
1. **I/O → Devices → right-click → Add New Item… → EtherCAT → EtherCAT Master**.
2. Under the master add the boxes with **Add New Item** (names = BMK from EPLAN):
   - `EK1100` (6K1) → `EL1809` (6K10), `EL2809` (6K20)
   - `EK1100` (7K1) → `EL1809` (7K10), `EL2809` (7K20)
   - `EP1018-0001` ×3 (9K1, 9K2, 9K3), `EP2028-0001` ×2 (10K1, 10K2)
   - The CU1128 switch and AX5206 are not needed for the PLC logic; add them only if you want the full topology.
3. **Link the PLC variables to the I/O channels.** This connects the `AT %I*` / `AT %Q*` variables of `GVL_HW` to the physical terminal channels, so the PLC reads the real inputs and drives the real outputs. Do it as follows:
   1. **Build the PLC project first** (F7). The variables only appear in the link dialog after a successful build.
   2. In the Solution Explorer expand **I/O → Devices → Device 1 (EtherCAT) → Box 1 (EK1100) → Term 2 (EL1809)** and open **Channel 1**. Every channel has a sub-entry **Input** (for input terminals) or **Output** (for output terminals). The PLC side is under **PLC → PlcLaser → PlcLaser Instance → PlcTask Inputs / PlcTask Outputs**, where all `GVL_HW` variables are listed.
   3. Click the channel's **Input** entry (e.g. EL1809 +MP-6K10 → *Channel 1 → Input*), right-click it and choose **Change Link…**.
   4. The dialog *Attach Variable* lists only the PLC variables that have the right direction and type (a BOOL input channel only shows `%I*` BOOL variables). Select `PlcLaser Instance → PlcTask Inputs → GVL_HW.xMaintPressureOK` and confirm with **OK**.
   5. The channel now shows a small arrow symbol and the *Linked to* field names the PLC variable. If the symbol is missing, the link was not created.
   6. Repeat for every used channel. The channel number is the EPLAN bit number **+ 1** (EPLAN `E0.0` = DI0 = *Channel 1*, `E0.1` = DI1 = *Channel 2*, …, `A1051.4` = DO4 = *Channel 5*). Unused channels (e.g. EL1809 channels 3-16) stay unlinked.
   7. In the *Attach Variable* dialog you can tick **Multiple** to select several consecutive variables at once and link a whole block of channels in one go. Check the result afterwards, because the order of the list follows the variable declaration.
   8. Finally use **TwinCAT → Activate Configuration**. With real hardware a wrongly linked channel is the most common error, so test each input by switching the sensor by hand and watching the variable in the online view.

   Link table (terminal → channel → variable):

   | Terminal (BMK) | Channel | EPLAN | Variable in `GVL_HW` |
   |---|---|---|---|
   | EL1809 +MP-6K10 | 1 / 2 | E0.0 / E0.1 | `xMaintPressureOK`, `xEStopPressed` |
   | EL2809 +MP-6K20 | 1 / 2 | A0.0 / A0.1 | `xMaintVent`, `xLaserEnable` |
   | EL1809 +LS-7K10 | 1 / 2 / 3 | E50.0 / .1 / .2 | `xCW_Lready`, `xCW_JobLoaded`, `xCW_MarkBusy` |
   | EL2809 +LS-7K20 | 1 / 2 / 3 / 4 / 5 / 6 | A50.0 … A50.5 | `xCW_Trig`, `xCW_Job0`, `xCW_Job1`, `xCW_Job2`, `xCW_Job3`, `xCW_STO` |
   | EP1018 +MS-9K1 | 1 … 6 | E1050.0 … .5 | `xSnsEjector_AS/GS`, `xSnsClamp_AS/GS`, `xSnsDiverter_AS/GS` |
   | EP1018 +MS-9K2 | 1 … 4 | E1051.0 … .3 | `xSnsInfeed_AS/GS`, `xSnsOutfeed_AS/GS` |
   | EP1018 +MS-9K3 | 1 … 8 | E1052.0 … .7 | `xLS_Infeed`, `xServoIn_Latched/AS/GS`, `xLS_Outfeed`, `xServoOut_Latched/AS/GS` |
   | EP2028 +MS-10K1 | 1 … 6 | A1050.0 … .5 | `xValveEjector_AS/GS`, `xValveClamp_AS/GS`, `xValveDiverter_AS/GS` |
   | EP2028 +MS-10K2 | 1 … 8 | A1051.0 … .7 | `xValveInfeed_AS/GS`, `xValveOutfeed_AS/GS`, `xValveBlow_AS/GS`, `xValveBypass_AS/GS` |

   The same order is written as a comment behind each variable in `GVL_HW` (e.g. `// E1050.2`), so you can also link by reading the comment.
4. In offline/simulation mode you can skip step 3 completely, because `GVL_Ctrl.xSim = TRUE` bypasses `GVL_HW`.

## 4. Run the simulation on your PC
Offline "simulation" here means the PLC runs on the **local TwinCAT runtime** (installed together with XAE on an x64 PC) with the built-in simulation FBs.

1. **Disable the EtherCAT master before you activate (mandatory without hardware).** In the Solution Explorer open **I/O → Devices**, right-click **Device 1 (EtherCAT)** → **Disable**. The device and all its boxes turn grey. Without this step step 3 fails with the errors listed in section 4.1. Alternatively delete the EtherCAT device from the tree; the PLC code does not need it in simulation (`GVL_Ctrl.xSim = TRUE`).
2. **SYSTEM → License → Order Information (Runtime) → 7 Days Trial License** (type the shown validation code). Needed once per 7 days for the runtime.
3. **TwinCAT → Activate Configuration** (Ctrl+Shift+F4) → OK → *Restart TwinCAT System in Run Mode* → OK. Before you do this, check that the target (toolbar) is **`<Local>`** and that the EtherCAT device is shown as disabled (step 1). If the output window shows the errors from section 4.1, the device was not disabled.
4. Select the PLC project → **Login** (Alt+F8) → **Start** (F5).
5. Open `PRG_Seq`, `GVL_Ctrl`, `GVL_IO` and write values in the online view (double-click the *Prepared value*, then Ctrl+F7 to write):
   1. `GVL_Ctrl.xSimPartIn := TRUE` (part at infeed)
   2. `GVL_Ctrl.xStart := TRUE` (then back to FALSE) – the sequence runs through all steps; watch `PRG_Seq.eStep`.
   3. Optional tests: `GVL_Ctrl.xReject := TRUE` before a cycle (diverter + bypass path), `GVL_Ctrl.xSimEStop := TRUE` (fault code 1), `GVL_Ctrl.xSimPressureOK := FALSE` (fault 2). Acknowledge faults with a pulse on `GVL_Ctrl.xReset`.
6. For real hardware later: set `GVL_Ctrl.xSim := FALSE` (initial value), link the I/O (section 3), activate with the real EtherCAT master enabled.

### 4.1 Error: "Failed to connect to network adapter" / ADS error 1823 on activation

Typical output when activating with an EtherCAT master but without hardware:

- `EtherCAT Master (Adapter): Failed to connect to network adapter!`
- `PREOP to SAFEOP of 'EtherCAT Master (Adapter)' failed - 'request is aborted' 0x9811071F` (warning)
- `Sending ams command >> Init12\IO: Set State TComObj SAFEOP … AdsError: 1823 (0x71f, ADS ERROR: device aborted the action) << failed!`

**Cause.** The first message is the real one. The EtherCAT master in the I/O tree tries to open a network adapter with the TwinCAT real-time Ethernet driver and to find the terminals. On a PC without an EtherCAT line (or without the driver installed on the adapter) this fails. The other two messages are only the consequence: the master cannot go from PREOP to SAFEOP, so the whole system service aborts with ADS error 1823.

**Fix for offline simulation (no hardware):**
1. Stop TwinCAT if it is half-started: right-click the TwinCAT icon in the Windows tray → **System → Config** (or Stop).
2. In the Solution Explorer: **I/O → Devices → Device 1 (EtherCAT)** → right-click → **Disable**. (Or delete the device.)
3. Make sure the PLC project is built (F7) with 0 errors.
4. **TwinCAT → Activate Configuration** again → OK → *Restart TwinCAT System in Run Mode* → OK. The errors must be gone and the tray icon turns **green**.
5. **Login** and **Start** the PLC (step 4). In simulation `GVL_HW` is not used, so the missing master does not matter.

**Only if you really have an EtherCAT line connected:**
1. Install the real-time driver: **TwinCAT → Show Realtime Ethernet Compatible Devices… → Compatible devices → select the adapter → Install**. (Use a separate Intel/Realtek NIC that is *not* your normal network connection; it may not work in a virtual machine.)
2. Select **Device 1 (EtherCAT) → Adapter** tab → **Search…** → choose the installed adapter → OK.
3. In the same device use **Scan** (right-click the device → *Scan*) or re-check that the boxes in the tree match the real hardware, then activate again.

If the runtime will not start (error about real-time / Hyper-V), disable Windows *Memory Integrity / Core isolation* and Hyper-V, or build only (step 2.7) and review the code without running.

## 5. Fault codes (`PRG_Seq.nFaultCode`)
1 = E-stop, 2 = air pressure missing, 3 = cylinder fault (travel-time or sensor error), 4 = step timeout (30 s).
