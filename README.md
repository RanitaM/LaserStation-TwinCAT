# LaserStation-TwinCAT
TwinCAT Beckhoff Laser Station Project 

Created by Ranita Majumder and Hirak Chatterjee as part of SUAS Premier Program.

Create the project in TcXaeShell
1. Start TcXaeShell (run as administrator is not required for engineering).
2. File → New → Project → TwinCAT Projects → TwinCAT XAE Project (XML format). Name: LaserStation.
3. In the Solution Explorer click SYSTEM → in the toolbar choose the target <Local> (offline: no real device needed).
4. Right-click PLC → Add New Item… → Standard PLC Project, name PlcLaser. This creates MAIN, GVLs, DUTs, POUs.
5. Add objects (right-click the folder → Add):
6. DUTs: ST_CylIO (Structure), E_Step (Enumeration)
7. GVLs: GVL_HW, GVL_IO, GVL_Ctrl (Global Variable List)
8. POUs: FB_Cylinder, FB_CylinderSim, FB_CwSim (Function Block, ST) and PRG_IO_In, PRG_IO_Out, PRG_Seq (Program, ST)
9. Build → Build Solution (F7). Expect 0 errors. Warnings about unlinked AT %I* variables are normal while no hardware is linked.
