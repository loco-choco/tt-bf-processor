# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

#def simulate_instr(instr: str, dut):
#    dut._log.info(f"instr = '{instr}'")
#    intr_ascii = ord(instr)
#    if instr is '+':

def load_code(stack, code: str):
    for i in range(len(code)):
        stack[i] = ord(code[i])

@cocotb.test()
async def test_project(dut):
  dut._log.info("Start")
  
  clock = Clock(dut.clk, 0.05, units="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 0
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  dut.ena.value = 1
  #await FallingEdge(dut.clk) # start execution
  # brainf*ck circuit simulation
  pc_sim = 0
  reg_sim = 0
  stack_sim = [0 for i in range(256)]
  # brainf*ck interpreter
  pc_intr = 0
  reg_intr = 0
  instr_intr = ' '
  depth_intr = 0
  stack_intr = [0 for i in range(256)]

  # load code for both the interpreter and simulation
  code = "<++[-]"
  load_code(stack_sim, code)
  load_code(stack_intr, code)

  await FallingEdge(dut.clk) # go from reset state

  dut._log.info("Running Code")
  while pc_sim < len(code) or pc_intr < len(code):
    # fetch instr cycle 1.1 - writing addr
    # simulation --
    await FallingEdge(dut.clk) # go to reading data cycle
    assert int(dut.uio_oe.value) == 255 and dut.uo_out.value[-1] == 1, "write should be enabled!" #ff, write enabled
    assert dut.uo_out.value[-2] == 1, "addr should be enabled!"
    assert dut.uo_out.value[-3] == 1, "instr_addr should be enabled!"
    pc_sim = int(dut.uio_out.value)
    # interpreter --
    dut._log.info(f"\tPC: {pc_sim}({pc_intr})")
    assert pc_sim == pc_intr, "simulation doesnt match interpreter!"
    # fetch instr cycle 1.2 - reading addr
    # simulation --
    await FallingEdge(dut.clk) # go to reading data cycle
    assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" #00, write disabled
    assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
    assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
    dut.uio_in.value = stack_sim[pc_sim]
    # interpreter --
    instr_intr = stack_intr[pc_intr]
    dut._log.info(f"\tInstr: {chr(instr_intr)}({chr(stack_sim[pc_sim])})")
    assert stack_sim[pc_sim] == instr_intr, "simulation doesnt match interpreter!"
    # exec cycle
    await FallingEdge(dut.clk) # go to instr cycle

    if depth_intr != 0:
        dut._log.info("\t\tlooping...")
    if (instr_intr == ord('+') or instr_intr == ord('-')) and depth_intr == 0:
        # fetch data cycle 1.1 - writing addr
        await FallingEdge(dut.clk) # go to reading data cycle
        # simulation --
        assert int(dut.uio_oe.value) == 255 and dut.uo_out.value[-1] == 1, "write should be enabled!" #ff, write enabled
        assert dut.uo_out.value[-2] == 1, "addr should be enabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        reg_sim = int(dut.uio_out.value)
        # interpreter --
        dut._log.info(f"\t\tAddr: {reg_sim}({reg_intr}) -> OUT")
        assert reg_sim == reg_intr, "simulation doesnt match interpreter!"
        # fetch data cycle 1.2 - reading data 
        await FallingEdge(dut.clk) # go to temp++/-- cycle
        # simulation --
        assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" #00, write disabled
        assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        dut.uio_in.value = stack_sim[reg_sim]
        # interpreter --
        dut._log.info(f"\t\tData: {stack_sim[reg_sim]}({stack_intr[reg_intr]}) -> IN")
        assert stack_sim[reg_sim] == stack_intr[reg_intr], "simulation doesnt match interpreter!"
        # temp++/-- cycle
        await FallingEdge(dut.clk) # go to write back cycle
        # simulation --
        assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" # 00, write disabled
        assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        # interpreter --
        if instr_intr == ord('+'): # +
            stack_intr[reg_intr] = (stack_intr[reg_intr] + 1) % 256
        else: # -
            stack_intr[reg_intr] = stack_intr[reg_intr] - 1 
            if stack_intr[reg_intr] < 0:
                stack_intr[reg_intr] = 255
        # write back cycle 3.1 - writing addr
        await FallingEdge(dut.clk) # go to writing data cycle
        # simulation --
        assert int(dut.uio_oe.value) == 255 and dut.uo_out.value[-1] == 1, "write should be enabled!" #ff, write enabled
        assert dut.uo_out.value[-2] == 1, "addr should be enabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        reg_sim = int(dut.uio_out.value)
        # interpreter --
        dut._log.info(f"\t\tAddr: {reg_sim}({reg_intr}) -> OUT")
        assert reg_sim == reg_intr, "simulation doesnt match interpreter!"
        # write back cycle
        await FallingEdge(dut.clk) # go to pc++ cycle
        # simulation --
        assert int(dut.uio_oe.value) == 255 and dut.uo_out.value[-1] == 1, "write should be enabled!" #ff, write enabled
        assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        stack_sim[reg_sim] = int(dut.uio_out.value)
        # interpreter --
        dut._log.info(f"\t\tData: {stack_sim[reg_sim]}({stack_intr[reg_intr]}) -> OUT")
        assert stack_sim[reg_sim] == stack_intr[reg_intr] , "simulation doesnt match interpreter!"

    elif (instr_intr == ord('>') or instr_intr == ord('<')):
        # reg++/-- cycle
        await FallingEdge(dut.clk) # go to pc++ cycle
        # simulation --
        assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" #00, write disabled
        assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        # interpreter --
        if instr_intr == ord('>'): # >
            reg_intr = (reg_intr + 1) % 256
        else: # <
            reg_intr = reg_intr - 1
            if reg_intr < 0:
               reg_intr = 255

        dut._log.info(f"\t\tReg = {reg_intr}")
    elif instr_intr == ord('[') or instr_intr == ord(']'):
        temp = None
        if depth_intr == 0: # fetch data cycle 1.1 - writing addr
            await FallingEdge(dut.clk) # go to reading data cycle
            # simulation --
            assert int(dut.uio_oe.value) == 255 and dut.uo_out.value[-1] == 1, "write should be enabled!" #ff, write disabled
            assert dut.uo_out.value[-2] == 1, "addr should be enabled!"
            assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
            reg_sim = int(dut.uio_out.value)
            # interpreter --
            dut._log.info(f"\t\tAddr: {reg_sim}({reg_intr}) -> OUT")
            assert reg_sim == reg_intr, "simulation doesnt match interpreter!"
            # fetch data cycle 1.2 - reading data
            await FallingEdge(dut.clk) # go to depth++/--
            # simulation --
            assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" #00, write disabled
            assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
            assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
            dut.uio_in.value = stack_sim[reg_sim]
            # interpreter --
            temp = stack_intr[reg_intr]
            dut._log.info(f"\t\tData: {stack_sim[reg_sim]}({stack_intr[reg_intr]}) -> IN")
            assert stack_sim[reg_sim] == stack_intr[reg_intr], "simulation doesnt match interpreter!"
        # depth ++/-- cycle
        await FallingEdge(dut.clk) # go to pc++ cycle
        # simulation --
        assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" #00, write disabled
        assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
        assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
        # interpreter --
        if instr_intr == ord('[') and (depth_intr != 0 or temp == 0): # >
            depth_intr = (depth_intr + 1) % 256
        elif instr_intr == ord(']') and (depth_intr != 0 or temp != 0):
            depth_intr = depth_intr - 1
            if depth_intr < 0:
               depth_intr = 255

        dut._log.info(f"\t\tDepth = {depth_intr}")
    #else:
        #await FallingEdge(dut.clk) # go to pc++ cycle
    


    # pc++ cycle
    await FallingEdge(dut.clk) # go to fetch cycle
    # simulation -- 
    assert int(dut.uio_oe.value) == 0 and dut.uo_out.value[-1] == 0, "write should be disabled!" #00, write disabled
    assert dut.uo_out.value[-2] == 0, "addr should be disabled!"
    assert dut.uo_out.value[-3] == 0, "instr_addr should be disabled!"
    # interpreter --
    # pc++ with overflow and underflow
    if depth_intr <= 127:
        dut._log.info("\t\t\tPC++")
        pc_intr = (pc_intr + 1) % 256
    else:
        dut._log.info("\t\t\tPC--")
        pc_intr = pc_intr - 1
        if pc_intr < 0:
            pc_intr = 255


  
