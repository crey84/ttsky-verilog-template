import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_project(dut):
    cocotb.log.info("Start")

    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    cocotb.log.info("Reset")
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Test 1: after reset, dice result should be 1
    result = dut.uo_out.value & 0b00000111
    assert result == 1, f"FAIL Test 1: Expected 1 after reset, got {result}"
    cocotb.log.info(f"PASS Test 1: Reset gives dice_val = {result}")

    # Test 2: simulate button press and release (short version - no full debounce wait)
    # Hold button for debounce threshold cycles
    dut.ui_in.value = 1
    for _ in range(66000):
        await RisingEdge(dut.clk)

    dut.ui_in.value = 0
    for _ in range(66000):
        await RisingEdge(dut.clk)

    result = dut.uo_out.value & 0b00000111
    assert 1 <= result <= 6, f"FAIL Test 2: dice_val {result} out of range 1-6"
    cocotb.log.info(f"PASS Test 2: After roll, dice_val = {result} (valid 1-6)")

    # Test 3: result holds stable (no button press)
    stable = result
    for _ in range(100):
        await RisingEdge(dut.clk)
    result = dut.uo_out.value & 0b00000111
    assert result == stable, f"FAIL Test 3: Result changed without button press!"
    cocotb.log.info(f"PASS Test 3: Result stable between rolls ({result})")

    cocotb.log.info("ALL TESTS PASSED")