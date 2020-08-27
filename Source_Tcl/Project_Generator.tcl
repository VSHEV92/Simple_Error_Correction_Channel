# ------- Tcl ������ ��� ��������������� �������� ������� ---------- #
set Project_Name Vivado_Project

# ������� ������ ������, ���� �� ���������� 
close_project -quiet
if { [file exists ../$Project_Name] != 0 } { 
	file delete -force ../$Project_Name
	puts "Delete old Project"
}

# ������� ����� ������
create_project $Project_Name ../$Project_Name -part xcku5p-ffvb676-2-e
set_property board_part xilinx.com:kcu116:part0:1.4 [current_project]

# ��������� �������� ����� � �������
add_files [glob ../Source_Verilog/*.v]
add_files [glob ../Source_Verilog/*.vh]
add_files [glob ../Source_Verilog/Frame_Sync/*.v]
add_files [glob ../Source_Verilog/BCH_Codeing/*.v]
add_files [glob ../Source_Verilog/BCH_Codeing/*.vh]
add_files [glob ../Source_Verilog/Interleaving/*.v]

# ��������� ����� ������ � �������
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 [glob ../Source_Tests/*.v]



