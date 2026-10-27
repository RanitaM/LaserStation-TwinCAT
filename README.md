# LaserStation-TwinCAT
TwinCAT Beckhoff Laser Station Project 
Create the project in TcXaeShell
1. Start **TcXaeShell** (run as administrator is not required for engineering).
2. **File ÔåÆ New ÔåÆ Project ÔåÆ TwinCAT Projects ÔåÆ TwinCAT XAE Project (XML format)**. Name: `LaserStation`.
3. In the Solution Explorer click **SYSTEM** ÔåÆ in the toolbar choose the target **`<Local>`** (offline: no real device needed).
4. Right-click **PLC ÔåÆ Add New ItemÔÇª ÔåÆ Standard PLC Project**, name `PlcLaser`. This creates `MAIN`, `GVLs`, `DUTs`, `POUs`.
5. Add objects (right-click the folder ÔåÆ **Add**):
   - **DUTs**: `ST_CylIO` (Structure), `E_Step` (Enumeration)
   - **GVLs**: `GVL_HW`, `GVL_IO`, `GVL_Ctrl` (Global Variable List)
   - **POUs**: `FB_Cylinder`, `FB_CylinderSim`, `FB_CwSim` (Function Block, ST) and `PRG_IO_In`, `PRG_IO_Out`, `PRG_Seq` (Program, ST)
   - `MAIN` already exists (Program, ST) ÔÇô replace its content.
6. Paste the code blocks from `LaserStation_ST_Code.st` into the objects (declaration part above, code part below the separator line of the editor).
7. **Build ÔåÆ Build Solution** (F7). Expect 0 errors. Warnings about unlinked `AT %I*` variables are normal while no hardware is linked.
