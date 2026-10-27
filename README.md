# LaserStation-TwinCAT
TwinCAT Beckhoff Laser Station Project 

Created by Ranita Majumder and Hirak Chatterjee as part of SUAS Premier Program.
Create the project in TcXaeShell
Start TcXaeShell (run as administrator is not required for engineering).
File → New → Project → TwinCAT Projects → TwinCAT XAE Project (XML format). Name: LaserStation.
In the Solution Explorer click SYSTEM → in the toolbar choose the target <Local> (offline: no real device needed).
Right-click PLC → Add New Item… → Standard PLC Project, name PlcLaser. This creates MAIN, GVLs, DUTs, POUs.
Add objects (right-click the folder → Add):
DUTs: ST_CylIO (Structure), E_Step (Enumeration)
GVLs: GVL_HW, GVL_IO, GVL_Ctrl (Global Variable List)
POUs: FB_Cylinder, FB_CylinderSim, FB_CwSim (Function Block, ST) and PRG_IO_In, PRG_IO_Out, PRG_Seq (Program, ST)
MAIN already exists (Program, ST) – replace its content.
Paste the code blocks from LaserStation_ST_Code.st into the objects (declaration part above, code part below the separator line of the editor).
Build → Build Solution (F7). Expect 0 errors. Warnings about unlinked AT %I* variables are normal while no hardware is linked.
