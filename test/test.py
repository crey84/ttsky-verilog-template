import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_project(dut):
    cocotb.log.info("Start")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    cocotb.log.info("Reset")
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    for _ in range(20):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(20):
        await RisingEdge(dut.clk)

    # Test 1: after reset dice result should be 1
    result = dut.uo_out.value.integer & 7
    assert result == 1, "FAIL Test 1: Expected 1 after reset, got " + str(result)
    cocotb.log.info("PASS Test 1: Reset gives dice_val = " + str(result))

    # Test 2: press and release, result should be 1-6
    dut.ui_in.value = 1
    for _ in range(66000):
        await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    for _ in range(66000):
        await RisingEdge(dut.clk)

    result = dut.uo_out.value.integer & 7
    assert 1 <= result <= 6, "FAIL Test 2: dice_val out of range, got " + str(result)
    cocotb.log.info("PASS Test 2: After roll, dice_val = " + str(result))

    # Test 3: result holds stable between rolls
    stable = result
    for _ in range(100):
        await RisingEdge(dut.clk)
    result = dut.uo_out.value.integer & 7
    assert result == stable, "FAIL Test 3: Result changed! Was " + str(stable) + " now " + str(result)
    cocotb.log.info("PASS Test 3: Result stable " + str(result))

    cocotb.log.info("ALL TESTS PASSED")