# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
  dut._log.info("Start")
  
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  
  # Cheks if the '+' operation cycle is working
  dut._log.info("Non Instr Test")
  loops = 20
  for i in range(loops):
    await ClockCycles(dut.clk, 1)
    # fetch instr cycle
    dut._log.info(f"PC = {int(dut.uo_out.value)}")
    dut._log.info(f"Data = {int(dut.uio_out.value)}")
    dut._log.info(f"DataEn = {dut.uio_oe.value}")
    #assert dut.uo_out.value == i
    dut.uio_in.value = 43 # invalid instr
    await ClockCycles(dut.clk, 1)
