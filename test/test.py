import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def safe_read(signal):
    try:
        return signal.value.to_unsigned() & 7
    except ValueError:
        return None  # still X/unknown

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
    for _ in range(100):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # Wait for outputs to settle out of X state
    for _ in range(200):
        await RisingEdge(dut.clk)
        result = safe_read(dut.uo_out)
        if result is not None:
            break

    # Test 1: after reset dice result should be 1
    result = safe_read(dut.uo_out)
    assert result is not None, "FAIL Test 1: Output still X after reset"
    assert result == 1, "FAIL Test 1: Expected 1 after reset, got " + str(result)
    cocotb.log.info("PASS Test 1: Reset gives dice_val = " + str(result))

    # Test 2: press and release, result should be 1-6
    dut.ui_in.value = 1
    for _ in range(66000):
        await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    for _ in range(66000):
        await RisingEdge(dut.clk)

    result = safe_read(dut.uo_out)
    assert result is not None, "FAIL Test 2: Output is X after roll"
    assert 1 <= result <= 6, "FAIL Test 2: dice_val out of range, got " + str(result)
    cocotb.log.info("PASS Test 2: After roll, dice_val = " + str(result))

    # Test 3: result holds stable between rolls
    stable = result
    for _ in range(100):
        await RisingEdge(dut.clk)
    result = safe_read(dut.uo_out)
    assert result == stable, "FAIL Test 3: Result changed! Was " + str(stable) + " now " + str(result)
    cocotb.log.info("PASS Test 3: Result stable " + str(result))

    cocotb.log.info("ALL TESTS PASSED")