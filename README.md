# Simple 8-Bit VHDL Computer System

This project implements a basic computer system using VHDL. The system consists of multiple components working together, including the CPU, ALU, memory units, and control logic.

## Components
The project includes the following VHDL files:

- **ALU.vhd**: Implements arithmetic and logic operations.
- **computer.vhd**: Top-level module that integrates all components.
- **control_unit.vhd**: Generates control signals for execution.
- **cpu.vhd**: Central processing unit integrating ALU, control, and data path.
- **data_memeory.vhd**: Stores data required during execution.
- **data_path.vhd**: Manages the flow of data between units.
- **memory.vhd**: Additional memory handling logic.
- **output_ports.vhd**: Handles external output communication.
- **program_memory.vhd**: Stores instruction sequences for execution.
- **Testbench (tb_computer.vhd)**: Simulates the system for verification.

## How to Use
1. **Simulation**: Use a VHDL simulator (e.g., ModelSim, GHDL, or Vivado) to compile and run `tb_computer.vhd`.
2. **Synthesis (Optional)**: Load the files into an FPGA tool like Xilinx Vivado or Intel Quartus for implementation.
3. **Testing**: Review waveform outputs to validate the system's behavior.
